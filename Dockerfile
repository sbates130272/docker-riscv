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
  patchutils \
  texinfo

# Make a working folder and set the necessary environment variables.
ENV RISCV /opt/riscv
ENV NUMJOBS 1
RUN mkdir -p $RISCV

# Add the GNU utils bin folder to the path.
ENV PATH $RISCV/bin:$PATH

# Obtain the RISCV-tools repo which consists of a number of submodules
# so make sure we get those too.
WORKDIR $RISCV
RUN git clone https://github.com/riscv/riscv-tools.git && \
  cd riscv-tools && git submodule update --init --recursive

# Obtain the RISC-V branch of the Linux kernel
WORKDIR $RISCV
RUN curl -L https://www.kernel.org/pub/linux/kernel/v3.x/linux-3.14.41.tar.xz | \
  tar -xJ && cd linux-3.14.41 && git init && \
  git remote add origin https://github.com/riscv/riscv-linux.git && \
  git fetch && git checkout -f -t origin/master

# Before building the GNU tools make sure the headers there are up-to
# date.
WORKDIR $RISCV/linux-3.14.41
RUN make ARCH=riscv headers_check && \
  make ARCH=riscv INSTALL_HDR_PATH=\
  $RISCV/riscv-tools/riscv-gnu-toolchain/linux-headers headers_install

# Now build the toolchain for RISCV. Set -j 1 to avoid issues on VMs.
WORKDIR $RISCV/riscv-tools
RUN sed -i 's/JOBS=16/JOBS=$NUMJOBS/' build.common && \
  ./build.sh

# Run a simple test to make sure at least spike, pk and the newlib
# compiler are setup correctly.
RUN mkdir -p $RISCV/test
WORKDIR $RISCV/test
RUN echo '#include <stdio.h>\n int main(void) { printf("Hello \
  world!\\n"); return 0; }' > hello.c && \
  riscv64-unknown-elf-gcc -o hello hello.c && spike pk hello

# Set the WORKDIR to be in the $RISCV folder and we are done!
WORKDIR $RISCV
