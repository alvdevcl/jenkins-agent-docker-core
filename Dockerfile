ARG JENKINS_REMOTING_TAG=latest

FROM jenkins/inbound-agent:$JENKINS_REMOTING_TAG
LABEL maintainer="Dwolla Dev <dev+jenkins-agent-core@dwolla.com>"
LABEL org.label-schema.vcs-url="https://github.com/Dwolla/jenkins-agent-docker-core"
ENV JENKINS_HOME=/home/jenkins

COPY build/install-esh.sh /tmp/build/install-esh.sh

WORKDIR ${JENKINS_HOME}

USER root

# Update package list
RUN set -ex && apt-get update

# Install necessary packages
RUN apt-get install -y \
        apt-transport-https \
        bash \
        bc \
        ca-certificates \
        curl \
        expect \
        git \
        gpg \
        jq \
        make \
        python3 \
        python3-pip \
        python3-venv \
        shellcheck \
        zip

# Upgrade pip and install additional Python packages
RUN pip3 install --upgrade awscli virtualenv

# Create symbolic link for python3
RUN ln -s /usr/bin/python3 /usr/bin/python

# Ensure the script is executable and run it
RUN chmod +x /tmp/build/install-esh.sh && /tmp/build/install-esh.sh v0.3.1

# Clean up
RUN rm -rf /tmp/build && mkdir -p /usr/share/man/man1/ && touch /usr/share/man/man1/sh.distrib.1.gz

# Change /bin/sh to use bash
RUN echo "dash dash/sh boolean false" | debconf-set-selections && \
    DEBIAN_FRONTEND=noninteractive dpkg-reconfigure dash

USER jenkins

# Configure git
RUN git config --global user.email "dev+jenkins@dwolla.com" && \
    git config --global user.name "Jenkins Build Agent" && \
    git config --global init.defaultBranch main

ENTRYPOINT ["jenkins-agent"]
