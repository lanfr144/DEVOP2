# DEVOP2 – Exercices

État au 15/11/2026. Ce fichier explique chaque exercice à quelqu'un qui débute, dit ce qui est fait, ce qui manque et ce qu'il faut rendre.
Le détail des corrections du 26/10 (P01 à P03) reste dans `PLAN.md`.

## 1. Où en est-on

| Unité | Sujet | État | Reste à faire |
|---|---|---|---|
| 01-A | Frise « un jalon DevOps » (1 page) | 🟡 PDF rédigé (`Unit01/devopsMilestone.pdf`) | Relire `Unit01/devopsMilestone.pdf`, préparer l'oral de 5 minutes |
| 01-B | Logs dans MongoDB (P01) | ✅ fait, testé 8/8 | Rien |
| 01 | API Basics (HTTP, JSON, gRPC) | ✅ réponses dans le docx | Corriger une réponse (voir §3) |
| 02 | Elasticsearch + Kibana (P02) | ✅ fait, dashboard à 4 panneaux capturé | Relancer `./test_p02.sh` pour mettre à jour sa sortie |
| 03 | Configuration par environnement (P03) | ✅ fait, testé 8/8 dans Docker le 16/11 | Rien |
| 04b | Release management (P04) | ❌ pas fait | Tout le labo + le document de réponses |
| 04 | Labo API Gateway (NGINX devant Book&Ride, extraction du service rentals) | ❌ pas commencé ; le projet `bookandride` de départ n'est pas dans ce dossier | Retrouver le monolithe Book&Ride, faire les 4 checkpoints, README, ADR-001, ADR-002, 5 réponses |
| 04c | GitKraken (optionnel) | ❌ pas fait | Capture du graphe, lien de branche, 2 phrases |
| 05 | Rollbacks Git (P05) | 🟡 script + 7 réponses théoriques | Sortie du script enregistrée, réponses aux questions des parties (voir §3) |
| 06 | Évaluation 1 (logs, config, release, rollback) | – | Dépend de P02 à P05 |
| 07 | Packaging Python | ❌ pas commencé | Paquet + 1 test + preuve `pip install -e .` |
| 08 | CI/CD (Jenkins / GitHub Actions) | ❌ pas commencé | Pipeline sur un dépôt à toi |
| 09 et suivantes | Docker, métriques, alerting, IaC | – | Pas encore de support dans `COURS/` |

