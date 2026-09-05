#!/usr/bin/env bash
set -euo pipefail

NAMESPACE="${NAMESPACE:-crossplane-lab}"

echo "Pods Crossplane"
kubectl get pods -n crossplane-system -o wide

echo
echo "Packages"
kubectl get providers.pkg.crossplane.io,functions.pkg.crossplane.io

echo
echo "Configuration Proxmox"
kubectl get providerconfig.proxmoxbpg.m.crossplane.io -n "${NAMESPACE}"

echo
echo "API et Composition"
kubectl get xrd,composition

echo
echo "Ressources du laboratoire"
kubectl get virtualmachines.lab.example.org,environmentvms.virtualenvironmentvm.proxmoxbpg.m.crossplane.io \
  -n "${NAMESPACE}" 2>/dev/null || true

echo
echo "Derniers evenements"
kubectl get events -n "${NAMESPACE}" --sort-by=.lastTimestamp | tail -30
