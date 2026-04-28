#!/bin/sh
echo "Solving module-02" >> /tmp/progress.log

runuser -l rhel << 'RHEL_EOF'
syft rhhi-demo:v1 -o table
cd ~/scanning
syft rhhi-demo:v1 -o spdx-json=rhhi-demo.spdx
jq '.packages | length' rhhi-demo.spdx
jq '.packages[0]' rhhi-demo.spdx
cd ~
RHEL_EOF
