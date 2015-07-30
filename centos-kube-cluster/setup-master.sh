#!/bin/bash

#Sanity checks 
if [[ $# -eq 0 ]] ; then
    echo 'You need to pass the number of the minions in the cluster...Exiting...'
    exit 1
fi
if [[ $1 -lt 1 ]] ; then
    echo 'The number of minions needs to be greater than 0...Exiting...'
    exit 1
fi

#Fix name resolution first
dnsname=$2
export dnsip=$(ping -c 1 $dnsname | gawk -F'[()]' '/PING/{print $2}')
sed -i 's/255.255.255.255/'$dnsip'/g' /etc/resolv.conf
#When reboot happens
chmod +x /etc/rc.d/rc.local

cat << EOF >> /etc/azure-nameserver.conf
$dnsip
EOF

#To ensure idenpotance of this script
if [ -e /etc/rc.d/rc.local.original ] ; then
 cp /etc/rc.d/rc.local.original /etc/rc.d/rc.local
else
 cp /etc/rc.d/rc.local /etc/rc.d/rc.local.original
fi	
#Fix the DNS server Ip on consecutive boots, note the quotes around EOF
cat << 'EOF' >> /etc/rc.d/rc.local
if [ -e /etc/azure-nameserver.conf ]
then
 AZURENSIP=$(cat /etc/azure-nameserver.conf)
 sed -i 's/255.255.255.255/'$AZURENSIP'/g' /etc/resolv.conf
fi
EOF

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
sed -i 's\^#ETCD_INITIAL_ADVERTISE_PEER_URLS=.*\ETCD_INITIAL_ADVERTISE_PEER_URLS="http://0.0.0.0:2380"\g' /etc/etcd/etcd.conf
sed -i 's\^#ETCD_INITIAL_CLUSTER=.*\ETCD_INITIAL_CLUSTER="'$HOSTNAME'=http://0.0.0.0:2380"\g' /etc/etcd/etcd.conf
sed -i 's\^ETCD_ADVERTISE_CLIENT_URLS=.*\ETCD_ADVERTISE_CLIENT_URLS="http://0.0.0.0:4001"\g' /etc/etcd/etcd.conf

sed -i 's/^KUBE_API_ADDRESS=.*/KUBE_API_ADDRESS="--address=0.0.0.0"/g' /etc/kubernetes/apiserver
sed -i "s/127.0.0.1:4001/kube-master:4001/g" /etc/kubernetes/apiserver

# Insert between 
typeset -i END i
let END=$1 i=1
list='kube-minion0'
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