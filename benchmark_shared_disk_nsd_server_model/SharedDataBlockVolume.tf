resource "oci_core_volume" "SharedDataBlockVolumeA" {
  count = var.SharedData["Count"] * var.ServerNodeCountA

  availability_domain = data.oci_identity_availability_domains.ADs.availability_domains[var.AD - 1]["name"]
  compartment_id      = var.compartment_ocid
  display_name        = "SharedData${count.index + 1}"
  size_in_gbs         = var.SharedData["Size"]
}

resource "oci_core_volume" "SharedDataBlockVolumeB" {
  count = var.SharedData["Count"] * var.ServerNodeCountB

  availability_domain = data.oci_identity_availability_domains.ADs.availability_domains[var.AD - 1]["name"]
  compartment_id      = var.compartment_ocid
  display_name        = "SharedData${30 + count.index + 1}"
  size_in_gbs         = var.SharedData["Size"]
}

resource "oci_core_volume" "SharedDataBlockVolumeC" {
  count = var.SharedData["Count"] * var.ServerNodeCountC

  availability_domain = data.oci_identity_availability_domains.ADs.availability_domains[var.AD - 1]["name"]
  compartment_id      = var.compartment_ocid
  display_name        = "SharedData${60 + count.index + 1}"
  size_in_gbs         = var.SharedData["Size"]
}

