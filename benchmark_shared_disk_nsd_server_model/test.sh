#!/bin/bash
set -x 

x=1; while [ $x -le 5 ]; do echo "Welcome $x times" $(( x++ )); done

./install.sh --accept-all-defaults; while [ $? -ne 0 ]; do echo \"Running ./install.sh --accept-all-defaults\"; ./install.sh --accept-all-defaults;  done ;

#privateIp=`curl -s http://169.254.169.254/opc/v1/vnics/ | jq '.[1].privateIp' | sed 's/"//g' ` ; echo $privateIp
privateIp=null
privateIp="10.0.3.3"
      while [ -z "$privateIp" -o $privateIp = "null" ];
       do
         sleep 10s
         echo "Waiting for 2nd Physical NIC to get configured with hostname"
         privateIp=`curl -s http://169.254.169.254/opc/v1/vnics/ | jq '.[1].privateIp' | sed 's/"//g' ` ; echo $privateIp
       done
       echo "Server nodes with 2 NICs - get hostname for 2nd NIC..."