Ce que je n'ai pas pu vérifier : l'état de tes dépôts GitHub (pas d'accès réseau à GitHub depuis cette session). D'après `PLAN.md`, `release-strategies-lab` ne contenait que « Initial commit » le 26/10.

## 2. Tout tourne dans Docker

Sur la machine il ne faut que **Docker** et un terminal **bash** (WSL ou Git Bash) pour lancer les scripts `*.sh`. Python, pyyaml, pymongo, curl, git, gh : tout est dans l'image `devop2-tools` (`docker/Dockerfile`). `mongosh` est déjà dans le conteneur `mongo`.

Dans chaque unité :

```bash
cd UnitXX
./start.sh            # 1) .env  2) ports libres ?  3) docker compose up -d --build --wait
docker compose exec tools <commande>     # lancer un outil dans le conteneur
docker compose down   # arrêter
```

- **`.env` et `.env.example`** : `.env.example` est le modèle versionné (valeurs factices). `./start.sh` le copie en `.env` s'il manque. Unités 01 et 02 : il s'arrête pour que tu mettes tes mots de passe. Unités 04 et 05 : il remplit `GIT_USER_NAME`, `GIT_USER_EMAIL` et `GH_TOKEN` depuis la machine (`git config --global`, `gh auth token`) et dit ce qui manque. `.env` ne part jamais dans Git.
- **Si le démarrage échoue** : `./start.sh` affiche un diagnostic (état, contrôles de santé, fin des journaux, réseaux), puis arrête et supprime tous les conteneurs de l'unité (`docker compose down`, les données sont gardées). `KEEP_ON_FAILURE=1 ./start.sh` les laisse tourner pour enquêter.
- **Suite** : à la fin, `./start.sh` affiche les commandes à taper (par exemple `docker exec -it unit05-tools-1 bash` puis `./TestUnit5.sh`).
- **Ports** : tous les ports côté machine viennent de `.env` (`MONGO_HOST_PORT`, `EXPRESS_HOST_PORT`, `ES_PORT_EXPOSE`, `ES_TRANSPORT_PORT_EXPOSE`, `KIBANA_PORT_EXPOSE`). Avant de démarrer, `scripts/check_ports.sh` vérifie que chacun est libre ; sinon il nomme la variable à changer dans `.env` et rien n'est lancé. Les ports sont publiés sur `127.0.0.1` seulement.
- **Healthchecks** : chaque service en a un (mongo, mongo-express, elasticsearch, kibana, tools), et l'image `devop2-tools` a son `HEALTHCHECK` dans le Dockerfile. `up --wait` ne rend la main que lorsque tout est « healthy ».
- **Vérifier une unité** : chaque dossier a un `VERIFICATION.md` (commandes, résultat attendu, fichiers à contrôler, ce qui manque).
- **Un seul `.gitignore`**, à la racine. Les anciens `Unit01/02/03/.gitignore` sont dans `_to_delete/`.

## 3. Les exercices, un par un

### Unité 01-A – Frise d'un jalon DevOps
- **Énoncé** : `COURS/Unit01/Unit 01a - Course Introduction History-Metadata.pdf`, exercice A.
- **But** : choisir un jalon (Docker 2013, Jenkins 2011, Kubernetes 2014…) et expliquer ce qu'il a changé.
- **À rendre** : 1 page, 300 à 350 mots, PDF ou Word, avec : année et événement, présentation de la technologie, impact sur DevOps, exemple concret, 1 ou 2 références. Plus un résumé oral de 5 minutes. Noté sur 20.
- **État** : aucun fichier trouvé.

### Unité 01-B – Logs dans MongoDB (`Unit01/`)
- **Idée** : un log est une ligne JSON (date, service, niveau, utilisateur, action). On les range dans MongoDB pour pouvoir les interroger.
- **Ce qu'on apprend** : lancer une base dans Docker avec un volume (les données survivent au redémarrage) et un mot de passe ; importer des données ; écrire trois requêtes.
- **Lancer** :
  ```bash
  cd Unit01
  ./start.sh                    # .env, ports, démarrage
  ./run_queries.sh              # les 3 requêtes (mongosh du conteneur mongo)
  docker compose exec tools python log_to_mongo.py   # logs Python écrits dans MongoDB
  ./test_p01.sh                 # test complet sur une pile séparée
  ```
- **Les trois requêtes** (heure de référence imposée : 2025-09-18 10:00 UTC) : nombre d'ERROR sur 24 h → 3 ; actions de l'utilisateur U12345 → 5 ; services ayant émis un WARN → auth-api, orders-api, payment-api.
- **Piège à retenir** : `mongoimport` enregistre la date comme du texte. Une comparaison de dates ne trouve alors rien. Le script `init/01-seed-logs.js` convertit en vraie date.
- **Livrable** : `P01_DELIVERABLE.md` (requêtes, sorties, paragraphe d'interprétation) + `docker-compose.yml` (bonus mongo-express). Complet.

### Unité 01 – API Basics (`Unit01/Unit 01 - API Basics.docx`)
- **Idée** : méthodes HTTP (GET lit, POST crée, PUT remplace, PATCH modifie en partie, DELETE supprime), codes de retour (2xx succès, 4xx erreur du client, 5xx erreur du serveur), JSON, gRPC.
- **État** : questions répondues, avec les scripts Python et leurs sorties.
- **À corriger** : « JSON keys must always be strings » est noté *False* ; la bonne réponse est *True* (ton explication dit d'ailleurs que la norme l'impose).

### Unité 02 – Elasticsearch et Kibana (`Unit02/`)
- **Idée** : MongoDB stocke les logs ; Elasticsearch les rend cherchables en plein texte et sait les compter par catégorie ; Kibana en fait des graphiques.
- **Lancer** :
  ```bash
  cd Unit02
  ./start.sh
  ./kibana/create_dashboard.sh  # recrée le dashboard (curl dans le conteneur tools)
  ./test_p02.sh
  ```
- **Fait** : 15 documents dans `logs-demo` (3 services, 3 niveaux), 4 requêtes avec leur sortie (`query_*.json`), export de l'index (`logs-demo-export.json`), comparaison Unit 01 / Unit 02 dans `P02_DELIVERABLE.md`, dashboard à 2 panneaux.
- **Manque** :
  1. `Unit02/dashboard.png` : la capture du dashboard est exigée (4 points sur 20 pour « data view + dashboard »). Ouvrir <http://localhost:5602/app/dashboards#/view/p02-dashboard>, vérifier que les deux panneaux affichent des données, capturer.
  2. `Unit02/LISEZMOI.md` est une copie de celui de l'unité 03. À supprimer ou réécrire.

### Unité 03 – Configuration par environnement (`Unit03/`)
- **Idée** : le même code tourne en dev, en staging et en prod. Ce qui change (adresse de la base, clé d'API, mode debug) est sorti du code et mis dans `config.yaml`. La variable `APP_ENV` choisit le bloc.
- **Lancer** :
  ```bash
  cd Unit03
  ./start.sh
  docker compose exec tools python app.py                     # dev par défaut
  docker compose exec -e APP_ENV=staging tools python app.py
  docker compose exec -e APP_ENV=prod    tools python app.py
  docker compose exec tools ./test_p03.sh
  ```
- **Fait** : `config.yaml`, `config_loader.py`, `app.py`, sortie des 3 environnements dans `terminal_output_3_envs.txt`, variante `.env` (`loader_env.py`), version avec validation.
- **Manque** : rien. `config.yaml` (valeurs factices) n'est plus exclu par `.gitignore`.
- **À savoir** : ton `config.yaml` range les trois blocs sous une clé `environments:`, alors que le PDF de l'exercice les met à la racine. Le loader est cohérent avec ton fichier ; dis-le en une phrase dans le livrable.

### Unité 04b – Release management (`Unit04/`) — à faire
- **Énoncé à suivre** : `COURS/Unit04/Unit 04b - Release Management Lab.pdf` (version la plus récente ; celle de `EXERCISES/Unit04/…Strategies-1.pdf` est plus ancienne et n'a ni rollback ni questions).
- **Idée** : un numéro de version dit ce qui a changé. `MAJEUR.MINEUR.CORRECTIF` : correctif = bug corrigé, mineur = nouveauté compatible, majeur = ça casse l'existant. Un tag Git colle ce numéro sur un commit.
- **Les 4 parties** :
  1. Créer le dépôt `release-strategies-lab`, trois commits, trois tags `v1.0.0`, `v1.1.0`, `v2.0.0`.
  2. Écrire `RELEASE_NOTES.md` (la plus récente en haut, le changement cassant bien visible) et pousser avec `git push origin main --tags`.
  3. Simuler trois façons de déployer : blue/green (deux branches, on bascule par un merge), rolling (3 dossiers `server1..3`, un commit par serveur), canary (un seul serveur passe en v2.0.0).
  4. Annuler le canary avec `git revert --no-edit HEAD` (pas `reset` : on ne réécrit pas un historique partagé).
- **État** : seuls `app.py` (état v2.0.0) et un `RELEASE_NOTES.md` sans titres Markdown (`#`, `##`) existent. Pas de dépôt local, pas de réponses.
- **À rendre** : **un seul PDF ou DOCX avec le lien du dépôt en haut**, contenant :
  - la sortie de `git log --oneline --graph --all` après la partie 3 ;
  - les réponses aux questions des parties 1 à 4 (version d'un correctif après v2.0.0, quoi vérifier entre deux lots du rolling, métriques et seuil d'arrêt du canary…) ;
  - les 4 questions de debrief ;
  - un paragraphe de 5 à 8 lignes : quelle stratégie pour un service à 10 000 utilisateurs par jour, et pourquoi.
- Les commandes pas à pas sont dans `PLAN.md` §4. Pour les taper dans Docker : `./start.sh`, puis `docker exec -it unit04-tools-1 bash`.

### Unité 04c – GitKraken (optionnel)
- **Énoncé** : `COURS/Unit04/Unit 04c - GitKraken (optional).pdf`.
- **À faire** : se connecter à GitHub depuis GitKraken (sans copier de jeton), cloner le dépôt donné par le professeur, créer la branche `release-<prénom>-1.2` (l'ancienne consigne `1.1-release` de `GitKarken.txt` n'est plus valable), committer, pousser, puis « Revert Commit ».
- **À rendre**, dans le même document que 04b : capture du graphe montrant le commit et son revert, lien de la branche, deux phrases d'explication.

### Unité 05 – Rollbacks Git (`Unit05/`) — incomplet
- **Énoncé à suivre** : `COURS/Unit05/Unit 05 - Rollback Strategies v2.pdf` (11/11). Le PDF présent dans `EXERCISES/Unit05/` est la v1, sans livrable.
- **Idée** : selon l'endroit où se trouve l'erreur, la commande change.

  | Où est l'erreur | Commande | Risque |
  |---|---|---|
  | Fichier modifié, pas encore `git add` | `git restore fichier` | la modification est perdue |
  | Fichier ajouté (`git add`) | `git restore --staged fichier` | aucun |
  | Commit déjà partagé | `git revert <hash>` | aucun, l'historique est gardé |
  | Commit local jamais poussé | `git reset --soft / --mixed / --hard` | `--hard` efface le travail |
  | Commit « perdu » après un reset | `git reflog` puis `git reset --hard <hash>` | – |
  | Version publiée défectueuse | revert + nouveau tag, ou branche `hotfix` | – |

- **Principe du rendu** : le script crée un dépôt jetable, déroule tout le labo puis supprime le dépôt. Ce qui compte est le cheminement affiché, pas le dépôt final.
- **Ce qui existe** :
  - `TestUnit5.sh` : rejoue le labo et affiche l'état des 4 zones Git après chaque étape. Depuis le 15/11, l'option 2 de la partie 9 ne fait plus de `git push --force` : le `reset --hard v1.0.0` est montré en local, le script explique pourquoi le push forcé est dangereux, puis revient à l'historique publié avec `git reset --hard origin/main`.
  - `P05_THEORY_ANSWERS.txt` : les 7 exercices théoriques du §7 de l'énoncé v2.
  - `README.md` : schéma des zones Git et tableau des parties.
- **Lancer** : `./start.sh` (remplit `.env` depuis la machine ; le jeton `gh` doit avoir le droit `delete_repo`), puis `docker exec -it unit05-tools-1 bash` et `./TestUnit5.sh`. Pour garder la trace : `./TestUnit5.sh 2>&1 | tee TestUnit5_output.txt`.
- **Reste à faire** :
  1. Lancer le script et enregistrer sa sortie : c'est elle qui montre le cheminement.
  2. Répondre aux questions posées dans les parties 2 à 8 et aux 4 questions de debrief (énoncé v2, §8).
  3. Écarts restants avec la v2, à corriger seulement si le professeur les attend : tags `v2.0.1` et `v2.0.2`, cas `notes.txt`, `git branch -d hotfix`, graphe final, 15 premières lignes de `git reflog`.

### Unité 06 – Évaluation 1
Grille trouvée dans `Planning_Promo2_DevOp2.xlsx` (feuille `assessment1`) : QCM 10 pts ; configuration (config.yaml + loader + `APP_ENV`) 2 ; release (tags, `RELEASE_NOTES.md`, blue/green ou canary) 2 ; observabilité (Elasticsearch + Kibana, dashboard) 2 ; rollback (revert, reset, reflog, preuve de récupération) 2 ; présentation (dossier organisé, captures, court rapport) 2. Les points pratiques reprennent donc P02 à P05 : P04 et P05 comptent pour 4 points tant qu'ils ne sont pas faits.

### Unité 07 – Packaging Python — pas commencé
- **Support** : `COURS/Unit 06/Unit 07 - Python Package.pdf`.
- **Idée** : transformer un script en paquet installable. Structure `src/monpaquet/`, tests dans `tests/`, un `pyproject.toml` qui dit comment l'installer.
- **À produire** (planning) : le paquet, au moins un test unitaire, et la preuve que `pip install -e ".[dev]"` puis `pytest` fonctionnent (copie du terminal).

### Unité 08 – CI/CD — pas commencé
- **À produire** (planning) : un `Jenkinsfile` ou un workflow GitHub Actions qui installe les dépendances, lance les tests et construit le paquet, poussé sur un petit dépôt et exécuté.
- **Dans le dossier** : `ci-cd-demo/` et `kubernetes-setup-scripts/ci-cd-demo/` sont deux clones identiques du dépôt d'une autre personne (un seul `Jenkinsfile`). Ce n'est pas ton travail : ne pas le rendre.

### Hors périmètre
`COURS/Unit11/Arbeitsblatt…` sont des fiches d'un autre module, non comptées. Le labo « Unit 04 - API Gateway » porte l'en-tête DATOP2 par erreur : il fait partie de DEVOP2 (précision du 16/11) et il est compté dans l'unité 04.

## 4. Ce qu'il faut rendre

Les énoncés 04b et 05 demandent chacun **un PDF ou DOCX avec le lien du dépôt en haut**. Deux liens Git sont donc attendus (le dépôt du labo 05 est jetable : on rend le script, sa sortie et les réponses) :

| Lien | Contenu | État |
|---|---|---|
| `github.com/lanfr144/DEVOP2` | ce dossier `EXERCISES/` (unités 01 à 03, documents de réponses 04 et 05) | à créer (§5) |
| `github.com/lanfr144/release-strategies-lab` | labo 04b : tags, notes de version, branches blue/green, revert | à compléter |

Liste de contrôle avant d'envoyer le lien :

- [ ] `Unit02/dashboard.png`
- [ ] `Unit02/LISEZMOI.md` remplacé
- [x] `Unit03/config.yaml` suivi par Git
- [ ] Frise 01-A (PDF ou Word)
- [ ] `Unit04/P04_DELIVERABLE` (PDF/DOCX) + dépôt poussé avec `--tags`
- [ ] `Unit05/TestUnit5_output.txt` + réponses aux questions des parties et du debrief (`P05_THEORY_ANSWERS.txt` est fait)
- [ ] Mots de passe changés (ils ont été écrits en clair par le passé, voir `PLAN.md` §3)
- [ ] Dates limites : le planning du dossier porte les dates 2025-2026 ; à confirmer auprès du professeur

## 5. Mettre ce dossier sur Git

Seul `EXERCISES/` devient un dépôt : `COURS/` n'en fait pas partie, et les supports du cours copiés ici (PDF, PPTX, DOCX) sont exclus par le `.gitignore`. Restent tes deux documents (`Unit 01 - API Basics.docx`, `Elasticsearch.docx`). Un essai à blanc de `git add .` donne 70 fichiers, sans `.env` ni mot de passe.

```bat
cd "C:\Users\lanfr144\OneDrive - 365education\Documents\semestre_3\DEVOP2\EXERCISES" &&
git init -b main &&
git add . &&
git status &&
git commit -m "Initial commit - v1.0.0" &&
git tag -a v1.0.0 -m "Initial version" &&
gh repo create lanfr144/DEVOP2 --public --source=. --remote=origin --push &&
git push origin v1.0.0 && echo ok
```

### Versions

Trois chiffres, écrits dans `VERSION`, détaillés dans `CHANGELOG.md`, et posés comme tag Git (`v2.0.0`) :

| Chiffre | Change quand | Commande |
|---|---|---|
| 1er | on passe à l'**unité suivante** | `./scripts/release.sh next-unit "…"` |
| 2e | un changement **dans la même unité** | `./scripts/release.sh same-unit "…"` |
| 3e | une petite correction | `./scripts/release.sh fix "…"` |

Le script met à jour `VERSION` et `CHANGELOG.md`, committe, crée le tag et pousse. Les versions jusqu'à `v1.4.1` ont été numérotées avant cette règle.

### À savoir

- Le dépôt est **public** : relire la liste de `git status` avant le commit.
- `Unit05/MyTestUnit5.sh` (brouillon, exclu de Git) contient `gh repo delete lanfr144/DEVOP2` : ne plus le lancer, il supprimerait ce dépôt.
