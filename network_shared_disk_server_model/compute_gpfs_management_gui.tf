resource "oci_core_instance" "mgmt_gui_node" {
  count               = "${var.mgmt_gui_node["count"]}"
  availability_domain = "${lookup(data.oci_identity_availability_domains.ADs.availability_domains[var.availability_domain - 1],"name")}"
  compartment_id      = "${var.compartment_ocid}"
  display_name        = "${var.mgmt_gui_node["hostname_prefix"]}${format("%01d", count.index+1)}"
  hostname_label      = "${var.mgmt_gui_node["hostname_prefix"]}${format("%01d", count.index+1)}"
  shape               = "${var.mgmt_gui_node["shape"]}"
  subnet_id           = "${oci_core_subnet.privateb.*.id[var.availability_domain - 1]}"

  source_details {
    source_type = "image"
    source_id = "${var.images[var.region]}"
  }

  metadata = {
    ssh_authorized_keys = "${var.ssh_public_key}"
    user_data = "${base64encode(data.template_file.mgmt_gui_boot_script.rendered)}"
  }

  timeouts {
    create = "60m"
  }

}





