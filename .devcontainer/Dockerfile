# Reuse the existing build container, but add a few extras
FROM ghcr.io/xarantolus/bromite-build:main

# Put my utility scripts in $PATH
RUN git clone https://github.com/xarantolus/scripts /var/scripts && cd /var/scripts && chmod +x *
ENV PATH="${PATH}:/var/scripts"

#
# Now make sure docker commands inside the container use the hosts docker engine.
# See https://github.com/microsoft/vscode-dev-containers/tree/main/containers/docker-from-docker
#

# Install Docker CE CLI
RUN apt-get update \
    && apt-get install -y apt-transport-https ca-certificates curl gnupg2 lsb-release \
    && curl -fsSL https://download.docker.com/linux/$(lsb_release -is | tr '[:upper:]' '[:lower:]')/gpg | apt-key add - 2>/dev/null \
    && echo "deb [arch=amd64] https://download.docker.com/linux/$(lsb_release -is | tr '[:upper:]' '[:lower:]') $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list \
    && apt-get update \
    && apt-get install -y docker-ce-cli

# Install Docker Compose
RUN LATEST_COMPOSE_VERSION=$(curl -sSL "https://api.github.com/repos/docker/compose/releases/latest" | grep -o -P '(?<="tag_name": ").+(?=")') \
    && curl -sSL "https://github.com/docker/compose/releases/download/${LATEST_COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose \
    && chmod +x /usr/local/bin/docker-compose

#
# Some custom stuff
#

# Install other utilities
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y ripgrep fdupes

# enable terminal colors
RUN sed -i 's/#force_color_prompt=yes/force_color_prompt=yes/' /root/.bashrc
