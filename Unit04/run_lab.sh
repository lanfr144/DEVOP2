#!/bin/bash
#!/bin/bash
set -euxo pipefail
cd "$(dirname "$0")"                      # Unit04, dans WSL comme dans le conteneur
[ ! -e release-strategies-lab ] || { echo "release-strategies-lab existe déjà : supprime-le d'abord" >&2; exit 1; }

echo "Partie 1 : trois versions"
git init release-strategies-lab && cd release-strategies-lab && git branch -m main
echo "# Release Management Lab" > README.md
git add README.md && git commit -m "Initial commit"
echo "print('Hello, version 1.0.0')" > app.py
git add app.py && git commit -m "Add initial version of app" && git tag v1.0.0
echo "print('New feature: logging enabled')" >> app.py
git add app.py && git commit -m "Add logging feature" && git tag v1.1.0
printf "def start_app():\n    print('App starting with new API')\n" > app.py
git add app.py && git commit -m "Refactor: breaking API change" && git tag v2.0.0

echo "Partie 2 : notes de version (écrire RELEASE_NOTES.md, puis)"
cat > RELEASE_NOTES.md <<'EOF'
# Release Notes

## v2.0.0 (Breaking release)
- Refactored main application to use the start_app() function.
- WARNING: breaking API change. Code that calls the old script directly must be updated.

## v1.1.0
- Added logging feature for better observability.

## v1.0.0
- Initial release: the app prints "Hello".
EOF
git add RELEASE_NOTES.md && git commit -m "Add release notes for v1.0.0 to v2.0.0"
gh repo create lanfr144/release-strategies-lab --public --source=. --remote=origin --push
git push origin --tags

echo "Partie 3.1 : blue/green"
git checkout -b blue
echo "Blue version running" > deployment.txt
git add deployment.txt && git commit -m "Blue: current production version"
git checkout -b green
echo "Green version running" > deployment.txt
git add deployment.txt && git commit -m "Green: new version deployed and validated"
git checkout main && git merge green

echo "Partie 3.2 : rolling"
mkdir server1 server2 server3
for s in 1 2 3; do echo "v1.0.0" > server$s/version.txt; done
git add . && git commit -m "Initial state: 3 servers on v1.0.0"
for s in 1 2 3; do echo "v1.1.0" > server$s/version.txt; git add . && git commit -m "Rolling update: server$s to v1.1.0"; done

# Partie 3.3 : canary, puis partie 4 : rollback
echo "v2.0.0 (canary)" > server1/version.txt
git add . && git commit -m "Canary: server1 runs v2.0.0 for 10% of traffic"
git revert --no-edit HEAD
cat server1/version.txt        # v1.1.0

echo "Pousser et enregistrer la trace"
git push origin main --tags
git push origin blue green
cd .. && ./record_history.sh

echo "Contrôler"
cd release-strategies-lab
git log --oneline --graph --all --decorate
git ls-remote --tags origin
