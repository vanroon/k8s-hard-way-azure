#!/bin/bash

echo "Data encryption smoke test"

kubectl create secret generic kubernetes-the-hard-way \
		  --from-literal="mykey=mydata"

CONTROLLER="controller-0"
PUBLIC_IP_ADDRESS=$(az network public-ip show -g kubernetes \
		  -n ${CONTROLLER}-pip --query "ipAddress" -otsv)

ssh kuberoot@${PUBLIC_IP_ADDRESS} \
		  "sudo ETCDCTL_API=3 etcdctl get \
		    --endpoints=https://127.0.0.1:2379 \
			  --cacert=/etc/etcd/ca.pem \
			    --cert=/etc/etcd/kubernetes.pem \
				  --key=/etc/etcd/kubernetes-key.pem\
				    /registry/secrets/default/kubernetes-the-hard-way | hexdump -C"






echo "Deployment smoke test"
kubectl create deployment nginx --image=nginx
kubectl get pods -l app=nginx

#echo "Port forwarding smoke test"
#POD_NAME=$(kubectl get pods -l app=nginx -o jsonpath="{.items[0].metadata.name}")
#kubectl port-forward $POD_NAME 8080:80


echo "logging smoke test"
kubectl logs $POD_NAME


