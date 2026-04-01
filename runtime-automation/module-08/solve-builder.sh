#!/bin/sh
echo "Solving module-08: Using standard baseline image" >> /tmp/progress.log

source /etc/profile.d/lab.sh

# Make sure we're in the right repository
cd ~/bootc-version || exit 1

# Create a new git branch for the changes
git switch -C base-image 2>/dev/null || git checkout -b base-image

# Organize the repository structure
mkdir -p app
mkdir -p etc/systemd/system
mkdir -p etc/nginx/conf.d
mkdir -p etc/tmpfiles.d

# Move application files to app/ directory (if not already done)
if [ -f app.py ]; then
    mv app.py config.json helpers.py requirements.txt nginx_connect_flask_sock.* app/ 2>/dev/null || true
    mv static templates app/ 2>/dev/null || true
fi

# Move service file to etc structure
if [ -f info-app.service ]; then
    mv info-app.service etc/systemd/system/
elif [ -f app/info-app.service ]; then
    mv app/info-app.service etc/systemd/system/
fi

# Move nginx config to etc structure
if [ -f info-app.conf ]; then
    mv info-app.conf etc/nginx/conf.d/
elif [ -f app/info-app.conf ]; then
    mv app/info-app.conf etc/nginx/conf.d/
fi

# Create nginx tmpfiles.d configuration
cat > etc/tmpfiles.d/nginx.conf << 'EOF'
d /var/lib/nginx     770 nginx root -
d /var/lib/nginx/tmp 770 nginx root -
d /var/log/nginx     711 root  root -
EOF

# Create the updated Containerfile
cat > Containerfile << EOCONTAINERFILE
# Start with the secured baseline
FROM registry-${GUID}.${DOMAIN}/base

# Install necessary packages from RHEL Application Streams using dnf
# This includes default Python 3, pip, and Nginx
RUN dnf install -y \\
    python3 \\
    python3-pip \\
    nginx && \\
    dnf clean all && rm -rf /var/cache/dnf

# Copy the Flask application files
COPY app/ /app

# custom Nginx configuration file that acts as a reverse proxy
# nginx tmpfiles.d configuration
# application systemd service definition
COPY etc/ /etc

# Install requirements via pip3
RUN pip3 install -r /app/requirements.txt

# Configure firewall for http service
RUN firewall-offline-cmd -s http

# Ensure nginx can talk to gunicorn
WORKDIR /app
RUN checkmodule -M -m nginx_connect_flask_sock.te -o nginx_connect_flask_sock.mo
RUN semodule_package -o nginx_connect_flask_sock.pp -m nginx_connect_flask_sock.mo
RUN semodule -i nginx_connect_flask_sock.pp
RUN mkdir /run/flask-app && chgrp -R nginx /run/flask-app && chmod 770 /run/flask-app
RUN semanage fcontext -a -t httpd_var_run_t /run/flask-app

# Enable our application services
RUN systemctl enable nginx.service
RUN systemctl enable info-app.service

RUN rm /var/{cache,lib}/dnf /var/lib/rhsm /var/cache/ldconfig -rf

RUN bootc container lint
EOCONTAINERFILE

# Build the v2 image from the baseline
podman build --file Containerfile --tag registry-${GUID}.${DOMAIN}/app-test:v2 2>&1 | tee /tmp/module-08-build.log

# Push to the registry
podman push registry-${GUID}.${DOMAIN}/app-test:v2

echo "Module-08 solve complete" >> /tmp/progress.log
