## Dockerfile for SiFive freedom-u-sdk for RISCV CPUs

### Information

This container includes a number of tools and dependencies useful for
developing on for the SiFive freedom-u board and the Microsemi HiFive
expansion card.

Once you get everything in this repo up and running you should have
the following:

* A toolchain.
* A Linux kernel and bbl.
* A buildroot based rootfs.
* A Debian Sid (aka Unstable) based rootfs.
* A QEMU model of the virt RISCV machine with support for PCIe
* A Docker image containing all of the above.

### Getting Started

1. Generate a static qemu-riscv64-static user emaulation binary. On
some systems this is as simple as apt-get install qemu-static. In
other cases this is more complicated. Note that the docker image will
generate this for its own purposes so if you are clever you can copy
out that one. You also need to ensure binfmt is updated to support the
detection of RISCV executables.

2. Generate the bare-bones Debian sid root filesystem (rootfs) for
RISC-V. You can do that using something like:
	```
	sudo ROOTFS=multistrap-rootfs INTERP=/opt/qemu/bin/qemu-riscv64-static ./create-rootfs
	```
	Review the arguments section of create-rootfs to see how to alter the
hostname and root password. In this case a 8GB raw qemu image file
will be created called multistrap-rootfs.img.

3. Build the docker image using something like:
	```
	docker build .
	```
Do note this will take a loooong time (2-3 hours on some systems).

4. Spin up a container based on the resultant image. This should put
you in a working folder at the top level of the Eideticom fork of
freedom-u-sdk. You should have access to all the tools, kernel source
and buildroot code. You can also do something like:
	```
	make qemu
	```
	to run a buildroot based qemu. Or:
	```
	make qemu-debian
	```
	to run the Debian sid based rootfs which also includes a couple of
virtual NVM Express (NVMe SSDs). Or you can use docker run to run the
qemu from outside the container using:
	```
	docker run <tag> make qemu-debian
	```

### Updating the Debian Sid RootFS

Note that the Debian RootFS is generated outside the container and
copied in. This allows you to update the external image file and
docker will pull in the updated image file the next time the container
is built. Of course any changes to the image file inside the container
will be ephemeral. Another option (and possible pull request) would be
to add an option to mount through the container to point to the host
version of the image file.

### Issues

1. Currently there are some issues with debootstrap for RISCV
Sid. Hence we use the more flexible multistrap.
1. The Sid git package has a issue (broken dependency on git-man). So
instead we copy in a hacked fix (git_sbates.deb) in the /root
folder. Run:
```
dpkg -i /root/git_bates.deb
```
to install git. Hopefully this will be fixed soon in Sid and we can
remove this step for people who want git.

### Notes

1. Note this Dockerfile does not run through the automated build
process on Docker Hub because it exceeds the two hour build limit. If
someone is interested in hosting this and paying for it them please
let us know via an issues ticket on the GitHub repo.

Stephen Bates <sbates@raithlin.com>
Andrew Maier <andrew.maier@eideticom.com>