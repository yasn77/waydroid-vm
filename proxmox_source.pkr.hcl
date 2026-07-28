source "proxmox-iso" "waydroid_proxmox" {
  proxmox_url              = var.proxmox_api_url
  username                 = var.proxmox_api_token_id
  token                    = var.proxmox_api_token_secret
  insecure_skip_tls_verify = true

  node = var.proxmox_node

  boot_iso {
    type     = "scsi"
    iso_file = var.proxmox_iso_file
    unmount  = true
  }

  template_name                       = "archlinux-waydroid-golden"
  template_description                = "Arch Linux Waydroid appliance with GAPPS, ADB, Cage, and optional Tailscale."
  cloud_init                          = true
  cloud_init_storage_pool             = var.proxmox_cloud_init_storage_pool
  cloud_init_disk_type                = "scsi"
  cloud_init_disable_upgrade_packages = true

  os       = "l26"
  cores    = 4
  memory   = 4096
  cpu_type = "host"

  scsi_controller = "virtio-scsi-single"

  disks {
    disk_size    = "32G"
    format       = "raw"
    storage_pool = var.proxmox_storage_pool
    type         = "scsi"
  }

  vga {
    type   = var.proxmox_vga_type
    memory = 64
  }

  serials = ["socket"]

  network_adapters {
    model  = "virtio"
    bridge = "vmbr0"
  }

  boot_command = [
    "<enter><wait30s>",
    "curl -fsSL http://${var.proxmox_http_ip}:${var.proxmox_http_port}/install-arch.sh | bash",
    "<enter>"
  ]
  boot_wait = "10s"
  http_content = {
    "/install-arch.sh" = templatefile("${path.root}/http/install-arch.sh", {
      http_proxy   = var.http_proxy
      ssh_password = var.ssh_password
    })
  }
  http_bind_address = var.proxmox_http_ip
  http_port_min     = var.proxmox_http_port
  http_port_max     = var.proxmox_http_port

  ssh_username = var.ssh_username
  ssh_password = var.ssh_password
  ssh_timeout  = "30m"
}
