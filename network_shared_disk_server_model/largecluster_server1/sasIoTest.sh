#!/bin/bash

declare -A svrName
svrName[1,0]="ss-server-1";   svrName[1,1]="ss-server-2"
svrName[2,0]="ss-server-3";   svrName[2,1]="ss-server-4"
svrName[3,0]="ss-server-5";   svrName[3,1]="ss-server-6"
svrName[4,0]="ss-server-7";   svrName[4,1]="ss-server-8"
svrName[5,0]="ss-server-9";   svrName[5,1]="ss-server-10"
svrName[6,0]="ss-server-11";  svrName[6,1]="ss-server-12"
svrName[7,0]="ss-server-13";  svrName[7,1]="ss-server-14"
svrName[8,0]="ss-server-15";  svrName[8,1]="ss-server-16"
svrName[9,0]="ss-server-17";  svrName[9,1]="ss-server-18"
svrName[10,0]="ss-server-19"; svrName[10,1]="ss-server-20"
svrName[11,0]="ss-server-21"; svrName[11,1]="ss-server-22"

#for numBuildBlock in {1..11}
#do
numBuildBlock=11
  for i in $(eval echo "{1..$numBuildBlock}")
  do
    ssh ${svrName[$i,0]} "/root/sas/iotest.sh -i 24 -t /gpfs/fs${i}/test0 -b 4587520 -s 64" &
    ssh ${svrName[$i,1]} "/root/sas/iotest.sh -i 24 -t /gpfs/fs${i}/test1 -b 4587520 -s 64" &
  done
#done
