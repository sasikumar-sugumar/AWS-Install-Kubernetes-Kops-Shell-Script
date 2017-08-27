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

# Get the latest snapshot
git clone https://github.com/sasikumar-sugumar/AWS-Install-Kubernetes-Kops-Shell-Script.git myproject

# Change directory
cd myproject

# Execute Permission
chmod 777 Install-Kubernetes.sh

# Run the Script
./Install-Kubernetes.sh


### Prerequisites

- [AWS Command Line](https://aws.amazon.com/cli/)
- [./jq](https://stedolan.github.io/jq/)
- [IAM user permission]
    - The IAM user to create the Kubernetes cluster must have the following permissions:
    - AmazonEC2FullAccess
    - AmazonRoute53FullAccess
    - AmazonS3FullAccess
    - IAMFullAccess
    - AmazonVPCFullAccess
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
        This install kops
    - [x] installKubectl.
        This install kubectl
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

## Running the tests

Explain how to run the automated tests for this system

### Break down into end to end tests

Explain what these tests test and why

```
Give an example
```

### And coding style tests

Explain what these tests test and why

```
Give an example
```

## Deployment

Add additional notes about how to deploy this on a live system

## Built With

* [Dropwizard](http://www.dropwizard.io/1.0.2/docs/) - The web framework used
* [Maven](https://maven.apache.org/) - Dependency Management
* [ROME](https://rometools.github.io/rome/) - Used to generate RSS Feeds

## Contributing

Please read [CONTRIBUTING.md](https://gist.github.com/PurpleBooth/b24679402957c63ec426) for details on our code of conduct, and the process for submitting pull requests to us.

## Versioning

We use [SemVer](http://semver.org/) for versioning. For the versions available, see the [tags on this repository](https://github.com/your/project/tags). 

## Authors

* **Billie Thompson** - *Initial work* - [PurpleBooth](https://github.com/PurpleBooth)

See also the list of [contributors](https://github.com/your/project/contributors) who participated in this project.

## License

This project is licensed under the MIT License - see the [LICENSE.md](LICENSE.md) file for details

## Acknowledgments

* Hat tip to anyone who's code was used
* Inspiration
* etc
