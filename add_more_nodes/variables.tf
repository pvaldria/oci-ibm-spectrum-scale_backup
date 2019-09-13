###
## Variables.tf for Terraform
###

variable "tenancy_ocid" {
}

variable "user_ocid" {
}

variable "fingerprint" {
}

variable "private_key_path" {
}

variable "region" {
  default = "us-phoenix-1"
}

variable "compartment_ocid" {
}

variable "ssh_public_key" {
}

variable "ssh_private_key" {
}

variable "ssh_private_key_path" {
}

# For instances created using Oracle Linux and CentOS images, the user name opc is created automatically.
# For instances created using the Ubuntu image, the user name ubuntu is created automatically.
# The ubuntu user has sudo privileges and is configured for remote access over the SSH v2 protocol using RSA keys. The SSH public keys that you specify while creating instances are added to the /home/ubuntu/.ssh/authorized_keys file.
# For more details: https://docs.cloud.oracle.com/iaas/Content/Compute/References/images.htm#one
variable "ssh_user" {
  default = "opc"
}

# For Ubuntu images,  set to ubuntu. 
# variable "ssh_user" { default = "ubuntu" }

variable "AD" {
  default = "3"
}

variable "VPC-CIDR" {
  default = "10.0.0.0/16"
}

# Please make sure your OS version and kernel version is within the supported one in table 38 of https://www.ibm.com/support/knowledgecenter/en/STXKQY/gpfsclustersfaq.html#linux
# https://docs.cloud.oracle.com/iaas/images/image/66a17669-8a67-4b43-924a-78d8ae49f609/
variable "InstanceImageOCID" {
  type = map(string)
  default = {
    // See https://docs.us-phoenix-1.oraclecloud.com/images/ or https://docs.cloud.oracle.com/iaas/images/
    // Oracle-provided image "CentOS-7.xxxx"
    eu-frankfurt-1 = "ocid1.image.oc1.eu-frankfurt-1.aaaaaaaatbfzohfzwagb5eplk5abjifwmr5bpytuo2pgyufflpkdfkkb3eca"
    us-ashburn-1   = "ocid1.image.oc1.iad.aaaaaaaa3p2d4bzgz4gw435tw3522u4d3enh7jwlwpymfgqwp6hrhebs4s2q"
    uk-london-1    = "ocid1.image.oc1.uk-london-1.aaaaaaaaktvxlhhjs3k57fbloubrbuju7vdyaivdw5pclmva2kwhqhqlewbq"
    us-phoenix-1   = "ocid1.image.oc1.phx.aaaaaaaavzt7r56xh2lj2w7ibqbkvumxbqr2z2jswoma3qjbunu7wj63rigq"
  }
}

# Compute Instance counts
# Bastion server count.  1 should be enough
variable "BastionNodeCount" {
  default = "1"
}

variable "BastionNodeShape" {
  default = "VM.Standard2.2"
}

variable "ibm_ss_version" {
  default = "5.0.2.0"
}

# Should be a http/https link which is accessible from the compute instances we will create. You can use OCI Object Storage bucket with pre-authenticated URL.  
variable "software_download_url" {
  default = "http://somehost.com"
}

# example: https://objectstorage.us-phoenix-1.oraclecloud.com/p/B_xxxxxx-xxxxxx/n/tenancyname/b/bucketname/o/Scale_dme_install-5.0.2.0_x86_64.tar

# path to download OCI Command Line Tool to perform multi-attach for Block Volumes
variable "oci_cli_download_url" {
  default = "http://somehost.com"
}

# File System Configurations
variable "BlockSize" {
  default = "256K"
}

variable "DataReplica" {
  default = "1"
}

variable "GpfsMountPoint" {
  default = "/gpfs/fs1"
}

# NSD Configurations
#variable "DiskPerNode" { default = "4" }
#variable "DiskSize" { default = "700" }

# NSD Configurations
# Block Volumes count and size of each disk
variable "SharedData" {
  type = map(string)
  default = {
    Count = "10"
    Size  = "800"
  }
}

