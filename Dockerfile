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

# Now build the glibc toolchain as well. This complements the newlib
# tool chain we added above.
WORKDIR $RISCV/riscv-tools/riscv-gnu-toolchain
RUN ./configure --prefix=$RISCV && make linux

# Now build the linux kernel image. Note that the RISCV Linux GitHub
# site has a -j in the make command and that seems to break things on
# a VM.
WORKDIR $RISCV/linux-3.14.41
RUN make ARCH=riscv defconfig && make ARCH=riscv -j $NUMJOBS vmlinux

# Now install busybox as we will use that in our linux based
# environment.
WORKDIR $RISCV
RUN curl -L http://busybox.net/downloads/busybox-1.21.1.tar.bz2 | \
  tar -xj && cd busybox-1.21.1 && \
  curl -L http://riscv.org/install-guides/busybox-riscv.config > \
  .config && make -j $NUMJOBS

# Create a root filesystem with the necessary files in it to boot up
# the Linux environment and jump into busybox. Note that since we
# can't run mount inside a docker container we, for now, download this
# root.bin file from a hosted website (GitHub in this case).
WORKDIR $RISCV/linux-3.14.41
#RUN dd if=/dev/zero of=root.bin bs=1M count=64 && \
#  mkfs.ext2 -F root.bin && mkdir mnt && mount -o loop \
#  root.bin mnt && cd mnt && mkdir -p bin etc dev lib proc \
#  sbin sys tmp usr usr/bin usr/lib usr/sbin && \
#  cp $RISCV/busybox-1.21.1/busybox bin && \
#  curl -L http://riscv.org/install-guides/linux-inittab > \
#  etc/inittab && ln -s ./bin/busybox sbin/init && cd .. && \
#  umount mnt
RUN curl -L http://github.com/sbates130272/riscv/master/blob/root.bin

# Now do a test of booting Linux and using the root filesystem we just
# created.
WORKDIR $RISCV/linux-3.14.41
RUN spike +disk=root.bin bbl vmlinux

# Set the WORKDIR to be in the $RISCV folder and we are done!
WORKDIR $RISCV
