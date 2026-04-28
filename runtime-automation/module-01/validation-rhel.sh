#!/bin/sh
echo "Validating module-01" >> /tmp/progress.log

if ! runuser -u rhel -- podman image exists rhhi-demo:v1; then
    echo "FAIL: rhhi-demo:v1 image not found" >> /tmp/progress.log
    echo "HINT: Run 'podman images' to see available images. Contact lab support if images are missing." >> /tmp/progress.log
    exit 1
fi

if ! runuser -u rhel -- podman image exists rhhi-demo:ubi; then
    echo "FAIL: rhhi-demo:ubi image not found" >> /tmp/progress.log
    echo "HINT: Run 'podman images' to see available images. Contact lab support if images are missing." >> /tmp/progress.log
    exit 1
fi

if ! command -v grype > /dev/null 2>&1; then
    echo "FAIL: grype binary not found" >> /tmp/progress.log
    echo "HINT: grype should be pre-installed at /usr/local/bin/grype. Contact lab support." >> /tmp/progress.log
    exit 1
fi

if ! runuser -u rhel -- systemctl --user is-active podman.socket > /dev/null 2>&1; then
    echo "FAIL: podman.socket is not active for the rhel user" >> /tmp/progress.log
    echo "HINT: Run 'systemctl --user enable --now podman.socket' to enable it." >> /tmp/progress.log
    exit 1
fi

echo "PASS: Both images exist, grype is installed, and podman.socket is active" >> /tmp/progress.log
exit 0
