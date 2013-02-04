quantum-l3-test
===============

Test L3 Quantum model

There are a few assumptions being made in this script:

- The script creates keys and places them in the /root/.ssh/ path therefore we are assuming you are running this script as root.  If you are not running as 'root' then you need to change the path in the 'create_vm' file for the ssh-keygen line.

- If you have existing files in the /root/.ssh/ path then the script will see them and prompt you to overwrite. You need to overwrite the files or you will end up getting a "permissions denied" error when ssh'ing into the test instance.

Instructions:

1) cd into the quantum-l3-test directory you just cloned 

2) Run:  ./create_vm
  this will run net_setup on its own

3) You will be prompted to enter your specific network values for the public/private networks as well as altering the default path where the Ubuntu Precise image is downloaded from (i.e. your own local mirror). 

4) You should be able to log into the host with "ssh ubuntu@{fixed or floating ip of instance}"



To reset the Quantum settings created by the script and relaunch the test VM from scratch:

1) ./reset

2) ./create_vm

