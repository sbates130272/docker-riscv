#!/bin/bash
#
# A small script to generate the root filesystem for the
# sbates130272/riscv Dockerfile since the mount command is not allowed
# inside a Dockerfile [1].

dd if=/dev/zero of=root.bin bs=1M count=64 && \
  mkfs.ext2 -F root.bin && mkdir mnt && mount -o loop \
  root.bin mnt && cd mnt && mkdir -p bin etc dev lib proc \
  sbin sys tmp usr usr/bin usr/lib usr/sbin && \
  cp ../busybox bin && curl -L \
  http://riscv.org/install-guides/linux-inittab > \
  etc/inittab && cd sbin && ln -s ../bin/busybox init && \
  cd ../.. && umount mnt && rm -rf mnt && tar -cjf \
  root.bin.tar.bz2 root.bin
