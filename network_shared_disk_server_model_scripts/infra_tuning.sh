mv /etc/yum.repos.d/epel.repo  /etc/yum.repos.d/epel.repo.disabled
mv /etc/yum.repos.d/epel-testing.repo  /etc/yum.repos.d/epel-testing.repo.disabled
sed -i "s/SELINUX=enforcing/SELINUX=disabled/g" /etc/selinux/config
setenforce 0

### OS Performance tuning
cd /usr/lib/tuned/
cp -r throughput-performance/ gpfs-oci-performance

echo "
#
# tuned configuration
#

[main]
summary=gpfs perf tuning for common gpfs workloads

[cpu]
force_latency=1
governor=performance
energy_perf_bias=performance
min_perf_pct=100

[vm]
transparent_huge_pages=never

[sysctl]
net.ipv4.tcp_timestamps=1
net.ipv4.tcp_sack=1
net.ipv4.tcp_dsack=1
net.ipv4.tcp_low_latency=1
net.ipv4.tcp_adv_win_scale=2
net.ipv4.tcp_window_scaling=1
net.ipv4.tcp_slow_start_after_idle=0
net.ipv4.tcp_syn_retries=8
net.ipv4.tcp_rmem=4096 87380 16777216
net.ipv4.tcp_wmem=4096 65536 16777216
net.core.rmem_max=16777216
net.core.wmem_max=16777216
net.core.rmem_default=16777216
net.core.wmem_default=16777216
net.core.optmem_max=16777216
net.core.somaxconn = 8192
net.core.netdev_max_backlog=250000
sunrpc.udp_slot_table_entries=128
sunrpc.tcp_slot_table_entries=128
kernel.sysrq = 1
kernel.sched_min_granularity_ns = 10000000
kernel.sched_wakeup_granularity_ns = 15000000
vm.min_free_kbytes = 16777216
vm.dirty_ratio = 30
vm.dirty_background_ratio = 10
vm.swappiness=30
" > gpfs-oci-performance/tuned.conf

cd -

echo "$thisHost" | grep -q  $nsdNodeHostnamePrefix
if [ $? -eq 0 ] ; then
  tuned-adm profile gpfs-oci-performance
fi


# before applying to client nodes, make sure they have enough memory.
echo "$thisHost" | grep -q  $clientNodeHostnamePrefix
if [ $? -eq 0 ] ; then
  coreIdCount=`grep "^core id" /proc/cpuinfo | sort -u | wc -l` ; echo $coreIdCount
  socketCount=`echo $(($(grep "^physical id" /proc/cpuinfo | awk '{print $4}' | sort -un | tail -1)+1))` ; echo $socketCount
  if [ $((socketCount*coreIdCount)) -gt 4  ]; then
    tuned-adm profile gpfs-oci-performance
  else
    # Client is using shape with less than 4 physical cores and less 30GB memory, above tuned profile requires atleast 16GB of vm.min_free_kbytes, hence let user evaluate what are valid values for such small compute shapes.
    echo "skip profile tuning..."
  fi ;
fi;

# Display active profile
tuned-adm active

# only for client nodes
echo "$thisHost" | grep -q  $clientNodeHostnamePrefix
if [ $? -eq 0 ] ; then
  echo off > /sys/devices/system/cpu/smt/control
fi

echo "$thisHost" | grep -q  $clientNodeHostnamePrefix
if [ $? -eq 0 ] ; then
  # This might be applicable only for compute-n nodes.  Its unclear from recommendations doc.
  # require restart for the change to be effective
  echo "* soft nofile 500000" >> /etc/security/limits.conf
  echo "* soft nproc 131072" >> /etc/security/limits.conf
  echo "* hard nofile 500000" >> /etc/security/limits.conf
  echo "* hard nproc 131072" >> /etc/security/limits.conf

  # To set values for current session
  ulimit -n 500000
  ulimit -u 131072
  echo "ulimit -n 500000 >>  ~/.bash_profile
  echo "ulimit -u 131072 >>  ~/.bash_profile
fi

echo "$thisHost" | grep -q  $nsdNodeHostnamePrefix
if [ $? -eq 0 ] ; then
  echo "*   soft    memlock      -1 " >> /etc/security/limits.conf
  echo "*   hard    memlock      -1 " >> /etc/security/limits.conf
  echo "*   soft    rss          -1 " >> /etc/security/limits.conf
  echo "*   hard    rss          -1 " >> /etc/security/limits.conf
  echo "*   soft    core          -1 " >> /etc/security/limits.conf
  echo "*   hard    core          -1 " >> /etc/security/limits.conf
  echo "*   soft    maxlogins     8192 " >> /etc/security/limits.conf
  echo "*   hard    maxlogins     8192 " >> /etc/security/limits.conf
  echo "*   soft    stack         -1 " >> /etc/security/limits.conf
  echo "*   hard    stack         -1 " >> /etc/security/limits.conf
  echo "*   soft    nproc         2067554 " >> /etc/security/limits.conf
  echo "*   hard    nproc         2067554 " >> /etc/security/limits.conf
  echo "* soft nofile 500000 " >> /etc/security/limits.conf
  echo "* hard nofile 500000 " >> /etc/security/limits.conf

  echo "ulimit -l unlimited" >>  ~/.bash_profile
  echo "ulimit -m unlimited" >>  ~/.bash_profile
  echo "ulimit -c unlimited" >>  ~/.bash_profile
  echo "ulimit -s unlimited" >>  ~/.bash_profile
  echo "ulimit -u 2067554" >>  ~/.bash_profile
  echo "ulimit -n 500000" >>  ~/.bash_profile

echo '#
# Identify eligible SCSI disks by the absence of a SWAP partition.
# The only attribute that should possibly be changed is max_sectors_kb,
# up to a value of 8192, depending on what the SCSI driver and disks support.
#
ACTION=="add|change", SUBSYSTEM=="block", KERNEL=="sd*[^0-9]", PROGRAM="/usr/bin/lsblk -rno FSTYPE,MOUNTPOINT,NAME /dev/%k", RESULT!="*SWAP*", ATTR{queue/scheduler}="deadline", ATTR{queue/nr_requests}="256", ATTR{device/queue_depth}="31", ATTR{queue/max_sectors_kb}="8192", ATTR{queue/read_ahead_kb}="0", ATTR{queue/rq_affinity}="2"
' > /etc/udev/rules.d/99-ibm-spectrum-scale.rules
# Run this to load the rules
udevadm control --reload-rules && udevadm trigger

fi

cd -
