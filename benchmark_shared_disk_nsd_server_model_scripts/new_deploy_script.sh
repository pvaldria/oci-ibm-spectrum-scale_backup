#!/bin/bash

set -x

# For GUI node:
#yum -y install gpfs.base gpfs.gpl gpfs.msg.en_US gpfs.gskit gpfs.license* gpfs.ext gpfs.crypto gpfs.compression gpfs.adv gpfs.gss.pmsensors gpfs.docs gpfs.java gpfs.kafka gpfs.librdkafka gpfs.gui gpfs.gss.pmcollector
# For non-GUI node:
yum -y install gpfs.base gpfs.gpl gpfs.msg.en_US gpfs.gskit gpfs.license* gpfs.ext gpfs.crypto gpfs.compression gpfs.adv gpfs.gss.pmsensors gpfs.docs gpfs.java gpfs.kafka gpfs.librdkafka

# Build the GPFS potability layer.
/usr/lpp/mmfs/bin/mmbuildgpl

# Up date the PATH environmental variable.
echo -e '\nexport PATH=/usr/lpp/mmfs/bin:$PATH' >> ~/.bash_profile

echo "ss-server-1.privateb0.ibmssvcnv3.oraclevcn.com:quorum-manager
ss-server-2.privateb0.ibmssvcnv3.oraclevcn.com:quorum-manager
ss-server-3.privateb0.ibmssvcnv3.oraclevcn.com:quorum-manager
ss-compute-1.privateb0.ibmssvcnv3.oraclevcn.com
ss-compute-2.privateb0.ibmssvcnv3.oraclevcn.com
ss-compute-3.privateb0.ibmssvcnv3.oraclevcn.com
ss-compute-4.privateb0.ibmssvcnv3.oraclevcn.com
ss-compute-5.privateb0.ibmssvcnv3.oraclevcn.com
ss-compute-6.privateb0.ibmssvcnv3.oraclevcn.com" > /root/node.stanza


# Create the local hosts file to avoid DNS lookup issue, and copy it to all other nodes.
# TODO

for x_fqdn in `cat /tmp/allnodehosts ` ; do
  echo $x_fqdn
  ip=`nslookup $x_fqdn  | grep "Address: " | gawk '{print $2}'`
  x=${x_fqdn%%.*}
  echo "$ip $x_fqdn $x" >> /etc/hosts
done ;

exit 0;
