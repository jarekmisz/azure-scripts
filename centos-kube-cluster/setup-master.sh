#!/bin/bash

cat << EOF > /etc/yum.repos.d/virt7-testing.repo
[virt7-testing]
name=virt7-testing
baseurl=http://cbs.centos.org/repos/virt7-testing/x86_64/os/
gpgcheck=0
EOF

yum -y install docker docker-logrotate kubernetes etcd flannel
