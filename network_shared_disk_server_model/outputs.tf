

output "SSH-login" {
value = <<END

        Bastion: ssh -i ~/.ssh/id_rsa ${var.ssh_user}@${oci_core_instance.bastion.*.public_ip[0]}

        Server1: ssh -i ${var.ssh_private_key_path}  -o BatchMode=yes -o StrictHostkeyChecking=no  -o ProxyCommand="ssh -i /home/${var.ssh_user}/.ssh/id_rsa  -o BatchMode=yes -o StrictHostkeyChecking=no ${var.ssh_user}@${oci_core_instance.bastion.*.public_ip[0]} -W %h:%p %r" ${var.ssh_user}@${oci_core_instance.nsd_node.*.private_ip[0]}


        Server2: ssh -i ${var.ssh_private_key_path}  -o BatchMode=yes -o StrictHostkeyChecking=no  -o ProxyCommand="ssh -i /home/${var.ssh_user}/.ssh/id_rsa  -o BatchMode=yes -o StrictHostkeyChecking=no ${var.ssh_user}@${oci_core_instance.bastion.*.public_ip[0]} -W %h:%p %r" ${var.ssh_user}@${oci_core_instance.nsd_node.*.private_ip[1]}


        Client1: ssh -i ${var.ssh_private_key_path}  -o BatchMode=yes -o StrictHostkeyChecking=no  -o ProxyCommand="ssh -i /home/${var.ssh_user}/.ssh/id_rsa  -o BatchMode=yes -o StrictHostkeyChecking=no ${var.ssh_user}@${oci_core_instance.bastion.*.public_ip[0]} -W %h:%p %r" ${var.ssh_user}@${oci_core_instance.client_node.*.private_ip[0]}

END
}




