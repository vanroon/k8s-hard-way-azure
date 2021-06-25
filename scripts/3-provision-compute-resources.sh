echo "Create azure resource group"
az group create -n kubernetes -l northeurope

echo "Createing vnet"
az network vnet create -g kubernetes -n kubernetes-vnet --address-prefix 10.240.0.0/24 --subnet-name kubernetes-subnet

# Create firewall (network security group; nsg)
echo "Create firewall"
az network nsg create -g kubernetes -n kubernetes-nsg

# And assign it to the created subnet
echo "Assign firewall to subnet"
az network vnet subnet update \
	-g kubernetes \
	-n kubernetes-subnet \
	--vnet-name kubernetes-vnet \
	--network-security-group kubernetes-nsg

echo "Create firewall rules that allows external SSH and HTTPS"
az network nsg rule create -g kubernetes \
	-n kubernetes-allow-ssh \
	--access allow \
	--destination-address-prefix '*' \
	--destination-port-range 22 \
	--direction inbound \
	--nsg-name kubernetes-nsg \
	--protocol tcp \
	--source-address-prefix '*' \
	--source-port-range '*' \
	--priority 1000

az network nsg rule create -g kubernetes \
	-n kubernetes-allow-api-server \
	--access allow \
	--destination-address-prefix '*' \
	--destination-port-range 6443 \
	--direction inbound \
	--nsg-name kubernetes-nsg \
	--protocol tcp \
	--source-address-prefix '*' \
	--source-port-range '*' \
	--priority 1001

echo "List FW rules"
az network nsg rule list -g kubernetes --nsg-name kubernetes-nsg \
	--query "[].{Name:name, Direction:direction, Port:destinationPortRange}" -o table



echo "Allocate static public IP and Load Balancer"
az network lb create -g kubernetes \
	-n kubernetes-lb \
	--backend-pool-name kubernetes-lb-pool \
	--public-ip-address kubernetes-pip \
	--public-ip-address-allocation static


# Virtual MAchines
echo "Creating availability set and VMs"

# Create availability-set
echo "Creating availability-set"
az vm availability-set create -n controller-as -g kubernetes

# Create  VMs in AS
echo "Creating VMs"

echo "Setting UBUNTULTS"
export UBUNTULTS="Canonical:UbuntuServer:18.04-LTS:18.04.202105120"

for i in 0 1 2; do
	echo "[Controller ${i}] Creating public IP..."
	az network public-ip create -n controller-${i}-pip -g kubernetes > /dev/null

	echo "[Controller ${i}] Creating NIC..."
	az network nic create -g kubernetes \
		-n controller-${i}-nic \
		--subnet kubernetes-subnet \
		--private-ip-address 10.240.0.1${i} \
		--public-ip-address controller-${i}-pip \
		--vnet kubernetes-vnet \
		--ip-forwarding \
		--lb-name kubernetes-lb \
		--lb-address-pools kubernetes-lb-pool > /dev/null

	echo "[Controller ${i}] Creating VM..."
	az vm create -g kubernetes \
		-n controller-${i} \
		--image ${UBUNTULTS} \
		--nics controller-${i}-nic \
		--availability-set controller-as --nsg '' --admin-username 'kuberoot' \
		--generate-ssh-keys > /dev/null
done


# Create availability-set
az vm availability-set create -n worker-as -g kubernetes

# Create  VMs in AS
for i in 0 1; do
	echo "[Worker ${i}] Creating public IP..."
	az network public-ip create -n worker-${i}-pip -g kubernetes > /dev/null

	echo "[Worker ${i}] Creating NIC..."
	az network nic create -g kubernetes \
		-n worker-${i}-nic \
		--subnet kubernetes-subnet \
		--private-ip-address 10.240.0.2${i} \
		--public-ip-address worker-${i}-pip \
		--vnet kubernetes-vnet \
		--ip-forwarding > /dev/null

	echo "[Worker ${i}] Creating VM..."
	az vm create -g kubernetes \
		-n worker-${i} \
		--image ${UBUNTULTS} \
		--nics worker-${i}-nic \
		--tags pod-cidr=10.200.${i}.0/24 \
		--availability-set worker-as --nsg '' --admin-username 'kuberoot' \
		--generate-ssh-keys > /dev/null

done
