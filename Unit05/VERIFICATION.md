# Unité 05 – Comment vérifier

## 1. Lancer

```bash
cd Unit05
./start.sh                               # remplit .env depuis git et gh de la machine
docker exec -it unit05-tools-1 bash
./TestUnit5.sh 2>&1 | tee TestUnit5_output.txt
```

Avant : `gh auth refresh -h github.com -s delete_repo` sur la machine, sinon le script ne peut pas supprimer son dépôt d'essai.

## 2. Ce que tu dois voir

| Où | Résultat attendu |
|---|---|
| `./start.sh` | `SET` ou `KEEP` pour `GIT_USER_NAME`, `GIT_USER_EMAIL`, `GH_TOKEN` (aucun `MISS`), puis `tools` en `(healthy)` |
| Début de la sortie | `Authenticated GitHub User: lanfr144` |
| Partie 3 | après `git restore app.txt`, le fichier ne contient plus `Temporary change` |
| Partie 4 | après `git reset app.txt`, `New feature` est dans le fichier mais plus dans la zone 2 (staging) |
| Partie 5 | un commit `Revert "Add bug"` ; `Bug` a disparu du fichier, le commit `Add bug` reste dans l'historique |
| Partie 6 | soft : `Secret data` reste en zone 2 ; mixed : seulement en zone 1 ; hard : disparu partout |
| Partie 7 | `git reflog` montre le commit perdu ; après `git reset --hard <hash>`, `Secret data` est revenu |
| Partie 8 | `app.txt` supprimé puis restauré, deux fois |
| Partie 9 | `Revert "v2.0.0"` poussé ; puis `## main...origin/main [behind 2]` après le reset local ; **aucune** ligne `$ git push --force` |
| Partie 10 | `Apply hotfix` fusionné dans `main` et poussé |
| Fin | `ALL LAB EXERCISES COMPLETED`, puis `Successfully deleted remote repository` et `Successfully deleted local directory` |

Contrôles rapides sur la sortie enregistrée :

```bash
grep -c '❌' TestUnit5_output.txt                    # 0
grep -c '\$ git push --force' TestUnit5_output.txt   # 0
grep 'ALL LAB EXERCISES COMPLETED' TestUnit5_output.txt
```

## 3. Fichiers à contrôler

| Fichier | Ce qu'il faut y vérifier |
|---|---|
| `TestUnit5.sh` | le script du labo ; pas de `git push --force` exécuté |
| `TestUnit5_output.txt` | **à créer** en lançant le script : c'est la preuve du cheminement |
| `P05_THEORY_ANSWERS.txt` | les 7 réponses théoriques ; à relire et reformuler avec tes mots |
| `README.md` | explication des 4 zones Git et du tableau des parties ; cohérent avec le script (`TestProj`, dépôt public) |
| `.env` | `GIT_USER_NAME`, `GIT_USER_EMAIL`, `GH_TOKEN` remplis ; absent de `git status` |

## 4. Ce qui manque

- `TestUnit5_output.txt`.
- Les réponses aux questions posées dans les parties 2 à 8 de l'énoncé v2 et aux 4 questions de debrief.
- `MyTestUnit5.sh` est un brouillon (exclu de Git) : ne pas le lancer, il supprimerait le dépôt `lanfr144/DEVOP2`.
