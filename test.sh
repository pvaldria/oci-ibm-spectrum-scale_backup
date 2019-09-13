#!/bin/bash

#set -x 

# mmchlicense server --accept -N 1,2,3
nsdNodeCount=$1
clientNodeCount=$2
blockVolumesPerPool=$3
totalNsdNodePools=$4
nsdNodesPerPool=$5
nsdNodeHostnamePrefix="ss-server-"
diskArray=(b c d e f g h i j k l m n o p q r s t u v w x y z aa ab ac ad ae af ag)

command="mmchlicense server --accept -N "
for node in `seq 1 $nsdNodeCount`; 
do
  echo $node
  command="$command $node"
done
echo $command
$command

startIndex=$((nsdNodeCount+1))
endIndex=$((nsdNodeCount+clientNodeCount))
command="mmchlicense client --accept -N  "
for node in `seq $startIndex $endIndex`;
do
  echo $node
  command="$command $node"
done
echo $command
$command

rm /tmp/nsd.stanza.sv3.set1

for poolIndex in `seq 1 $totalNsdNodePools`;
do

rm /tmp/nsd.stanza.sv${nsdNodesPerPool}.set${poolIndex}
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

echo "
%nsd: nsd=nsd$((((poolIndex-1)*blockVolumesPerPool)+i))
device=/dev/oracleoci/oraclevd${diskArray[(($i-1))]}
servers=$primaryServer,$secondaryServer
usage=dataAndMetadata
pool=system

" >> /tmp/nsd.stanza.sv${nsdNodesPerPool}.set${poolIndex}
done

#cat /tmp/nsd.stanza.sv${nsdNodesPerPool}.set${poolIndex}

done


#Create the NSDs from all NSD stanza files.
for poolIndex in `seq 1 $totalNsdNodePools`;
do
echo "mmcrnsd -F /tmp/nsd.stanza.sv${nsdNodesPerPool}.set${poolIndex}  "
mmcrnsd -F /tmp/nsd.stanza.sv${nsdNodesPerPool}.set${poolIndex} 
done


# Create a file system fs1 using the first NSD stanza.
# Add additional NSDs to the existing filesystem fs1
for poolIndex in `seq 1 $totalNsdNodePools`;
do
if [ $poolIndex -eq 1 ]; then 
echo "mmcrfs fs1  -F /tmp/nsd.stanza.sv${nsdNodesPerPool}.set${poolIndex} -B $blockSize   "
mmcrfs fs1  -F /tmp/nsd.stanza.sv${nsdNodesPerPool}.set${poolIndex} -B $blockSize   
else
echo "mmadddisk -F /tmp/nsd.stanza.sv${nsdNodesPerPool}.set${poolIndex}  "
mmadddisk -F /tmp/nsd.stanza.sv${nsdNodesPerPool}.set${poolIndex}
fi
done
# Balance the occupancy across all NSDs.
mmrestripefs fs1 -b

# Check if all NSDs are attached to the filesystem.
mmlsnsd
mmlsfs fs1
df -h

