#!/bin/bash
# Ask the user for the folder to upload
#folder to upload

KOPS_HOME=/home/ubuntu/kops
KUBE_HOME=$KOPS_HOME/kubectl
SUBDOMAIN_NAME=
KUBE_CONFIG_HOME=$KOPS_HOME/$SUBDOMAIN_NAME/kubeconfig
HOSTED_ZONE_FILE=$KOPS_HOME/hosted-zone.json
K8_SUB_DOMAIN_DEFAULT=$KOPS_HOME/k8-sub-domain-default.json
K8_SUB_DOMAIN_ENV=$KOPS_HOME/k8-sub-domain.json
SSH_KEY_HOME=$KOPS_HOME/$SUBDOMAIN_NAME/sshkeys

getSubDomain() {
    read -p "Hello, what is the SUB-DOMAIN ?. : " SUBDOMAIN_NAME
	if [[ $SUBDOMAIN_NAME == "" ]]; then
		echo "Exiting... SUB-DOMAIN is MANDATORY"
		exit
	fi
}

installKubectl() {
	curl -LO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl
	curl -LO https://storage.googleapis.com/kubernetes-release/release/v1.7.0/bin/linux/amd64/kubectl
	chmod +x ./kubectl
	sudo mv ./kubectl /usr/local/bin/kubectl
}

installKops() {
	wget https://github.com/kubernetes/kops/releases/download/1.6.1/kops-linux-amd64
	chmod +x kops-linux-amd64
	sudo mv kops-linux-amd64 /usr/local/bin/kops
}

createS3Bucket() {
	echo "######### Creating S3 Bucket $SUBDOMAIN_NAME ######"
	aws s3 rb s3://$SUBDOMAIN_NAME-kubernetes-state
	aws s3 mb s3://$SUBDOMAIN_NAME-kubernetes-state --region us-east-1
	echo "######### export KOPS_STATE_STORE ######"
	export KOPS_STATE_STORE=s3://$SUBDOMAIN_NAME-kubernetes-state
	echo "#########  S3 Bucket Creation Complete ######"
}

createSSHKeys() {
	echo "######### Creating SSH Keys ######"
	#create directory for subdomain
	mkdir -p $KOPS_HOME/$SUBDOMAIN_NAME
	touch $KUBE_CONFIG_HOME
	export KUBECONFIG="$KUBE_CONFIG_HOME"
	#kube config home
	echo "KUBECONFIG=$KUBECONFIG"
	# create ssh key home
	mkdir $SSH_KEY_HOME
	# generate ssh key
	ssh-keygen -f $SSH_KEY_HOME/id_rsa -t rsa #save the key in the sshkeys
	echo "######### SSH Keys created successfully ######"
}

createSubDomain() {
	rm -rf $HOSTED_ZONE_FILE
	ID=$(uuidgen) && aws route53 create-hosted-zone --name $SUBDOMAIN_NAME --caller-reference $ID >>$HOSTED_ZONE_FILE
}

createComment() {
	COMMENT=$1
	jq '. | .Comment="'"$COMMENT"'"' $K8_SUB_DOMAIN_DEFAULT >>$K8_SUB_DOMAIN_ENV
	echo "Created Comment $COMMENT"
}

createResourceRecordSet() {
	SUBDOMAIN_NAME=$1
	jq '. | .Changes[0].ResourceRecordSet.Name="'"$SUBDOMAIN_NAME"'"' $K8_SUB_DOMAIN_ENV >>$KOPS_HOME/k8-sub-domain-updated.json
	mv $KOPS_HOME/k8-sub-domain-updated.json $K8_SUB_DOMAIN_ENV
	echo "Created Sub-Domain $SUBDOMAIN_NAME"
	createAddress
}

createAddress() {
	ADDRESS_1=$(jq '. | .DelegationSet.NameServers[0]' $KOPS_HOME/hosted-zone.json)
	ADDRESS_2=$(jq '. | .DelegationSet.NameServers[1]' $KOPS_HOME/hosted-zone.json)
	ADDRESS_3=$(jq '. | .DelegationSet.NameServers[2]' $KOPS_HOME/hosted-zone.json)
	ADDRESS_4=$(jq '. | .DelegationSet.NameServers[3]' $KOPS_HOME/hosted-zone.json)
	echo "Created Address $SUBDOMAIN_NAME"
	jq '. | .Changes[0].ResourceRecordSet.ResourceRecords[0].Value='"$ADDRESS_1"' | .Changes[0].ResourceRecordSet.ResourceRecords[1].Value='"$ADDRESS_2"' | .Changes[0].ResourceRecordSet.ResourceRecords[2].Value='"$ADDRESS_3"' | .Changes[0].ResourceRecordSet.ResourceRecords[3].Value='"$ADDRESS_4"' ' $K8_SUB_DOMAIN_ENV >>$KOPS_HOME/k8-sub-domain-updated.json
	mv $KOPS_HOME/k8-sub-domain-updated.json $K8_SUB_DOMAIN_ENV
}

