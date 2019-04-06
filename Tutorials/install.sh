# Referencia: https://wiki.gentoo.org/wiki/Handbook:AMD64
###########################################################
#### Parte 1ª: iniciar con Gentoo MinimalCD ####

# La configuración de la red se hace así:
wpa_passphrase “MOVISTAR_1CAA” > /etc/wpa.conf #(y escribir la contraseña)
chmod -v 600 /etc/wpa.conf
cat /etc/wpa.conf
wpa_supplicant -Dnl80211,wext -iwlpxxx -c/etc/wpa.conf -B
dhcpcd
ping -c 3 www.google.com

# En caso de particionar el disco duro, realizar la acción bien con cfdisk o bien con gparted o similar. Debería quedar así:
# /dev/sda1 200M UEFI BOOT
# /dev/sda2 30G (-8G para el /swapfile, más adelante) /
# /dev/sda3 resto del espacio /home

# Para ello, ejecutar en gdisk las siguientes instrucciones, sin swapfile (con swapfile, utilizar +30G)
# (↵ hace referencia a la tecla enter):
# o (borrar todo el disco), y confirmar con y
# n, 1, ↵, +200M, EF00
# n, 2, ↵, +4G, 8200
# n, 3, ↵, +25G, 8300
# n, 4, ↵, ↵, 8300
# w, y

mkfs.vfat -F 32 /dev/sda1  ## Solo si no existe una partición /boot
mkswap /dev/sda2
swapon /dev/sda2
mkfs.ext4 /dev/sda3
mkfs.ext4 /dev/sda4

## Montar las particiones
mount /dev/sda2 /mnt/gentoo
mkdir /boot/efi  ## Solo si no existe una partición /boot
mount /dev/sda1 /boot/efi  ## Solo si no existe una partición /boot
mkdir /mnt/gentoo/home
mount /dev/sda3 /mnt/gentoo/home

#### Parte 2ª: instalar los paquetes del stage ####

## Determinar la hora

date MMDDhhmmYY

## Descargar el paquete stage3
cd /mnt/gentoo
wget -c ftp://ftp.uni-erlangen.de/pub/mirrors/gentoo/releases/amd64/autobuilds/current-stage3-amd64/stage3-amd64-XXXXXX.tar.xz
# Las XXXX hacen referencia al código alfanumérico del paquete en cuestión, imposible reproducirlo porque cambia cada día o semana
tar xvpf stage3-*.tar.xz --xattrs-include='*.*' --numeric-owner

## Modificar make.conf
nano -w /mnt/gentoo/etc/portage/make.conf
# COMMON_FLAGS=”-march=native -O2 -pipe”
# CFLAGS=”${COMMON_FLAGS}”
# CXXFLAGS=”${COMMON_FLAGS}”
# FCFLAGS=”${COMMON_FLAGS}”
# FFLAGS=”${COMMON_FLAGS}”
# MAKEOPTS=”-j5”
# FEATURES=”${FEATURES} ccache”
# CACHE_DIR=”/gentoo/ccache”
# USE=”-bindist icu mmx python sse sse2 emu”
# INPUT_DEVICES=”evdev keyboard mouse”
# VIDEO_CARDS=”intel i965”
# LANG=”es_ES.UTF-8”
# LINGUAS=”es”
# L10N=”es es-ES”
# GRUB_PLATFORMS=”efi-64”  ## Solo si se va a usar Grub.


## Elegir los espejos
mirrorselect -i -o >> /mnt/gentoo/etc/portage/make.conf

## Crear el repositorio ebuild
mkdir --parents /mnt/gentoo/etc/portage/repos.conf
cp /mnt/gentoo/usr/share/portage/config/repos.conf /mnt/gentoo/etc/portage/repos.conf/gentoo.conf
#(El archivo debe contener lo siguiente:

#[DEFAULT]
#main-repo = gentoo

#[gentoo]
#location = /usr/portage
#sync-type = rsync
#sync-uri = rsync://rsync.gentoo.org/gentoo-portage
#auto-sync = yes
#sync-rsync-verify-jobs = 1
#sync-rsync-verify-metamanifest = yes
#sync-rsync-verify-max-age = 24
#sync-openpgp-key-path = /usr/share/openpgp-keys/gentoo-release.asc
#sync-openpgp-key-refresh-retry-count = 40
#sync-openpgp-key-refresh-retry-overall-timeout = 1200
#sync-openpgp-key-refresh-retry-delay-exp-base = 2
#sync-openpgp-key-refresh-retry-delay-max = 60
#sync-openpgp-key-refresh-retry-delay-mult = 4
#)

#### Parte 3ª: cambiar de sistema ####

## Copiar la información DNS y montar los sistemas de archivos necesarios
cp --dereference /etc/resolv.conf /mnt/gentoo/etc/
mount --types proc /proc /mnt/gentoo/proc
mount --rbind /sys /mnt/gentoo/sys
mount --rbind /dev /mnt/gentoo/dev

## chroot
chroot /mnt/gentoo /bin/bash
source /etc/profile
export PS1="(chroot) ${PS1}"

## Si al crear las particiones en la parte 1ª no se creó una partición swap, realizar los siguientes pasos
fallocate -l 4096M /swapfile
chmod 600 /swapfile
mkswap /swapfile
swapon /swapfile

## Sincronizar espejos y seleccionar perfiles
time emerge-webrsync
eselect profile list
eselect profile set X ## La X es el número apropiado.
time emerge -avuND @world

