#!/bin/bash
set -euo pipefail

LOG=/tmp/setup.log
exec > >(tee -a "$LOG") 2>&1

log() { echo "[$(date '+%H:%M:%S')] $*"; }

log "=== k8sdiy-env setup start ==="

# Install OpenTofu
log "Installing OpenTofu..."
curl -fsSL https://get.opentofu.org/install-opentofu.sh | sh -s -- --install-method standalone
log "OpenTofu installed"

# Install K9s
log "Installing K9s..."
curl -sS https://webi.sh/k9s | sh
log "K9s installed"

# Add aliases to bashrc
cat >> ~/.bashrc <<'EOF'

# k8sdiy-env aliases
alias kk="EDITOR='code --wait' k9s"
alias tf=tofu
alias k=kubectl
EOF

# Initialize Tofu
log "Running tofu init..."
cd bootstrap
tofu init
log "tofu init done"

log "Running tofu apply..."
tofu apply -auto-approve
log "tofu apply done"

export KUBECONFIG=~/.kube/config

cd ..

# Install cloud-provider-kind (LoadBalancer support)
log "Installing cloud-provider-kind..."
case "$(uname -s)" in
  Linux)  CPK_OS=linux ;;
  Darwin) CPK_OS=darwin ;;
  *)
    log "Unsupported OS: $(uname -s); skipping cloud-provider-kind"
    CPK_OS=
    ;;
esac
case "$(uname -m)" in
  x86_64|amd64) CPK_ARCH=amd64 ;;
  arm64|aarch64) CPK_ARCH=arm64 ;;
  *)
    log "Unsupported arch: $(uname -m); skipping cloud-provider-kind"
    CPK_ARCH=
    ;;
esac
if [[ -n "${CPK_OS:-}" && -n "${CPK_ARCH:-}" ]]; then
  CPK_URL="https://github.com/kubernetes-sigs/cloud-provider-kind/releases/download/v0.6.0/cloud-provider-kind_0.6.0_${CPK_OS}_${CPK_ARCH}.tar.gz"
  curl -fsSL "$CPK_URL" -o /tmp/cloud-provider-kind.tar.gz
  tar -xzf /tmp/cloud-provider-kind.tar.gz -C /tmp cloud-provider-kind
  rm -f /tmp/cloud-provider-kind.tar.gz
  nohup /tmp/cloud-provider-kind > /tmp/cloud-provider-kind.log 2>&1 &
  log "cloud-provider-kind started (pid $!)"
fi


log "=== setup complete ==="
