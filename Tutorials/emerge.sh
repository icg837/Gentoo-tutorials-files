## The following USE changes are necessary to proceed:
## # required by foo-foo/foo-x.x.x::gentoo
## # required by foo-foo/foo (argument)
## >=foo2-foo2/foo2.x.x.x USEflag
nano -w /etc/portage/package.use/package.use
# Copiar en ese archivo la línea donde se especifica el USE flag a añadir

## The following keyword changes are necessary to proceed:
## # required by foo-foo/foo (argument)
## =foo-foo/foo-x.x.x ~amd64
emerge --autounmask-write foo-foo/foo
dispatch-conf
# Pulsar la tecla "u" para use-new y salir con la tecla "q"
emerge -av foo-foo/foo
