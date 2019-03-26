# Referencia: https://www.funtoo.org/Install/Introduction
###########################################################
#### Parte 1ª: iniciar con Gentoo MinimalCD ####

# La configuración de la red se hace así:
wpa_passphrase “MOVISTAR_1CAA” > /etc/wpa.conf (y escribir la contraseña)
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
