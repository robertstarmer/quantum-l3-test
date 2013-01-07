#!/bin/bash
#
# assumes that openstack credentails are set in this file
source /root/openrc

#!/bin/bash
# Our generic lab model is to create a network that uses the VLAN id to help
# define Subnet IPs.  We'll do this here for both our "public" access network
# and for the OpenStack L3 agent NATd network
if [ -z ${VLAN:?VLAN must be set} ] ; then
 echo 'please set your VLAN id'
 exit 1
fi

# otherwise, use an Ubuntu precise image. This is a larger image, but a little more
# feature-full and realistic
wget http://192.168.26.163/precise.img
# import that image into glance
glance image-create --name="precise-amd64" --is-public=true --container-format=ovf --disk-format=qcow2 < precise.img
# Caputre the Image ID so taht we can call the right UUID for this image
IMAGE_ID=`glance index | grep 'precise-amd64' | head -1 |  awk -F' ' '{print $1}'`

login_user='ubuntu'

# create a pub/priv keypair
ssh-keygen -f /tmp/id_rsa -t rsa -N ''

#add the public key to nova.
nova keypair-add --pub_key /tmp/id_rsa.pub key_percise

# create a security group so that we can allow ssh, http, and ping traffic
# when we add a floating IP (assuming you are adding floating IPs)
nova secgroup-create nova_test 'Precise test security group'
nova secgroup-add-rule nova_test tcp 22 22 0.0.0.0/0
nova secgroup-add-rule nova_test tcp 80 80 0.0.0.0/0
nova secgroup-add-rule nova_test icmp -1 -1 0.0.0.0/0

# request a floating IP address, and extract the address from the results message
# floating_ip=`nova floating-ip-create | grep None | awk '{print $2}'`

# initialize a network in quantum for use by VMs and assign it a non-routed subnet
NET_ID=`quantum net-list | grep private | awk -F' ' '{ print $2 }'`

instance_name='precise_test_vm'
# Boot the added image against the "1" flavor which by default maps to a micro instance.   Include the percise_test group so our address will work when we add it later 
nova boot --flavor 1 --security_groups nova_test --nic net-id=${NET_ID} --image ${IMAGE_ID} --key_name key_percise $instance_name

# let the system catch up
sleep 15

# Show the state of the system we just requested.
nova show $instance_name

## wait for the server to boot
#sleep 15

### Now add the floating IP we reserved earlier to the machine.
#nova add-floating-ip $instance_name $floating_ip
## Wait  and then try to SSH to the node, leveraging the private key
## we generated earlier.
#sleep 15
#ssh $login_user@$floating_ip -i /tmp/id_rsa
#
# We use 192.168.VLAN.0/24 as our public network range(s)
PUB_NET="192.168.${VLAN}.0/24"
# We use 10.VLAN.1.0/24 for our private default network(s)
PRIV_NET="10.${VLAN}.1.0/24"
# subnet to it
PUB_NET_ID=`quantum net-list | grep ' public ' | awk -F' ' '{print $2}'`
PRIV_ROUTER=`quantum router-list | grep private_router_1 | awk -F' ' '{print $2}'`

# Let's see if we can hit our node
ip netns exec qrouter-${PRIV_ROUTER} ip addr list
if ! ip netns exec qrouter-${PRIV_ROUTER} ping -c 3 10.${VLAN}.1.3 ;then
 echo '!!!! Cant ping the host!!!'
 echo 'Exiting. Fix your network, then try again'
 exit 1
fi

# Now, for a floating IP
VM_PORT_ID=`quantum port-list | grep "10.${VLAN}.1.3" | awk -F' ' '{print $2}'`
FLOAT_ID=`quantum floatingip-create ${PUB_NET_ID} | grep ' id ' | awk -F' ' '{print $4}'`
FLOAT_IP=`quantum floatingip-list | grep ${FLOAT_ID} | awk -F' ' '{print $3}'`
echo "Floating IP: ${FLOAT_IP}"
quantum floatingip-associate ${FLOAT_ID} ${VM_PORT_ID}
