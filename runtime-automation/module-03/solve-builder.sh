#!/bin/sh
echo "Solving module-03: Deploying bootc VM" >> /tmp/progress.log

source /etc/profile.d/lab.sh

cd ~ || exit 1

# Get the SSH public key
SSH_KEY=$(cat ~/.ssh/${GUID}key.pub)

# Create config.toml for bootc-image-builder
cat > config.toml << EOF
[[customizations.user]]
name = "core"
password = "redhat"
groups = ["wheel"]
key = "$SSH_KEY"
EOF

# Create the disk image using bootc-image-builder
# This takes 2+ minutes
podman run --rm --privileged --security-opt label=type:unconfined_t \
  --volume ./config.toml:/config.toml \
  --volume /var/lib/containers/storage:/var/lib/containers/storage \
  --volume .:/output \
  registry.redhat.io/rhel10/bootc-image-builder:10.1 \
  --type qcow2 \
  registry-${GUID}.${DOMAIN}/base 2>&1 | tee /tmp/module-03-image-builder.log

# Verify the image was created
if [ -f qcow2/disk.qcow2 ]; then
    echo "VM disk image created successfully" >> /tmp/progress.log
else
    echo "ERROR: VM disk image not created" >> /tmp/progress.log
    exit 1
fi
cp /root/qcow2/disk.qcow2 /var/lib/libvirt/images/bootc-vm.qcow2
# Create the virtual machine
virt-install \
  --name bootc-vm \
  --memory 4096 \
  --vcpus 2 \
  --disk /var/lib/libvirt/images/bootc-vm.qcow2 \
  --import \
  --os-variant rhel10-unknown \
  --network network=default \
  --graphics none \
  --noautoconsole

virsh start bootc-vm

echo "Module-03 solve complete - VM created" >> /tmp/progress.log
