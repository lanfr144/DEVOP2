# Unité 02 – Comment vérifier

## 1. Lancer

Ces commandes se tapent **sur la machine** (WSL ou Git Bash), pas dans un conteneur : elles pilotent Docker.

```bash
cd Unit02
./start.sh                       # .env, ports libres, démarrage (1 à 3 minutes la première fois)
./kibana/create_dashboard.sh     # crée ou met à jour le dashboard
./test_p02.sh 2>&1 | tee test_p02_output.txt
```

## 2. Ce que tu dois voir

| Commande | Résultat attendu |
|---|---|
| `./start.sh` | `FREE` pour les 3 ports, puis `elasticsearch`, `kibana` et `tools` en `(healthy)` |
| `./kibana/create_dashboard.sh` | une ligne JSON avec `"success":true` et `"successCount":6` |
| `./test_p02.sh` | 10 lignes `PASS`, puis `=== ALL TESTS PASSED` ; on y lit 15 documents, 3 services, 5 erreurs |

Dans le navigateur, <http://localhost:5602/app/dashboards#/view/p02-dashboard> (utilisateur `elastic`, mot de passe `PASSWORD_ELASTIC` du `.env`) :

| Panneau | Ce qu'il doit montrer |
|---|---|
| P02 - Logs by service | 3 barres (auth-api, orders-api, payment-api) de 5 logs chacune, découpées par niveau |
| P02 - Logs by level | anneau : INFO 6, ERROR 5, WARN 4 |
| P02 - Errors by service | barres dont le total fait 5 |
| P02 - Logs over time | barres réparties sur la journée du 12/10/2026 |

Si un panneau affiche une erreur : *Edit* sur le panneau, corriger dans Lens, *Save and return*. Les quatre panneaux ont été vus remplis le 15/11 (voir `dashboard.png`).

Dans *Discover* : période « Last 1 year », requête `level : "ERROR"` → 5 documents.

## 3. Fichiers à contrôler

| Fichier | Ce qu'il faut y vérifier |
|---|---|
| `P02_DELIVERABLE.md` | **le livrable** : comparaison Unit 01 / Unit 02 (4 à 6 phrases), description des parties A et B |
| `dashboard.png` | capture du dashboard : les quatre panneaux sont remplis (INFO 6, ERROR 5, WARN 4) |
| `query_a_search.json`, `query_b_filter.json`, `query_c_agg_level.json`, `query_custom_agg.json` | les 4 sorties JSON ; `test_p02.sh` les compare au résultat réel |
| `logs-demo-export.json` | 15 documents |
| `docker-compose.yml` | aucun mot de passe ni jeton en clair ; ports sur `127.0.0.1` ; Kibana se connecte avec `kibana_system` |
| `Elasticsearch.docx` | ton rapport pas à pas : aucun mot de passe lisible, y compris dans les captures |
| `.env.example` / `.env` | factice / réel ; `.env` absent de `git status` |

## 4. Ce qui manque

- `LISEZMOI.md` est une copie de celui de l'unité 03 (exclu de Git) : à supprimer.
