#!/bin/bash
set -e

# --- setup guard ------------------------------------------------------------
# foreground.sh waits for /tmp/setup-finished. Touch it on every exit, so a
# failed step can never leave the terminal waiting forever, and record the first
# failed step so foreground.sh and verify.sh can report it instead of the player
# debugging a half-built environment.
SETUP_FAILED=/tmp/setup-failed
rm -f "$SETUP_FAILED"
trap '[ -f "$SETUP_FAILED" ] || echo "setup step failed (line $LINENO): $BASH_COMMAND" > "$SETUP_FAILED"' ERR
trap 'touch /tmp/setup-finished' EXIT

NAMESPACE="challenge4"
WORKDIR="/tmp/challenge4-tls"

mkdir -p "${WORKDIR}"

if ! command -v helm >/dev/null 2>&1; then
  curl -fsSL -o /tmp/get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
  chmod 700 /tmp/get_helm.sh
  /tmp/get_helm.sh
  rm -f /tmp/get_helm.sh
fi

if ! command -v yq >/dev/null 2>&1; then
  curl -sL "https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64" -o /usr/local/bin/yq
  chmod +x /usr/local/bin/yq
fi

if ! command -v openssl >/dev/null 2>&1; then
  apt-get update && apt-get install -y openssl
fi

kubectl create namespace "${NAMESPACE}" --dry-run=client -o yaml | kubectl apply -f -

# Generate a local CA and server certificate for the in-cluster HTTPS service
openssl genrsa -out "${WORKDIR}/ca.key" 2048
openssl req -x509 -new -nodes -key "${WORKDIR}/ca.key" -sha256 -days 3650 \
  -subj "/CN=NorthPole-Internal-CA" \
  -out "${WORKDIR}/ca.crt"

openssl genrsa -out "${WORKDIR}/server.key" 2048

cat > "${WORKDIR}/server.cnf" << 'EOF'
[req]
default_bits = 2048
prompt = no
default_md = sha256
distinguished_name = dn
req_extensions = req_ext

[dn]
CN = tls-echo.challenge4.svc.cluster.local

[req_ext]
subjectAltName = @alt_names

[alt_names]
DNS.1 = tls-echo
DNS.2 = tls-echo.challenge4
DNS.3 = tls-echo.challenge4.svc
DNS.4 = tls-echo.challenge4.svc.cluster.local
EOF

openssl req -new -key "${WORKDIR}/server.key" -out "${WORKDIR}/server.csr" -config "${WORKDIR}/server.cnf"

cat > "${WORKDIR}/v3.ext" << 'EOF'
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = digitalSignature, keyEncipherment
extendedKeyUsage = serverAuth
subjectAltName = @alt_names

[alt_names]
DNS.1 = tls-echo
DNS.2 = tls-echo.challenge4
DNS.3 = tls-echo.challenge4.svc
DNS.4 = tls-echo.challenge4.svc.cluster.local
EOF

openssl x509 -req -in "${WORKDIR}/server.csr" -CA "${WORKDIR}/ca.crt" -CAkey "${WORKDIR}/ca.key" -CAcreateserial \
  -out "${WORKDIR}/server.crt" -days 365 -sha256 -extfile "${WORKDIR}/v3.ext"

kubectl -n "${NAMESPACE}" delete secret tls-echo-server --ignore-not-found
kubectl -n "${NAMESPACE}" create secret tls tls-echo-server \
  --cert="${WORKDIR}/server.crt" \
  --key="${WORKDIR}/server.key"

kubectl -n "${NAMESPACE}" delete secret northpole-ca --ignore-not-found
kubectl -n "${NAMESPACE}" create secret generic northpole-ca \
  --from-file=ca.crt="${WORKDIR}/ca.crt"

touch /tmp/setup-finished
