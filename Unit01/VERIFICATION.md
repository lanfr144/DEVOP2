# Unité 01 – Comment vérifier

## 1. Lancer

Ces commandes se tapent **sur la machine** (WSL ou Git Bash), pas dans un conteneur : elles pilotent Docker.

```bash
cd Unit01
./start.sh          # .env, ports libres, démarrage, attend les healthchecks
./run_queries.sh    # les 3 requêtes de l'exercice
./test_p01.sh 2>&1 | tee test_p01_output.txt
```

## 2. Ce que tu dois voir

| Commande | Résultat attendu |
|---|---|
| `./start.sh` | `FREE` pour `MONGO_HOST_PORT` et `EXPRESS_HOST_PORT`, puis `mongo`, `mongo-express` et `tools` en `(healthy)` |
| `./run_queries.sh` | dernière ligne : `RESULT q1=3 q2=5 q3=auth-api,orders-api,payment-api` |
| `./test_p01.sh` | 8 lignes `PASS`, puis `=== ALL TESTS PASSED` |
| <http://localhost:8082> | page mongo-express après identification (`EXPRESS_BASICAUTH_USER` / `PASSWORD_EXPRESS_BASICAUTH` du `.env`) ; base `unit01`, collection `logs`, 10 documents |

Si `./start.sh` affiche `BUSY`, change le port indiqué dans `.env` et relance.

## 3. Fichiers à contrôler

| Fichier | Ce qu'il faut y vérifier |
|---|---|
| `P01_DELIVERABLE.md` | **le livrable** : les 3 requêtes, leurs sorties, le paragraphe d'interprétation (4 à 6 phrases), ton nom |
| `queries.js` | l'heure de référence est bien `2025-09-18T10:00:00Z` et la fenêtre fait 24 h |
| `queries_output.txt` | sortie identique à ce que `./run_queries.sh` affiche aujourd'hui |
| `docker-compose.yml` | aucun mot de passe en clair ; ports pris dans `.env` ; un `healthcheck` par service |
| `.env.example` | valeurs factices seulement (`PASSWORD_MONGO_ROOT=PASSWORD_MONGO_ROOT`) |
| `.env` | tes vrais mots de passe ; **ne doit pas** apparaître dans `git status` |
| `logs.ndjson` | 10 lignes, non modifié (jeu de données imposé) |
| `Unit 01 - API Basics.docx` | réponse « JSON keys must always be strings » = **True** |

## 4. Ce qui manque

- La frise « un jalon DevOps » (exercice A) est rédigée : le PDF à rendre est `devopsMilestone.pdf` (une page) ; à relire et à préparer pour le résumé oral de 5 minutes.
- `todo.sh` est un brouillon de notes : à retirer si tu ne veux pas qu'il soit publié.
