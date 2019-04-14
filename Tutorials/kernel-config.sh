## Este archivo solo señalará aquellas configuraciones que se modifiquen para el equipo en cuestión.
## Antes de nada, ejecutar los comandos lspci -v, y lsusb -v, para conocer qué módulos incluir o no.

make menuconfig

Device drivers
    Network device support
        Wireless LAN
            Ralink driver support <M>
                Ralink rt27xx/rt28xx/rt30xx (USB) support <M>
            Broadcom devices
                Broadcom 43xx wireless support (mac80211 stack) <M>
    MMC/SD/SDIO card support <M>
    USB support
        xHCI HCD (USB 3.0) support <*>
Processor type and features
    EFI stub support [*]
        EFI mixee-mode support [*]
