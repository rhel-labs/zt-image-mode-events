#!/bin/sh
echo "Validating module-09: Multi-stage build" >> /tmp/progress.log

source /etc/profile.d/lab.sh

cd ~/bootc-version || exit 1

# Check that Containerfile has multiple FROM statements
FROM_COUNT=$(grep -c "^FROM " Containerfile)
if [ "$FROM_COUNT" -lt 2 ]; then
    echo "FAIL: Containerfile should have multiple FROM statements for multi-stage build"
    echo "HINT: Add a first stage for SELinux policy build"
    exit 1
fi

# Check for AS policy stage
if ! grep -q "FROM.*AS policy" Containerfile; then
    echo "FAIL: Containerfile should define policy stage"
    echo "HINT: Add: FROM registry.redhat.io/rhel10/rhel-bootc:10.1 AS policy"
    exit 1
fi

# Check for COPY --from=policy
if ! grep -q "COPY --from=policy" Containerfile; then
    echo "FAIL: Containerfile should copy from policy stage"
    echo "HINT: Use COPY --from=policy to get SELinux module"
    exit 1
fi

# Verify build log shows multi-stage
if [ -f /tmp/module-09-build.log ] && ! grep -q "\[1/2\]" /tmp/module-09-build.log; then
    echo "FAIL: Build should show multi-stage steps"
    exit 1
fi

# Check image exists
if ! podman image exists registry-${GUID}.${DOMAIN}/app-test:v2; then
    echo "FAIL: app-test:v2 image should exist"
    exit 1
fi

echo "PASS: Module-09 validation complete" >> /tmp/progress.log
exit 0
