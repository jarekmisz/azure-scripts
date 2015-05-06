#!/bin/bash

set -x

HOSTNAME=`hostname`

tee -a ~/index.html <<EOF
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">
 <html>
 <head>
     <title>Home of $HOSTNAME</title>
 </head>
 <body>
     <b>Hello from HTTP Server on $HOSTNAME</b>
     <p>
     The intention is to test load balancer and autoscaling.
     </p>
 </body>
 </html>
EOF

screen -dmS "SimpleHTTPServer"  sh -c "sudo python -m SimpleHTTPServer 8080"
sleep 3
