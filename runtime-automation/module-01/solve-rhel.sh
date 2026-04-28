#!/bin/sh
echo "Solving module-01" >> /tmp/progress.log
systemctl --user enable --now podman.socket
grype version
syft version
grype rhhi-demo:v1 --by-cve
grype rhhi-demo:ubi --by-cve --only-fixed
