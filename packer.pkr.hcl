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
      "sudo systemctl enable waydroid-container.service waydroid-adb.service waydroid-kiosk.service qemu-guest-agent sshd",
      "sudo systemctl start waydroid-container.service",
      "sudo systemctl start waydroid-kiosk.service",
      "sudo systemctl start waydroid-adb.service",
      "timeout 60 bash -c 'until waydroid status 2>/dev/null | grep -q RUNNING; do sleep 2; done'",
      "sudo waydroid status || true"
    ]
  }

  provisioner "shell" {
    inline = [
      "http_proxy='${var.http_proxy}' https_proxy='${var.http_proxy}' curl -fsSL '${var.tailscale_android_apk_url}' -o /tmp/tailscale-android.apk",
      "echo 'Waiting for Waydroid session to be ready...'",
      "timeout 60 bash -c 'until waydroid status 2>/dev/null | grep -q RUNNING; do sleep 2; done'",
      "sleep 5",
      "waydroid app install /tmp/tailscale-android.apk",
      "timeout 30 bash -c 'until waydroid app list | grep -q com.tailscale.ipn; do sleep 2; done'",
      "rm -f /tmp/tailscale-android.apk"
    ]
  }

  provisioner "shell" {
    inline = [
      "echo '=== Scrubbing Arch system identity for golden template ==='",
      "sudo systemctl stop waydroid-kiosk.service waydroid-container.service || true",
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
