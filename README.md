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
- The IAM user to create the Kubernetes cluster must have the following permissions:
    * AmazonEC2FullAccess
    * AmazonRoute53FullAccess
    * AmazonS3FullAccess
    * IAMFullAccess
    * AmazonVPCFullAccess
- A Valid domain 

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
```
    install kops using the below script
    wget https://github.com/kubernetes/kops/releases/download/1.6.1/kops-linux-amd64
	chmod +x kops-linux-amd64
	sudo mv kops-linux-amd64 /usr/local/bin/kops
```
- [x] installKubectl.
```
    install kubectl using the below script
    curl -LO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl
	curl -LO https://storage.googleapis.com/kubernetes-release/release/v1.7.0/bin/linux/amd64/kubectl
	chmod +x ./kubectl
	sudo mv ./kubectl /usr/local/bin/kubectl
```
- [x] createSubDomain.
    * Create Hosted-Zone in route53 for the SUB-DOMAIN provided and write the output to hosted-zone.json in the current directory
- [x] createResourceRecordSet.
    * Replace the placeholders in k8-sub-domian.json template with the actual value using hosted-zone.json and user provided sub-domain
- [x] createRecordInParentDomain.
    * Get the parent domain hosted zone id.
    * Create a record in the parent domain using the k8-sub-domain.json.
    * Grab the Change ID from the above operation
- [x] waitForINSYNC.
    * Wait until the DNS Change takes effect (look for the status INSYNC)
- [x] waitForINSYNC.  
    * Once the status of the DNS change is INSYNC, create SSH Keys.
    * Create the S3 Bucket using the SUB-DOMAIN (e.g : SUB-DOMAIN-kubernetes-state) and export KOPS_STATE_STORE
    * Create and update cluster running --yes
    
```
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

kops update cluster $SUBDOMAIN_NAME --yes   
```

