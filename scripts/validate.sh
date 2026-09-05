#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${PROJECT_ROOT}"

for command_name in python3 yamllint shellcheck; do
  if ! command -v "${command_name}" >/dev/null 2>&1; then
    echo "Validateur manquant: ${command_name}" >&2
    echo "Consulte la section 'Préparer le dossier' de docs/PUBLICATION_GITHUB.md." >&2
    exit 1
  fi
done

yamllint --strict -c .yamllint.yml manifests .github
shellcheck scripts/*.sh
bash -n scripts/*.sh
python3 scripts/validate_yaml.py

GIT_ROOT=""
if command -v git >/dev/null 2>&1; then
  GIT_ROOT="$(git -C "${PROJECT_ROOT}" rev-parse --show-toplevel 2>/dev/null || true)"
fi

if [[ "${GIT_ROOT}" == "${PROJECT_ROOT}" ]]; then
  TRACKED_FILES="$(git ls-files)"
  if grep -E '(^|/)(secrets/|kubeconfig)|\.(key|pem|p12|pfx)$|credentials.*\.(json|ya?ml)$' <<<"${TRACKED_FILES}"; then
    echo "Un fichier potentiellement sensible est suivi par Git." >&2
    exit 1
  fi
fi

if grep -RIlE --exclude-dir=.git -- '-----BEGIN (RSA |OPENSSH |EC )?PRIVATE KEY-----' .; then
  echo "Une cle privee semble presente dans le depot." >&2
  exit 1
fi

echo "Validation terminee avec succes."
