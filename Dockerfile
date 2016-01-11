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
  ncurses-dev \
  patchutils \
  squashfs-tools \
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

# Run a simple test to make sure at least spike, pk and the Newlib
# compiler are setup correctly.
RUN mkdir -p $RISCV/test
WORKDIR $RISCV/test
RUN echo '#include <stdio.h>\n int main(void) { printf("Hello \
  world!\\n"); return 0; }' > hello.c && \
  riscv64-unknown-elf-gcc -o hello hello.c && spike pk hello

# Now build the glibc toolchain as well. This complements the newlib
# tool chain we added above. When done we clean up the intermediate
# folders as this saves a ton (>6G of space). 
WORKDIR $RISCV/riscv-tools/riscv-gnu-toolchain
RUN ./configure --prefix=$RISCV && make linux && rm -rf \
  build-binutils-linux \
  build-gcc-linux-stage1 \
  build-gcc-linux-stage2 \
  build-glibc-linux-headers \
  build-glibc-linux64 \
  src \
  build/src \
  stamps

# Now build the linux kernel image. Note that the RISC-V Linux GitHub
# site has a -j in the make command and that seems to break things on
# a VM so here we use NUMJOBS to set the parallelism. We also get the
# .config from my GitHub site since we have enabled more than the
# default (squashfs for example).
WORKDIR $RISCV/linux-3.14.41
RUN curl -L https://raw.githubusercontent.com/sbates130272/docker-riscv/\
master/.config-linux-3.14.41 > .config && make ARCH=riscv -j $NUMJOBS \
  vmlinux  

# Now create a mnt subfolder that we will squashfs into our root
# filesystem for the linux environment. 
WORKDIR $RISCV
RUN mkdir mnt && cd mnt && mkdir -p bin etc dev lib proc \
  sbin sys tmp usr usr/bin usr/lib usr/sbin &&  curl -L \
  http://riscv.org/install-guides/linux-inittab > etc/inittab
  
# Now install busybox as we will use that in our linux based
# environment. We grab the .config for this from our GitHub site
# because we want more stuff in it than the default and we want to
# make sure it installs to the right place (using some sed magic).
WORKDIR $RISCV
RUN curl -L http://busybox.net/downloads/busybox-1.21.1.tar.bz2 | \
  tar -xj && cd busybox-1.21.1 && curl -L https://raw.githubusercontent\
.com/sbates130272/docker-riscv/master/.config-busybox-1.21.1 > \
  .config && make -j $NUMJOBS install

# Create the root filesystem using squashfs.
WORKDIR $RISCV
RUN mksquashfs mnt root.bin.sqsh && cd .. && \
  rm -rf mnt

# Set the WORKDIR to be in the $RISCV folder and we are done!
WORKDIR $RISCV

# Now you can launch the container and run a command like:
#
# spike -m128 -p1 +disk=root.bin.sqsh bbl linux-3.14.41/vmlinux
#
