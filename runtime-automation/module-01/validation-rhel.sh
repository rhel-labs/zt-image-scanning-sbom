#!/bin/sh
echo "Validating module-01" >> /tmp/progress.log

if ! runuser -u rhel -- podman image exists rhhi-demo:v1 2>/dev/null; then
    echo "FAIL: rhhi-demo:v1 image not found" >> /tmp/progress.log
    echo "HINT: Run 'podman images' to see available images. Contact lab support if images are missing." >> /tmp/progress.log
    exit 1
fi

if ! runuser -u rhel -- podman image exists rhhi-demo:ubi 2>/dev/null; then
    echo "FAIL: rhhi-demo:ubi image not found" >> /tmp/progress.log
    echo "HINT: Run 'podman images' to see available images. Contact lab support if images are missing." >> /tmp/progress.log
    exit 1
fi

if ! test -x /usr/local/bin/grype; then
    echo "FAIL: grype binary not found" >> /tmp/progress.log
    echo "HINT: grype should be pre-installed at /usr/local/bin/grype. Contact lab support." >> /tmp/progress.log
    exit 1
fi

RHEL_UID=$(id -u rhel)
if ! test -S /run/user/${RHEL_UID}/podman/podman.sock; then
    echo "FAIL: podman.socket is not active for the rhel user" >> /tmp/progress.log
    echo "HINT: Run 'systemctl --user enable --now podman.socket' to enable it." >> /tmp/progress.log
    exit 1
fi

echo "PASS: Both images exist, grype is installed, and podman.socket is active" >> /tmp/progress.log
exit 0
