#!/bin/sh
echo "Validating module-08: Standard baseline deployment" >> /tmp/progress.log

source /etc/profile.d/lab.sh

# Check that we're in the right directory
if [ ! -d ~/bootc-version ]; then
    echo "FAIL: bootc-version repository not found"
    exit 1
fi

cd ~/bootc-version || exit 1

# Check that the directory structure exists
if [ ! -d app ]; then
    echo "FAIL: app/ directory should exist"
    echo "HINT: Create directory structure: mkdir -p app etc/systemd/system etc/nginx/conf.d etc/tmpfiles.d"
    exit 1
fi

if [ ! -d etc/systemd/system ]; then
    echo "FAIL: etc/systemd/system/ directory should exist"
    exit 1
fi

if [ ! -d etc/nginx/conf.d ]; then
    echo "FAIL: etc/nginx/conf.d/ directory should exist"
    exit 1
fi

if [ ! -d etc/tmpfiles.d ]; then
    echo "FAIL: etc/tmpfiles.d/ directory should exist"
    exit 1
fi

# Check that files are in the right places
if [ ! -f app/app.py ]; then
    echo "FAIL: app.py should be in app/ directory"
    echo "HINT: Move application files to app/ directory"
    exit 1
fi

if [ ! -f etc/systemd/system/info-app.service ]; then
    echo "FAIL: info-app.service should be in etc/systemd/system/"
    echo "HINT: Move service file to etc/systemd/system/"
    exit 1
fi

if [ ! -f etc/nginx/conf.d/info-app.conf ]; then
    echo "FAIL: info-app.conf should be in etc/nginx/conf.d/"
    echo "HINT: Move nginx config to etc/nginx/conf.d/"
    exit 1
fi

if [ ! -f etc/tmpfiles.d/nginx.conf ]; then
    echo "FAIL: nginx.conf should exist in etc/tmpfiles.d/"
    echo "HINT: Create nginx tmpfiles.d configuration"
    exit 1
fi

# Check that Containerfile uses the baseline image
if ! grep -q "FROM registry-.*\..*\/base" Containerfile; then
    echo "FAIL: Containerfile should use baseline image as FROM"
    echo "HINT: Change FROM line to: FROM registry-\${GUID}.\${DOMAIN}/base"
    exit 1
fi

# Check that Containerfile has the updated COPY commands
if ! grep -q "COPY app/ /app" Containerfile; then
    echo "FAIL: Containerfile should copy app/ directory"
    echo "HINT: Update COPY commands to use new directory structure"
    exit 1
fi

if ! grep -q "COPY etc/ /etc" Containerfile; then
    echo "FAIL: Containerfile should copy etc/ directory"
    echo "HINT: Add COPY etc/ /etc to Containerfile"
    exit 1
fi

# Check that Containerfile has firewall configuration
if ! grep -q "firewall-offline-cmd" Containerfile; then
    echo "FAIL: Containerfile should configure firewall"
    echo "HINT: Add RUN firewall-offline-cmd -s http"
    exit 1
fi

# Check that the v2 image exists locally
if ! podman image exists registry-${GUID}.${DOMAIN}/app-test:v2; then
    echo "FAIL: app-test:v2 image not found in local podman storage"
    echo "HINT: Build the image with: podman build --file Containerfile --tag registry-${GUID}.${DOMAIN}/app-test:v2"
    exit 1
fi

# Check that the v2 image was pushed to registry
if ! skopeo inspect docker://registry-${GUID}.${DOMAIN}/app-test:v2 > /dev/null 2>&1; then
    echo "FAIL: app-test:v2 image not found in registry"
    echo "HINT: Push the image with: podman push registry-${GUID}.${DOMAIN}/app-test:v2"
    exit 1
fi

# Check that git branch exists
if ! git rev-parse --verify base-image > /dev/null 2>&1; then
    echo "FAIL: Git branch 'base-image' should exist"
    echo "HINT: Create branch with: git switch -C base-image"
    exit 1
fi

echo "PASS: Module-08 validation complete - app reorganized and built from baseline" >> /tmp/progress.log
exit 0
