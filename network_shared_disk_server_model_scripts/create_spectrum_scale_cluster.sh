#!/bin/bash

set -x

source /tmp/gpfs_env_variables.sh

# Only on installerNode
echo "$thisHost" | grep -q -w $installerNode
if [ $? -eq 0 ] ; then
  rm  /root/node.stanza
#  count=0
  for hname in `cat /tmp/allnodehosts` ; do
    echo "$hname" | grep -q $nsdNodeHostnamePrefix
    if [ $? -eq 0 ] ; then
#     if [ $count -lt 3 ]; then
        echo "${hname}:quorum-manager" >> /root/node.stanza
#     else
#        echo "${hname}" >> /root/node.stanza
#     fi
#      count=$((count+1))
    fi
    echo "$hname" | grep -q $clientNodeHostnamePrefix
    if [ $? -eq 0 ] ; then
      echo "${hname}" >> /root/node.stanza
    fi
  done
  cat /root/node.stanza

  mmcrcluster -N node.stanza -r /usr/bin/ssh -R /usr/bin/scp -C ss-demo01.privateb2.ibmssvcnv3.oraclevcn.com -A
  sleep 30s



  diskArray=(b c d e f g h i j k l m n o p q r s t u v w x y z aa ab ac ad ae af ag)

  command="mmchlicense server --accept -N "
  for node in `seq 1 $nsdNodeCount`;
  do
    echo $node
    if [ $node -eq $nsdNodeCount ]; then
      # no comma at the end
      command="${command}${node}"
    else
      command="${command}${node},"
    fi
  done
  echo $command
  $command

  sleep 30s

  startIndex=$((nsdNodeCount+1))
  endIndex=$((nsdNodeCount+clientNodeCount))
  command="mmchlicense client --accept -N  "
  for node in `seq $startIndex $endIndex`;
  do
    echo $node
    if [ $node -eq $endIndex ]; then
      # no comma at the end
      command="${command}${node}"
    else
      command="${command}${node},"
    fi
  done
  echo $command
  $command

  sleep 30s

  rm /tmp/nsd.stanza.sv*
  for poolIndex in `seq 1 $totalNsdNodePools`;
  do
    if [ $highAvailability = true ]; then
      if [ $((poolIndex % 2)) -eq 0  ]; then
        failureGroup=102
      else
        failureGroup=101
      fi
    fi

    setFileName="/tmp/nsd.stanza.sv${nsdNodesPerPool}.set${poolIndex}"
    rm $setFileName
    for i in `seq 1 $blockVolumesPerPool`;
    do
      if [ $((i % 2)) -eq 0 ]; then
        # ${((poolIndex-1*nsdNodesPerPool+1))}"
        primaryServer="${nsdNodeHostnamePrefix}$((((poolIndex-1)*nsdNodesPerPool)+2))"
        secondaryServer="${nsdNodeHostnamePrefix}$((((poolIndex-1)*nsdNodesPerPool)+1))"
      else
        primaryServer="${nsdNodeHostnamePrefix}$((((poolIndex-1)*nsdNodesPerPool)+1))"
        secondaryServer="${nsdNodeHostnamePrefix}$((((poolIndex-1)*nsdNodesPerPool)+2))"
      fi

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

      setFileName="/tmp/nsd.stanza.sv${nsdNodesPerPool}.set${poolIndex}"
      echo " " >> $setFileName
      echo "%nsd: nsd=nsd$((((poolIndex-1)*blockVolumesPerPool)+i))" >> $setFileName
      echo "device=/dev/oracleoci/oraclevd${diskArray[(($i-1))]}" >> $setFileName
      echo "servers=$primaryServer,$secondaryServer" >> $setFileName
      echo "usage=dataAndMetadata" >> $setFileName
      echo "pool=system" >> $setFileName
      echo "failureGroup=$failureGroup" >> $setFileName
    done

  done

  #Create the NSDs from all NSD stanza files.
  for poolIndex in `seq 1 $totalNsdNodePools`;
  do
    echo "mmcrnsd -F /tmp/nsd.stanza.sv${nsdNodesPerPool}.set${poolIndex}  "
    mmcrnsd -F /tmp/nsd.stanza.sv${nsdNodesPerPool}.set${poolIndex}
    sleep 15s
  done

  mmchconfig maxblocksize=16M,maxMBpS=6250,numaMemoryInterleave=yes,tscCmdPortRange=60000-61000,workerThreads=1024
  mmchconfig pagepool=128G,maxFilesToCache=5M -N nsdNodes
  mmchconfig pagepool=64G,maxFilesToCache=1M -N clientNodes


