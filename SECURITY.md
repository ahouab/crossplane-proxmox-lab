# Politique de sécurité

## Signaler un problème

Ne publie pas de vulnérabilité ni de secret dans une issue publique. Utilise la
fonction **Security advisories > Report a vulnerability** du dépôt. Si elle n'est
pas activée, contacte le mainteneur du dépôt par un canal privé.

Le signalement doit contenir une description, les versions concernées, les
conditions de reproduction et une proposition de correction si disponible. Ne
joins jamais de token Proxmox, kubeconfig ou clé privée réel.

## Secret exposé

Si un secret réel a été commité ou poussé :

1. révoque ou renouvelle immédiatement le secret dans Proxmox ;
2. supprime-le du contenu et de l'historique Git ;
3. vérifie les journaux d'accès Proxmox ;
4. documente l'incident par le canal privé de sécurité.

Retirer seulement le fichier du dernier commit ne suffit pas : les anciennes
révisions Git restent accessibles.

## Périmètre

Ce dépôt est un laboratoire éducatif et n'offre aucune garantie de support ou de
compatibilité de production. Le provider Proxmox utilisé est communautaire.
