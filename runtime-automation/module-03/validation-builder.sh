#!/bin/sh
echo "Validating module-03: VM deployment" >> /tmp/progress.log


source /etc/profile.d/lab.sh


# Check that config.toml exists
if [ ! -f ~/config.toml ]; then
    echo "FAIL: config.toml should exist in home directory" >> /tmp/progress.log
    echo "HINT: Create config.toml with user customization" >> /tmp/progress.log
    exit 1
fi

# Check that config.toml has required content
if ! grep -q 'name = "core"' ~/config.toml; then
    echo "FAIL: config.toml should define core user" >> /tmp/progress.log
    exit 1
fi

# Check that qcow2 image was created
if [ ! -f ~/qcow2/disk.qcow2 ]; then
    echo "FAIL: qcow2 disk image should exist" >> /tmp/progress.log
    echo "HINT: Run bootc-image-builder to create the disk image" >> /tmp/progress.log
    exit 1
fi

# Check that VM exists
if ! virsh list --all | grep -q bootc-vm; then
    echo "FAIL: bootc-vm should exist" >> /tmp/progress.log
    echo "HINT: Create VM with virt-install" >> /tmp/progress.log
    exit 1
fi

# Check that VM is running
if ! virsh list --state-running | grep -q bootc-vm; then
    echo "FAIL: bootc-vm should be running" >> /tmp/progress.log
    echo "HINT: Start VM with: virsh start bootc-vm" >> /tmp/progress.log
    exit 1
fi

echo "PASS: Module-03 validation complete - VM deployed" >> /tmp/progress.log
exit 0
