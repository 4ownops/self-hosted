packer {
  required_plugins {
    proxmox = {
      version = ">= 1.1.3"
      source  = "github.com/hashicorp/proxmox"
    }
  }
}

variable "iso_file" {
  type = string
}

variable "cloudinit_storage_pool" {
  type    = string
  default = "local-lvm"
}

variable "cores" {
  type    = string
  default = "1"
}

variable "disk_format" {
  type    = string
  default = "raw"
}

variable "disk_size" {
  type    = string
  default = "10G"
}

variable "disk_storage_pool" {
  type    = string
  default = "local-lvm"
}

variable "cpu_type" {
  type    = string
  default = "host"
}

variable "memory" {
  type    = string
  default = "1024"
}

variable "network_vlan" {
  type    = string
  default = ""
}

variable "machine_type" {
  type    = string
  default = ""
}

variable "proxmox_api_password" {
  type      = string
  sensitive = true
}

variable "proxmox_api_user" {
  type = string
}

variable "proxmox_host" {
  type = string
}

variable "proxmox_node" {
  type = string
}

variable "tftp_server_address" {
  type = string
}

variable "vm_id" {
  type = number
  default = ""
}

source "proxmox-iso" "debian" {
  proxmox_url              = "https://${var.proxmox_host}/api2/json"
  insecure_skip_tls_verify = true
  username                 = var.proxmox_api_user
  password                 = var.proxmox_api_password

  template_description = "Built from ${basename(var.iso_file)} on ${formatdate("YYYY-MM-DD hh:mm:ss ZZZ", timestamp())}"
  node                 = var.proxmox_node
  network_adapters {
    bridge   = "vmbr0"
    firewall = true
    model    = "virtio"
    vlan_tag = var.network_vlan
  }
  disks {
    disk_size    = var.disk_size
    format       = var.disk_format
    io_thread    = true
    storage_pool = var.disk_storage_pool
    type         = "scsi"
  }
  scsi_controller = "virtio-scsi-single"

  iso_file       = var.iso_file
  http_directory = "./"
  boot_wait      = "10s"
  boot_command   = ["<esc><wait>auto url=tftp://${var.tftp_server_address}/preseed/vm4.cfg<enter>"]
  unmount_iso    = true

  cloud_init              = true
  cloud_init_storage_pool = var.cloudinit_storage_pool

  vm_name  = trimsuffix(basename(var.iso_file), ".iso")
  vm_id    = var.vm_id
  cpu_type = var.cpu_type
  os       = "l26"
  memory   = var.memory
  cores    = var.cores
  sockets  = "1"
  machine  = var.machine_type

  ssh_password = "packer"
  ssh_username = "root"
  ssh_timeout  = "10m"
}

build {
  sources = ["source.proxmox-iso.debian"]

  provisioner "file" {
    destination = "/etc/sysctl.d"
    source      = "configs/"
  }

  provisioner "shell" {
    inline = [
      "cp /etc/default/grub /etc/default/grub.orig",
      "sed -i 's/GRUB_CMDLINE_LINUX=\"\"/GRUB_CMDLINE_LINUX=\"transparent_hugepage=never\"/g' /etc/default/grub",
      "update-grub",
      "reboot"
    ]
    expect_disconnect = true
  }

  provisioner "file" {
    destination = "/etc/cloud/cloud.cfg"
    source      = "cloud.cfg"
  }
}
