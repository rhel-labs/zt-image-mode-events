#!/bin/sh
echo "Validating module-07: Bootc deployment fix" >> /tmp/progress.log

# Check that we're in the right directory
if [ ! -d ~/bootc-version ]; then
    echo "FAIL: bootc-version repository not found"
    exit 1
fi

cd ~/bootc-version || exit 1

# Check that Containerfile has the tmpfiles.d configuration
if ! grep -q "/usr/lib/tmpfiles.d/nginx.conf" Containerfile; then
    echo "FAIL: Containerfile should contain tmpfiles.d nginx configuration"
    echo "HINT: Add the tmpfiles.d heredoc to create nginx directories"
    exit 1
fi

# Check that Containerfile has the cleanup line
if ! grep -q "rm /var/{cache,lib}/dnf" Containerfile; then
    echo "FAIL: Containerfile should clean up /var directories"
    echo "HINT: Add the RUN command to remove dnf cache directories"
    exit 1
fi

# Check that Containerfile has linting enabled
if ! grep -q "bootc container lint" Containerfile; then
    echo "FAIL: Containerfile should have bootc container lint"
    echo "HINT: Add 'RUN bootc container lint' as the final step"
    exit 1
fi

# Check that the image exists locally
if ! podman image exists registry-${GUID}.${DOMAIN}/app-test; then
    echo "FAIL: app-test image not found in local podman storage"
    echo "HINT: Build the image with: podman build --file Containerfile --tag registry-${GUID}.${DOMAIN}/app-test"
    exit 1
fi

# Check that the image was pushed to registry (verify with skopeo)
if ! skopeo inspect docker://registry-${GUID}.${DOMAIN}/app-test > /dev/null 2>&1; then
    echo "FAIL: app-test image not found in registry"
    echo "HINT: Push the image with: podman push registry-${GUID}.${DOMAIN}/app-test"
    exit 1
fi

echo "PASS: Module-07 validation complete - bootc image with nginx fix built and pushed" >> /tmp/progress.log
exit 0
