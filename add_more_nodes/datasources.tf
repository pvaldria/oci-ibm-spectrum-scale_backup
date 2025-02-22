# Gets a list of Availability Domains
data "oci_identity_availability_domains" "ADs" {
  compartment_id = var.tenancy_ocid
}

data "template_file" "boot_script" {
  template = file("${var.scripts_directory}/boot.sh.tpl")
  vars = {
    IBMSSVersion              = var.ibm_ss_version
    SoftwareDownloadURL       = var.software_download_url
    SSHPrivateKey             = var.ssh_private_key
    SSHPublicKey              = var.ssh_public_key
    ServerNodeCount           = var.ServerNodeCount
    ServerNodeHostnamePrefix  = var.ServerNodeHostnamePrefix
    ComputeNodeCount          = var.ComputeNodeCount
    ComputeNodeHostnamePrefix = var.ComputeNodeHostnamePrefix
    BlockSize                 = var.BlockSize
    DataReplica               = var.DataReplica
    GpfsMountPoint            = var.GpfsMountPoint
    SharedDataDiskCount       = var.SharedData["Count"]
    InstallerNode             = "${var.ServerNodeHostnamePrefix}1"
    PrivateSubnetsFQDN        = "ibmssvcnv3.oraclevcn.com private2.ibmssvcnv3.oraclevcn.com"
    PrivateBSubnetsFQDN       = "ibmssvcnv3.oraclevcn.com privateb2.ibmssvcnv3.oraclevcn.com"
    CompanyName               = var.CompanyName
    CompanyID                 = var.CompanyID
    CountryCode               = var.CountryCode
    EmailAddress              = var.EmailAddress
    NSDServersInPoolCount     = var.NSDServersInPoolCount
  }
}


# PrivateSubnetsFQDN        = "${oci_core_virtual_network.ibmss_vcnv3.dns_label}.oraclevcn.com ${oci_core_subnet.private[0].dns_label}.${oci_core_virtual_network.ibmss_vcnv3.dns_label}.    oraclevcn.com ${oci_core_subnet.private[1].dns_label}.${oci_core_virtual_network.ibmss_vcnv3.dns_label}.oraclevcn.com ${oci_core_subnet.private[2].dns_label}.${oci_core_virtual_network.ib    mss_vcnv3.dns_label}.oraclevcn.com"
# PrivateBSubnetsFQDN       = "${oci_core_virtual_network.ibmss_vcnv3.dns_label}.oraclevcn.com ${oci_core_subnet.privateb[0].dns_label}.${oci_core_virtual_network.ibmss_vcnv3.dns_label}    .oraclevcn.com ${oci_core_subnet.privateb[1].dns_label}.${oci_core_virtual_network.ibmss_vcnv3.dns_label}.oraclevcn.com ${oci_core_subnet.privateb[2].dns_label}.${oci_core_virtual_network    .ibmss_vcnv3.dns_label}.oraclevcn.com"


