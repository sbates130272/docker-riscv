#
# RISC-V Dockerfile
#
# https://github.com/sbates130272/docker-riscv
#
# This Dockerfile creates a container full of lots of useful tools for
# RISC-V development. See associated README.md for more
# information. This Dockerfile is mostly based on the instructions
# found at https://github.com/riscv/riscv-tools.

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
  curl \
  emacs24-nox \
  flex \
  gawk \
  git \
  gperf \
  libmpc-dev \
  libmpfr-dev \
  libgmp-dev \
  libtool \
  ncurses-dev \
  patchutils \
  squashfs-tools \
  texinfo

# Make a working folder and set the necessary environment variables.
ENV RISCV /opt/riscv
ENV NUMJOBS 16
ENV P2P https://github.com/sbates130272/linux-p2pmem.git
RUN mkdir -p $RISCV

# Add the GNU utils bin folder to the path.
ENV PATH $RISCV/bin:$PATH

# Obtain the RISCV-tools repo which consists of a number of submodules
# so make sure we get those too.
WORKDIR $RISCV
RUN git clone https://github.com/sifive/freedom-u-sdk.git

WORKDIR $RISCV/freedom-u-sdk
RUN sed -i -E "s|(url = ).*linux\.git|\1"$P2P"|g" .gitmodules
RUN git submodule update --init --recursive

WORKDIR $RISCV/freedom-u-sdk/linux
RUN git checkout riscv-p2p-sifive

WORKDIR $RISCV/freedom-u-sdk
RUN make -j $NUMJOBS

