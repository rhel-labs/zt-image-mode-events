#!/bin/sh
echo "Validating module-02: First bootc image build" >> /tmp/progress.log


source /etc/profile.d/lab.sh


# Check that bootc-base directory exists
if [ ! -d ~/bootc-base ]; then
    echo "FAIL: ~/bootc-base directory should exist" >> /tmp/progress.log
    echo "HINT: Create directory with: mkdir -p ~/bootc-base" >> /tmp/progress.log
    exit 1
fi

cd ~/bootc-base || exit 1

# Check that directory structure exists
if [ ! -d etc/sudoers.d ] || [ ! -d etc/ostree ] || [ ! -d usr/lib/bootc/kargs.d ]; then
    echo "FAIL: Required directory structure missing in bootc-base" >> /tmp/progress.log
    echo "HINT: Create directories: etc/sudoers.d, etc/ostree, usr/lib/bootc/kargs.d" >> /tmp/progress.log
    exit 1
fi

# Check that Containerfile exists
if [ ! -f Containerfile ]; then
    echo "FAIL: Containerfile should exist in ~/bootc-base" >> /tmp/progress.log
    echo "HINT: Create Containerfile with bootc image definition" >> /tmp/progress.log
    exit 1
fi

# Check that Containerfile has required content
if ! grep -q "FROM registry.redhat.io/rhel10/rhel-bootc" Containerfile; then
    echo "FAIL: Containerfile should use rhel-bootc base image" >> /tmp/progress.log
    exit 1
fi

if ! grep -q "pcp-zeroconf" Containerfile; then
    echo "FAIL: Containerfile should install pcp-zeroconf and other admin tools" >> /tmp/progress.log
    exit 1
fi

if ! grep -q "epel-release" Containerfile; then
    echo "FAIL: Containerfile should install EPEL repository" >> /tmp/progress.log
    exit 1
fi

if ! grep -q "COPY etc/ /etc" Containerfile; then
    echo "FAIL: Containerfile should copy etc/ directory" >> /tmp/progress.log
    exit 1
fi

if ! grep -q "bootc-fetch-apply-updates.timer" Containerfile; then
    echo "FAIL: Containerfile should mask bootc-fetch-apply-updates.timer" >> /tmp/progress.log
    exit 1
fi

# Check that auth.json exists in the right place
if [ ! -f etc/ostree/auth.json ]; then
    echo "FAIL: Registry auth file should exist at etc/ostree/auth.json" >> /tmp/progress.log
    echo "HINT: Create with: podman login --authfile=auth.json then move to etc/ostree/" >> /tmp/progress.log
    exit 1
fi

# Check that the base image exists locally
if ! podman image exists registry-${GUID}.${DOMAIN}/base; then
    echo "FAIL: Base image not found in local podman storage" >> /tmp/progress.log
    echo "HINT: Build with: podman build --file Containerfile --tag registry-${GUID}.${DOMAIN}/base" >> /tmp/progress.log
    exit 1
fi

# Check that the image was pushed to registry
if ! skopeo inspect docker://registry-${GUID}.${DOMAIN}/base > /dev/null 2>&1; then
    echo "FAIL: Base image not found in registry" >> /tmp/progress.log
    echo "HINT: Push with: podman push registry-${GUID}.${DOMAIN}/base" >> /tmp/progress.log
    exit 1
fi

echo "PASS: Module-02 validation complete - first bootc image built and pushed" >> /tmp/progress.log
exit 0
