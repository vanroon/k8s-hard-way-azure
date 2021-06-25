#!/bin/bash

echo "Deploy dashboard"
kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.0.0-rc5/aio/deploy/recommended.yaml


echo "access dashboard with link: http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/#/"

echo "Create Service account"

kubectl create serviceaccount dashboard -n default

echo "Add cluster binding rules"

kubectl create clusterrolebinding dashboard-admin -n default --clusterrole=cluster-admin --serviceaccount=default:dashboard

echo "Printing token to use to login to the dashboard"
kubectl get secret $(kubectl get serviceaccount dashboard -o jsonpath="{.secrets[0].name}") -o jsonpath="{.data.token}" | base64 --decode




echo -e "\n\nCreate proxy to dashboard"
kubectl proxy
