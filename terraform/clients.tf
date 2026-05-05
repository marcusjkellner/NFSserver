resource "proxmox_virtual_environment_vm" "clientLegal" {
  depends_on = [proxmox_virtual_environment_vm.controller]

  name      = var.clientLegal_name
  node_name = var.nodename
  vm_id     = var.clientLegal_vmid

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
        address = var.clientLegal_ip
        gateway = var.vm_gateway
      }
    }
    user_account {
      username = var.clientLegal_username
      keys = [
        var.ssh_public_key,
        data.external.controller_pubkey.result["key"]
      ]
    }
  }

  connection {
    type        = "ssh"
    user        = var.clientLegal_username
    private_key = file("~/.ssh/id_ed25519")
    host        = split("/", var.clientLegal_ip)[0]
    timeout     = "10m"
  }

  provisioner "remote-exec" {
    inline = [
      "echo '=== Legal Client is Created! ==='"
    ]
  }
}

resource "proxmox_virtual_environment_vm" "clientSales" {
  depends_on = [proxmox_virtual_environment_vm.controller]

  name      = var.clientSales_name
  node_name = var.nodename
  vm_id     = var.clientSales_vmid

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
        address = var.clientSales_ip
        gateway = var.vm_gateway
      }
    }
    user_account {
      username = var.clientSales_username
      keys = [
        var.ssh_public_key,
        data.external.controller_pubkey.result["key"]
      ]
    }
  }

  connection {
    type        = "ssh"
    user        = var.clientSales_username
    private_key = file("~/.ssh/id_ed25519")
    host        = split("/", var.clientSales_ip)[0]
    timeout     = "10m"
  }

  provisioner "remote-exec" {
    inline = [
      "echo '=== Sales Client is Created! ==='"
    ]
  }
}