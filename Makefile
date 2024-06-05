# base stubs
guix-time-machine = guix time-machine -C ./channels-lock.scm
shell-default-args = --development --rebuild-cache # cache might cause errors
nrepl-exp = "((@ (nrepl server) run-nrepl-server) \#:port 7888)" # hashtag has to be escaped even inside string or it will count as comment

# hatis
guile = -- shell \
	guile-next \
	guile-ares-rs \
	-f guix/packages/wlroots.scm \
	-f guix/packages/guile-wayland.scm \
	-f guix.scm \
	-L guix \
	${shell-default-args} -- guile

nrepl:
	${guix-time-machine} ${guile} -e ${nrepl-exp}

repl:
	${guix-time-machine} ${guile}

build:
	guix build -f guix.scm -L guix

# guile-wayland
dev/guile-wayland/nrepl:
	guix shell \
	guile-next \
	guile-ares-rs \
	-L guix \
	-f guix/packages/wlroots.scm \
	-f guix/packages/guile-wayland.scm \
	${shell-default-args} \
	-- guile \
	-e ${nrepl-exp}
