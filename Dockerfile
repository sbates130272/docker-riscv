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
ENV FREEDOMCHECKOUT eidetic
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

# Copy in the debian rootfs and make the nvme image files needed to
# run qemu-debian

WORKDIR $RV/freedom-u-sdk
ENV PATH="${RV}/freedom-u-sdk/work/riscv-qemu/prefix/bin:${PATH}"
RUN make -j $NUMJOBS nvme0.qcow2 nvme1.qcow2
COPY multistrap-rootfs.img debian-sid-riscv64-rootfs.img

# We should now be ready to run something like:
#
# docker run <tag> make qemu-debian
#
# Which should launch a dockerized version of QEMU's riscv64 virt
# machine with PCIe support on a p2pdma enabled kernel and with some
# NVMe drives in the system. Enjoy!
