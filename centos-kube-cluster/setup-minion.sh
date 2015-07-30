#!/bin/bash

#Fix name resolution first
dnsname=$1
dnsip=$(ping -c 1 $dnsname | gawk -F'[()]' '/PING/{print $2}')
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

export HOSTNAME=`hostname`
	
sed -i "s/127.0.0.1:8080/kube-master:8080/g" /etc/kubernetes/config

sed -i "s/127.0.0.1:4001/kube-master:4001/g" /etc/sysconfig/flanneld
sed -i 's\^FLANNEL_ETCD_KEY=.*\FLANNEL_ETCD_KEY="/flannel/network"\g' /etc/sysconfig/flanneld

# Configure the Kubelet Service
sed -i 's/^KUBELET_ADDRESS=.*/KUBELET_ADDRESS="--address=0.0.0.0"/g' /etc/kubernetes/kubelet
sed -i 's/^KUBELET_HOSTNAME=.*/KUBELET_HOSTNAME=/g' /etc/kubernetes/kubelet
sed -i 's\^KUBELET_API_SERVER=.*\KUBELET_API_SERVER="--api_servers=http://kube-master:8080"\g' /etc/kubernetes/kubelet

service=flanneld
systemctl enable $service
systemctl restart $service
systemctl status $service 

sleep 10

for service in kube-proxy kubelet docker; do
    systemctl enable $service
    systemctl restart $service
    systemctl status $service 
done
