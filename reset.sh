#!/bin/bash
source ~/openrc
# Our generic lab model is to create a network that uses the VLAN id to help
# define Subnet IPs.  We'll do this here for both our "public" access network
# and for the OpenStack L3 agent NATd network

#if ! `quantum port-delete -- private_router_1 --device_owner network:router_gateway`; then
# echo 'cloud not delete router gateway port'
# exit 1
#fi

if ! nova delete precise_test_vm ; then
 echo perhaps you did not create a vm?
 echo continuing...
fi

PRIV_SUBNET_ID=`quantum subnet-list | grep '192.' | awk -F' ' '{print $2}'`
FLOAT_ID=`quantum floatingip-list | grep 192 | awk -F' ' '{print $2}'`
 if ! quantum floatingip-delete $FLOAT_ID >&/dev/null ; then
  echo perhaps you did not create a floating ip?
  echo continuing...
 fi
#if ! quantum router-interface-delete private_router_1 "${PRIV_SUBNET_ID}" ;then
# echo 'could not delete router port'
# exit 1
#fi

if ! quantum router-gateway-clear private_router_1 ; then
 echo 'could not clear router gateway'
# exit 1
fi

if ! quantum net-delete public  ; then
 echo 'public net not deleted'
# exit 1
fi
if ! quantum net-delete private ; then
 echo 'private net not delted'
# exit 1
fi

if ! quantum router-delete private_router_1 ; then
 echo 'router not delted'
# exit 1
fi

exit 0
