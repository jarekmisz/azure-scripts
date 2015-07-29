#!/bin/bash

cat << EOF > /etc/yum.repos.d/virt7-testing.repo
[virt7-testing]
name=virt7-testing
baseurl=http://cbs.centos.org/repos/virt7-testing/x86_64/os/
gpgcheck=0
EOF

yum -y install docker docker-logrotate kubernetes etcd flannel
#Common config
export HOSTNAME=`hostname`
	
sed -i "s/127.0.0.1:8080/kube-master:8080/g" /etc/kubernetes/config

sed -i "s/127.0.0.1:4001/kube-master:4001/g" /etc/sysconfig/flanneld
sed -i 's\^FLANNEL_ETCD_KEY=.*\FLANNEL_ETCD_KEY="/flannel/network"\g' /etc/sysconfig/flanneld

cp /etc/etcd/etcd.conf /etc/etcd/etcd.conf.orig
sed -i 's\^ETCD_NAME=.*\ETCD_NAME='$HOSTNAME'\g' /etc/etcd/etcd.conf
sed -i 's\^#ETCD_LISTEN_PEER_URLS=.*\ETCD_LISTEN_PEER_URLS="http://0.0.0.0:2380"\g' /etc/etcd/etcd.conf
sed -i 's\^ETCD_LISTEN_CLIENT_URLS=.*\ETCD_LISTEN_CLIENT_URLS="http://0.0.0.0:4001"\g' /etc/etcd/etcd.conf
sed -i 's\^#ETCD_INITIAL_ADVERTISE_PEER_URLS=.*\ETCD_INITIAL_ADVERTISE_PEER_URLS="http://'$HOSTNAME':2380"\g' /etc/etcd/etcd.conf
sed -i 's\^ETCD_ADVERTISE_CLIENT_URLS=.*\ETCD_ADVERTISE_CLIENT_URLS="http://'$HOSTNAME':4001"\g' /etc/etcd/etcd.conf

sed -i 's/^KUBE_API_ADDRESS=.*/KUBE_API_ADDRESS="--address=0.0.0.0"/g' /etc/kubernetes/apiserver
sed -i "s/127.0.0.1:4001/kube-master:4001/g" /etc/kubernetes/apiserver
# Insert between 
list='kube-minion0'
let END=$1 i=1
while ((i<END)); do list=$list',kube-minion'$i; echo $list; let i++; done
sed -i 's/^# defaults from config and apiserver.*/KUBELET_ADDRESSES="--machines='$list'"/g' /etc/kubernetes/controller-manager

for service in etcd kube-apiserver kube-controller-manager kube-scheduler; do 
    systemctl enable $service
    systemctl restart $service
    systemctl status $service 
done

cat << EOF > ./flannel-config.json
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
EOF

curl -L http://kube-master:4001/v2/keys/flannel/network/config -XPUT --data-urlencode value@./flannel-config.json

service=flanneld
systemctl enable $service
systemctl restart $service
systemctl status $service 