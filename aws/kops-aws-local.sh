#!/bin/bash
set -e												# Any subsequent(*) commands which fail will cause the shell script to exit immediately

export KOPS_CLUSTER_NAME='<Cluster Name>' 			# Cluster name should FQDN, example : myfirstcluster.k8s.local
export KOPS_STATE_STORE="s3://<bucket-name>"  	    # Create a S3 bucket and enter name of the bucket. Bucket name should be Unique globally.
export NODE_ZONES="<zones>"							# Enter Worker nodes zones with comma separated.
export MASTER_ZONES="<zones>"						# Enter Master nodes zones with comma separated.
                                                    # https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/using-regions-availability-zones.html
export NODE_COUNT= 									# Enter Worker nodes count.
export MASTER_COUNT=								# Enter Master nodes count.
export MASTER_SIZE="<Machine Type>"					# Master node machine type.
export NODE_SIZE="<Machine Type>"					# Worker node machine type.
													# https://aws.amazon.com/ec2/instance-types/
export KOPS_FEATURE_FLAGS=AlphaAllowGCE


PROJECT=`gcloud config get-value project`

if ! type kops > /dev/null; then
  	curl -Lo kops https://github.com/kubernetes/kops/releases/download/$(curl -s https://api.github.com/repos/kubernetes/kops/releases/latest | grep tag_name | cut -d '"' -f 4)/kops-linux-amd64
	chmod +x ./kops
	sudo mv ./kops /usr/local/bin/
fi

if ! type kubectl > /dev/null; then
	curl -LO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl
	chmod +x ./kubectl
	sudo mv ./kubectl /usr/local/bin/
fi

case "$1" in

create)
	# Create Kubernetes Cluster
	kops create cluster --name=${KOPS_CLUSTER_NAME}  \
		--state=${KOPS_STATE_STORE} 				 \
		--zones=${NODE_ZONES} 						 \
		--master-zones=${MASTER_ZONES}				 \
		--node-count=${NODE_COUNT}					 \
		--node-size=${NODE_SIZE}					 \
		--master-count=${MASTER_COUNT}				 \
		--master-size=${MASTER_SIZE}				 \
		--cloud aws									 \
		--yes
	;;
delete)
	# Delete Kubernetes Cluster
	kops delete cluster --name=${KOPS_CLUSTER_NAME} --state=${KOPS_STATE_STORE}  --yes
	;;
list)
	# Get Clusters
	kops get cluster --state=${KOPS_STATE_STORE}
	;;
validate)
	# Get Clusters
	kops validate cluster
	;;
*)
   echo "Usage: $0 {create|delete|list|validate}"

esac
exit 0 
