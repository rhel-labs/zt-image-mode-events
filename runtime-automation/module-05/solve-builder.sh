#!/bin/sh
echo "Solving module-05: Adding security and compliance" >> /tmp/progress.log

source /etc/profile.d/lab.sh

cd ~/bootc-base || exit 1

# Create tailored SCAP policy
autotailor --unselect xccdf_org.ssgproject.content_rule_sshd_disable_root_login \
  --new-profile-id cis_server_l1_customized \
  --output cis_server_l1_customized.xml \
  /usr/share/xml/scap/ssg/content/ssg-rhel10-ds.xml cis_server_l1

# Update Containerfile to add security packages and policy
# First, backup original
cp Containerfile Containerfile.backup

# Add security packages after the systemctl mask line
cat >> Containerfile << 'EOF'

# Security and Hardening
RUN dnf -y install audit fapolicyd openscap-utils scap-security-guide setroubleshoot-server

LABEL profile="CIS Server Level 1 base image"
ENV profileID=cis_server_l1_customized

COPY $profileID.xml /tmp/$profileID.xml
RUN oscap-im --profile $profileID --tailoring-file /tmp/$profileID.xml /usr/share/xml/scap/ssg/content/ssg-rhel10-ds.xml
EOF

# Build with security policy
podman build --file Containerfile --tag registry-${GUID}.${DOMAIN}/base 2>&1 | tee /tmp/module-05-build.log

# Push to registry
podman push registry-${GUID}.${DOMAIN}/base

echo "Module-05 solve complete - security policy applied" >> /tmp/progress.log
