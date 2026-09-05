#!/usr/bin/env python3
"""Validation légère des manifests du laboratoire, sans contacter un cluster."""

from pathlib import Path
import sys

import yaml


ROOT = Path(__file__).resolve().parent.parent
MANIFESTS = ROOT / "manifests"
REQUIRED = {
    "00-namespace.yaml",
    "01-provider.yaml",
    "02-providerconfig.yaml",
    "03-managed-vm.yaml",
    "04-functions.yaml",
    "05-xrd.yaml",
    "06-composition.yaml",
    "07-xr.yaml",
}


def main() -> int:
    found = {path.name for path in MANIFESTS.glob("*.yaml")}
    missing = sorted(REQUIRED - found)
    if missing:
        print(f"Manifests manquants: {', '.join(missing)}", file=sys.stderr)
        return 1

    errors: list[str] = []
    documents = 0
    for path in sorted(MANIFESTS.glob("*.yaml")):
        try:
            loaded = list(yaml.safe_load_all(path.read_text(encoding="utf-8")))
        except yaml.YAMLError as error:
            errors.append(f"{path.relative_to(ROOT)}: {error}")
            continue

        for index, document in enumerate(loaded, start=1):
            if not isinstance(document, dict):
                errors.append(f"{path.relative_to(ROOT)} document {index}: objet YAML attendu")
                continue
            for field in ("apiVersion", "kind", "metadata"):
                if field not in document:
                    errors.append(
                        f"{path.relative_to(ROOT)} document {index}: champ {field} manquant"
                    )
            documents += 1

    if errors:
        print("\n".join(errors), file=sys.stderr)
        return 1

    print(f"{documents} documents YAML valides.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
