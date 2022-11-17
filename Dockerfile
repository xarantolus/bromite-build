# Use ubuntu 20.04 as base image
FROM ubuntu:20.04

RUN apt-get update && apt-get install -y git make wget curl

# Set the working directory to /build
WORKDIR /build

# Make sure git trusts all git repos
RUN git config --global --add safe.directory *

ENTRYPOINT ["/bin/bash", "/build/build.sh"]
