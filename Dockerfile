#
# RISC-V Dockerfile
#
# https://github.com/sbates130272/docker-RV
#
# This Dockerfile creates a container full of lots of useful tools for
# RISC-V development. See associated README.md for more
# information. This Dockerfile is mostly based on the instructions
# found at https://github.com/RV/riscv-tools.

# Pull base image (use Wily for now).
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
	ncurses-dev \
	patchutils \
	pkg-config \
	python \
	squashfs-tools \
	sudo \
	texinfo \
	wget \
	unzip \
	vim \
	zlib1g-dev

# Make a working folder and set the necessary environment variables.
ENV RV /opt/riscv
ENV NUMJOBS 16
ENV P2P https://github.com/sbates130272/linux-p2pmem.git
ENV P2PSHA 7b5137305c0a6afa27fc3a6ad64db131518f6c5a
RUN mkdir -p $RV

# Add the GNU utils bin folder to the path.
ENV PATH $RV/bin:$PATH

# Obtain the RV-tools repo which consists of a number of submodules
# so make sure we get those too.
WORKDIR $RV
RUN git clone https://github.com/amaier17/freedom-u-sdk.git

WORKDIR $RV/freedom-u-sdk
RUN git config --file=.gitmodules submodule.linux.update none
RUN git submodule sync && git submodule update --recursive --init && rm -rf linux
RUN git clone $P2P linux

WORKDIR $RV/freedom-u-sdk/linux
RUN git checkout $P2PSHA

WORKDIR $RV/freedom-u-sdk/conf
COPY config-linux-freedom-u-sdk ./linux_defconfig

WORKDIR $RV/freedom-u-sdk
RUN make -j $NUMJOBS
RUN make -j $NUMJOBS prep-qemu
