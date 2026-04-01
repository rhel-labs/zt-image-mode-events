#!/bin/sh
echo "Solving module-09: Multi-stage container build" >> /tmp/progress.log

source /etc/profile.d/lab.sh

# This assumes the app-test image and repo exist from previous modules
cd ~/bootc-version || exit 1

# Backup current Containerfile
cp Containerfile Containerfile.before-multistage

# Create multi-stage Containerfile
cat > Containerfile << EOCONTAINERFILE
# First stage: Build SELinux policy
FROM registry.redhat.io/rhel10/rhel-bootc:10.1 AS policy
COPY app/nginx_connect_flask_sock.te .
RUN checkmodule -M -m nginx_connect_flask_sock.te -o nginx_connect_flask_sock.mo
RUN semodule_package -o nginx_connect_flask_sock.pp -m nginx_connect_flask_sock.mo

# Second stage: Application image from baseline
FROM registry-${GUID}.${DOMAIN}/base AS host

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

# Deploy the binary SELinux policy and update the labeling
COPY --from=policy nginx_connect_flask_sock.pp \\
/usr/share/selinux/packages/targeted/
RUN semodule -i /usr/share/selinux/packages/targeted/nginx_connect_flask_sock.pp
RUN semanage fcontext -a -t httpd_var_run_t /run/flask-app

# Enable our application services
RUN systemctl enable nginx.service
RUN systemctl enable info-app.service

RUN rm /var/{cache,lib}/dnf /var/lib/rhsm /var/cache/ldconfig -rf

RUN bootc container lint
EOCONTAINERFILE

# Build with multi-stage
podman build --file Containerfile --tag registry-${GUID}.${DOMAIN}/app-test:v2 2>&1 | tee /tmp/module-09-build.log

# Push to registry
podman push registry-${GUID}.${DOMAIN}/app-test:v2

echo "Module-09 solve complete - multi-stage build" >> /tmp/progress.log
