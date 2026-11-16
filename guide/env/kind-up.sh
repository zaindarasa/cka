#!/usr/bin/env bash
# Create the standard 3-node kind cluster "lab" with Calico.
set -euo pipefail
here=$(dirname "$0")
kind create cluster --name lab --config "$here/kind.yaml"
kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.33.0/manifests/calico.yaml
kubectl -n kube-system rollout status ds/calico-node --timeout=600s
kubectl wait --for=condition=Ready nodes --all --timeout=300s

# On macOS/Windows Docker backends that do not pass IP-protocol-4 between
# nodes (OrbStack, Docker Desktop), Calico's default IPIP encapsulation breaks
# pod->ClusterIP replies: CoreDNS and local-path-provisioner stay unhealthy.
# All kind nodes share one L2 bridge, so no-encap is safe:
kubectl patch ippool default-ipv4-ippool --type=merge \
  -p '{"spec":{"ipipMode":"Never","vxlanMode":"Never"}}' || true
