#!/bin/bash
## cloud-init bootstrap script

set -x 

#THIS_FQDN=`hostname --fqdn`
#THIS_HOST=$${THIS_FQDN%%.*}

INSTALLERNODE=${InstallerNode}
echo "INSTALLERNODE = $INSTALLERNODE"

SSHPRIVATEKEY="${SSHPrivateKey}"
SSHPUBLICKEY="${SSHPublicKey}"
echo "$SSHPRIVATEKEY" > /root/.ssh/id_rsa
echo "$SSHPUBLICKEY" > /root/.ssh/id_rsa.pub
chmod 600 ~/.ssh/id_rsa
chmod 600 ~/.ssh/id_rsa.pub
chmod 640 ~/.ssh/authorized_keys

IBMSSVERSION="${IBMSSVersion}"
SOFTWAREDOWNLOADURL="${SoftwareDownloadURL}"
SERVERNODECOUNT="${ServerNodeCount}"
SERVERNODEHOSTNAMEPREFIX="${ServerNodeHostnamePrefix}"
COMPUTENODECOUNT="${ComputeNodeCount}"
COMPUTENODEHOSTNAMEPREFIX="${ComputeNodeHostnamePrefix}"

NSDSERVERSINPOOLCOUNT="${NSDServersInPoolCount}"

BLOCKSIZE="${BlockSize}"
DATAREPLICA="${DataReplica}"
GPFSMOUNTPOINT="${GpfsMountPoint}"
SharedDataDiskCount="${SharedDataDiskCount}"
DISKPERNODE=$SharedDataDiskCount
## Preconfigured. 
METADATAREPLICA=2 

COMPANYNAME="${CompanyName}"
COMPANYID="${CompanyID}"
COUNTRYCODE="${CountryCode}"
EMAILADDRESS="${EmailAddress}"

# we might need this for BM shapes
sleep 60s

#######################################################"
################# Turn Off the Firewall ###############"
#######################################################"
echo "Turning off the Firewall..."
which apt-get &> /dev/null
if [ $? -eq 0 ] ; then
    echo "" > /etc/iptables/rules.v4
    echo "" > /etc/iptables/rules.v6

    iptables -F
    iptables -X
    iptables -t nat -F
    iptables -t nat -X
    iptables -t mangle -F
    iptables -t mangle -X
    iptables -P INPUT ACCEPT
    iptables -P OUTPUT ACCEPT
    iptables -P FORWARD ACCEPT
else
    service firewalld stop
    chkconfig firewalld off
fi

#######################################################"
#################   Update resolv.conf  ###############"
#######################################################"
## Modify resolv.conf to ensure DNS lookups work from one private subnet to another subnet
cp /etc/resolv.conf /etc/resolv.conf.backup
rm -f /etc/resolv.conf
#echo "search ${PrivateSubnetsFQDN}" > /etc/resolv.conf
#echo "nameserver 169.254.169.254" >> /etc/resolv.conf

echo `hostname` | grep -q $COMPUTENODEHOSTNAMEPREFIX
if [ $? -eq 0 ] ; then
  echo "search ${PrivateBSubnetsFQDN}" > /etc/resolv.conf
  echo "nameserver 169.254.169.254" >> /etc/resolv.conf
else 
  echo "search ${PrivateBSubnetsFQDN} ${PrivateSubnetsFQDN} " > /etc/resolv.conf
  echo "nameserver 169.254.169.254" >> /etc/resolv.conf
fi


#######################################################"
#######################################################"
echo `hostname` | grep -q $COMPUTENODEHOSTNAMEPREFIX
if [ $? -eq 0 ] ; then
  echo "Compute nodes - get hostname..."
  THIS_FQDN=`hostname --fqdn`
  THIS_HOST=$${THIS_FQDN%%.*}
