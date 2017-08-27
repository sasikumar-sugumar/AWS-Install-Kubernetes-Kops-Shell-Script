<!-- If you'd like to use a logo instead uncomment this code and remove the text above this line

  ![Logo](URL to logo img file goes here)

-->

By [Sasikumar Sugumar](http://sasikumarsugumar.io/).

# Install Kubernetes in AWS through Kops

A Script for creating kubernetes cluster up and running in AWS through Kops.

#### Features

- [x] Clean Install Kubernetes.
- [x] Install Kops.
- [x] Install Kubectl.
- [x] Create K8 Cluster.

## Getting Started

The easiest way to get started is to clone the repository:

```
# Get the latest snapshot
git clone https://github.com/sasikumar-sugumar/AWS-Install-Kubernetes-Kops-Shell-Script.git myproject

# Change directory
cd myproject

# Execute Permission
chmod 777 Install-Kubernetes.sh

# Run the Script
./Install-Kubernetes.sh
```


### Prerequisites

- [AWS Command Line](https://aws.amazon.com/cli/)
- [./jq](https://stedolan.github.io/jq/)
- [IAM user permission]
    The IAM user to create the Kubernetes cluster must have the following permissions:
    AmazonEC2FullAccess
    AmazonRoute53FullAccess
    AmazonS3FullAccess
    IAMFullAccess
    AmazonVPCFullAccess
- A valid domain 

### Installing

### Resource Record Set Template

```k8-sub-domian.json
{
    "Comment": "$COMMENT",
    "Changes": [{
        "Action": "CREATE",
        "ResourceRecordSet": {
            "Name": "$SUBDOMAINNAME",
            "Type": "NS",
            "TTL": 300,
            "ResourceRecords": [{
                    "Value": "$VALUE1"
                },
                {
                    "Value": "$VALUE2"
                },
                {
                    "Value": "$VALUE3"
                },
                {
                    "Value": "$VALUE4"
                }
            ]
        }
    }]
}
```

# User Menu Prompt

                 M A I N - M E N U

               1. Clean Install Kubernetes
               2. Install kops
               3. Install Kubectl
               4. Create K8 Cluster

               Enter your choice [1-4]

# Clean Install Kubernetes
    This installs kubernetes from scratch , following sequence of operations are performed
    - [x] installKops.
        install kops using the below script
        wget https://github.com/kubernetes/kops/releases/download/1.6.1/kops-linux-amd64
	    chmod +x kops-linux-amd64
	    sudo mv kops-linux-amd64 /usr/local/bin/kops
    - [x] installKubectl.
        install kubectl using the below script
        curl -LO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl
	    curl -LO https://storage.googleapis.com/kubernetes-release/release/v1.7.0/bin/linux/amd64/kubectl
	    chmod +x ./kubectl
	    sudo mv ./kubectl /usr/local/bin/kubectl
    - [x] createSubDomain.
        Create Hosted-Zone for the SUB-DOMAIN provided and write the output to a file
    - [x] createResourceRecordSet.
        SUBDOMAIN_NAME=$1
	    jq '. | .Changes[0].ResourceRecordSet.Name="'"$SUBDOMAIN_NAME"'"' $K8_SUB_DOMAIN_ENV >>$KOPS_HOME/k8-sub-domain-updated.json
	    mv $KOPS_HOME/k8-sub-domain-updated.json $K8_SUB_DOMAIN_ENV
	    echo "Created Sub-Domain $SUBDOMAIN_NAME"
        rm -rf $HOSTED_ZONE_FILE
	    ID=$(uuidgen) && aws route53 create-hosted-zone --name $SUBDOMAIN_NAME --caller-reference $ID >>$HOSTED_ZONE_FILE
		createSubDomain
		createComment "k8 subdomain $SUBDOMAIN_NAME"
		createResourceRecordSet "$SUBDOMAIN_NAME"
		createRecordInParentDomain


End with an example of getting some data out of the system or using it for a little demo

