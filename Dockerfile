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

# Now cd into the working folder and setup and install the API
# module. Note we do this on the same RUN comma
WORKDIR kinetic-py
RUN git submodule update --init
RUN python setup.py develop

# Now cd back to the top-level folder and grab the
# sbates130272/kinetic repo which contains a codebase for working with
# the kinetic HDDs.
WORKDIR ..
git clone https://github.com/sbates130272/kinetic.git
WORKDIR kinetic

