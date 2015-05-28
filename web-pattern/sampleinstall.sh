#!/bin/bash
set -x
export WLP_BASE_DIR="/opt/was/liberty"
export FILE_REPO_URI="http://jmchefserver.cloudapp.net:8080/repos"
export HOSTNAME=`hostname`
export MONGODBHOST="jmmongo.cloudapp.net"
if [ ! -d "$WLP_BASE_DIR" ]; then
 echo "Liberty not installed in $WLP_BASE_DIR...Exiting script." 
 exit 1
fi
yum -y install screen
#Install the sample app and its dependencies
cd $WLP_BASE_DIR
wget "$FILE_REPO_URI/install_images/mongodbsample/mongoDBSample.jar"
printf '\n\n' | java -jar mongoDBSample.jar
#Fix the server.xml
sed -i 's/id="defaultHttpEndpoint"/id="defaultHttpEndpoint" host="*"/g' "$WLP_BASE_DIR/wlp/usr/servers/mongoDBSample/server.xml"
sed -i "s/hostNames=\"localhost\"/hostNames=\"$MONGODBHOST\"/g" "$WLP_BASE_DIR/wlp/usr/servers/mongoDBSample/server.xml"
cd wlp/bin
screen -S mongoDBSample -d -m ./server run mongoDBSample
echo "MongoDB sample running at http://$HOSTNAME.cloudapp.net:9121/mongoDBApp"
 