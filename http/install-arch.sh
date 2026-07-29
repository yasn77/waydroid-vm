#!/usr/bin/env bash
set -euxo pipefail

export http_proxy='${http_proxy}'
export https_proxy='${http_proxy}'

if [[ -z "$${http_proxy}" ]]; then
  unset http_proxy https_proxy
else
  sed -i '/^XferCommand = \/usr\/bin\/curl -x /d' /etc/pacman.conf
  printf 'XferCommand = /usr/bin/curl -x %s -L -C - -o %%o %%u\n' "$${http_proxy}" >> /etc/pacman.conf
fi

timedatectl set-ntp true

DISK="$(lsblk -dpno NAME,TYPE | awk '$2 == "disk" { print $1; exit }')"
[[ -n "$${DISK}" ]]

wipefs --all --force "$${DISK}"
sgdisk --zap-all "$${DISK}"
parted --script "$${DISK}" mklabel msdos
parted --script "$${DISK}" mkpart primary ext4 1MiB 100%

ROOT_PART="$${DISK}1"
[[ "$${DISK}" == *nvme* ]] && ROOT_PART="$${DISK}p1"
mkfs.ext4 -F "$${ROOT_PART}"
mount "$${ROOT_PART}" /mnt

pacstrap -K /mnt \
  base linux linux-firmware grub sudo openssh curl ca-certificates \
  cage weston spice-vdagent mesa mesa-utils libglvnd vulkan-swrast \
  qemu-guest-agent cloud-init lxc dnsmasq iptables-nft android-tools waydroid

genfstab -U /mnt >> /mnt/etc/fstab

arch-chroot /mnt /bin/bash -s <<CHROOT
set -euxo pipefail

sed -i '/^XferCommand = \/usr\/bin\/curl -x /d' /etc/pacman.conf

ln -sf /usr/share/zoneinfo/Europe/London /etc/localtime
hwclock --systohc

sed -i 's/^#en_GB.UTF-8 UTF-8/en_GB.UTF-8 UTF-8/' /etc/locale.gen
locale-gen
printf 'LANG=en_GB.UTF-8\n' > /etc/locale.conf
printf 'KEYMAP=uk\n' > /etc/vconsole.conf
printf 'arch-waydroid\n' > /etc/hostname

groupadd --force render
useradd --create-home --groups wheel,input,video,render --shell /bin/bash arch
printf 'arch:${ssh_password}\n' | chpasswd
printf 'arch ALL=(ALL) NOPASSWD: ALL\n' > /etc/sudoers.d/arch
chmod 0440 /etc/sudoers.d/arch

sed -i 's/^#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config
sed -i 's/^PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config

sed -i 's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers

mkdir -p /etc/systemd/network
cat > /etc/systemd/network/20-wired.network <<'NETWORK'
[Match]
Name=en*

[Network]
DHCP=yes
IPv6AcceptRA=yes
NETWORK

systemctl enable systemd-networkd systemd-resolved sshd qemu-guest-agent
systemctl enable spice-vdagentd.service || true
systemctl enable cloud-init-main.service cloud-final.service || true
ln -sfn /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf || true

mkdir -p /etc/cloud/cloud.cfg.d
cat > /etc/cloud/cloud.cfg.d/99-waydroid-arch.cfg <<'CLOUD'
datasource_list: [ NoCloud, ConfigDrive ]
ssh_pwauth: true
disable_root: true
CLOUD

grub-install --target=i386-pc "$${DISK}"
grub-mkconfig -o /boot/grub/grub.cfg

mkdir -p /etc/modules-load.d /etc/modprobe.d
cat > /etc/modules-load.d/waydroid.conf <<'MODULES'
loop
tun
MODULES
cat > /etc/modprobe.d/waydroid.conf <<'MODULES'
options binder_linux devices=binder,hwbinder,vndbinder
MODULES

cat > /etc/sysctl.d/99-waydroid.conf <<'SYSCTL'
net.ipv4.ip_forward = 1
net.ipv6.conf.all.forwarding = 1
kernel.pid_max = 65535
SYSCTL

systemctl enable waydroid-container.service

cat > /usr/local/bin/waydroid-kiosk <<'KIOSK'
#!/usr/bin/env bash
set -euo pipefail

waydroid prop set persist.adb.tcp.port 5555 || true
waydroid prop set persist.waydroid.multi_windows false || true
waydroid session start >/tmp/waydroid-session.log 2>&1 &
for _ in $(seq 1 30); do
  if waydroid status 2>/dev/null | grep -q 'Session:[[:space:]]*RUNNING'; then
    sleep 30
    break
  fi
  sleep 1
done
export XDG_RUNTIME_DIR=/run/user/1000
export WAYLAND_DISPLAY=wayland-0
exec waydroid show-full-ui
KIOSK
chmod 0755 /usr/local/bin/waydroid-kiosk

cat > /etc/systemd/system/waydroid-kiosk.service <<'SERVICE'
[Unit]
Description=Waydroid standalone GUI
After=waydroid-container.service network-online.target
Wants=waydroid-container.service network-online.target
Conflicts=getty@tty1.service

[Service]
Type=simple
User=arch
Group=arch
PAMName=login
Environment=XDG_SESSION_TYPE=wayland
Environment=WLR_LIBINPUT_NO_DEVICES=1
ExecStart=/usr/bin/cage -d -s -- /usr/local/bin/waydroid-kiosk
Restart=always
RestartSec=3
StandardInput=tty
TTYPath=/dev/tty1
TTYReset=yes
TTYVHangup=yes

[Install]
WantedBy=multi-user.target
SERVICE

systemctl enable waydroid-kiosk.service

CHROOT

rm -f /mnt/etc/resolv.conf || true
cp --dereference /etc/resolv.conf /mnt/etc/resolv.conf
NO_PROXY=sourceforge.net,.sourceforge.net no_proxy=sourceforge.net,.sourceforge.net \
  arch-chroot /mnt waydroid init -s GAPPS

rm -f /mnt/etc/resolv.conf || true
ln -sfn /run/systemd/resolve/stub-resolv.conf /mnt/etc/resolv.conf || true

umount -R /mnt || true
reboot
