#!/bin/sh
echo "Validating module-02" >> /tmp/progress.log

SBOM_FILE="/home/rhel/scanning/rhhi-demo.spdx"

if [ ! -f "$SBOM_FILE" ]; then
    echo "FAIL: SBOM file not found at ~/scanning/rhhi-demo.spdx" >> /tmp/progress.log
    echo "HINT: Run 'cd ~/scanning && syft rhhi-demo:v1 -o spdx-json=rhhi-demo.spdx' to generate it." >> /tmp/progress.log
    exit 1
fi

if ! jq empty "$SBOM_FILE" > /dev/null 2>&1; then
    echo "FAIL: ~/scanning/rhhi-demo.spdx exists but is not valid JSON" >> /tmp/progress.log
    echo "HINT: Delete the file and regenerate with 'syft rhhi-demo:v1 -o spdx-json=rhhi-demo.spdx'." >> /tmp/progress.log
    exit 1
fi

PKG_COUNT=$(jq '.packages | length' "$SBOM_FILE" 2>/dev/null)
if [ -z "$PKG_COUNT" ]; then
    echo "FAIL: Could not read package count from SBOM" >> /tmp/progress.log
    echo "HINT: The SBOM may be malformed. Regenerate with syft." >> /tmp/progress.log
    exit 1
fi

if [ "$PKG_COUNT" -le 100 ]; then
    echo "FAIL: SBOM contains only $PKG_COUNT packages (expected > 100)" >> /tmp/progress.log
    echo "HINT: The SBOM may be incomplete. Regenerate with 'syft rhhi-demo:v1 -o spdx-json=rhhi-demo.spdx'." >> /tmp/progress.log
    exit 1
fi

echo "PASS: SBOM found at ~/scanning/rhhi-demo.spdx with $PKG_COUNT packages" >> /tmp/progress.log
exit 0