variable "ServerNodeCountA" {
  default = "3"
}

variable "ServerNodeCountB" {
  default = "3"
}

variable "ServerNodeCountC" {
  default = "3"
}

variable "NSDServersInPoolCount" {
  default = "3"
}

# NSD/Server Node Configurations
variable "ServerNodeCount" {
  default = "9"
}

variable "ServerNodeShape" {
  default = "BM.Standard2.52"
}

#variable "ServerNodeShape" { default = "BM.DenseIO2.52" }  # BM.DenseIO2.52
variable "ServerNodeHostnamePrefix" {
  default = "ss-server-"
}

# Client/Compute Node Configurations
variable "ComputeNodeCount" {
  default = "20"
}

variable "ComputeNodeShape" {
  default = "BM.Standard2.52"
}

variable "ComputeNodeHostnamePrefix" {
  default = "bm-compute-"
}

variable "InstallerNode" {
  default = "1"
}

# GPFS Management GUI Node Configurations
variable "GPFSMgmtGUINodeCount" {
  default = "0"
}

variable "GPFSMgmtGUINodeShape" {
  default = "VM.Standard2.4"
}

variable "GPFSMgmtGUINodeHostnamePrefix" {
  default = "ss-mgmt-gui-"
}

variable "ProtocolNode" {
  type = map(string)
  default = {
    Count          = "2"
    Shape          = "VM.Standard2.2"
    HostnamePrefix = "ss-protocol-"
  }
}

variable "WindowsNode" {
  type = map(string)
  default = {
    Count          = "1"
    Shape          = "VM.Standard2.2"
    HostnamePrefix = "ss-windows-"
  }
}

# Callhome Configuration
variable "CompanyName" {
  default = "Company Name"
}

variable "CompanyID" {
  default = "1234567"
}

variable "CountryCode" {
  default = "US"
}

variable "EmailAddress" {
  default = "name@email.com"
}

variable "scripts_directory" {
  default = "../benchmark_shared_disk_nsd_server_model_scripts"
}

variable "SharedDataVolumeAttachDeviceMapping" {
  type = map(string)
  default = {
    "0"  = "/dev/oracleoci/oraclevdb"
    "1"  = "/dev/oracleoci/oraclevdc"
    "2"  = "/dev/oracleoci/oraclevdd"
    "3"  = "/dev/oracleoci/oraclevde"
    "4"  = "/dev/oracleoci/oraclevdf"
    "5"  = "/dev/oracleoci/oraclevdg"
    "6"  = "/dev/oracleoci/oraclevdh"
    "7"  = "/dev/oracleoci/oraclevdi"
    "8"  = "/dev/oracleoci/oraclevdj"
    "9"  = "/dev/oracleoci/oraclevdk"
    "10" = "/dev/oracleoci/oraclevdl"
    "11" = "/dev/oracleoci/oraclevdm"
    "12" = "/dev/oracleoci/oraclevdn"
    "13" = "/dev/oracleoci/oraclevdo"
    "14" = "/dev/oracleoci/oraclevdp"
    "15" = "/dev/oracleoci/oraclevdq"
    "16" = "/dev/oracleoci/oraclevdr"
    "17" = "/dev/oracleoci/oraclevds"
    "18" = "/dev/oracleoci/oraclevdt"
    "19" = "/dev/oracleoci/oraclevdu"
    "20" = "/dev/oracleoci/oraclevdv"
    "21" = "/dev/oracleoci/oraclevdw"
    "22" = "/dev/oracleoci/oraclevdx"
    "23" = "/dev/oracleoci/oraclevdy"
    "24" = "/dev/oracleoci/oraclevdz"
    "25" = "/dev/oracleoci/oraclevdaa"
    "26" = "/dev/oracleoci/oraclevdab"
    "27" = "/dev/oracleoci/oraclevdac"
    "28" = "/dev/oracleoci/oraclevdad"
    "29" = "/dev/oracleoci/oraclevdae"
    "30" = "/dev/oracleoci/oraclevdaf"
    "31" = "/dev/oracleoci/oraclevdag"
  }
}

