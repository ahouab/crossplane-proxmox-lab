#!/usr/bin/env bash
set -euo pipefail

TEMPLATE_VMID="${TEMPLATE_VMID:-9000}"
TEMPLATE_NAME="${TEMPLATE_NAME:-ubuntu-2404-cloudinit}"
VM_STORAGE="${VM_STORAGE:-local-lvm}"
VM_BRIDGE="${VM_BRIDGE:-vmbr0}"
IMAGE_URL="${IMAGE_URL:-https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img}"
IMAGE_PATH="${IMAGE_PATH:-/var/lib/vz/template/iso/noble-server-cloudimg-amd64.img}"

if [[ "${EUID}" -ne 0 ]]; then
  echo "Ce script doit etre execute en root sur le noeud Proxmox." >&2
  exit 1
fi

for command_name in qm pvesm wget virt-customize; do
  if ! command -v "${command_name}" >/dev/null 2>&1; then
    echo "Commande manquante: ${command_name}" >&2
    echo "Pour virt-customize: apt update && apt install -y libguestfs-tools" >&2
    exit 1
  fi
done

if qm status "${TEMPLATE_VMID}" >/dev/null 2>&1; then
  echo "Le VMID ${TEMPLATE_VMID} existe deja. Aucun changement effectue." >&2
  exit 1
fi

if ! pvesm status --storage "${VM_STORAGE}" >/dev/null 2>&1; then
  echo "Stockage Proxmox introuvable: ${VM_STORAGE}" >&2
  exit 1
fi

if [[ ! -e "/sys/class/net/${VM_BRIDGE}" ]]; then
  echo "Bridge Proxmox introuvable: ${VM_BRIDGE}" >&2
  exit 1
fi

mkdir -p "$(dirname "${IMAGE_PATH}")"
wget --https-only --continue --output-document "${IMAGE_PATH}" "${IMAGE_URL}"

# Le provider attend le Guest Agent pour publier l'adresse IP de la VM.
virt-customize -a "${IMAGE_PATH}" \
  --install qemu-guest-agent \
  --run-command 'systemctl enable qemu-guest-agent'

qm create "${TEMPLATE_VMID}" \
  --name "${TEMPLATE_NAME}" \
  --ostype l26 \
  --memory 2048 \
  --cores 2 \
  --cpu host \
  --net0 "virtio,bridge=${VM_BRIDGE}" \
  --agent enabled=1 \
  --scsihw virtio-scsi-single

qm importdisk "${TEMPLATE_VMID}" "${IMAGE_PATH}" "${VM_STORAGE}"
qm set "${TEMPLATE_VMID}" --scsi0 "${VM_STORAGE}:vm-${TEMPLATE_VMID}-disk-0"
qm set "${TEMPLATE_VMID}" --ide2 "${VM_STORAGE}:cloudinit"
qm set "${TEMPLATE_VMID}" --boot order=scsi0
qm set "${TEMPLATE_VMID}" --serial0 socket --vga serial0
qm template "${TEMPLATE_VMID}"

echo "Template ${TEMPLATE_NAME} cree avec le VMID ${TEMPLATE_VMID}."
