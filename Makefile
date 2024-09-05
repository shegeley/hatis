# base stubs
guix-time-machine = guix time-machine -C ./channels-lock.scm
guile-ares-latest = "(begin (use-modules (guix transformations) (gnu packages guile-xyz)) ((options->transformation '((with-commit . \"guile-ares-rs=959fcb762ca95801072f81d4bd91b7436763f1c6\"))) guile-ares-rs))" # zero-value-conts handling introduced in this commit

shell-default-args = \
	jq \
	guile-next \
	-e ${guile-ares-latest} \
	-f guix/packages/wlroots.scm \
	-f guix/packages/guile-wayland.scm \
	-f guix/packages/wayland-protocols.scm \
	-L guix \
	--no-substitutes #--rebuild-cache

nrepl-exp = "((@ (ares server) run-nrepl-server) \#:port 7888)"

# hatis
guile = ${shell-default-args} -- guile -L ./src

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

sway-nrepl-cmd = "exec foot make nrepl; exec foot"
sway-tm/nrepl-cmd = "exec foot make tm/nrepl; exec foot"

sway+nrepl: # have to create tmpfile for `sway -c`
	$(eval TMP := $(shell mktemp))
	@echo ${sway-nrepl-cmd} >> $(TMP)
	sway -c $(TMP)
	rm -rf $(TMP)

sway+tm/nrepl:
	$(eval TMP := $(shell mktemp))
	@echo ${sway-tm/nrepl-cmd} >> $(TMP)
	sway -c $(TMP)
	rm -rf $(TMP)
