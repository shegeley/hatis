# base stubs
guix-time-machine = guix time-machine -C ./channels-lock.scm
shell-default-args = \
	guile-next \
	guile-ares-rs \
	-f guix/packages/wlroots.scm \
	-f guix/packages/guile-wayland.scm \
	-f guix.scm \
	-L guix \
	--rebuild-cache
nrepl-exp = "((@ (ares server) run-nrepl-server))"

# hatis
guile = ${shell-default-args} -- guile -L ./src -L /data/abcdw/work/abcdw/guile-ares-rs/src/guile

nrepl:
	guix shell ${guile} -e ${nrepl-exp}

repl:
	guix shell ${guile}

tm/nrepl:
	${guix-time-machine} -- shell ${guile} -e ${nrepl-exp}

tm/repl:
	${guix-time-machine} -- shell ${guile}

build:
	guix build -f guix.scm -L guix

# guile-wayland
dev/guile-wayland/nrepl:
	guix shell \
	${guile} \
	-e ${nrepl-exp}

dev-sway:
	sway -c files/sway/config
