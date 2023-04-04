provider "virtualbox" {
  version = ">= 2.4.0"
}

provider "virtualbox" {}

resource "virtualbox_vm" "ubuntu" {
  name        = "ubuntu-server"
  ostype      = "Ubuntu_64"
  memory      = "1024"
  vram        = "16"
  boot_order  = "dvd"
}

resource "virtualbox_storage_controller" "sata" {
  name            = "SATA Controller"
  bus             = "sata"
  controller_type = "IntelAhci"
}

resource "virtualbox_storage_attach" "dvd" {
  storage_controller_name = "${virtualbox_storage_controller.sata.name}"
  medium                  = "/home/oryza/Downloads/ubuntu-22.04.2-live-server-amd64.iso"
  port                    = "0"
  device                  = "0"
}

resource "virtualbox_nat_network" "network" {
  network_name = "NAT"
}

resource "virtualbox_network_adapter" "adapter1" {
  vm_name             = "${virtualbox_vm.ubuntu.name}"
  nic_type            = "virtio"
  adapter_number      = "1"
  nat_network_name    = "${virtualbox_nat_network.network.network_name}"
  host_only_interface = ""
}

resource "virtualbox_guest_additions_iso" "ubuntu" {
  vm_name = "${virtualbox_vm.ubuntu.name}"
}

resource "null_resource" "ubuntu" {
  provisioner "remote-exec" {
    inline = [
      "sudo apt-get update",
      "sudo apt-get install -y openssh-server",
    ]
  }

  provisioner "local-exec" {
    command = "echo ${virtualbox_network_adapter.adapter1.ipv4_address} > ip_address.txt"
  }

  depends_on = [
    "virtualbox_storage_attach.dvd",
    "virtualbox_guest_additions_iso.ubuntu",
  ]
}

terraform {
  required_providers {
    virtualbox = {
      source = "terra-farm/virtualbox"
      version = "0.2.1"
    }
  }
}

resource "virtualbox_vm" "node" {
  count     = 2
  name      = format("node-%02d", count.index + 1)
  image     = "https://app.vagrantup.com/ubuntu/boxes/bionic64/versions/20180903.0.0/providers/virtualbox.box"
  cpus      = 1
  memory    = "512 mib"
  user_data = file("${path.module}/user_data")

  network_adapter {
    type           = "hostonly"
    host_interface = "vboxnet1"
  }
}

output "IPAddr" {
  value = element(virtualbox_vm.node.*.network_adapter.0.ipv4_address, 1)
}

output "IPAddr_2" {
  value = element(virtualbox_vm.node.*.network_adapter.0.ipv4_address, 2)
}

