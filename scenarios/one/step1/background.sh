#!/bin/bash

# Exit immediately if a command exits with a non-zero status

set -e

sudo apt update && sudo apt install curl yq -y
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

# Optional: Create a 'done' file if your foreground.sh or index.json needs to wait for this
touch /opt/background-finished