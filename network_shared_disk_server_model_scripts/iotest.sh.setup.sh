#!/bin/bash

echo "Run this on GPFS client nodes as opc user, not root" 

cd ~/
curl -O http://ftp.sas.com/techsup/download/ts-tools/external/SASTSST_UNIX_installation.sh
chmod 744 SASTSST_UNIX_installation.sh

mkdir -p ~/sas
./SASTSST_UNIX_installation.sh

# yes ~/sas 14

cd ~/sas
chmod 0555 iotest.sh
sudo chown -R opc:opc /gpfs/*


echo "./iotest.sh -i 1 -t /gpfs/fs1 -s 64 -b 1000000"
echo "64K SAS block size,  data transfered is 64K * 1000000  = xxGB"

echo 'for i in {1..4};do ssh ss-compute-${i} "/root/sas/iotest.sh -i 24 -t /gpfs/fs1/test${i} -b 4587520 -s 64" & done '

# 3355438 = 209GB file each
# 4587520 = GB file each
# 5259264 = > than 320 GB file size (larger than memory)
# Need to be root user for ssh passwordless and run the below on each grid node.

echo 'for i in {1..4};do ssh grid-${i} "mkdir -p /gpfs/fs1/test${i}" ; ssh grid-${i} "/home/opc/sas/iotest.sh -i 24 -t /gpfs/fs1/test${i} -b 5259264 -s 64" & done '

# for i in {1..3};do ssh grid-${i} "mkdir -p /gpfs/fs1/test${i}" ; ssh grid-${i} "/home/opc/sas/iotest.sh -i 24 -t /gpfs/fs1/test${i} -b 5259264 -s 64 " & done