else
  ifconfig | grep "^eno3d1:\|^enp70s0f1d1:"
  if [ $? -eq 0 ] ; then
    echo "2 NIC setup"
    ifconfig | grep "^enp70s0f1d1:"
      if [ $? -eq 0 ] ; then
        interface="enp70s0f1d1"
      else
        interface="eno3d1"
      fi

      ip route
      ifconfig
      route
      ip addr

      cd /etc/sysconfig/network-scripts/
      
      # Wait till 2nd NIC is configured, since the GPFS cluster will use the 2nd NIC for cluster comm. 
      privateIp=`curl -s http://169.254.169.254/opc/v1/vnics/ | jq '.[1].privateIp' | sed 's/"//g' ` ; echo $privateIp
      while [ -z "$privateIp" -o $privateIp = "null" ];
      do
        sleep 10s
        echo "Waiting for 2nd Physical NIC to get configured with hostname"
        privateIp=`curl -s http://169.254.169.254/opc/v1/vnics/ | jq '.[1].privateIp' | sed 's/"//g' ` ; echo $privateIp
      done
      echo "Server nodes with 2 NICs - get hostname for 2nd NIC..."
      
      #SecondNicFQDNHostname=`hostname -A  | gawk -F" " '{ print $2 }'` ; echo $SecondNicFQDNHostname  ;
      #while [ -z "$SecondNicFQDNHostname" ];
      #do
      #  sleep 10s
      #  echo "Waiting for 2nd Physical NIC to get configured with hostname"
      #  SecondNicFQDNHostname=`hostname -A  | gawk -F" " '{ print $2 }'` ; echo $SecondNicFQDNHostname  ;
      #done
      #echo "Server nodes with 2 NICs - get hostname for 2nd NIC..."
      #THIS_FQDN=$SecondNicFQDNHostname
      #THIS_HOST=$${THIS_FQDN%%.*}

      
      privateIp=`curl -s http://169.254.169.254/opc/v1/vnics/ | jq '.[1].privateIp' | sed 's/"//g' ` ; echo $privateIp
      macAddr=`curl -s http://169.254.169.254/opc/v1/vnics/ | jq '.[1].macAddr' | sed 's/"//g' ` ; echo $macAddr
      subnetCidrBlock=`curl -s http://169.254.169.254/opc/v1/vnics/ | jq '.[1].subnetCidrBlock' | sed 's/"//g' ` ; echo $subnetCidrBlock
      vnicId=`curl -s http://169.254.169.254/opc/v1/vnics/ | jq '.[1].vnicId' | sed 's/"//g' ` ; echo $vnicId


      echo "$subnetCidrBlock via $privateIp dev $interface" >  /etc/sysconfig/network-scripts/route-$interface

      echo "DEVICE=$interface
