#!/bin/bash
set -x
export intfc=eth0
export IP=`ifconfig $intfc | grep 'inet addr:' | cut -d: -f2 | awk '{ print $1}'`
export HOSTNAME=`hostname`
#save stdout and stderr to file descriptors 3 and 4, then redirect them to "config.log"
#exec 3>&1 4>&2 >wlp_config.log 2>&1
#Fix the etc/hosts file
tee -a /etc/hosts <<EOF
$IP $HOSTNAME 
EOF


#install chef client
curl -L https://www.getchef.com/chef/install.sh | bash

#Set up the chef environment
mkdir -p /etc/chef

tee /etc/chef/client.rb <<EOF
log_location     STDOUT
chef_server_url  "https://jmchefserver.cloudapp.net/organizations/mayo"
validation_client_name "mayo-validator"
#Using default node name (fqdn)
EOF

tee /etc/chef/validation.pem <<EOF
-----BEGIN RSA PRIVATE KEY-----
MIIEpAIBAAKCAQEAynl8zyYUrI8QNDGlmpf4hSg08SmVJCQs6stFrludtuN/sfmM
xHurj83ZdTSNC7PaqqoMJczO0GDQ3Lzue0B1fHZ+ilnMrsst7C1CHlJhh+uZv0E/
vWhU6yEP2jK3RA9wkBqsGyKjBqyuT2cn6+ne459SQBQ6NAnbKjg+0lXPzXIVGOeM
F1UwI4uyyJs0DiUlYHwTROMgQyZVcMG4j0vDmPjXN8ekuLmrsLC5v8CWEdte48oL
/vrmnl4K1Tr6yiThk2jQUwkn75Sjb5TOL+D5yS+bthyB4m7KuI9uRtsRZUscAbJ1
4UTJzK9ZQOvmfrdEJE2mn/zkmiA5DyTtGgxIqQIDAQABAoIBAQCUfG/ZgrXarrhV
bqtiKl0pWgkpazNi49zE+/nIGowZGdIF9VsUpRV2SqJVYAqoMGgGjNqHxiFNlBLY
Lv4+CVGfy06Vq7F95qdw8ufwUL4R7eg86F8USrUsEn0LqfHYyfHk3IqnA8nHFVBo
DuCqFENPbwHk2HCuxSOjXMhFfIT+xoHaIV07FbkKGbnLWzmJ8l9i2ijMornU//Qt
UIbQ3DGNT8o9sjR2icDszDdkutdmj+G+H+KL7jlEVEBSoaKPDEIasjSp1TSWvkaK
0oeIg9r+hBMjw6uA+RtwnU3ttxp2pA9QqB4881ejeY/X7mqJaKHonQ8BSSysLmnp
ChbQg2lhAoGBAPp5aq0NjK/yRTbWTzKbBus/gsCgORAVg8/gpXYBzRd3Zyxxihmh
5IgeVz8SuBifxYrQRhpT0o8xfssR1QOHDHUtYkD4P5uw/6UPWALpHQENpDoJIoa0
2Pa/2BrwwVPlF+qnY31Ur/JiMsf7QglbrzPR3czSWCdd5losVA4fyh0VAoGBAM7w
/Jej2eK430IQP1hhvmAyHerbvgupsyJNlEkbhk7udboV2OIWZ8H89S5ae4eyaU2P
262DJCNMM8FO/oUR6BXGUMr31Uj7ds6frjP3tqsy4h6NdfwiJsTuXkDxqNGHlGPg
LQlgAwrrHTIUmEi1+LH74HxrB1JIk+Bm0OoV2SpFAoGBAMyDLOYF5TSYZYlD7UCN
slWM8u7jJBSM7KZkb9Vt3Q7nEJgKUM9jD51Q4L4AQ87fTcVtD4BZptgCetvGQJ5z
u2lF2C7iQ9WU7PfSEnO18Ve10r0MTmOc8HZw6Dv/Dmu46BFSAXsJFeyb34jIEABi
Gyj9l9OwgAgMtJQ2E5/Atx+NAoGAaYfxeC9BtOIMUHdSpnKqEApewV8wKmhvBqZD
YYjc1DG87ZmokZtVbFLggbP43Pl5w+kB4RlIe4untQPgveGk1j3dA7ShGufJ7ZL2
1l+T0vhO4b/IFD0iQjlA7aOPMNMQNGKk9Ov2gUHnEJv6ENJjsfg9wZUfFbIXX09v
aICdz3UCgYBY+F1rEzBwq5kbjM/s5C+20gFG1y4TuPPYmiypRNmpozocntnb7QEG
jKEMAEPQ+lRULoMBgwp5Vi7ni+bTC3uI+Wpwsc7DDpU9tiCEPs+Gt+GB/IZyZTha
JYE6Sv398VkGeOGLzOF1yN5kp4D7Dh8SL6TMFtk7HMfxyEl6EbonnA==
-----END RSA PRIVATE KEY-----
EOF

#Need to get the SLL certificate from the Chef server
knife ssl fetch https://jmchefserver.cloudapp.net/organizations/mayo -c /etc/chef/client.rb


#Install Websphere Liberty Profile
chef-client -r "recipe[wlp]"
#restore stdout and stderr
#exec 1>&3 2>&4
