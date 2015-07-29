#!/bin/bash

cat << EOF > /etc/yum.repos.d/virt7-testing.repo
[virt7-testing]
name=virt7-testing
baseurl=http://cbs.centos.org/repos/virt7-testing/x86_64/os/
gpgcheck=0
EOF

yum -y install docker docker-logrotate kubernetes etcd flannel

export HOSTNAME=`hostname`
	
sed -i "s/127.0.0.1:8080/kube-master:8080/g" /etc/kubernetes/config

sed -i "s/127.0.0.1:4001/kube-master:4001/g" /etc/sysconfig/flanneld
sed -i 's\^FLANNEL_ETCD_KEY=.*\FLANNEL_ETCD_KEY="/flannel/network"\g' /etc/sysconfig/flanneld

# Configure the Kubelet Service
sed -i 's/^KUBELET_ADDRESS=.*/KUBELET_ADDRESS="--address=0.0.0.0"/g' /etc/kubernetes/kubelet
sed -i 's/^KUBELET_HOSTNAME=.*/KUBELET_HOSTNAME=/g' /etc/kubernetes/kubelet
sed -i 's\^KUBELET_API_SERVER=.*\KUBELET_API_SERVER="--api_servers=http://kube-master:8080"\g' /etc/kubernetes/kubelet

for service in kube-proxy kubelet docker flanneld; do
    systemctl enable $service
    systemctl restart $service
    systemctl status $service 
done
