#
# RISC-V Dockerfile
#
# https://github.com/sbates130272/docker-riscv
#

# Pull base image (use Wily for now).
FROM dockerfile/ubuntu:15.10

# Set the maintainer
MAINTAINER Stephen Bates (sbates130272) <sbates@raithlin.com>

# Install some base tools that we will need to get the risc-v
# toolchain working.
RUN apt-get update && apt-get install -y \
  git \
  emacs24-nox
