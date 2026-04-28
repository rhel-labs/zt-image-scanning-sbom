#!/bin/sh
echo "Solving module-01" >> /tmp/progress.log

runuser -l rhel << 'RHEL_EOF'
systemctl --user enable --now podman.socket
grype version
syft version
podman images rhhi-demo
grype rhhi-demo:v1 --by-cve
grype rhhi-demo:ubi --by-cve --only-fixed
RHEL_EOF
