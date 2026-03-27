#!/bin/sh
echo "Solving module-04: Updating bootc image" >> /tmp/progress.log

cd ~/bootc-base || exit 1

# Create sudoers drop-in file
cat > etc/sudoers.d/10-wheel << 'EOF'
# Enable passwordless sudo for the wheel group
%wheel        ALL=(ALL)       NOPASSWD: ALL
EOF

# Create kernel args configuration
cat > usr/lib/bootc/kargs.d/console_kargs.conf << 'EOF'
kargs = ["console=tty0", "console=ttyS0,115200n8"]
EOF

# Rebuild the image with new configs
podman build --file Containerfile --tag registry-${GUID}.${DOMAIN}/base 2>&1 | tee /tmp/module-04-build.log

# Push updated image
podman push registry-${GUID}.${DOMAIN}/base

echo "Module-04 solve complete - image updated" >> /tmp/progress.log
