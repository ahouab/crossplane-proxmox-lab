# Publier ce laboratoire sur GitHub

Cette procédure publie le projet sans envoyer de secret Proxmox.

## 1. Préparer le dossier

Place-toi à la racine, là où se trouvent `README.md`, `Makefile` et `manifests/` :

```bash
cd tp-crossplane-proxmox
python3 -m venv .venv
source .venv/bin/activate
python -m pip install -r .github/requirements-ci.txt
sudo apt-get update
sudo apt-get install shellcheck
make validate
```

Vérifie qu'aucun secret réel n'a remplacé les valeurs d'exemple :

```bash
grep -RInE --exclude-dir=.git --exclude=README.md \
  'BEGIN .*PRIVATE KEY|api_token|password' . || true
find . -type f \( -name '*.key' -o -name '*.pem' -o -name 'kubeconfig*' \)
```

La commande `find` ne doit rien retourner. Le token Proxmox doit uniquement
exister dans le Secret du cluster créé par `scripts/02-create-provider-secret.sh`.

## 2. Initialiser Git

Configure ton identité Git si elle ne l'est pas déjà :

```bash
git config --global user.name "TON NOM"
git config --global user.email "TON-EMAIL-GITHUB"
```

Initialise le dépôt et contrôle exactement ce qui sera publié :

```bash
git init -b main
git add .
git status
git diff --cached --check
git commit -m "Initial commit: Crossplane Proxmox lab"
```

Ne poursuis pas si `git status` affiche un Secret, une clé privée, un kubeconfig
ou un fichier `.env`.

## 3A. Publication avec GitHub CLI — recommandé

Installe `gh`, puis authentifie-toi :

```bash
gh auth login
gh auth status
```

Crée d'abord un dépôt privé :

```bash
gh repo create crossplane-proxmox-lab \
  --private \
  --source=. \
  --remote=origin \
  --push \
  --description "TP complet pour piloter Proxmox VE avec Crossplane 2"
```

Ouvre le dépôt :

```bash
gh repo view --web
```

Après vérification du contenu et de l'historique, tu peux le rendre public dans
**Settings > General > Danger Zone > Change repository visibility**.

## 3B. Publication sans GitHub CLI

Sur GitHub, crée un dépôt vide nommé `crossplane-proxmox-lab`. Ne demande pas à
GitHub d'ajouter un README, une licence ou un `.gitignore`, car ils existent déjà.

Puis exécute :

```bash
git remote add origin https://github.com/TON-COMPTE/crossplane-proxmox-lab.git
git remote -v
git push -u origin main
```

Avec SSH :

```bash
git remote set-url origin git@github.com:TON-COMPTE/crossplane-proxmox-lab.git
git push -u origin main
```

## 4. Configurer le dépôt GitHub

Dans **Settings** :

1. active les Issues si tu veux recevoir des retours ;
2. active **Security > Private vulnerability reporting** ;
3. active Secret scanning et Push protection lorsqu'ils sont disponibles ;
4. crée une règle de branche pour `main` ;
5. exige une pull request et le contrôle CI `validate` avant fusion ;
6. désactive les force-push et la suppression de `main` ;
7. laisse les permissions GitHub Actions en lecture seule : cette CI ne déploie rien.

Le workflow `.github/workflows/validate.yml` vérifie les YAML, les scripts et les
fichiers sensibles. Il ne possède aucun secret et ne se connecte pas à Proxmox.

## 5. Description et sujets suggérés

Description :

```text
TP complet pour installer Crossplane 2 sur Kubernetes et gérer des VM Proxmox VE via le provider BPG.
```

Topics :

```text
crossplane proxmox kubernetes k3s infrastructure-as-code platform-engineering homelab
```

Avec GitHub CLI :

```bash
gh repo edit --add-topic crossplane,proxmox,kubernetes,k3s,infrastructure-as-code,platform-engineering,homelab
```

## 6. Créer la première version

Lorsque le workflow `validate` est vert :

```bash
git tag -a v1.0.0 -m "Première version du TP Crossplane Proxmox"
git push origin v1.0.0
gh release create v1.0.0 --generate-notes --title "Crossplane Proxmox Lab v1.0.0"
```

## 7. Cycle de modification

```bash
git switch -c docs/amelioration-tp
# Modifier les fichiers.
make validate
git add .
git commit -m "docs: améliore la procédure du TP"
git push -u origin docs/amelioration-tp
gh pr create --fill
```

Après fusion :

```bash
git switch main
git pull --ff-only
```

## 8. Ce qui ne doit jamais aller sur GitHub

- la valeur du token `crossplane@pve!provider=...` ;
- un export du Secret `proxmox-credentials` ;
- `/etc/rancher/k3s/k3s.yaml` ou tout kubeconfig ;
- une clé SSH privée ;
- des sauvegardes ou dumps Proxmox ;
- des journaux contenant des informations privées non nettoyées.

Si un secret a déjà été poussé, considère-le compromis et renouvelle-le avant de
nettoyer l'historique.
