#
# RISC-V Dockerfile
#
# https://github.com/sbates130272/docker-riscv
#

# Pull base image (use Wily for now).
FROM ubuntu:15.10

# Set the maintainer
MAINTAINER Stephen Bates (sbates130272) <sbates@raithlin.com>

# Install some base tools that we will need to get the risc-v
# toolchain working.
RUN apt-get update && apt-get install -y \
  autoconf \
  automake \
  autotools-dev \
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
  patchutils \
  texinfo

# Make a working folder and set the necessary environment variables.
RUN mkdir -p /opt/riscv/git
ENV RISCV /opt/riscv

# Obtain the RISC-V branch of the Linux kernel
WORKDIR /opt/riscv/git
RUN curl -L https://www.kernel.org/pub/linux/kernel/v3.x/linux-3.14.41.tar.xz | \
  tar -xJ && cd linux-3.14.41 && git init && \
  git remote add origin https://github.com/riscv/riscv-linux.git && \
  git fetch && git checkout -f -t origin/master

# Fetch the GNU toolchain source
WORKDIR /opt/riscv/git
RUN git clone https://github.com/riscv/riscv-gnu-toolchain.git

# Before building the GNU tools make sure the headers there are up-to
# date.
WORKDIR /opt/riscv/git/linux-3.14.41
RUN make ARCH=riscv headers_check && \
  make ARCH=riscv INSTALL_HDR_PATH=\
  $RISCV/git/riscv-gnu-toolchain/linux-headers headers_install

# Now build the GNU toolchain for RISCV. We enable support for both 32
# and 64 bit RISC-V processors.
WORKDIR /opt/riscv/git/riscv-gnu-toolchain
RUN ./configure --prefix=/opt/riscv --enable-multilib && \
  make linux

# Now build the linux kernel image
WORKDIR /opt/riscv/git/linux-3.14.41
RUN make ARCH=riscv defconfig && make ARCH=riscv -j vmlinux

# Install Spike, the ISA simulator
WORKDIR /opt/riscv/git
RUN git clone https://github.com/riscv/riscv-isa-sim.git && \
  cd riscv-isa-sim && mkdir build && cd build && \
  ../configure --prefix=$RISCV --with-fesvr=$RISCV && \
  make && make install

# Set the entrypoint in the $RISCV folder.
ENTRYPOINT $RISCV
