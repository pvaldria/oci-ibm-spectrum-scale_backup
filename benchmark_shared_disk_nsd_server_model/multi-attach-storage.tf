resource "null_resource" "copy_nsddevices_to_all_server_nodes" {
  depends_on = [oci_core_instance.ServerNode]
  count      = var.ServerNodeCount
  provisioner "file" {
    source      = "${var.scripts_directory}/nsddevices"
    destination = "/tmp/nsddevices"
    connection {
      agent               = false
      timeout             = "30m"
      host                = element(oci_core_instance.ServerNode.*.private_ip, count.index)
      user                = var.ssh_user
      private_key         = var.ssh_private_key
      bastion_host        = oci_core_instance.bastion[0].public_ip
      bastion_port        = "22"
      bastion_user        = var.ssh_user
      bastion_private_key = var.ssh_private_key
    }
  }
}

resource "null_resource" "install_oci_cli_preview" {
  count = "1"
  provisioner "local-exec" {
    command = "set -x; rm -rf ~/oci-cli-installer; mkdir -p ~/oci-cli-installer; cd ~/oci-cli-installer; wget -q ${var.oci_cli_download_url} ; file_path=${var.oci_cli_download_url} ; unzip oci-cli-full-install-2.4.40+preview.1.1330.zip  -d ./ ;./install.sh --accept-all-defaults;  oci os bucket list --compartment-id ${var.compartment_ocid}; mkdir -p ~/.oci ; cd ~/.oci ; echo \"[DEFAULT]\nuser=${var.user_ocid}\nfingerprint=${var.fingerprint}\nkey_file=${var.private_key_path}\ntenancy=${var.tenancy_ocid}\nregion=${var.region}\n\" > ~/.oci/config; "
  }
}

resource "null_resource" "multi_attach_shared_data_bv_to_server_nodesA" {
  depends_on = [
    oci_core_instance.ServerNode,
    oci_core_volume.SharedDataBlockVolumeA,
    null_resource.install_oci_cli_preview,
  ]
  count = var.ServerNodeCountA * var.SharedData["Count"] * var.ServerNodeCountA

  /*
    triggers {
      instance_ids = "oci_core_instance.ServerNode.*.id[0]"
      # "${join(",", oci_core_instance.ServerNode.*.id[0])}"
      }
*/

  provisioner "local-exec" {
    command = "oci compute volume-attachment attach --type iscsi --is-shareable true  --instance-id ${oci_core_instance.ServerNode[count.index % var.ServerNodeCountA].id}  --volume-id ${oci_core_volume.SharedDataBlockVolumeA[floor(count.index / var.ServerNodeCountA)].id} --device ${var.SharedDataVolumeAttachDeviceMapping[floor(count.index / var.ServerNodeCountA)]}   --config-file ~/.oci/config ;sleep 61s; "
  }
}

resource "null_resource" "multi_attach_shared_data_bv_to_server_nodesB" {
  depends_on = [
    oci_core_instance.ServerNode,
    oci_core_volume.SharedDataBlockVolumeB,
    null_resource.install_oci_cli_preview,
  ]
  count = var.ServerNodeCountB * var.SharedData["Count"] * var.ServerNodeCountB

  provisioner "local-exec" {
    command = "oci compute volume-attachment attach --type iscsi --is-shareable true  --instance-id ${oci_core_instance.ServerNode[3 + (count.index % var.ServerNodeCountB)].id}  --volume-id ${oci_core_volume.SharedDataBlockVolumeB[floor(count.index / var.ServerNodeCountB)].id} --device ${var.SharedDataVolumeAttachDeviceMapping[floor(count.index / var.ServerNodeCountB)]}   --config-file ~/.oci/config ;sleep 81s; "
  }
}

resource "null_resource" "multi_attach_shared_data_bv_to_server_nodesC" {
  depends_on = [
    oci_core_instance.ServerNode,
    oci_core_volume.SharedDataBlockVolumeC,
    null_resource.install_oci_cli_preview,
  ]
  count = var.ServerNodeCountC * var.SharedData["Count"] * var.ServerNodeCountC

  provisioner "local-exec" {
    command = "oci compute volume-attachment attach --type iscsi --is-shareable true  --instance-id ${oci_core_instance.ServerNode[6 + (count.index % var.ServerNodeCountC)].id}  --volume-id ${oci_core_volume.SharedDataBlockVolumeC[floor(count.index / var.ServerNodeCountC)].id} --device ${var.SharedDataVolumeAttachDeviceMapping[floor(count.index / var.ServerNodeCountC)]}   --config-file ~/.oci/config ;sleep 71s; "
  }
}

resource "null_resource" "notify_server_nodes_oci_cli_multi_attach_complete" {
  depends_on = [null_resource.multi_attach_shared_data_bv_to_server_nodesA, null_resource.multi_attach_shared_data_bv_to_server_nodesB, null_resource.multi_attach_shared_data_bv_to_server_nodesC]
  count      = var.ServerNodeCount
  provisioner "remote-exec" {
    connection {
      agent               = false
      timeout             = "30m"
      host                = element(oci_core_instance.ServerNode.*.private_ip, count.index)
      user                = var.ssh_user
      private_key         = var.ssh_private_key
      bastion_host        = oci_core_instance.bastion[0].public_ip
      bastion_port        = "22"
      bastion_user        = var.ssh_user
      bastion_private_key = var.ssh_private_key
    }
    inline = [
      "set -x",
      "sudo touch /tmp/multi-attach.complete",
    ]
  }
}

