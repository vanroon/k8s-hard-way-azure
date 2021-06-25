#!/bin/bash

echo "Bootstrapping k8s workers"o

for worker in worker-0 worker-1; do
		PUBLIC_IP_ADDRESS=$(az network public-ip show -g kubernetes -n ${worker}-pip --query "ipAddress" -otsv)


		ssh kuberoot@${PUBLIC_IP_ADDRESS} < bootstrap-worker-nodes.sh 
	
done


echo "Verifying "

CONTROLLER="controller-0"
PUBLIC_IP_ADDRESS=$(az network public-ip show -g kubernetes \
		  -n ${CONTROLLER}-pip --query "ipAddress" -otsv)

ssh kuberoot@${PUBLIC_IP_ADDRESS} "kubectl get nodes"