HWADDR=$macAddr
ONBOOT=yes
TYPE=Ethernet
USERCTL=no
IPADDR=$privateIp
NETMASK=255.255.255.0
MTU=9000" > /etc/sysconfig/network-scripts/ifcfg-$interface


      systemctl status network.service
      # You might see some DHCP error, ignore it.  Its not impacting any functionality I know of.
      systemctl restart network.service

      ip route ; ifconfig ; route ; ip addr ;
      #SecondNicFQDNHostname=`hostname -A  | gawk -F" " '{ print $2 }'` ; echo $SecondNicFQDNHostname  ;
      SecondNicFQDNHostname=`nslookup $privateIp | grep "name = " | gawk -F"=" '{ print $2 }' | sed  "s|^ ||g" | sed  "s|\.$||g"`
      THIS_FQDN=$SecondNicFQDNHostname
      THIS_HOST=$${THIS_FQDN%%.*}
      SecondNICDomainName=$${THIS_FQDN#*.*} 
      echo $SecondNICDomainName
      primaryNICHostname="`hostname`"
      sed -i "s/$primaryNICHostname\$//g" /etc/hosts  
      cat /etc/hosts
      echo "$privateIp $primaryNICHostname" >>/etc/hosts 
      cat /etc/hosts
      if [ -z /etc/oci-hostname.conf ]; then
        echo "PRESERVE_HOSTINFO=2" > /etc/oci-hostname.conf
      fi 
      # https://docs.cloud.oracle.com/iaas/Content/Network/Tasks/managingDHCP.htm#notes
      sed -i "s/^PRESERVE_HOSTINFO=0/PRESERVE_HOSTINFO=2/g" /etc/oci-hostname.conf  
      cat /etc/oci-hostname.conf
    else
      # Servers with only 1 physical NIC
      echo "Server nodes with 2 NICs - get hostname for 1st NIC..." 
      THIS_FQDN="`hostname --fqdn`"
      THIS_HOST="$${THIS_FQDN%%.*}" 
    fi
fi

#######################################################"

mv /etc/yum.repos.d/epel.repo  /etc/yum.repos.d/epel.repo.disabled
mv /etc/yum.repos.d/epel-testing.repo  /etc/yum.repos.d/epel-testing.repo.disabled
sed -i "s/SELINUX=enforcing/SELINUX=disabled/g" /etc/selinux/config
setenforce 0 

###########################
### OS Performance tuning
###########################

# The below applies for both compute and server nodes (storage)
cd /usr/lib/tuned/
cp -r throughput-performance/ sas-performance

echo "#
# tuned configuration
#

[main]
include=throughput-performance
summary=Broadly applicable tuning that provides excellent performance across a variety of common server workloads

[cpu]
force_latency=1
governor=performance
energy_perf_bias=performance
min_perf_pct=100

[vm]
transparent_huge_pages=never

[sysctl]
kernel.sched_min_granularity_ns = 10000000
kernel.sched_wakeup_granularity_ns = 15000000
vm.dirty_ratio = 30
vm.dirty_background_ratio = 10
vm.swappiness=30
" > sas-performance/tuned.conf

tuned-adm profile sas-performance

# Display active profile
tuned-adm active

echo "$THIS_HOST" | grep -q  $COMPUTENODEHOSTNAMEPREFIX
if [ $? -eq 0 ] ; then

  # This might be applicable only for compute-n nodes.  Its unclear from recommendations doc.  
  # require restart for the change to be effective
  echo "* soft nofile 500000
* soft nproc 131072
* hard nofile 500000
* hard nproc 131072
" >> /etc/security/limits.conf

  # To set values for current session
  ulimit -n 500000
  ulimit -u 131072

  # check if the ulimits were updated for the current session
  ulimit -n 
  ulimit -u  

  echo "ulimit -n 500000
ulimit -u 131072
" >>  ~/.bash_profile

  # Made changes on compute node also
  #echo "ifconfig ens3 txqueuelen 2048" >> /etc/rc.d/rc.local
  #echo "ethtool -G ens3 rx 2040"  >> /etc/rc.d/rc.local
  #chmod +x /etc/rc.d/rc.local

  # to make the above changes effective for current session without restart
  #ifconfig ens3 txqueuelen 2048
  #ethtool -G ens3 rx 2040


else
# Assume its server node 

echo "*   soft    memlock      -1 
*   hard    memlock      -1
*   soft    rss          -1
*   hard    rss          -1
*   soft    core          -1
*   hard    core          -1
*   soft    maxlogins     8192
*   hard    maxlogins     8192
*   soft    stack         -1
*   hard    stack         -1
*   soft    nproc         2067554
*   hard    nproc         2067554
" >> /etc/security/limits.conf

echo "* soft nofile 500000
* hard nofile 500000
" >> /etc/security/limits.conf



#echo "ifconfig ens3 txqueuelen 2048" >> /etc/rc.d/rc.local
#echo "ethtool -G ens3 rx 2040"  >> /etc/rc.d/rc.local
#chmod +x /etc/rc.d/rc.local


# to make the above changes effective for current session without restart 
#ifconfig ens3 txqueuelen 2048
#ethtool -G ens3 rx 2040

echo "ulimit -l unlimited
ulimit -m unlimited
ulimit -c unlimited
ulimit -s unlimited
ulimit -u 2067554
ulimit -n 500000
" >>  ~/.bash_profile



fi

cd - 


###########################
### OS Performance tuning - END
###########################


KERNALVERSION=`uname -a  | gawk -F" " '{ print $3 }' | sed "s|.x86_64||g"`
sudo yum install kernel-devel-$KERNALVERSION  -y
yum install kernel-headers-$KERNALVERSION -y 
yum install gcc gcc-c++ -y 




cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup
sed -i 's/#PermitRootLogin yes/PermitRootLogin yes/g' /etc/ssh/sshd_config
service sshd restart


mv /root/.ssh/authorized_keys /root/.ssh/authorized_keys.backup
cp /home/opc/.ssh/authorized_keys /root/.ssh/authorized_keys


#cat /dev/zero | ssh-keygen -b 2048 -t rsa -q -N "" > /dev/null


echo "export PATH=$PATH:/usr/lpp/mmfs/bin" >> ~/.bash_profile

cd /root/.ssh/; cat id_rsa.pub >> authorized_keys ; cd - 

SecondNICDomainName=$${THIS_FQDN#*.*} ; echo $SecondNICDomainName;
echo "Doing nslookup for nodes"
ct=1
if [ $SERVERNODECOUNT -gt 0 ]; then
        while [ $ct -le $SERVERNODECOUNT ]; do
                nslk=`nslookup $SERVERNODEHOSTNAMEPREFIX$${ct}.$SecondNICDomainName`
                ns_ck=`echo -e $?`
                if [ $ns_ck = 0 ]; then
                        hname=`nslookup $SERVERNODEHOSTNAMEPREFIX$${ct}.$SecondNICDomainName | grep Name | gawk '{print $2}'`
                        echo "$hname" >> /tmp/servernodehosts;
                        echo "$hname" >> /tmp/allnodehosts;
                        if [ $ct -le 2 ]; then
				echo "$hname" >> /tmp/adminnodehosts;
    				echo "$hname" >> /tmp/guinodehosts;
			fi
                        ct=$((ct+1));
                else
                        # sleep 10 seconds and check again - infinite loop
                        echo "Sleeping for 10 secs and will check again for nslookup $SERVERNODEHOSTNAMEPREFIX$${ct}.$SecondNICDomainName"
                        sleep 10
                fi
        done;
        echo "Found `cat /tmp/servernodehosts | wc -l` nodes";
        echo `cat /tmp/servernodehosts`;
else
        echo "no server nodes configured"
fi


echo "Doing nslookup for nodes"
ct=1;
if [ $COMPUTENODECOUNT -gt 0 ]; then
        while [ $ct -le $COMPUTENODECOUNT ]; do
                nslk=`nslookup $COMPUTENODEHOSTNAMEPREFIX$ct`
                ns_ck=`echo -e $?`
                if [ $ns_ck = 0 ]; then
                        hname=`nslookup $COMPUTENODEHOSTNAMEPREFIX$ct | grep Name | gawk '{print $2}'`
                        echo "$hname" >> /tmp/computenodehosts;
                        echo "$hname" >> /tmp/allnodehosts;
                        ct=$((ct+1));
                else
                        # sleep 10 seconds and check again - infinite loop
                        echo "Sleeping for 10 secs and will check again for nslookup $COMPUTENODEHOSTNAMEPREFIX$ct"
                        sleep 10
                fi
        done;
        echo "Found `cat /tmp/computenodehosts | wc -l` nodes";
        echo `cat /tmp/computenodehosts`;
else
        echo "no compute nodes configured"
fi



if [ ! -f ~/.ssh/known_hosts ]; then
        touch ~/.ssh/known_hosts
fi

for x_fqdn in `cat /tmp/allnodehosts` ; do

        if [ -z `ssh-keygen -F $x_fqdn` ]; then
                ssh-keyscan -H $x_fqdn > /tmp/keyscan
                cat /tmp/keyscan | grep "ssh-rsa"
                while [ $? -ne 0 ]; do
                          sleep 10s;
                          ssh-keyscan -H $x_fqdn > /tmp/keyscan
                          cat /tmp/keyscan | grep "ssh-rsa"
                done;
                ssh-keyscan -H $x_fqdn >> ~/.ssh/known_hosts
        fi


        x=$${x_fqdn%%.*}
        if [ -z `ssh-keygen -F $x` ]; then
                ssh-keyscan -H $x > /tmp/keyscan
                cat /tmp/keyscan | grep "ssh-rsa"
                while [ $? -ne 0 ]; do
                          sleep 10s;
                          ssh-keyscan -H $x > /tmp/keyscan
                          cat /tmp/keyscan | grep "ssh-rsa"
                done;
                ssh-keyscan -H $x  >> ~/.ssh/known_hosts
        fi

        ip=`nslookup $x_fqdn | grep "Address: " | gawk '{print $2}'`
        if [ -z `ssh-keygen -F $ip` ]; then
                ssh-keyscan -H $ip > /tmp/keyscan
                cat /tmp/keyscan | grep "ssh-rsa"
                while [ $? -ne 0 ]; do
                          sleep 10s;
                          ssh-keyscan -H $ip > /tmp/keyscan
                          cat /tmp/keyscan | grep "ssh-rsa"
                done;
                ssh-keyscan -H $ip  >> ~/.ssh/known_hosts
        fi

done ;



echo "$THIS_HOST" | grep -q $SERVERNODEHOSTNAMEPREFIX
if [ $? -eq 0 ] ; then

  # Wait for multi-attach of the Block volumes to complete.  Only way to do that is via OCI CLI preview tool version which is called from Terraform scripts.  
  # It then creates the below file on all nodes of the cluster. 
  while [ ! -f /tmp/multi-attach.complete ]
  do
    sleep 60s
    echo "Waiting for multi-attach via oci-cli to  complete ..."
  done
fi 

# Run the iscsi commands
# iscsiadm discovery/login
# loop over various ip's but needs to only attempt disks that actually
# do/will exist.

# Compute nodes will only have Shared Data disk attached and Server nodes requires both metadata and data nodes attached (IBM requirement)
echo "$THIS_HOST" | grep -q $SERVERNODEHOSTNAMEPREFIX
if [ $? -eq 0 ] ; then
  total_disk_count=$((SharedDataDiskCount*NSDSERVERSINPOOLCOUNT))
else
  total_disk_count=0
fi

if [ $total_disk_count -gt 0 ] ;
then
  echo "Number of disks : $total_disk_count"
  for n in `seq 2 $((total_disk_count+1))`; do
    echo "Disk $((n-2)), attempting iscsi discovery/login of 169.254.2.$n ..."
    success=1
    while [[ $success -eq 1 ]]; do
      iqn=$(iscsiadm -m discovery -t sendtargets -p 169.254.2.$n:3260 | awk '{print $2}')
      if  [[ $iqn != iqn.* ]] ;
      then
        echo "Error: unexpected iqn value: $iqn"
        sleep 10s
        continue
      else
        echo "Success for iqn: $iqn"
        success=0
      fi
    done
    iscsiadm -m node -o update -T $iqn -n node.startup -v automatic
    iscsiadm -m node -T $iqn -p 169.254.2.$n:3260 -l
  done
else
  echo "Zero block volumes, not calling iscsiadm, Total Disk Count: $((SharedDataDiskCount+SharedMetaDataDiskCount))"
fi

touch /tmp/multi-attach-iscsi.complete


echo "$THIS_HOST" | grep -q $SERVERNODEHOSTNAMEPREFIX
if [ $? -eq 0 ] ; then
  # Run on all server nodes
  # To enable custom disk consistent devicepath discovery for nsds.
  mkdir -p /var/mmfs/etc/
  if [ -f /tmp/nsddevices ]; then
    cp /tmp/nsddevices /var/mmfs/etc/
    chmod +x /var/mmfs/etc/nsddevices
  else 
    exit 1
  fi
fi




#if [ $SERVERNODECOUNT -gt 1 ] ; then 
#        ADMINNODELIST="$${SERVERNODEHOSTNAMEPREFIX}1 $${SERVERNODEHOSTNAMEPREFIX}2"
#else 
#	ADMINNODELIST="$${SERVERNODEHOSTNAMEPREFIX}1"
#fi 


## To be ran on 1 of the nodes of the cluster.  We will assume node1.
echo "$THIS_HOST" | grep -q -w $INSTALLERNODE
if [ $? -eq 0 ] ; then

echo $IBMSSVERSION

wget $SOFTWAREDOWNLOADURL

cd /tmp
















index=0;
for x_fqdn in `cat /tmp/allnodehosts` ; do
  if [ $index -eq 0 ]; then 
    echo "skip checking on current node - $x_fqdn"
  else
	while [ ! `ssh $x_fqdn "if [ -f /tmp/complete ]; then echo \"true\"; else echo \"false\" ; fi"` = "true" ]; do
	sleep 20s;
	done;
  fi
  index=$((index+1))
done;

# Only do touch after checking on all other machines. To avoid the above loop from waiting for current node,  it has been skipped. 
touch /tmp/complete


exit 0


else	
	# To indicate on rest of the nodes,  that boot cloud init is complete. 
	touch /tmp/complete
# end if loop
fi


echo "boot.sh.tpl setup complete"
set +x 
