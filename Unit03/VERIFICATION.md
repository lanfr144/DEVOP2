# Unité 03 – Comment vérifier

## 1. Lancer

```bash
cd Unit03
./start.sh
docker exec -it unit03-tools-1 bash      # un shell dans le conteneur
python app.py                            # dev (par défaut)
APP_ENV=staging python app.py
APP_ENV=prod python app.py
APP_ENV=qa python app.py                 # doit échouer
./test_p03.sh 2>&1 | tee test_p03_output.txt
```

## 2. Ce que tu dois voir

| Commande | Résultat attendu |
|---|---|
| `python app.py` | `[DEBUG MODE] Verbose logs enabled`, base `dev_db`, clé `dev-... (masked)` |
| `APP_ENV=staging python app.py` | `[DEBUG MODE]`, base `staging_db`, clé `stag... (masked)` |
| `APP_ENV=prod python app.py` | `[PRODUCTION MODE] Logging minimal`, base `prod_db`, clé `prod... (masked)` |
| `APP_ENV=qa python app.py` | `ValueError: Invalid APP_ENV: qa. Choose from ['dev', 'staging', 'prod']` |
| `./test_p03.sh` | 8 lignes `PASS`, puis `=== ALL TESTS PASSED` |

Dans toutes les sorties, le mot de passe de la base est remplacé par `****`.

## 3. Fichiers à contrôler

| Fichier | Ce qu'il faut y vérifier |
|---|---|
| `config.yaml` | exercice 1 : 3 environnements, chacun avec `DB_URL`, `API_KEY`, `DEBUG` ; indentation de 2 espaces ; `true` / `false` en minuscules ; valeurs factices |
| `config_loader.py` | exercice 2 : `dev` par défaut, `ValueError` si l'environnement n'existe pas, `DEBUG` converti en booléen |
| `app.py` | exercice 3 : affiche le mode, masque le mot de passe et la clé |
| `terminal_output_3_envs.txt` | **livrable** : la sortie des 3 environnements, identique à ce que tu obtiens |
| `P03_DELIVERABLE.md` | **le livrable** ; il doit dire que les environnements sont sous la clé `environments:` (le PDF les met à la racine) |
| `config_bad.yaml`, `.env.bad` | fichiers volontairement faux, utilisés par les tests 5 et 7 : ne pas les corriger |
| `.env.dev`, `.env.staging`, `.env.prod` | variante `.env` (`loader_env.py`) ; absents de `git status` |

## 4. Ce qui manque

Rien. `term` est un brouillon (exclu de Git).
