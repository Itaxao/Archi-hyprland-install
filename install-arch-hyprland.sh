#!/bin/bash
set -e

# ================================
# Variáveis de usuário
# ================================
USERNAME="italo"
HOSTNAME="arch-hypr"
LOCALE="pt_BR.UTF-8"
TIMEZONE="America/Sao_Paulo"
KERNEL="linux"

# ================================
# Partição já deve estar montada em /mnt
# Exemplo: mount /dev/nvme0n1p2 /mnt
# ================================

echo "[*] Instalando pacotes base..."
pacstrap -K /mnt base base-devel $KERNEL $KERNEL-firmware \
    networkmanager vim git sudo

echo "[*] Gerando fstab..."
genfstab -U /mnt >> /mnt/etc/fstab

arch-chroot /mnt /bin/bash <<EOF
echo "[*] Configurando timezone e locale..."
ln -sf /usr/share/zoneinfo/$TIMEZONE /etc/localtime
hwclock --systohc
echo "$LOCALE UTF-8" >> /etc/locale.gen
locale-gen
echo "LANG=$LOCALE" > /etc/locale.conf
echo "$HOSTNAME" > /etc/hostname

echo "[*] Configurando hosts..."
cat <<EOT > /etc/hosts
127.0.0.1    localhost
::1          localhost
127.0.1.1    $HOSTNAME.localdomain $HOSTNAME
EOT

echo "[*] Defina senha do root:"
passwd

echo "[*] Criando usuário $USERNAME..."
useradd -m -G wheel $USERNAME
echo "[*] Defina senha para $USERNAME:"
passwd $USERNAME

echo "[*] Configurando sudo..."
sed -i 's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers

echo "[*] Instalando systemd-boot..."
bootctl install

ROOT_PART=\$(findmnt -no SOURCE /)
cat <<EOT > /boot/loader/entries/arch.conf
title   Arch Linux
linux   /vmlinuz-$KERNEL
initrd  /initramfs-$KERNEL.img
options root=\$ROOT_PART rw
EOT

cat <<EOT > /boot/loader/loader.conf
default arch
timeout 3
console-mode max
editor no
EOT

echo "[*] Ativando serviços..."
systemctl enable NetworkManager

echo "[*] Instalando Hyprland cru + fish..."
pacman -S --noconfirm hyprland fish

echo "[*] Alterando shell padrão para fish..."
chsh -s /usr/bin/fish $USERNAME
EOF

echo "[*] Instalação concluída! Agora:"
echo "1) reboot"
echo "2) logar com usuário $USERNAME"
echo "3) instalar yay: git clone https://aur.archlinux.org/yay.git"
echo "4) yay -S caelestia-meta"
echo "5) ~/.local/share/caelestia/install.fish --noconfirm"
