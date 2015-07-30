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

1. The Azure virtual network, on which the VMs reside:
* kubeVNET - 10.11.50.0/16
* Subnet-1 - 10.11.50.0/24

The VMs get static addresses on Subnet-1:

| Node Name   | IP Address |
|:--- |:---|
| kube-master | 10.11.50.9 |
| kube-minion0 | 10.11.50.10 |
| ... | ... |
| kube-minion9 | 10.11.50.19 |

2. Ovelay network managed by flannel that is used by docker containers. The flannel network definition is shown below:

{
    "Network": "10.254.0.0/16",
    "SubnetLen": 24,
    "SubnetMin": "10.254.50.0",
    "SubnetMax": "10.254.199.0",
    "Backend": {
        "Type": "vxlan",
        "VNI": 1
    }
}




