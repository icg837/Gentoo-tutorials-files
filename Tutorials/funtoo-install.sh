# Referencia: https://www.funtoo.org/Install/Introduction
###########################################################
#### Parte 1ª: iniciar con Gentoo MinimalCD ####

# La configuración de la red se hace así:
wpa_passphrase “MOVISTAR_1CAA” > /etc/wpa.conf #(y escribir la contraseña)
chmod -v 600 /etc/wpa.conf
cat /etc/wpa.conf
wpa_supplicant -Dnl80211,wext -iwlpxxx -c/etc/wpa.conf -B
dhcpcd
ping -c 3 www.google.com

# En caso de particionar el disco duro, realizar la acción bien con gdisk. Debería quedar así:
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

mkfs.vfat -F 32 /dev/sda1
mkswap /dev/sda2
swapon /dev/sda2
mkfs.ext4 /dev/sda3
mkfs.ext4 /dev/sda4

## Montar las particiones
mount /dev/sda3 /mnt/funtoo
mkdir /mnt/funtoo/boot
mount /dev/sda1 /mnt/funtoo/boot
mkdir /mnt/funtoo/home
mount /dev/sda4 /mnt/funtoo/home

#### Parte 2ª: instalar los paquetes del stage ####

## Determinar la hora

date MMDDhhmmYY
hwclock --systohc

## Descargar el paquete stage3
cd /mnt/funtoo
wget -c https://build.funtoo.org/1.3-release-std/x86-64bit/generic_64/stage3-latest.tar.xz
tar xvpf stage3-latest.tar.xz

#### Parte 3ª: cambiar de sistema ####

## Copiar la información DNS y montar los sistemas de archivos necesarios
cp /etc/resolv.conf /mnt/funtoo/etc/
mount -t proc none proc
mount --rbind /sys sys
mount --rbind /dev dev

## chroot
env -i HOME=/root TERM=$TERM /bin/chroot . bash -l
export PS1="(chroot) $PS1"

## Probar la conexión a internet
ping -c 3 www.google.com

# Si hay problemas en el paso anterior, comprobar que el archivo /etc/resolv.conf no contiene cosas como 127.0.x.x, y si las
# tiene, sustituirlas por 8.8.8.8. De nuevo, cambiarlas por mi DNS una vez instalado el sistema.

## Sincronizar espejos
ego sync

## Configurar la tabla de particiones
nano -w /etc/fstab
# /dev/sda1 /boot vfat defaults,noatime 0 2
# /dev/sda2 none  swap sw               0 0
# /dev/sda3 /     ext4 defaults,noatime 0 1
# /dev/sda4 /home ext4 defaults,noatime 0 2

## Configurar zona horaria
ln -sf /usr/share/zoneinfo/Europe/Madrid /etc/localtime

## Modificar make.conf
nano -w /etc/portage/make.conf
# COMMON_FLAGS=”-march=native -O2 -pipe”
# CFLAGS=”${COMMON_FLAGS}”
# CXXFLAGS=”${COMMON_FLAGS}”
# FCFLAGS=”${COMMON_FLAGS}”
# FFLAGS=”${COMMON_FLAGS}”

# MAKEOPTS=”-j5”
# FEATURES=”${FEATURES} ccache”
# CACHE_DIR=”/gentoo/ccache”

# #CPU_FLAGS_X86="mmx sse sse2"
# USE=”-bindist icu python emu mmx sse sse2”
# INPUT_DEVICES=”evdev keyboard mouse”
# VIDEO_CARDS=”intel i965”

# LANG=”es_ES.UTF-8”
# LINGUAS=”es”
# L10N=”es es-ES”

#GRUB_PLATFORMS=”efi-64”

## Cambiar el teclado
nano -w /etc/conf.d/keymaps
# keymap=“es”
# windowkeys=“YES”
#nano -w /etc/locale.gen
# es_ES ISO-8859-1
# es_ES.UTF-8 UTF-8
#locale-gen
#eselect locale list

## Cambiar el nombre del host
nano -w /etc/conf.d/hostname
# hostname=”nombredelhost”

## Actualizar el sistema
ego sync #(ver el paso de sincronización, pero ejecutarlo de nuevo si pasó bastante tiempo desde aquella vez, y siempre
# antes del siguiente comando).
emerge -avuDN @world
# emerge -avuND @world --with-bdeps=y (ejecutar el comando con esa última variable cada cierto tiempo)
# perl-cleaner --all (solo cuando se actualiza a una nueva versión de perl)

## Instalar con emerge
emerge -av app-portage/cpuid2cpuflags
# emerge -av1 packagename (la variable -1 ejecutarla sólo si no se desea añadir el paquete a @world, como el caso de alguna
# dependencia).

## Desinstalar con emerge
emerge -aC packagename
emerge -a --depclean #(eliminar paquetes huérfanos).

#### Parte 4ª: Kernel ####

emerge -s debian-sources-lts #(sólo para ver la versión preinstalada).
emerge -av sys-kernel/linux-firmware

#### Parte 5ª: internet ####

emerge -av networkmanager
rc-update add NetworkManager default
rc
nmtui dev wifi list
nmtui #(¡¡¡IMPORTANTE!!! Ejecutar este comando tras salir del entorno de instalación e iniciar el sistema instalado.)

#### Parte 6ª: configuración variada ####

## Contraseña
passwd

## TTY
nano -w /etc/inittab
# c1:12345:respawn:/sbin/agetty 38400 tty1 linux --noclear

## Instalar varios programas
emerge -av flaggie sudo dosfstools ¿wpa_supplicant? wireless-tools

#¿touch /etc/ wpa_supplicant/wpa_supplicant.conf

#### Parte 7ª: Gestor de arranque ####

emerge -av grub
nano -w /etc/boot.conf

boot {
	generate grub
	default "Funtoo Linux" 
	timeout 3 
}

"Funtoo Linux" {
	kernel bzImage[-v]
}

"Funtoo Linux genkernel" {
	kernel kernel[-v]
	initrd initramfs[-v]
	params += real_root=auto rootfstype=auto
}

mount -o remount,rw /sys/firmware/efi/efivars
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id="Funtoo Linux [GRUB]" --recheck /dev/sda
ego boot update #(cada vez que se modifica el archivo anterior, o cada vez que se actualiza el kernel o se instalan nuevos).

## Opcional
emerge -qav app-shells/zsh app-shells/zsh-completions x11-wm/awesome x11-terms/rxvt-unicode chsh -s /bin/zsh

#### Parte 6ª: configuración post-instalación inicial ####

# Wi-Fi

nmtui

## Añadir usuario

useradd -m -G users,wheel,audio,games,usb,video,plugdev -s /bin/zsh (/bin/bash) usuario
passwd usuario
