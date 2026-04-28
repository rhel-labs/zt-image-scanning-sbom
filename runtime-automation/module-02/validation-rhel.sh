#!/bin/sh
echo "Validating module-02" >> /tmp/progress.log

SBOM_FILE="$HOME/scanning/rhhi-demo.spdx"

# Check that the SBOM file exists
if [ ! -f "$SBOM_FILE" ]; then
    echo "FAIL: SBOM file not found at ~/scanning/rhhi-demo.spdx"
    echo "HINT: Run 'cd ~/scanning && syft rhhi-demo:v1 -o spdx-json=rhhi-demo.spdx' to generate it."
    exit 1
fi

# Check that jq can parse the file (valid JSON)
if ! jq empty "$SBOM_FILE" > /dev/null 2>&1; then
    echo "FAIL: ~/scanning/rhhi-demo.spdx exists but is not valid JSON"
    echo "HINT: Delete the file and regenerate with 'syft rhhi-demo:v1 -o spdx-json=rhhi-demo.spdx'."
    exit 1
fi

# Check that the SBOM contains a meaningful number of packages (expect > 100)
PKG_COUNT=$(jq '.packages | length' "$SBOM_FILE" 2>/dev/null)
if [ -z "$PKG_COUNT" ]; then
    echo "FAIL: Could not read package count from SBOM"
    echo "HINT: The SBOM may be malformed. Regenerate with syft."
    exit 1
fi

if [ "$PKG_COUNT" -le 100 ]; then
    echo "FAIL: SBOM contains only $PKG_COUNT packages (expected > 100)"
    echo "HINT: The SBOM may be incomplete. Regenerate with 'syft rhhi-demo:v1 -o spdx-json=rhhi-demo.spdx'."
    exit 1
fi

echo "PASS: SBOM found at ~/scanning/rhhi-demo.spdx with $PKG_COUNT packages"
exit 0
