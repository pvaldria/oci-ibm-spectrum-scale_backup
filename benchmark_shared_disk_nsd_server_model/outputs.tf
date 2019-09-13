output "SSH_login" {
  value = <<END

        Bastion: ssh -i ~/.ssh/id_rsa ${var.ssh_user}@${oci_core_instance.bastion[0].public_ip}

        ssh -i ${var.ssh_private_key_path}  -o BatchMode=yes -o StrictHostkeyChecking=no  -o ProxyCommand="ssh -i /home/${var.ssh_user}/.ssh/id_rsa  -o BatchMode=yes -o StrictHostkeyChecking=no ${var.ssh_user}@${oci_core_instance.bastion[0].public_ip} -W %h:%p %r" ${var.ssh_user}@${oci_core_instance.ServerNode[0].private_ip}


       ssh -i ${var.ssh_private_key_path}  -o BatchMode=yes -o StrictHostkeyChecking=no  -o ProxyCommand="ssh -i /home/${var.ssh_user}/.ssh/id_rsa  -o BatchMode=yes -o StrictHostkeyChecking=no ${var.ssh_user}@${oci_core_instance.bastion[0].public_ip} -W %h:%p %r" ${var.ssh_user}@${oci_core_instance.ServerNode[1].private_ip}


       ssh -i ${var.ssh_private_key_path}  -o BatchMode=yes -o StrictHostkeyChecking=no  -o ProxyCommand="ssh -i /home/${var.ssh_user}/.ssh/id_rsa  -o BatchMode=yes -o StrictHostkeyChecking=no ${var.ssh_user}@${oci_core_instance.bastion[0].public_ip} -W %h:%p %r" ${var.ssh_user}@${oci_core_instance.ComputeNode[0].private_ip}


END

}