## Configurar zona horaria
ls /usr/share/zoneinfo
echo "Europe/Madrid" > /etc/timezone
emerge --config sys-libs/timezone-data

## Configurar idioma
nano -w /etc/locale.gen
# es_ES ISO-8859-1
# es_ES.UTF-8 UTF-8
nano -w /etc/env.d/02locale ## Sólo si no existe o si no está configurado
# LANG="es_ES.UTF-8"
# LC_COLLATE="C"
locale-gen
eselect locale list
eselect locale set X ## La X es el número apropiado, normalmente es_ES.utf-8
env-update && source /etc/profile && export PS1="(chroot) ${PS1}"

#### Parte 4ª: instalación y configuración del kernel ####

## Instalar las fuentes
time emerge -av sys-kernel/gentoo-sources

## Subparte 1ª: instalación manual
time emerge -av pciutils usbutils
cd /usr/src/linux
make menuconfig  ## Si se va a actualizar el kernel, usar el comando make menuconfig olddefconfig
## En este punto seleccionar y deseleccionar aquello que se vaya a usar y que no se vaya a usar
make -j5
make modules_install
make install

## Subparte 2ª: genkernel
time emerge -av sys-kernel/genkernel
nano -w /etc/fstab
# UUID=xxx /boot/efi vfat defaults,noatime 0 2
# UID=yyy swap swap defaults,noatime 0 2
# UUID=zzz / ext4 defaults,noatime 0 1
# UUID=aaa /home ext4 defaults,noatime 0 2
## Para conocer los identificadores UUID, usar el comando blkid

genkernel --no-zfs --no-btrfs --menuconfig all
## En este punto seleccionar y deseleccionar aquello que se vaya a usar y que no se vaya a usar
ls /boot/kernel* /boot/initramfs* ## Apuntar los nombres del kernel y del initrd para usarlos más adelante, en el boot

## Configurar los módulos
find /lib/modules/<kernel version>/ -type f -iname '*.o' -or -iname '*.ko' | less
mkdir -p /etc/modules-load.d
nano -w /etc/modules-load.d/network.conf
## Escribir el nombre del módulo a cargar automáticamente, en caso necesario
emerge -av sys-kernel/linux-firmware net-wireless/broadcom-sta*
* ## Solo si se va a usar ese dispositivo
emerge -avn net-misc/netifrc
nano -w /etc/conf.d/net
# modules_wlp2s0=”wpa_supplicant”
# config_wlp2s0=”dhcpcd”
cd /etc/init.d && ln -s net.lo net.wlp2s0 && rc-update add net.wlp2s0 default

#### Parte 5ª: Configuración variada ####

## Contraseña
passwd

## Host
nano -w /etc/conf.d/hostname
# hostname="gentoo"
nano -w /etc/hosts
# 127.0.0.1 gentoo localhost
nano -w /etc/rc.conf
# rc_shell=/sbin/sulogin
# unicode=“YES”
nano -w /etc/conf.d/keymaps
# keymap=“es”
# windowkeys=“YES”
nano -w /etc/conf.d/hwclock
# clock="local" ## Cambiar a UTC
nano -w /etc/inittab
# c1:12345:respawn:/sbin/agetty 38400 tty1 linux --noclear
time emerge -av /sysklogd cronie mlocate ccache flaggie gentoolkit sudo
rc-update add sysklogd default
rc-update add cronie default
emerge -av dosfstools dhcpcd wpa_supplicant wireless-tools
touch /etc/ wpa_supplicant/wpa_supplicant.conf
time emerge -av grub
mount -o remount,rw /sys/firmware/efi/efivars
mount -o remount,rw /boot/efi
grub-install --target=x86_64-efi --efi-directory=/boot/efi
grub-mkconfig -o /boot/grub/grub.cfg

## Opcional
time emerge -av app-shells/zsh app-shells/zsh-completions app-shells/gentoo-zsh-completions x11-wm/i3-gaps x11-terms/rxvt-unicode
chsh -s /bin/zsh

## Finalización
exit
cd
umount -l /mnt/gentoo/dev{/shm,/pts,}
umount -R /mnt/gentoo
reboot

#### Parte 6ª: Configuración post-instalación inicial ####

## Añadir usuario

useradd -m -G users,wheel,audio,games,usb,video -s /bin/zsh usuario
passwd usuario
rm /stage3-*.tar.bz2*

#### Parte 7ª: Consideraciones al usar un LiveCD/DVD de otra distribución ####
## Crear el directorio para gentoo antes de montar las particiones
mkdir /mnt/gentoo
mount /dev/sda3 /mnt/gentoo
mkdir /mnt/gentoo/home
mount /dev/sda4 /mnt/gentoo/home

## Desempaquetar stage3
# tar xvpf stage3-*.tar.xz --xattrs-include='*.*' --numeric-owner
tar xvpf stage3-*.tar.xz --xattrs-include='*.*' --numeric-owner -C /mnt/gentoo

## Añadir, al menos, un espejo manualmente al archivo make.conf
# GENTOO_MIRRORS="http://distfiles.gentoo.org"

## Montar el sistema de archivos proc
# mount --types proc /proc /mnt/gentoo/proc
mount -o bind /proc /mnt/gentoo/proc

## chroot
# chroot /mnt/gentoo /bin/bash
chroot /mnt/gentoo /bin/env -i TERM=$TERM /bin/bash
env-update
source /etc/profile
export PS1="(chroot) $PS1"

## Instalar mirrorselect después de actualizar (opcional)
time emerge -qavuND @world && time emerge -av mirrorselect
