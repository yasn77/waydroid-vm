variable "arch_iso_url" {
  type    = string
  default = "https://www.mirrorservice.org/sites/ftp.archlinux.org/iso/2026.07.01/archlinux-2026.07.01-x86_64.iso"
}

variable "arch_iso_checksum" {
  type    = string
  default = "e86295dc0bdf9b85a5a9256810c553239689d2ae8e80eeec81b4e2e910d8a6c0"
}

variable "proxmox_iso_file" {
  type        = string
  default     = "local:iso/archlinux-x86_64.iso"
  description = "Path to the ISO file on Proxmox storage."
}

variable "proxmox_iso_storage_pool" {
  type        = string
  default     = "local"
  description = "Proxmox storage pool for ISO images."
}

variable "proxmox_storage_pool" {
  type        = string
  default     = "local-lvm"
  description = "Proxmox storage pool for VM disks."
}

variable "proxmox_cloud_init_storage_pool" {
  type        = string
  default     = "local"
  description = "Proxmox storage pool for the generated cloud-init drive."
}

variable "http_proxy" {
  type        = string
  default     = ""
  description = "HTTP proxy server URL for Arch package and installer downloads."
}

variable "proxmox_vga_type" {
  type        = string
  default     = "std"
  description = "Temporary installer-compatible VGA type. The finished template is switched to virtio-gl after the build."
}

variable "proxmox_http_ip" {
  type        = string
  description = "(Local) Address reachable by the Proxmox VM during Arch installation."
}

variable "proxmox_http_port" {
  type        = number
  default     = 8888
  description = "Fixed Packer HTTP port used by the Proxmox installer transport."
}

variable "tailscale_android_apk_url" {
  type        = string
  default     = "https://pkgs.tailscale.com/stable/tailscale-android-universal-1.98.8.apk"
  description = "Official Tailscale Android APK installed into Waydroid."
}

variable "ssh_password" {
  type      = string
  sensitive = true
  default   = "arch"
}

variable "ssh_username" {
  type      = string
  default   = "arch"
  sensitive = false
}

variable "proxmox_node" {
  type    = string
  default = "pve"
}

variable "proxmox_api_url" {
  type    = string
  description = "Format is https://xxx.xxx.xxx.xxx:8006/api2/json"
}

variable "proxmox_api_token_id" {
  type    = string
  default = "root@pam!packer"
}

variable "proxmox_api_token_secret" {
  type      = string
  sensitive = true
  default   = "secret"
}

variable "waydroid_init_type" {
  type        = string
  default     = "GAPPS"
  description = "Android ROM type to initialize: 'GAPPS' (with Google Play) or 'VANILLA'."
}

variable "waydroid_system_channel" {
  type        = string
  default     = ""
  description = "Optional custom OTA channel URL to force specific Android versions (leave empty for official default)."
}

variable "waydroid_vendor_channel" {
  type        = string
  default     = ""
  description = "Optional custom vendor OTA channel URL (leave empty for official default)."
}
