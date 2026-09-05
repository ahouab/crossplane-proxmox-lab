# Contribuer

Merci de contribuer à ce laboratoire Crossplane pour Proxmox.

## Avant toute modification

- n'ajoute jamais de token, mot de passe, kubeconfig, clé privée ou certificat
  privé au dépôt ;
- conserve des VMID d'exemple et des adresses réservées à la documentation ;
- teste uniquement sur une infrastructure de laboratoire ;
- garde les ressources Kubernetes namespaced lorsque c'est possible.

## Développement

```bash
git switch -c type/description-courte
make validate
```

Types de branche suggérés : `docs/`, `fix/`, `feat/` et `chore/`.

Avant la pull request :

```bash
git diff --check
git status --short
make validate
```

La pull request doit expliquer le besoin, les changements, le test effectué et
l'impact éventuel sur la création ou la suppression de ressources Proxmox.

## Test réel

Les tests CI ne contactent jamais Proxmox. Toute validation réelle doit être
faite avec un cluster et des VMID de laboratoire. Ne colle pas de journaux
contenant un endpoint privé ou un identifiant dans une issue publique.
