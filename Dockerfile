#
# RISC-V freedom-u-sdk Dockerfile
#
# https://github.com/sbates130272/docker-riscv
#
# This Dockerfile creates a container full of lots of useful tools for
# RISC-V development on the freedom-u board from SiFive. See
# associated README.md for more information.

FROM ubuntu:16.04

# Set the maintainer
MAINTAINER Andrew Maier (amaier17) <andrew.maier@eideticom.com>

# Install some base tools that we will need to get the risc-v
# toolchain working.
RUN apt-get update && apt-get install -y \
	autoconf \
	automake \
	autotools-dev \
	bc \
	bison \
	build-essential \
	cpio \
	curl \
	debootstrap \
	emacs24-nox \
	flex \
	gawk \
	git \
	gperf \
	libglib2.0-dev \
	libgmp-dev \
	libmpc-dev \
	libmpfr-dev \
	libpixman-1-dev \
	libtool \
	man \
	ncurses-dev \
	patchutils \
	pkg-config \
	python \
	squashfs-tools \
	sudo \
	texinfo \
	tmux \
	tree \
	wget \
	unzip \
	vim \
	zlib1g-dev

# Make a working folder and set the necessary environment variables.
ENV RV /opt/riscv
ENV NUMJOBS 16
ENV FREEDOMCHECKOUT dev/stephen
RUN mkdir -p $RV

# Add the GNU utils bin folder to the path.
ENV PATH $RV/bin:$PATH

# Obtain the RV-tools repo which consists of a number of submodules
# so make sure we get those too.
WORKDIR $RV
RUN git clone https://github.com/Eideticom/freedom-u-sdk.git

WORKDIR $RV/freedom-u-sdk
RUN git checkout $FREEDOMCHECKOUT
RUN git submodule update --recursive --init

WORKDIR $RV/freedom-u-sdk
RUN make -j $NUMJOBS
RUN make -j $NUMJOBS prep-qemu

# Start the rootfs generation in rootfs-debian. We can now use
# debootstrap for this. We use --foreign since we are assuming you are
# not runing this docker build on a riscv64 SoC (but one day that
# assumption may no longer hold ;-)).

WORKDIR $RV/freedom-u-sdk
RUN debootstrap --arch riscv64 --foreign sid rootfs-debian \
  http://deb.debian.org/debian-ports/
RUN cp work/riscv-qemu/prefix/bin/qemu-riscv64 \
  /root/qemu-riscv64-static

# In order to complete the rootfs generation we need to interact with the
# host system outside the container. Refer for the README associated
# with this Dockerfile repo for information on that. That step outside
# the container should result in a bootable Debian Sid rootfs image
# file that will work in both QEMU and on real hardware.

WORKDIR $RV/freedom-u-sdk
RUN chroot rootfs-debian /debootstrap/debootstrap --second-stage
