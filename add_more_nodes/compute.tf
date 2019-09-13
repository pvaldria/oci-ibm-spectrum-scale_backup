
resource "oci_core_instance" "ComputeNode" {
  count               = var.ComputeNodeCount
  availability_domain = data.oci_identity_availability_domains.ADs.availability_domains[var.AD - 1]["name"]
  compartment_id      = var.compartment_ocid
  display_name        = "${var.ComputeNodeHostnamePrefix}${format("%01d", count.index + 1)}"
  hostname_label      = "${var.ComputeNodeHostnamePrefix}${format("%01d", count.index + 1)}"
  shape               = var.ComputeNodeShape
  subnet_id           = "ocid1.subnet.oc1.iad.aaaaaaaaoiqn66nezqbnfe6zdase3mfywavwkat7nowri4fa7xh7owp6njaa" 

  source_details {
    source_type = "image"
    source_id   = var.InstanceImageOCID[var.region]
    #boot_volume_size_in_gbs = "${var.boot_volume_size}"
  }

  metadata = {
    ssh_authorized_keys = var.ssh_public_key
    user_data           = base64encode(data.template_file.boot_script.rendered)
  }

  timeouts {
    create = "60m"
  }
}


