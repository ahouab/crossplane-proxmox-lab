SHELL := /usr/bin/env bash

NAMESPACE ?= crossplane-lab
CROSSPLANE_VERSION ?= 2.4.0

.DEFAULT_GOAL := help

.PHONY: help validate preflight install-crossplane install-provider create-secret
.PHONY: configure-provider create-direct-vm install-platform create-composite-vm status
.PHONY: delete-vms uninstall-platform uninstall-crossplane

help: ## Affiche les commandes disponibles
	@awk 'BEGIN {FS = ":.*## "; printf "\nCommandes disponibles :\n\n"} /^[a-zA-Z0-9_-]+:.*## / {printf "  %-24s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

validate: ## Valide les scripts, les YAML et l'absence de secrets suivis par Git
	bash scripts/validate.sh

preflight: ## Vérifie les outils locaux et les placeholders obligatoires
	@for tool in kubectl helm jq; do command -v "$$tool" >/dev/null || { echo "Outil manquant: $$tool"; exit 1; }; done
	@kubectl cluster-info >/dev/null
	@if grep -R "AAAA_A_REMPLACER" manifests/03-managed-vm.yaml manifests/07-xr.yaml >/dev/null; then \
		echo "Remplace d'abord AAAA_A_REMPLACER par ta cle SSH publique."; exit 1; \
	fi

install-crossplane: ## Installe Crossplane dans le cluster courant
	helm repo add crossplane-stable https://charts.crossplane.io/stable --force-update
	helm repo update
	helm upgrade --install crossplane crossplane-stable/crossplane \
		--namespace crossplane-system --create-namespace \
		--version "$(CROSSPLANE_VERSION)" --wait --timeout 10m

install-provider: ## Installe le provider Proxmox et attend son état Healthy
	kubectl apply -f manifests/00-namespace.yaml
	kubectl apply -f manifests/01-provider.yaml
	kubectl wait --for=condition=Healthy provider.pkg.crossplane.io/provider-proxmox-bpg --timeout=10m

create-secret: ## Demande le token Proxmox et crée directement le Secret Kubernetes
	NAMESPACE="$(NAMESPACE)" bash scripts/02-create-provider-secret.sh

configure-provider: ## Crée le ProviderConfig namespaced
	kubectl apply -f manifests/02-providerconfig.yaml

create-direct-vm: preflight ## Crée la VM Managed Resource 9110
	kubectl apply -f manifests/03-managed-vm.yaml

install-platform: ## Installe les fonctions, l'XRD et la Composition
	kubectl apply -f manifests/04-functions.yaml
	kubectl wait --for=condition=Healthy function.pkg.crossplane.io/function-patch-and-transform --timeout=10m
	kubectl wait --for=condition=Healthy function.pkg.crossplane.io/function-auto-ready --timeout=10m
	kubectl apply -f manifests/05-xrd.yaml
	kubectl wait --for=condition=Established xrd/virtualmachines.lab.example.org --timeout=2m
	kubectl apply -f manifests/06-composition.yaml

create-composite-vm: preflight ## Crée la VM 9120 avec l'API composite
	kubectl apply -f manifests/07-xr.yaml

status: ## Affiche l'état complet du laboratoire
	NAMESPACE="$(NAMESPACE)" bash scripts/check.sh

delete-vms: ## Supprime les demandes de VM et attend leur suppression dans Proxmox
	kubectl delete -f manifests/07-xr.yaml --ignore-not-found
	kubectl delete -f manifests/03-managed-vm.yaml --ignore-not-found
	kubectl wait --for=delete environmentvm --all -n "$(NAMESPACE)" --timeout=10m

uninstall-platform: ## Retire la Composition, l'XRD, les fonctions et le provider
	kubectl delete -f manifests/06-composition.yaml --ignore-not-found
	kubectl delete -f manifests/05-xrd.yaml --ignore-not-found
	kubectl delete -f manifests/04-functions.yaml --ignore-not-found
	kubectl delete -f manifests/02-providerconfig.yaml --ignore-not-found
	kubectl delete secret proxmox-credentials -n "$(NAMESPACE)" --ignore-not-found
	kubectl delete -f manifests/01-provider.yaml --ignore-not-found
	kubectl delete -f manifests/00-namespace.yaml --ignore-not-found

uninstall-crossplane: ## Désinstalle Crossplane du cluster courant
	helm uninstall crossplane -n crossplane-system
