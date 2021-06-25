# Bootstrapping the etcd cluster

# these commands must be run on each controller instance


for controller in controller-0 controller-1 controller-2; do
		PUBLIC_IP_ADDRESS=$(az network public-ip show -g kubernetes -n ${controller}-pip --query "ipAddress" -otsv)
		echo "${controller} ip: ${PUBLIC_IP_ADDRESS}"

		echo "-- Downloading etcd release binairies --"
		ssh kuberoot@${PUBLIC_IP_ADDRESS} < bootstrap-k8s-control-plane.sh

done


# Configuring RBAC permissions to allow K8s API server to access the Kubelet API on each worker node

CONTROLLER="controller-0"
PUBLIC_IP_ADDRESS=$(az network public-ip show -g kubernetes \
		  -n ${CONTROLLER}-pip --query "ipAddress" -otsv)

ssh kuberoot@${PUBLIC_IP_ADDRESS} < configure-rbac-for-kubelet-auth.sh


# Setup K8s Frontend LB

az network lb probe create -g kubernetes \
	--lb-name kubernetes-lb \
	--name kubernetes-apiserver-probe \
	--port 6443 \
	--protocol tcp

az network lb rule create -g kubernetes \
	-n kubernetes-apiserver-rule \
	--protocol tcp \
	--lb-name kubernetes-lb \
	--frontend-ip-name LoadBalancerFrontEnd \
	--frontend-port 6443 \
	--backend-pool-name kubernetes-lb-pool \
	--backend-port 6443 \
	--probe-name kubernetes-apiserver-probe



KUBERNETES_PUBLIC_IP_ADDRESS=$(az network public-ip show -g kubernetes \
		  -n kubernetes-pip --query ipAddress -otsv)


curl --cacert ca.pem https://$KUBERNETES_PUBLIC_IP_ADDRESS:6443/version