# mmstartup -a
  # or
mmstartup -N nsdNodes
while [ `mmgetstate -a | grep "active" | wc -l` -ne $((nsdNodeCount)) ] ; do echo "waiting for server nodes of cluster to start ..." ; sleep 10s; done;

mmumount fs1 -a
sleep 15s
mmmount fs1 -a
sleep 15s

mmstartup -N clientNodes
while [ `mmgetstate -a | grep "active" | wc -l` -ne $((nsdNodeCount + clientNodeCount)) ] ; do echo "waiting for client nodes of cluster to start ..." ; sleep 10s; done;

#  while [ `mmgetstate -a | grep "active" | wc -l` -ne $((nsdNodeCount + clientNodeCount)) ] ; do echo "waiting for cluster to start ..." ; sleep 10s; done;


  # Consolidate into a single file,  since both failure groups needs to be in the same file, for the command the work.
  rm /tmp/nsd.stanza.sv${nsdNodesPerPool}.consolidated
  for poolIndex in `seq 1 $totalNsdNodePools`;
  do
    echo "consolidating the files... /tmp/nsd.stanza.sv${nsdNodesPerPool}.set${poolIndex} into /tmp/nsd.stanza.sv${nsdNodesPerPool}.consolidated "
    cat /tmp/nsd.stanza.sv${nsdNodesPerPool}.set${poolIndex} >> /tmp/nsd.stanza.sv${nsdNodesPerPool}.consolidated
    sleep 15s
  done

  # Create a file system fs1
  mmcrfs fs1  -F /tmp/nsd.stanza.sv${nsdNodesPerPool}.consolidated -B $blockSize -m $metadataReplica -M 2 -r $dataReplica -R 2
  sleep 60s

  # Balance the occupancy across all NSDs.
  mmrestripefs fs1 -b
  # sleep 120s


  # Check if all NSDs are attached to the filesystem.
  mmlsnsd
  mmlsfs fs1
  mmlsdisk fs1 -L

  mmmount fs1 -a
  sleep 15s
  df -h

### CES Nodes ###
## mmaddnode needs to be ran on a node which is already part of the cluster
# Step1.  Add the nodes to existing GPFS cluster.
# Step 2.  Assign proper license to the newly added nodes.
# Step 3.  Assign the quorum role to one of protocol node and the manager role to both nodes.
for node in `cat /tmp/cesnodehosts` ; do
  mmaddnode -N $node
  mmchlicense server --accept -N $node
  mmchnode --manager -N $node
  mmstartup -N $node
done

# TODO - check deamon is active.  while loop
while [ `mmgetstate -a  | grep "$cesNodeHostnamePrefix" | grep "active" | wc -l` -lt $((cesNodeCount)) ] ; do echo "waiting for ces nodes of cluster to start ..." ; sleep 10s; done;


# To ensure pmsensors is installed on all nodes.
#   mmdsh -N all "rpm -qa | grep gpfs.gss.pmsensors"
# To ensure pmcollector is installed on only GUI mgmt nodes.
#   mmdsh -N all "rpm -qa | grep gpfs.gss.pmcollector"

# Step1.  Add the nodes to existing GPFS cluster.
# Step 2.  Assign proper license to the newly added nodes.
# Step 3.  Configure pagepool for the GUI nodes.
for node in `cat /tmp/mgmtguinodehosts` ; do
  mmaddnode -N $node
  mmchlicense client --accept -N $node
  mmchconfig pagepool=32G -N $node
done

fi

exit 0;

# NOTES #
# Correct GPFS restart procedure
#   mmumount fs1 -a
#   mmshutdown -a
#   mmstartup -N nsdNodes
#   while [ `mmgetstate -a | grep "active" | wc -l` -lt $((nsdNodeCount)) ] ; do echo "waiting for server nodes of cluster to start ..." ; sleep 10s; done;

#   mmumount fs1 -a
#   sleep 15s
#   mmmount fs1 -a
#   sleep 15s

#   mmstartup -N clientNodes
#   while [ `mmgetstate -a | grep "active" | wc -l` -lt $((nsdNodeCount + clientNodeCount)) ] ; do echo "waiting for client nodes of cluster to start ..." ; sleep 10s; done;


