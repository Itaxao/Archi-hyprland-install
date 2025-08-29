#!/bin/bash
set -e

# ================================
# VARIÁVEIS DO USUÁRIO
# ================================
DISK="/dev/sda"             # HDD SATA alvo (cuidado!)
USERNAME="italo"
HOSTNAME="arch-hypr"
LOCALE="pt_BR.UTF-8"
TIMEZONE="America/Sao_Paulo"
KERNEL="linux"

# ================================
# 1. PARTIÇÃO E FORMATAÇÃO
# ================================
echo "[*] Apagando tabela de partição de $DISK..."
sgdisk --zap-all $DISK

echo "[*] Criando novas partições..."
parted -s $DISK mklabel gpt
parted -s $DISK mkpart EFI fat32 1MiB 513MiB
parted -s $DISK set 1 esp on
parted -s $DISK mkpart ROOT ext4 513MiB 100%

EFI_PART="${DISK}1"
ROOT_PART="${DISK}2"

echo "[*] Formatando partições..."
mkfs.fat -F32 $EFI_PART
mkfs.ext4 -F $ROOT_PART

echo "[*] Montando partições..."
mount $ROOT_PART /mnt
mkdir -p /mnt/boot
mount $EFI_PART /mnt/boot

# ================================
# 2. PACOTES BASE
# ================================
echo "[*] Instalando pacotes base..."
pacstrap -K /mnt base base-devel $KERNEL $KERNEL-firmware \
    networkmanager vim git sudo

echo "[*] Gerando fstab..."
genfstab -U /mnt >> /mnt/etc/fstab

# ================================
# 3. CHROOT
# ================================
arch-chroot /mnt /bin/bash <<EOF
set -e

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

cat <<EOT > /boot/loader/entries/arch.conf
title   Arch Linux
linux   /vmlinuz-$KERNEL
initrd  /initramfs-$KERNEL.img
options root=$ROOT_PART rw
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

echo "[*] Instalação concluída!"
echo "Reinicie com: reboot"
echo "Depois logue com '$USERNAME' e siga com:"
echo "  1) Instalar yay"
echo "  2) Clonar Caelestia e rodar install.fish"
