#!/bin/bash
set -x 

highAvailability=false
metadataReplica=1
dataReplica=2
for i in `seq 0 10`; do 
if [ $highAvailability = false ] && ([ $metadataReplica -gt 1 ] || [ $dataReplica -gt 1 ]); then
echo $i
if [ $((i % 2)) -eq 0 ]; then
failureGroup=102
else
failureGroup=101
fi
else
failureGroup=100
fi
done

exit 0

  command="mmcrcluster -N node.stanza -r /usr/bin/ssh -R /usr/bin/scp -C ss-demo01.privateb2.ibmssvcnv3.oraclevcn.com -A"
  `$command`
  while [ $? -ne 0 ]; do
    echo "retry..."
    sleep 10s;
    `$command`
  done;



exit 0

highAvailability="true"
if [ $highAvailability = true ]; then
  echo "$highAvailability"
fi

highAvailability="false"
if [ $highAvailability = true ]; then
  echo "$highAvailability"
fi


exit 0 

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
