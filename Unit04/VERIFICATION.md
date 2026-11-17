# Unité 04 – Comment vérifier

Le labo n'est pas encore fait. Cette fiche dit quoi contrôler une fois qu'il le sera.

## 1. Lancer

```bash
cd Unit04
./start.sh                               # remplit .env depuis git et gh de la machine
docker exec -it unit04-tools-1 bash
git init release-strategies-lab && cd release-strategies-lab    # puis l'énoncé 04b, parties 1 à 4
```

## 2. Ce que tu dois voir à la fin du labo

Dans `release-strategies-lab/` :

| Commande | Résultat attendu |
|---|---|
| `git tag` | `v1.0.0`, `v1.1.0`, `v2.0.0` |
| `git show v2.0.0:app.py` | la fonction `start_app()` |
| `git branch -a` | `main`, `blue`, `green` |
| `cat deployment.txt` (sur `main`) | `Green version running` |
| `git log --oneline --graph --all` | les commits blue et green, 3 commits « Rolling update », 1 commit « Canary », 1 commit « Revert » |
| `cat server1/version.txt` | `v1.1.0` (le canary est annulé) ; `server2` et `server3` aussi en `v1.1.0` |
| `git log --oneline --grep '^Revert'` | une ligne : le commit du canary est annulé, pas effacé |
| `git ls-remote --tags origin` | les 3 tags sont sur GitHub |

## 3. Fichiers à contrôler

| Fichier | Ce qu'il faut y vérifier |
|---|---|
| `release-strategies-lab/RELEASE_NOTES.md` | titres Markdown (`# Release Notes`, `## v2.0.0 …`), version la plus récente en haut, changement cassant signalé |
| `RELEASE_NOTES.md` (dans `Unit04/`) | brouillon actuel : il lui manque les `#` et `##` |
| `app.py` | état v2.0.0 (`start_app()`) |
| `P04_DELIVERABLE` (PDF ou DOCX) | **à créer** : lien du dépôt en haut ; sortie de `git log --oneline --graph --all` ; réponses aux questions des parties 1 à 4 ; 4 questions de debrief ; paragraphe de 5 à 8 lignes sur la stratégie pour 10 000 utilisateurs par jour |
| `.env` | `GIT_USER_NAME`, `GIT_USER_EMAIL`, `GH_TOKEN` remplis ; absent de `git status` |

## 4. Ce qui manque

Tout le labo et le document de réponses. Optionnel (04c, GitKraken) : capture du graphe avec le commit et son revert, lien de la branche `release-<prénom>-1.2`, deux phrases.
