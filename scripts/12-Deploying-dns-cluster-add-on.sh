#!/bin/bash

kubectl apply -f https://raw.githubusercontent.com/ivanfioravanti/kubernetes-the-hard-way-on-azure/master/deployments/coredns.yaml

echo "listing pods created by kube-dns deployment"

kubectl get pods -l k8s-app=kube-dns -n kube-system


echo "Verifying - Creating a busybox"

kubectl run busybox --image=busybox:1.28 --command -- sleep 3600
kubectl get pods -l run=busybox


POD_NAME=$(kubectl get pods -l run=busybox -o jsonpath="{.items[0].metadata.name}")

kubectl exec -ti $POD_NAME -- nslookup kubernetes
