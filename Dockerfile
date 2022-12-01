FROM ubuntu:20.04

# Set the working directory to /build
WORKDIR /build

ENV PATH=$PATH:/build/depot_tools

RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y git make wget curl lsb-release gcc python3 pkg-config build-essential sudo gperf ninja-build libc6-dev-i386

# Make sure git trusts all git repos
RUN git config --global --add safe.directory *

# Install chromium dependencies into container to speed up actual builds, the script will be run again during build but should be much faster
COPY scripts/install_online_deps.sh /tmp/scripts/install_online_deps.sh
RUN chmod +x /tmp/scripts/install_online_deps.sh && /tmp/scripts/install_online_deps.sh

ENTRYPOINT ["/bin/bash", "/build/build.sh"]
