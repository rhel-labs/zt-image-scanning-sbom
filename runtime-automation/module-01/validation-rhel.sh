#!/bin/sh
echo "Validating module-01" >> /tmp/progress.log

# Check that both images exist
if ! podman image exists rhhi-demo:v1; then
    echo "FAIL: rhhi-demo:v1 image not found"
    echo "HINT: Run 'podman images' to see available images. Contact lab support if images are missing."
    exit 1
fi

if ! podman image exists rhhi-demo:ubi; then
    echo "FAIL: rhhi-demo:ubi image not found"
    echo "HINT: Run 'podman images' to see available images. Contact lab support if images are missing."
    exit 1
fi

# Check that grype is installed
if ! command -v grype > /dev/null 2>&1; then
    echo "FAIL: grype binary not found"
    echo "HINT: grype should be pre-installed at /usr/local/bin/grype. Contact lab support."
    exit 1
fi

# Check that podman.socket is active for the current user
if ! systemctl --user is-active podman.socket > /dev/null 2>&1; then
    echo "FAIL: podman.socket is not active for the current user"
    echo "HINT: Run 'systemctl --user enable --now podman.socket' to enable it."
    exit 1
fi

echo "PASS: Both images exist, grype is installed, and podman.socket is active"
exit 0
