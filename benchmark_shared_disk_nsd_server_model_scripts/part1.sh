
#cp /etc/hosts /etc/hosts.orig
#cp /etc/resolv.conf /etc/resolv.conf.orig

# Download the GPFS binary
#wget $1

chmod +x Spectrum_Scale_Data_Management-5.0.3.2-x86_64-Linux-install
./Spectrum_Scale_Data_Management-5.0.3.2-x86_64-Linux-install --silent

echo "5.0.3.2" > /etc/yum/vars/spec_scale_ver

echo '[spectrum_scale-gpfs]
name = Spectrum Scale - GPFS
baseurl = file:///usr/lpp/mmfs/$spec_scale_ver/gpfs_rpms
gpgcheck=0
enabled=1
[spectrum_scale-gpfs-optional]
name = Spectrum Scale - GPFS
baseurl = file:///usr/lpp/mmfs/$spec_scale_ver/gpfs_rpms/rhel7
gpgcheck=0
enabled=1
[spectrum_scale-ganesha]
name = Spectrum Scale - NFS-Ganesha
baseurl = file:///usr/lpp/mmfs/$spec_scale_ver/ganesha_rpms/rhel7
gpgcheck=0
enabled=1
[spectrum_scale-smb]
name = Spectrum Scale - SMB
baseurl = file:///usr/lpp/mmfs/$spec_scale_ver/smb_rpms/rhel7
gpgcheck=0
enabled=1
[spectrum_scale-object]
name = Spectrum Scale - Object
baseurl = file:///usr/lpp/mmfs/$spec_scale_ver/object_rpms/rhel7
gpgcheck=0
enabled=1
[spectrum_scale-zimon]
name = Spectrum Scale - Zimon
baseurl = file:///usr/lpp/mmfs/$spec_scale_ver/zimon_rpms/rhel7
gpgcheck=0
enabled=1' > /etc/yum.repos.d/spectrum-scale.repo


yum clean all
yum makecache

yum -y install kernel-devel cpp gcc gcc-c++ binutils kernel-headers

yum -y update

systemctl reboot

