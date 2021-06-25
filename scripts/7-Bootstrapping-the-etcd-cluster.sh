# Bootstrapping the etcd cluster

# these commands must be run on each controller instance


for controller in controller-0 controller-1 controller-2; do
		PUBLIC_IP_ADDRESS=$(az network public-ip show -g kubernetes -n ${controller}-pip --query "ipAddress" -otsv)
		echo "${controller} ip: ${PUBLIC_IP_ADDRESS}"

		echo "-- Downloading etcd release binairies --"
		ssh kuberoot@${PUBLIC_IP_ADDRESS} < bootstrap-etcd.sh

done
