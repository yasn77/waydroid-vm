packer {
  required_plugins {
    proxmox = {
      version = ">= 1.1.8"
      source  = "github.com/hashicorp/proxmox"
    }
    qemu = {
      version = ">= 1.1.0"
      source  = "github.com/hashicorp/qemu"
    }
  }
}

build {
  sources = [
    "source.proxmox-iso.waydroid_proxmox",
    "source.qemu.waydroid_qemu"
  ]

  provisioner "shell" {
    inline = [
      "sudo systemctl enable waydroid-container.service waydroid-kiosk.service qemu-guest-agent sshd",
      "sudo waydroid status || true"
    ]
  }

  provisioner "shell" {
    inline = [
      "sudo systemctl start waydroid-container.service",
      "http_proxy='${var.http_proxy}' https_proxy='${var.http_proxy}' curl -fsSL '${var.tailscale_android_apk_url}' -o /tmp/tailscale-android.apk",
      "waydroid session start >/tmp/waydroid-session.log 2>&1 &",
      "sleep 30",
      "waydroid app install /tmp/tailscale-android.apk",
      "rm -f /tmp/tailscale-android.apk"
    ]
  }

  provisioner "shell" {
    inline = [
      "echo '=== Scrubbing Arch system identity for golden template ==='",
      "sudo rm -f /etc/ssh/ssh_host_*_key*",
      "sudo truncate -s 0 /etc/machine-id",
      "sudo rm -f /var/lib/dbus/machine-id",
      "sudo ln -s /etc/machine-id /var/lib/dbus/machine-id",
      "sudo rm -rf /var/cache/pacman/pkg/* /tmp/* /var/tmp/*",
      "sudo cloud-init clean --logs --seed || true",
      "sudo rm -rf /var/lib/cloud/instances /var/lib/cloud/sem",
      "sudo journalctl --rotate || true",
      "sudo journalctl --vacuum-time=1s || true",
      "history -c || true"
    ]
  }
}
