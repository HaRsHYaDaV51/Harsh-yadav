#!/usr/bin/env bash
# ─────────────────────────────────────────────
# create-cluster.sh
# Fully automated kops Kubernetes cluster bootstrap
# Usage: ./create-cluster.sh
# ─────────────────────────────────────────────

set -euo pipefail

# ── Configuration ──────────────────────────
CLUSTER_NAME="${CLUSTER_NAME:-prod.k8s.yourdomain.com}"
KOPS_STATE_STORE="${KOPS_STATE_STORE:-s3://your-kops-state-bucket}"
AWS_REGION="${AWS_REGION:-us-east-1}"
KUBERNETES_VERSION="1.29.0"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log()   { echo -e "${GREEN}[INFO]${NC} $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*"; exit 1; }

# ── Preflight checks ───────────────────────
log "Running preflight checks..."

command -v kops    &>/dev/null || error "kops not installed"
command -v kubectl &>/dev/null || error "kubectl not installed"
command -v helm    &>/dev/null || error "helm not installed"
command -v aws     &>/dev/null || error "aws CLI not installed"

aws sts get-caller-identity &>/dev/null || error "AWS credentials not configured"

# ── Terraform: base infra ──────────────────
log "Step 1/5 — Provisioning base infrastructure with Terraform..."
cd "$(dirname "$0")/../terraform/environments/prod"
terraform init -input=false
terraform apply -auto-approve -input=false
cd -

# ── kops: create cluster ───────────────────
log "Step 2/5 — Creating kops cluster spec..."
kops create -f kops/cluster.yaml \
  --state "${KOPS_STATE_STORE}"

# Create SSH keypair (if not exists)
if [ ! -f ~/.ssh/kops-key ]; then
  ssh-keygen -t rsa -b 4096 -f ~/.ssh/kops-key -N "" -q
  log "SSH keypair created at ~/.ssh/kops-key"
fi

kops create secret sshpublickey admin \
  -i ~/.ssh/kops-key.pub \
  --name "${CLUSTER_NAME}" \
  --state "${KOPS_STATE_STORE}"

# ── kops: apply cluster ────────────────────
log "Step 3/5 — Applying cluster (this takes ~10-15 minutes)..."
kops update cluster "${CLUSTER_NAME}" \
  --state "${KOPS_STATE_STORE}" \
  --yes

# ── Wait for cluster readiness ─────────────
log "Step 4/5 — Waiting for cluster to be ready..."
MAX_ATTEMPTS=60
ATTEMPT=0

while [ $ATTEMPT -lt $MAX_ATTEMPTS ]; do
  if kops validate cluster "${CLUSTER_NAME}" \
       --state "${KOPS_STATE_STORE}" &>/dev/null; then
    log "✅ Cluster is ready!"
    break
  fi
  ATTEMPT=$((ATTEMPT + 1))
  warn "Cluster not ready yet... attempt $ATTEMPT/$MAX_ATTEMPTS (waiting 30s)"
  sleep 30
done

[ $ATTEMPT -eq $MAX_ATTEMPTS ] && error "Cluster did not become ready in time"

# ── Deploy monitoring ──────────────────────
log "Step 5/5 — Deploying Prometheus & Grafana monitoring stack..."
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

helm upgrade --install prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --create-namespace \
  -f monitoring/prometheus/values.yaml \
  --wait

# Deploy Cluster Autoscaler
log "Deploying Cluster Autoscaler..."
helm repo add autoscaler https://kubernetes.github.io/autoscaler
helm upgrade --install cluster-autoscaler autoscaler/cluster-autoscaler \
  --namespace kube-system \
  --set autoDiscovery.clusterName="${CLUSTER_NAME}" \
  --set awsRegion="${AWS_REGION}" \
  --wait

# ── Summary ────────────────────────────────
echo ""
echo -e "${GREEN}═══════════════════════════════════════════${NC}"
echo -e "${GREEN}  ✅ Cluster deployed successfully!${NC}"
echo -e "${GREEN}═══════════════════════════════════════════${NC}"
echo ""
echo "Cluster:    ${CLUSTER_NAME}"
echo "State:      ${KOPS_STATE_STORE}"
echo ""
echo "Access Grafana:"
echo "  kubectl port-forward svc/prometheus-grafana 3000:80 -n monitoring"
echo "  Then open: http://localhost:3000"
echo ""
kubectl get nodes
