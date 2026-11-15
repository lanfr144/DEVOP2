# DEVOP2 - Unit 03 - fichiers de code (Application Configuration)

Fichiers du labo, tels que dans le document Word v3 (aucune valeur réelle : tout est factice).
Tout tourne dans Docker : `./start.sh`, puis `docker exec -it unit03-tools-1 bash` (pyyaml et python-dotenv sont dans l'image).

- `config.yaml` : Exercise 1 (3 environnements dev / staging / prod)
- `config_loader.py` : Exercise 2 (`load_config()`, piloté par `APP_ENV`)
- `config_loader_validated.py` : Exercise 2, étape 2 (validation des clés requises)
- `app.py` : Exercise 3 (masque le mot de passe et la clé d'API)
- `loader_env.py` : annexe, variante `.env` avec python-dotenv
- `.env.example` (et le `.gitignore` à la racine du dépôt) : protection des secrets

Lancer : `python app.py` (dev), `APP_ENV=staging python app.py`, `APP_ENV=prod python app.py`
(PowerShell : `$env:APP_ENV="prod"; python app.py`).

## Mise à jour 2026-10-26

- `config_loader.py` / `config_loader_validated.py` : lisent la section `environments:` (bug corrigé, voir `P03_DELIVERABLE.md`).
- `.env.example` ajouté ; URL des `.env.*` réparées (les `=` erronés redevenus `:`).
- Test automatique : `./test_p03.sh` ; sortie des 3 environnements : `terminal_output_3_envs.txt`.
