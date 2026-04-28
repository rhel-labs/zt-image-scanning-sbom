#!/bin/bash
USER=rhel

echo "Adding wheel" > /root/post-run.log
usermod -aG wheel rhel

echo "Starting setup for zt-image-scanning-sbom" > /tmp/progress.log

chmod 666 /tmp/progress.log

# Fetch setup files from the lab git repository
TMPDIR=/tmp/lab-setup-$$
git clone --single-branch --branch ${GIT_BRANCH:-main} --no-checkout \
  --depth=1 --filter=tree:0 ${GIT_REPO} $TMPDIR
git -C $TMPDIR sparse-checkout set --no-cone /setup-files
git -C $TMPDIR checkout
SETUP_FILES=$TMPDIR/setup-files

# Install grype
GRYPE_VERSION=v0.111.0
curl -sSfL https://raw.githubusercontent.com/anchore/grype/main/install.sh | \
  sh -s -- -b /usr/local/bin ${GRYPE_VERSION}
su -l rhel -c "grype db update"
echo "Grype installed" >> /tmp/progress.log

# Install syft
SYFT_VERSION=v1.42.4
curl -sSfL https://raw.githubusercontent.com/anchore/syft/main/install.sh | \
  sh -s -- -b /usr/local/bin ${SYFT_VERSION}
echo "Syft installed" >> /tmp/progress.log

# Install Java for building the demo image
dnf install -y java-21-openjdk-devel
echo "Java installed" >> /tmp/progress.log

# Install quarkus CLI and scaffold project as rhel user
cat > /tmp/quarkus-install.sh <<'QEOF'
curl -Ls https://sh.jbang.dev | bash -s - trust add https://repo1.maven.org/maven2/io/quarkus/quarkus-cli/
curl -Ls https://sh.jbang.dev | bash -s - app install --fresh --force quarkus@quarkusio
if ! grep -q '.jbang/bin' ~/.bashrc 2>/dev/null; then
    echo 'export PATH="$HOME/.jbang/bin:$PATH"' >> ~/.bashrc
fi
QEOF
chmod +x /tmp/quarkus-install.sh
su -l rhel -c /tmp/quarkus-install.sh

su -l rhel -c "~/.jbang/bin/quarkus create app com.example:sample-app \
  --extension='rest,rest-jackson' --no-code"
echo "Quarkus project scaffolded" >> /tmp/progress.log

mkdir -p /home/rhel/sample-app/src/main/java/com/example
cp $SETUP_FILES/quarkus/GreetingResource.java \
  /home/rhel/sample-app/src/main/java/com/example/
cp $SETUP_FILES/quarkus/application.properties \
  /home/rhel/sample-app/src/main/resources/
cp $SETUP_FILES/quarkus/Containerfile /home/rhel/sample-app/
cp $SETUP_FILES/quarkus/Containerfile.ubi /home/rhel/sample-app/
cp $SETUP_FILES/quarkus/.dockerignore /home/rhel/sample-app/
chmod a+x /home/rhel/sample-app/mvnw
chmod -R a+rX /home/rhel/sample-app/.mvn/ /home/rhel/sample-app/src/
chmod a+r /home/rhel/sample-app/pom.xml
echo "Application files configured" >> /tmp/progress.log

# Pull base images into rhel's rootless store
su -l rhel -c "podman pull registry.access.redhat.com/hi/openjdk:21-builder"
su -l rhel -c "podman pull registry.access.redhat.com/hi/openjdk:21-runtime"
echo "Base images pulled" >> /tmp/progress.log

# Warm Maven cache inside the builder container
su -l rhel -c "podman run --rm --net=host \
  -v /home/rhel/sample-app:/build:Z -w /build \
  registry.access.redhat.com/hi/openjdk:21-builder \
  ./mvnw dependency:resolve -q"
echo "Maven cache warmed" >> /tmp/progress.log

# Build rhhi-demo:v1 (multi-stage hardened image)
su -l rhel -c "podman build -t rhhi-demo:v1 \
  -f /home/rhel/sample-app/Containerfile /home/rhel/sample-app"
echo "rhhi-demo:v1 built" >> /tmp/progress.log

# Build rhhi-demo:ubi (single-stage UBI image for comparison)
su -l rhel -c "podman build -t rhhi-demo:ubi \
  -f /home/rhel/sample-app/Containerfile.ubi /home/rhel/sample-app"
echo "rhhi-demo:ubi built" >> /tmp/progress.log

# Create scanning directory
su -l rhel -c "mkdir -p ~/scanning"

# Cleanup
rm -rf $TMPDIR /tmp/quarkus-install.sh
chown -R rhel:rhel /home/rhel

echo "Setup complete" >> /tmp/progress.log
