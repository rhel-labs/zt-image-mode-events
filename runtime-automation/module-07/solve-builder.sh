#!/bin/sh
echo "Solving module-07: Troubleshooting bootc deployment" >> /tmp/progress.log

# Change to the application repository
cd ~/bootc-version || exit 1

# Add linting to the Containerfile (automate the nano edit)
if ! grep -q "bootc container lint" Containerfile; then
    echo "RUN bootc container lint" >> Containerfile
fi

# Build the image with linting
podman build --file Containerfile --tag registry-${GUID}.${DOMAIN}/app-test 2>&1 | tee /tmp/module-07-build.log

# Push the image to registry
podman push registry-${GUID}.${DOMAIN}/app-test

# Add the tmpfiles.d workaround (automate the nano edit)
# Remove the lint line temporarily
sed -i '/^RUN bootc container lint$/d' Containerfile

# Add the tmpfiles.d heredoc before the final lint
cat >> Containerfile << 'EOCONTAINER'
RUN <<EORUN
    set -exuo pipefail
    echo "d /var/lib/nginx     770 nginx root -" >> /usr/lib/tmpfiles.d/nginx.conf
    echo "d /var/lib/nginx/tmp 770 nginx root -" >> /usr/lib/tmpfiles.d/nginx.conf
    echo "d /var/log/nginx     711 root  root -" >> /usr/lib/tmpfiles.d/nginx.conf
EORUN

RUN rm /var/{cache,lib}/dnf /var/lib/rhsm /var/cache/ldconfig -rf

RUN bootc container lint
EOCONTAINER

# Rebuild with the fix
podman build --file Containerfile --tag registry-${GUID}.${DOMAIN}/app-test 2>&1 | tee /tmp/module-07-build-fixed.log

# Push the fixed image
podman push registry-${GUID}.${DOMAIN}/app-test

echo "Module-07 solve complete" >> /tmp/progress.log
