#!/bin/bash
set -euo pipefail

echo "=== LGTM Stack Quickstart ==="
echo ""
echo "This will install a production-grade observability stack on your Kubernetes cluster."
echo "Components: Grafana, Loki, Tempo, Mimir, Prometheus, with automatic TLS and DNS."
echo ""
read -p "Continue? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    exit 1
fi

# Check prerequisites
echo "Checking prerequisites..."

# Check for kubectl
if ! command -v kubectl &>/dev/null; then
    echo "❌ kubectl not found. Please install kubectl first."
    exit 1
fi

# Check cluster connectivity
if ! kubectl cluster-info &>/dev/null; then
    echo "❌ Cannot connect to Kubernetes cluster. Please configure kubectl."
    exit 1
fi

# Get cluster info
CLUSTER_NAME=$(kubectl config current-context)
echo "✅ Connected to cluster: $CLUSTER_NAME"

# Install required tools
echo ""
echo "Installing required tools..."
./scripts/install-tools.sh

# Verify storage class
echo ""
echo "Checking for storage class..."
if ! kubectl get storageclass local-path &>/dev/null; then
    echo "⚠️  No 'local-path' storage class found."
    echo "Installing local-path-provisioner..."
    kubectl apply -f https://raw.githubusercontent.com/rancher/local-path-provisioner/v0.0.24/deploy/local-path-storage.yaml
    sleep 5
fi

# Create namespace
echo ""
echo "Creating monitoring namespace..."
kubectl create namespace monitoring --dry-run=client -o yaml | kubectl apply -f -

# Start Tilt
echo ""
echo "Starting Tilt..."
echo "This will take 5-10 minutes on first run (downloading images)."
echo ""
echo "Watch progress at: http://localhost:10350"
echo ""

tilt up --legacy=false

echo ""
echo "✅ LGTM Stack is running!"
echo ""
echo "Access Grafana: https://grafana.home.lab (or via kubectl port-forward)"
echo "Default credentials: admin / admin (change on first login)"
echo ""
echo "To trust the TLS certificate:"
echo "  ./scripts/export-ca.sh"
echo ""
echo "To stop the stack:"
echo "  tilt down"