createRecordInParentDomain() {
	PARENT_HOSTED_ZONE_ID=$(aws route53 list-hosted-zones | jq --raw-output '. | .HostedZones[0].Id')
	CHANGE_ID=$(aws route53 change-resource-record-sets \
		--hosted-zone-id $PARENT_HOSTED_ZONE_ID \
		--change-batch file://$KOPS_HOME/k8-sub-domain.json | jq --raw-output '. | .ChangeInfo.Id')
	echo "CHANGE CREATED : $CHANGE_ID"
	waitForINSYNC
}

waitForINSYNC() {
	CHANGE_STATUS="PENDING"
	while [[ $CHANGE_STATUS == "PENDING" ]]; do
		echo "TAKING A NAP FOR 5S"
		sleep 5s
		CHANGE_STATUS=$(aws route53 get-change --id $CHANGE_ID | jq --raw-output '. | .ChangeInfo.Status')
		echo "CHANGE Status : $CHANGE_STATUS"
	done
	createCluster
}

createCluster() {
	# create SSH KEYS
	createSSHKeys
	# create S3 Bucket 
	createS3Bucket
	#Execute create cluster
	echo "#### Creating KOPS Cluster ####"
	SSH_PUBLIC_KEY=$SSH_KEY_HOME/id_rsa.pub
	echo $SSH_PUBLIC_KEY
	kops create cluster --v=0 \
		--cloud=aws \
		--node-count 2 \
		--master-size=t2.medium \
		--master-zones=us-east-1a \
		--zones us-east-1a,us-east-1b \
		--name=$SUBDOMAIN_NAME \
		--node-size=m3.xlarge \
		--ssh-public-key=$SSH_PUBLIC_KEY \
		--dns-zone $SUBDOMAIN_NAME \
		2>&1 | tee $KOPS_HOME/create_cluster.txt

	echo "############# UPDATE CLUSTER STARTS ################"
	#run update to create the cluster
	kops update cluster $SUBDOMAIN_NAME --yes
	echo "############# UPDATE CLUSTER ENDS ################"
}

clean() {
	rm -rf $K8_SUB_DOMAIN_ENV
	rm -rf $KOPS_HOME/k8-sub-domain-updated.json
}

drawMenu() {
	# clear the screen
	tput clear

	# Move cursor to screen location X,Y (top left is 0,0)
	tput cup 3 15

	# Set a foreground colour using ANSI escape
	tput setaf 3
	echo "ACloudSoft INC."
	tput sgr0

	tput cup 5 17
	# Set reverse video mode
	tput rev
	echo "M A I N - M E N U"
	tput sgr0

	tput cup 7 15
	echo "1. Clean Install Kubernetes"

	tput cup 8 15
	echo "2. Install Kubectl"

	tput cup 9 15
	echo "3. Create K8 Cluster"

	# Set bold mode
	tput bold
	tput cup 12 15
	# The default value for PS3 is set to #?.
	# Change it i.e. Set PS3 prompt
	read -p "Enter your choice [1-3] " choice
}

drawMenu
tput sgr0
# set deployservice list
case $choice in
	1)
		echo "#########################"
		echo "Starting a clean INSTALL."
		getSubDomain
		clean
		createSubDomain
		createComment "k8 subdomain $SUBDOMAIN_NAME"
		createResourceRecordSet "$SUBDOMAIN_NAME"
		createRecordInParentDomain

		echo "#########################"
		;;
	2)
		echo "#########################"
		echo "Starting a Kubectl INSTALL."
		installKubectl
		echo "#########################"
		;;
	3)
		echo "#########################"
		echo "Creating Cluster."
		getSubDomain
		createCluster
		echo "#########################"
		;;
	*)
		echo "Error: Please try again (select 1..3)!"
		;;
esac
