#!/bin/bash

for hostName in ss-server-{1..22}
do
  echo $hostName
  ssh $hostName "ip link set dev eno2 mtu 9000; ip link set dev eno3d1 mtu 9000; \
                 ethtool -G eno2 rx 2047 tx 2047 rx-jumbo 8191; ethtool -G eno3d1 rx 2047 tx 2047 rx-jumbo 8191; \
                 ethtool -L eno2 combined 74; ethtool -L eno3d1 combined 74; \
                 sysctl -p /root/sysctl_test.conf"
done

for hostName in ss-compute-{1..30}
do
  echo $hostName
  ssh $hostName "ip link set dev eno2 mtu 9000; ip link set dev eno3d1 mtu 9000; \
                 ethtool -G eno2 rx 2047 tx 2047 rx-jumbo 8191; ethtool -G eno3d1 rx 2047 tx 2047 rx-jumbo 8191; \
                 ethtool -L eno2 combined 74; ethtool -L eno3d1 combined 74; \
                 sysctl -p /root/sysctl_test.conf; \
                 echo off > /sys/devices/system/cpu/smt/control"
done
