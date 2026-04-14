#!/bin/sh
echo "Validating module-05: Security and compliance" >> /tmp/progress.log

source /etc/profile.d/lab.sh

cd ~/bootc-base || exit 1

# Check that tailored policy exists
if [ ! -f cis_server_l1_customized.xml ]; then
    echo "FAIL: Tailored SCAP policy should exist" >> /tmp/progress.log
    echo "HINT: Run autotailor to create cis_server_l1_customized.xml" >> /tmp/progress.log
    exit 1
fi

# Check that Containerfile has security packages
if ! grep -q "fapolicyd" Containerfile; then
    echo "FAIL: Containerfile should install security packages" >> /tmp/progress.log
    echo "HINT: Add RUN dnf install for security tools" >> /tmp/progress.log
    exit 1
fi

# Check that Containerfile has oscap-im
if ! grep -q "oscap-im" Containerfile; then
    echo "FAIL: Containerfile should use oscap-im for policy application" >> /tmp/progress.log
    echo "HINT: Add oscap-im command with tailored policy" >> /tmp/progress.log
    exit 1
fi

# Verify build completed (check for log or recent image)
#if [ ! -f /tmp/module-05-build.log ]; then
#    echo "FAIL: Image should be built with security policy" >> /tmp/progress.log
#    exit 1
#fi

echo "PASS: Module-05 validation complete" >> /tmp/progress.log
exit 0
