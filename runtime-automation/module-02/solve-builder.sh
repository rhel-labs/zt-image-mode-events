#!/bin/sh
echo "Solving module-02: Building first bootc image" >> /tmp/progress.log

# Create the bootc-base directory structure
mkdir -p ~/bootc-base/etc/sudoers.d
mkdir -p ~/bootc-base/etc/ostree
mkdir -p ~/bootc-base/usr/lib/bootc/kargs.d
cd ~/bootc-base || exit 1

# Create the Containerfile
cat > Containerfile << 'EOF'
FROM registry.redhat.io/rhel10/rhel-bootc:10.1

# Set up some variables and labels to ID images in our environments
LABEL org.opencontainers.image.authors="sysadmins@example.com"
# RHEL version inherited from bootc base as redhat.version-id and release
LABEL vendor="Example Corp"

RUN dnf -y install pcp-zeroconf \
        rsyslog \
        tmux \
        tuned

RUN dnf install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-10.noarch.rpm

RUN sed -e '/^metalink=https:\/\/mirrors.fedoraproject.org\/metalink/ s/^/#/' \
    -e '/^#baseurl=http:/ s/http/https/' \
    -e '/^#baseurl=https:\/\/download.example/ s/^#//' \
    -e '/^baseurl=https:\/\/download.example/ s_https://download.example_https://dl.fedoraproject.org_' \
    -i /etc/yum.repos.d/epel*.repo

RUN dnf -y install btop iftop

COPY etc/ /etc
COPY usr/ /usr

RUN systemctl mask bootc-fetch-apply-updates.timer
EOF

# Login to registry and create auth file
podman login -u core -p redhat registry-${GUID}.${DOMAIN} --authfile=auth.json

# Move auth file to etc structure
mv auth.json etc/ostree/auth.json

# Build the image
podman build --file Containerfile --tag registry-${GUID}.${DOMAIN}/base 2>&1 | tee /tmp/module-02-build.log

# Push to registry
podman push registry-${GUID}.${DOMAIN}/base

echo "Module-02 solve complete" >> /tmp/progress.log
