source "qemu" "waydroid_qemu" {
  iso_url      = var.arch_iso_url
  iso_checksum = var.arch_iso_checksum

  disk_image     = false
  format         = "qcow2"
  accelerator    = "kvm"
  disk_size      = "32G"
  disk_interface = "virtio"
  net_device     = "virtio-net"
  display        = "none"

  cpu_model = "host"
  qemuargs = [
    ["-display", "none"],
    ["-smp", "4"],
    ["-m", "4096"],
    ["-vga", "virtio"],
    ["-serial", "file:/tmp/arch-serial.log"]
  ]

  boot_command = [
    "<enter><wait120s>",
    "curl -fsSL http://{{ .HTTPIP }}:{{ .HTTPPort }}/install-arch.sh | bash",
    "<enter>"
  ]
  boot_wait = "10s"
  http_content = {
    "/install-arch.sh" = templatefile("${path.root}/http/install-arch.sh", {
      http_proxy   = var.http_proxy
      ssh_password = var.ssh_password
    })
  }

  ssh_username = var.ssh_username
  ssh_password = var.ssh_password
  ssh_timeout  = "30m"

  shutdown_command = "echo '${var.ssh_password}' | sudo -S shutdown -h now"
  output_directory = "output-waydroid-qemu"
  vm_name          = "archlinux-waydroid-golden.qcow2"
}
