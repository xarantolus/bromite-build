FROM ubuntu:20.04

RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y git make wget curl lsb-release gcc python3 pkg-config build-essential sudo gperf

# Set the working directory to /build
WORKDIR /build

# Make sure git trusts all git repos
RUN git config --global --add safe.directory *

ENTRYPOINT ["/bin/bash", "/build/build.sh"]
