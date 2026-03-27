#!/bin/sh
echo "Validating module-04: Image updates" >> /tmp/progress.log

cd ~/bootc-base || exit 1

# Check sudoers file exists
if [ ! -f etc/sudoers.d/10-wheel ]; then
    echo "FAIL: Sudoers file should exist at etc/sudoers.d/10-wheel"
    echo "HINT: Create file with NOPASSWD for wheel group"
    exit 1
fi

# Check kargs file exists
if [ ! -f usr/lib/bootc/kargs.d/console_kargs.conf ]; then
    echo "FAIL: Kernel args file should exist"
    echo "HINT: Create file at usr/lib/bootc/kargs.d/console_kargs.conf"
    exit 1
fi

# Verify the image was rebuilt (check recent build log or image timestamp)
if [ ! -f /tmp/module-04-build.log ]; then
    echo "FAIL: Image should be rebuilt"
    echo "HINT: Run: podman build --file Containerfile --tag registry-${GUID}.${DOMAIN}/base"
    exit 1
fi

echo "PASS: Module-04 validation complete" >> /tmp/progress.log
exit 0
