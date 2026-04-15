resource "proxmox_virtual_environment_vm" "controller" {
  name      = var.controller_name
  node_name = "coastmox"
  vm_id     = var.controller_vmid

  clone {
    vm_id = 200
    full  = true
  }

  cpu {
    cores = 2
  }

  memory {
    dedicated = 2048
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
      # Generate SSH key pair on controller
      "ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519 -N '' -C 'controller-key'",
      "echo '=== Controller ready ==='"
    ]
  }
}

# Read controller's public key after it has been generated
data "external" "controller_pubkey" {
  depends_on = [proxmox_virtual_environment_vm.controller]

  program = [
    "powershell.exe",
    "-NoProfile",
    "-Command",
    <<-EOT
      $ip  = "${split("/", var.controller_ip)[0]}"
      $ssh = "$env:SystemRoot\System32\OpenSSH\ssh.exe"
      $key = (& $ssh -o StrictHostKeyChecking=accept-new -i "$HOME\.ssh\id_ed25519" "${var.controller_username}@$ip" "cat ~/.ssh/id_ed25519.pub" | Out-String).Trim()
      @{ key = $key } | ConvertTo-Json -Compress
    EOT
  ]
}

resource "proxmox_virtual_environment_vm" "fileserver" {
  depends_on = [proxmox_virtual_environment_vm.controller]

  name      = var.fileserver_name
  node_name = "coastmox"
  vm_id     = var.fileserver_vmid

  clone {
    vm_id = 200
    full  = true
  }

  cpu {
    cores = 2
  }

  memory {
    dedicated = 2048
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
        address = var.fileserver_ip
        gateway = var.vm_gateway
      }
    }
    user_account {
      username = var.fileserver_username
      # Both your Mac key AND controller's key
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

resource "proxmox_virtual_environment_vm" "webserver" {
  depends_on = [proxmox_virtual_environment_vm.controller]

  name      = var.webserver_name
  node_name = "coastmox"
  vm_id     = var.webserver_vmid

  clone {
    vm_id = 200
    full  = true
  }

  cpu {
    cores = 2
  }

  memory {
    dedicated = 2048
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
        address = var.webserver_ip
        gateway = var.vm_gateway
      }
    }
    user_account {
      username = var.webserver_username
      # Both your Mac key AND controller's key
      keys = [
        var.ssh_public_key,
        data.external.controller_pubkey.result["key"]
      ]
    }
  }

  connection {
    type        = "ssh"
    user        = var.webserver_username
    private_key = file("~/.ssh/id_ed25519")
    host        = split("/", var.webserver_ip)[0]
  }

  provisioner "remote-exec" {
    inline = [
      "echo '=== webserver ready ==='"
    ]
  }
}

# Test: controller SSHes into fileserver and prints success message
resource "null_resource" "test_controller_to_fileserver" {
  depends_on = [
    proxmox_virtual_environment_vm.controller,
    proxmox_virtual_environment_vm.fileserver,
	proxmox_virtual_environment_vm.webserver
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
	  
	  "ssh-keyscan -H ${split("/", var.webserver_ip)[0]} >> ~/.ssh/known_hosts",
      "ssh -i ~/.ssh/id_ed25519 ${var.webserver_username}@${split("/", var.webserver_ip)[0]} 'echo === SSH TEST SUCCESSFUL: Controller reached Webserver ==='",
    ]
  }
}