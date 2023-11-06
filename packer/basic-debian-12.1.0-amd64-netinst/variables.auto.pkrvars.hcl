proxmox_host           = "192.168.0.30:8006"
proxmox_node           = "pve"
proxmox_api_user       = "${proxmox_api_user}" # sensitive
proxmox_api_password   = "${proxmox_api_password}" # sensitive

iso_file               = "templates:iso/debian-12.1.0-amd64-netinst.iso"
cloudinit_storage_pool = "data"
disk_storage_pool      = "disks"
tftp_server_address    = "192.168.0.2"
vm_id                  = 102