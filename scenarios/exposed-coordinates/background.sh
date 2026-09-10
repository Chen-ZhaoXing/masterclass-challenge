#!/bin/bash

# Exit immediately if a command exits with a non-zero status

set -e

# --- setup guard ------------------------------------------------------------
# foreground.sh waits for /opt/background-finished. Touch it on every exit, so
# a failed step can never leave the terminal waiting forever, and record the
# first failed step so foreground.sh and verify.sh can report it instead of the
# player debugging a half-built environment.
SETUP_FAILED=/tmp/setup-failed
rm -f "$SETUP_FAILED"
trap '[ -f "$SETUP_FAILED" ] || echo "setup step failed (line $LINENO): $BASH_COMMAND" > "$SETUP_FAILED"' ERR
trap 'touch /opt/background-finished' EXIT

# Only reach for apt when curl is actually missing: apt is often locked for the
# first minutes of a fresh VM, and under set -e that alone would abort setup.
command -v curl >/dev/null 2>&1 || { sudo apt update && sudo apt install curl -y; }

# Install yq (Mike Farah's Go-based yq v4)
curl -sL "https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64" -o /usr/local/bin/yq
chmod +x /usr/local/bin/yq

# 1. Download the latest Linux tarball silently (-s) and follow redirects (-L)
curl -sL "https://github.com/stackrox/kube-linter/releases/latest/download/kube-linter-linux.tar.gz" -o kube-linter-linux.tar.gz

# 2. Extract the binary from the tar archive
tar -xzf kube-linter-linux.tar.gz

# 3. Move the binary to a directory that is already in the system PATH
mv kube-linter /usr/local/bin/

# 4. Ensure the binary is executable
chmod +x /usr/local/bin/kube-linter

# 5. Clean up the downloaded archive to keep the environment clean
rm kube-linter-linux.tar.gz

# Optional: Output the version to a log file to verify successful background installation
kube-linter version > /var/log/kube-linter-install.log

# Install Helm
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
chmod 700 get_helm.sh
./get_helm.sh
rm get_helm.sh

kubectl create ns challenge1

kubectl create secret generic masterclass-auth \
  --from-literal=legacy-sys-token=s3cr3t-ch4ll3ng3-t0k3n \
  -n challenge1

# Optional: Create a 'done' file if your foreground.sh or index.json needs to wait for this
touch /opt/background-finished