#!/bin/bash
set -e 												# Any subsequent(*) commands which fail will cause the shell script to exit immediately

export KOPS_CLUSTER_NAME='<Cluster Name>' 			# Cluster name should FQDN, example : myfirstcluster.example.com
export KOPS_VPC="<VPC Name>" 						# VPC will create with given name.
export KOPS_STATE_STORE="gs://<bucket name>/"  		# Bucket will create with given name. Bucket name should be Unique globally.
export NODE_ZONES="<zones>"							# Enter Worker nodes zones with comma separated.
export MASTER_ZONES="<zones>"						# Enter Master nodes zones with comma separated.
													# https://cloud.google.com/compute/docs/regions-zones/
export NODE_COUNT=3 								# Enter Worker nodes count.
export MASTER_COUNT=1								# Enter Master nodes count. If specifying both zones and master node count, the count should match with no.of zones.
export MASTER_SIZE="<Machine Type>"					# Master node machine type.
export NODE_SIZE="<Machine Type>"					# Worker node machine type.
													# https://cloud.google.com/compute/docs/machine-types
export KOPS_DNS_ZONE="<DNS Zone Name>"				# DNS zone name. It should be created before the cluster creation

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
	# Create a VPC
	gcloud compute networks 	\
		create ${KOPS_VPC} 		\
		--project=${PROJECT} 	\
		--subnet-mode=auto
	
	# Create a Storage Bucket
	gsutil mb ${KOPS_STATE_STORE}
	
	# Create Kubernetes Cluster
	kops create cluster --name=${KOPS_CLUSTER_NAME}  \
		--state=${KOPS_STATE_STORE} 				 \
		--zones=${NODE_ZONES} 						 \
		--master-zones=${MASTER_ZONES}				 \
		--vpc=${KOPS_VPC}							 \
		--dns-zone=${KOPS_DNS_ZONE} 			 	 \
		--project=${PROJECT} 						 \
		--node-count=${NODE_COUNT}					 \
		--node-size=${NODE_SIZE}					 \
		--master-count=${MASTER_COUNT}				 \
		--master-size=${MASTER_SIZE}				 \
		--cloud gce									 \
		--yes
	;;
delete)
	# Delete Kubernetes Cluster
	kops delete cluster --name=${KOPS_CLUSTER_NAME} --state=${KOPS_STATE_STORE}  --yes
	
	# Delete Storage Bucket
	gsutil rm -r ${KOPS_STATE_STORE}
	
	# Delete VPC
	gcloud compute networks delete ${KOPS_VPC}
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