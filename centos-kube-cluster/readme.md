#Deploy kubernetes cluster on CentOS 7.1 virtual machines
<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fjarekmisz%2Fazure-scripts%2Fmaster%2Fcentos-cube-cluster%2Fazuredeploy.json" target="_blank">
    <img src="http://azuredeploy.net/deploybutton.png"/>
</a>



This template deploys a kubernetes cluster that consists of a master and 2-10 nodes (minions). The deployment has been tested on CentOS 7.1. It utilizes systemd and etcd. There is just one instance on etcd that runs on the kubernetes master. The master constitues a single point of failure so it really doesn't matter if etcd is highly available.
The naming convention:

* kube-master
* kube-minion0 .. kube-minion9

Couple comments on networking:
There are two layers of networking:
* The Azure virtual network, on which the VMs reside:
** kubeVNET - 10.11.50.0/16
** Subnet-1 - 10.11.50.0/24




The public subnet is fronted by a load-balancer with one dynamically assigned public IP address and as many NAT ports as there are nodes, starting from port 50000.
The template also asks for a dns name and a location for the ip address.
Thus, if you want to connect to node 0, you'll type:

* ssh \<user\>@\<name\>.\<location\>.cloudapp.azure.com -p 50000

The private network is intended for cluster communications only.

The template also configures:

* A storage account where all the virtual hard disks are stored.
* A virtual network where the private and public subnet reside.

The template invokes a custom bash script that configures the second network card on CentOS nodes. By default the second card is recognized but the network stack is not set up.

The limit on the number of nodes is artificial. Alas, ARM does not support arithmetic operators yet, so one has to list all the possible NAT ports for the load-balancer configuration. I listed 10. Feel free to add more and you'll be able to increase the number of nodes. Also, if not all nodes require external connections, you can have as many nodes as the current subnet limit.
