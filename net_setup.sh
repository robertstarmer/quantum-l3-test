#!/bin/bash
source ~/openrc
# Our generic lab model is to create a network that uses the VLAN id to help
# define Subnet IPs.  We'll do this here for both our "public" access network
# and for the OpenStack L3 agent NATd network


if [ -z ${VLAN:?VLAN must be set} ] ; then
 echo 'please set your VLAN id'
 exit 1
fi
# We use 192.168.VLAN.0/24 as our public network range(s)
PUB_NET="192.168.${VLAN}.0/24"
# We use 10.VLAN.1.0/24 for our private default network(s)
PRIV_NET="10.${VLAN}.1.0/24"
echo "Public Private Subnets: ${PUB_NET} ${PRIV_NET}"
# Create a the public network, the l3 agent connection, and associate an IP
# subnet to it
if ! PUB_NET_ID=`quantum net-create public --router:external=True | grep ' id ' | awk -F' ' '{print $4}'`; then
 echo 'no public net created'
 exit 1
fi

if ! PUB_SUBNET_ID=`quantum subnet-create public ${PUB_NET} | grep ' id ' | awk -F' ' '{print $4}'` ; then
 echo 'no public subnet created'
 exit 1
fi
echo "Public Net and Subnet ID: ${PUB_NET_ID} ${PUB_SUBNET_ID}"
# Create the private network, ans assicate an IP, L3 cnnection is next
PRIV_NET_ID=`quantum net-create private | grep ' id ' | awk -F' ' '{print $4}'`
PRIV_SUBNET_ID=`quantum subnet-create private ${PRIV_NET} | grep ' id ' | awk -F' ' '{print $4}'`
echo "Private Net and Subnet ID: ${PRIV_NET_ID} ${PRIV_SUBNET_ID}"
# Create a router, and connect it to the private network
PRIV_ROUTER=`quantum router-create private_router_1 | grep ' id ' | awk -F' ' '{print $4}'`
# now attach the router to the private network port
PRIV_ROUTER_INT=`quantum router-interface-add private_router_1 "${PRIV_SUBNET_ID}"| grep ' id ' | awk -F' ' '{print $4}'`
# Now connect the router to the external public newtork
PUB_PRIV_ROUTER=`quantum router-gateway-set private_router_1 "${PUB_NET_ID}" | grep ' id ' | awk -F' ' '{print $4}'`
PUB_NETWORK=`quantum port-list -- --device_id ${PRIV_ROUTER} --device_owner network:router_gateway | grep ip_address | awk -F'"' '{print $8}'`
echo "Private Router and Subnet ID: ${PUB_NETWORK}"

