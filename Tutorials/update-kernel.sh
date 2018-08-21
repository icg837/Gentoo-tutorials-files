## Estos pasos deben hacerse siempre como administrador, no como usuario. De hacerse tras actualizar el paquete gentoo-sources

#### Parte 1ª: Instalación y habilitación del nuevo kernel ####

eselect kernel list
# [1] linux-x.x.x1-gentoo *
# [2] linux-x.x.x2-gentoo

## Paso 1º: de manera automática

eselect kernel set 2

## Paso 2º: de manera manual
rm linux ## Estando en el directorio /usr/src
ln -s linux-x.x.x2-gentoo/ linux
ls ## Para comprobar que vuelve a haber un enlace simbólico tras borrarlo anteriormente

## En cualquier caso, al ejecutar eselect kernel list, debería aparecer así:
# [1] linux-x.x.x1-gentoo
# [2] linux-x.x.x2-gentoo *

##

cd /usr/src/linux
cp ../linux-x.x.x1-gentoo/.config .oldconfig

## Paso 1º: genkernel

module-rebuild populate
genkernel --olconfig --menuconfig all
module-rebuild rebuild

## Paso 2º: manual

make olddefconfig
make menuconfig ## Opcional, sólo en caso de activar opciones no activadas en el núcleo anterior
make -j5 ## Al igual que en /etc/portage/make.conf, se debe poner -j seguido del número de núcleos del ordenador más 1
make modules_prepare
make modules
make modules_install
make install

## En este punto, copiar y/o actualizar las líneas de tipo modules_x_x_x_gentoo="vboxdrv vboxnetflt vboxnetadp vboxvideo" a
## /etc/conf.d/modules

##

grub2-mkconfig -o /boot/grub/grub.cfg ## O bien, con un editor de texto, editar /boot/grub/grub.cfg y cambiar el kernel
## en base a la salida del comando ls /boot
reboot
