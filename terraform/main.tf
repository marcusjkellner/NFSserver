resource "proxmox_virtual_environment_vm" "controller" {
  name      = var.controller_name
  node_name = var.nodename
  vm_id     = var.controller_vmid

  clone {
    vm_id = var.VMTemplateID
    full  = true
  }

  cpu {
    cores = 2
  }

  memory {
    dedicated = 4096
  }

  disk {
    datastore_id = "local-lvm"
    size         = 10
    interface    = "scsi0"
  }

  network_device {
    bridge = "vmbr0"
    model  = "virtio"
  }

  initialization {
    ip_config {
      ipv4 {
        address = var.controller_ip
        gateway = var.vm_gateway
      }
    }
    user_account {
      username = var.controller_username
      keys     = [var.ssh_public_key]
    }
  }

  connection {
    type        = "ssh"
    user        = var.controller_username
    private_key = file("~/.ssh/id_ed25519")
    host        = split("/", var.controller_ip)[0]
  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt-get update -y",
      "sudo apt-get install -y ansible",
      "ansible-galaxy collection install community.general:==2.5.9 --force",
      "sudo rm -rf /usr/lib/python3/dist-packages/ansible_collections/community/general",
      # Generate SSH key pair on controller
      "ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519 -N '' -C 'controller-key'",
      "echo '=== Controller ready, Ansible installed, packet manager Galaxy community.generl installed ==='"
    ]
  }
}

# Read controller's public key after it has been generated
data "external" "controller_pubkey" {
  depends_on = [proxmox_virtual_environment_vm.controller]

  program = var.os_type == "windows" ? [
    "powershell.exe",
    "-NoProfile",
    "-Command",
    <<-EOT
      $ip  = "${split("/", var.controller_ip)[0]}"
      $ssh = "$env:SystemRoot\System32\OpenSSH\ssh.exe"
      $key = (& $ssh -o StrictHostKeyChecking=accept-new -i "$HOME\.ssh\id_ed25519" "${var.controller_username}@$ip" "cat ~/.ssh/id_ed25519.pub" | Out-String).Trim()
      @{ key = $key } | ConvertTo-Json -Compress
    EOT
  ] : [
    "bash",
    "-c",
    <<-EOT
      KEY=$(ssh -o StrictHostKeyChecking=no -i ~/.ssh/id_ed25519 ${var.controller_username}@${split("/", var.controller_ip)[0]} "cat ~/.ssh/id_ed25519.pub")
      echo "{\"key\": \"$KEY\"}"
    EOT
  ]
}


resource "proxmox_virtual_environment_vm" "fileserver" {
  depends_on = [proxmox_virtual_environment_vm.controller]

  name      = var.fileserver_name
  node_name = var.nodename
  vm_id     = var.fileserver_vmid

  clone {
    vm_id = var.VMTemplateID
    full  = true
  }

  cpu {
    cores = 2
  }

  memory {
    dedicated = 2560
  }

# os disk
  disk {
    datastore_id = "local-lvm"
    size         = 10
    interface    = "scsi0"
  }

# disk for /shares
  disk {
    datastore_id = "local-lvm"
    size         = 10
    interface    = "scsi1"
  }

  network_device {
    bridge = "vmbr0"
    model  = "virtio"
  }

  initialization {
    ip_config {
      ipv4 {
        address = var.fileserver_ip
        gateway = var.vm_gateway
      }
    }
    user_account {
      username = var.fileserver_username
      keys = [
        var.ssh_public_key,
        data.external.controller_pubkey.result["key"]
      ]
    }
  }

  connection {
    type        = "ssh"
    user        = var.fileserver_username
    private_key = file("~/.ssh/id_ed25519")
    host        = split("/", var.fileserver_ip)[0]
  }

  provisioner "remote-exec" {
    inline = [
      "echo '=== Fileserver ready ==='"
    ]
  }
}


# Test: controller SSHes into fileserver and prints success message
resource "null_resource" "test_controller_to_fileserver" {
  depends_on = [
    proxmox_virtual_environment_vm.controller,
    proxmox_virtual_environment_vm.fileserver,
	  proxmox_virtual_environment_vm.clientLegal,
    proxmox_virtual_environment_vm.clientSales
  ]

  connection {
    type        = "ssh"
    user        = var.controller_username
    private_key = file("~/.ssh/id_ed25519")
    host        = split("/", var.controller_ip)[0]
  }

  provisioner "remote-exec" {
    inline = [
      "ssh-keyscan -H ${split("/", var.fileserver_ip)[0]} >> ~/.ssh/known_hosts",
      "ssh -i ~/.ssh/id_ed25519 ${var.fileserver_username}@${split("/", var.fileserver_ip)[0]} 'echo === SSH TEST SUCCESSFUL: Controller reached Fileserver ==='",
	  
	  "ssh-keyscan -H ${split("/", var.clientLegal_ip)[0]} >> ~/.ssh/known_hosts",
      "ssh -i ~/.ssh/id_ed25519 ${var.clientLegal_username}@${split("/", var.clientLegal_ip)[0]} 'echo === SSH TEST SUCCESSFUL: Controller reached Client Legal! ==='",
    
    "ssh-keyscan -H ${split("/", var.clientSales_ip)[0]} >> ~/.ssh/known_hosts",
      "ssh -i ~/.ssh/id_ed25519 ${var.clientSales_username}@${split("/", var.clientSales_ip)[0]} 'echo === SSH TEST SUCCESSFUL: Controller reached Client Sales! ==='",
    
    ]
  }
}

resource "null_resource" "run_ansible" {
  depends_on = [null_resource.test_controller_to_fileserver]

  connection {
    type        = "ssh"
    user        = var.controller_username
    private_key = file("~/.ssh/id_ed25519")
    host        = split("/", var.controller_ip)[0]
  }

  provisioner "remote-exec" {
    inline = [
      "git clone https://github.com/marcusjkellner/NFSserver.git ~/NFSserver",
      "printf '[controller]\\n${split("/", var.controller_ip)[0]} ansible_user=${var.controller_username} ansible_ssh_private_key_file=~/.ssh/id_ed25519\\n\\n[fileserver]\\n${split("/", var.fileserver_ip)[0]} ansible_user=${var.fileserver_username} ansible_ssh_private_key_file=~/.ssh/id_ed25519\\n\\n[clients]\\n${split("/", var.clientLegal_ip)[0]} ansible_user=${var.clientLegal_username} ansible_ssh_private_key_file=~/.ssh/id_ed25519\\n${split("/", var.clientSales_ip)[0]} ansible_user=${var.clientSales_username} ansible_ssh_private_key_file=~/.ssh/id_ed25519\\n' > ~/NFSserver/ansible/inventory.ini",
      "echo '=== Repo cloned and inventory ready ==='"
    ]
  }
}