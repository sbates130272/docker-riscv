## RISC-V Dockerfile (Development Branch)

This repository contains a **Dockerfile** of
[sbates130272/docker-riscv](https://github.com/sbates130272/docker-riscv)
for [Docker](https://www.docker.com/)'s
[Hub](https://registry.hub.docker.com/u/sbates130272/riscv) published 
to the public [Docker Hub Registry](https://registry.hub.docker.com/).

### Information

This container includes a number of tools and dependencies needed to
develop for the RISC-V open-source CPU. Many of these tools can be
located at 

https://github.com/riscv

and include an ISA simulator (Spike), a GCC toolchain for the RISC-V
ISA, the Linux Kernel for this kernel and other tools.

### Getting Started

The best way to get started is to download the image for this
container directly from Doc Hub and then run the container and play
inside it. Here are the steps for that.

   1. Install docker on your client.
   2. docker pull sbates130272/riscv
   3. docker run -it sbates130272/riscv
   4. cd into one of the sub-folders of /opt/riscv and play. For
   example in the /opt/riscv folder you can run
   ```
   spike -m128 -p1 +disk=root.bin.sqsh bbl linux-4.1.y/vmlinux
   ```
   to kick off the spike ISA simulator on a root filesystem awith
   busybox nd the 3.14.41 version of the Linux kernel.

   5. You can attach external directories for access inside the docker
   container:

```
   docker run -it -w $PWD -v $PWD:$PWD sbates130272/riscv
```

### Notes

   1. Note this Dockerfile does not run through the automated build
   process because it exceeds the two hour build limit.
