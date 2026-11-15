#!/bin/bash
# ==============================================================================
# DEVOP2 - Unit 05: Git Rollbacks & Recovery (Automated Lab Script)
# ==============================================================================

set -Eeuo pipefail
TESTPROJ=TestProj
export TESTPROJ

# Save the starting directory so cleanup can safely step out of TESTPROJ before deleting it
START_DIR="$(pwd)"
LAB_DIR="${START_DIR}/${TESTPROJ}"

handle_error() {
    local exit_code=$1
    local line_number=$2
    echo "❌ Error on line ${line_number} (exit code ${exit_code}): ${BASH_COMMAND}" >&2
}
trap 'handle_error $? $LINENO' ERR

# Display the command (on stderr so $(...) captures stay clean) and execute it
echodo() {
    echo "💻 \$ $*" >&2
    "$@"
}

# Helper function to display clear section headers in the terminal
banner() {
    echo ""
    echo "=========================================================================="
    echo "👉 $1"
    echo "=========================================================================="
}

# Cleanup function triggered automatically on script EXIT (normal end, error, or Ctrl+C)
cleanup() {
    local exit_code=$?
    # Disable strict mode & ERR trap inside cleanup to avoid recursive failures
    trap - ERR
    set +eEu

    banner "CLEANUP (trap EXIT): Removing remote repo and local lab directory"

    # 1. Clean up remote GitHub repository
    if [ -n "${GIT_REPO:-}" ]; then
        if echodo gh repo delete "$GIT_REPO" --yes 2>&1; then
            echo "✅ Successfully deleted remote repository ${GIT_REPO}."
        else
            echo "⚠️  Could not delete ${GIT_REPO} (it may not exist or 'gh auth refresh -s delete_repo' is needed)."
        fi
    fi

    # 2. Clean up local directory (move back to START_DIR first so we aren't inside LAB_DIR)
    cd "$START_DIR" 2>/dev/null || cd /
    if [ -d "$LAB_DIR" ]; then
        rm -rf "$LAB_DIR"
        echo "✅ Successfully deleted local directory ${LAB_DIR}."
    fi

    exit "$exit_code"
}
trap cleanup EXIT

# Inspect all 4 Git areas (Working Directory, Staging/Index, Local HEAD, Remote)
# Prefix spacing:
# - After "1 " : 0 extra spaces
# - After "2 " : 42 extra spaces (21 spaces total after '2')
# - After "3 " : 86 extra spaces (41 spaces total after '3')
# - After "4 " : 132 extra spaces (61 spaces total after '4')
git_info() {
    (
        set +Eeuvx
        set -o pipefail

        local S42 S86 S132
        printf -v S42 '%42s' ''
        printf -v S86 '%86s' ''
        printf -v S132 '%132s' ''

        echo "--- [Git Overview: Status & Log] ---"
        echodo git status -s 2>&1 | sed 's/.*/0 &/'
        echodo git log --oneline -n 5 2>&1 | sed 's/.*/0 &/'

        for i in *.txt
        do
            [ -e "$i" ] || continue
            {
                echo "1 [Working Dir] $i Local Files is :" &&
                cat "$i" 2>&1 | sed 's/.*/1 &/' &&
                echo "2 ${S42}[Staging Area] $i Staging Area is :" &&
                echodo git show :"$i" 2>&1 | sed "s/.*/2 ${S42}&/" &&
                echo "2 ${S42}Diff ======" &&
                echodo git diff "$i" 2>&1 | sed "s/.*/2 ${S42}&/" &&
                echo "3 ${S86}[Local Repo] $i Local Repository is :" &&
                echodo git show HEAD:"$i" 2>&1 | sed "s/.*/3 ${S86}&/" &&
                echo "3 ${S86}Diff ======" &&
                echodo git diff --staged "$i" 2>&1 | sed "s/.*/3 ${S86}&/" &&
                echo "4 ${S132}[Remote Repo] $i Remote Repository is :" &&
                echodo git show origin/main:"$i" 2>&1 | sed "s/.*/4 ${S132}&/" &&
                echo "4 ${S132}Diff ======" &&
                echodo git diff HEAD origin/main -- "$i" 2>&1 | sed "s/.*/4 ${S132}&/"
            } || true
        done
        echo "--------------------------------------------------------------------------"
    )
}

# ==============================================================================
# 0. DYNAMIC GITHUB USER & CLEAN ENVIRONMENT SETUP
# ==============================================================================
banner "0. Fetching current GitHub user & cleaning previous lab environment"

GH_USER=$(echodo gh api user --jq '.login')
export GIT_REPO="${GH_USER}/${TESTPROJ}"
echo "   Authenticated GitHub User: ${GH_USER}"
echo "   Target Remote Repository : ${GIT_REPO}"
echo "   Target Local Directory   : ${LAB_DIR}"

echo "   Deleting leftover remote repository ${GIT_REPO} if it exists from an interrupted run..."
( echodo gh repo delete "$GIT_REPO" --yes 2>&1 || true )

echo "   Removing leftover local ${LAB_DIR} directory if it exists..."
rm -rf "$LAB_DIR"

# ==============================================================================
# PART 1: INTRODUCTION (THEORY FROM PDF)
# ==============================================================================
banner "PART 1: Introduction - Why Rollback & Recovery Matters"
echo "Even experienced developers make mistakes (wrong commits, deleted files, broken releases)."
echo "Git provides safe & powerful tools to undo, restore, and recover almost anything."

# ==============================================================================
# PART 2: SETUP
# ==============================================================================
banner "PART 2: Repository Setup & Remote Creation"
echo "Creating ${LAB_DIR} directory, initializing Git on 'main', and pushing initial Version 1."

mkdir -p "$LAB_DIR"
cd "$LAB_DIR"
echo "# ${TESTPROJ}" > README.md
echodo git init -b main

echo "Version 1" > app.txt
echodo git add .
echodo git commit -m "Initial commit - v1"

echo "ℹ️  Creating public GitHub repo ${GIT_REPO} and pushing 'main'..."
echodo gh repo create "$GIT_REPO" --public --source=. --remote=origin --push
git_info

# ==============================================================================
# PART 3: UNDO CHANGES IN WORKING DIRECTORY
# ==============================================================================
banner "PART 3: Undo Changes in Working Directory (Unstaged changes)"
echo "⚠️  Warning: Discarding working directory changes deletes local modifications permanently!"

echo "ℹ️  Method A: Appending 'Temporary change' to app.txt and undoing with 'git checkout -- app.txt'"
echo "Temporary change" >> app.txt
echodo git status
echodo git checkout -- app.txt
git_info

echo "ℹ️  Method B: Appending 'Temporary change' to app.txt and undoing with modern 'git restore app.txt'"
echo "Temporary change" >> app.txt
echodo git status
echodo git restore app.txt
git_info

# ==============================================================================
# PART 4: UNDO STAGED CHANGES
# ==============================================================================
banner "PART 4: Undo Staged Changes (Unstage while keeping file modifications)"
echo "Staging 'New feature' into Index, then unstaging with 'git reset app.txt'."

echo "New feature" >> app.txt
echodo git add app.txt
echodo git status
git_info

echo "ℹ️  Unstaging app.txt (moves change back to Working Directory, keeps text intact)..."
echodo git reset app.txt
echodo git status
git_info

echo "ℹ️  Cleaning up unstaged 'New feature' with git restore before Part 5..."
echodo git restore app.txt

# ==============================================================================
# PART 5: REVERT COMMITS (SAFE FOR SHARED BRANCHES)
# ==============================================================================
banner "PART 5: Revert Commits (Safe Rollback - Preserves History)"
echo "Adding 'Step 1' and 'Bug' commits, then safely reverting the 'Add bug' commit."

echo "Step 1" >> app.txt
echodo git commit -am "Add step 1"
git_info

echo "Bug" >> app.txt
echodo git commit -am "Add bug"
git_info

echodo git log --oneline
BUG_HASH=$(echodo git log --oneline | grep "Add bug" | awk '{ print $1 }')
echo "ℹ️  Reverting commit ${BUG_HASH} ('Add bug') using --no-edit to create an inverse commit..."
echodo git revert --no-edit "$BUG_HASH"
git_info

# ==============================================================================
# PART 6: RESET COMMITS (DANGEROUS - REWRITES HISTORY)
# ==============================================================================
banner "PART 6: Reset Commits (--soft, --mixed, --hard)"
echo "⚠️  NEVER use reset on shared/public branches! Testing all 3 modes on a local commit."

# 6A: Soft Reset
echo "ℹ️  [6A] Committing 'Secret data', then running 'git reset --soft HEAD~1' (keeps changes STAGED)..."
echo "Secret data" >> app.txt
echodo git commit -am "Add secret data"
git_info

echodo git reset --soft HEAD~1
echo "✅ After --soft reset: Commit is undone, 'Secret data' is still STAGED in Index."
git_info

# Re-commit to test Mixed Reset
echodo git commit -m "Add secret data (re-committed for mixed reset)"

# 6B: Mixed Reset (Default)
echo "ℹ️  [6B] Running 'git reset HEAD~1' (--mixed default: keeps changes UNSTAGED in Working Dir)..."
echodo git reset HEAD~1
echo "✅ After --mixed reset: Commit is undone, 'Secret data' is UNSTAGED in Working Directory."
git_info

# Re-commit to test Hard Reset
echodo git commit -am "Add secret data (re-committed for hard reset)"
SECRET_HASH=$(echodo git rev-parse --short HEAD)
echo "ℹ️  Recorded commit hash before hard reset: ${SECRET_HASH}"

# 6C: Hard Reset
echo "ℹ️  [6C] Running 'git reset --hard HEAD~1' (DESTROYS commit, staging, and working dir changes)..."
echodo git reset --hard HEAD~1
echo "✅ After --hard reset: 'Secret data' is completely gone from Working Dir, Index, and Branch!"
git_info

# ==============================================================================
# PART 7: RECOVER LOST COMMITS WITH REFLOG
# ==============================================================================
banner "PART 7: Recover Lost Commits with 'git reflog'"
echo "Even after a --hard reset, Git tracks HEAD movements in the reflog."

echodo git reflog
echo "ℹ️  Recovering lost 'Secret data' commit (${SECRET_HASH}) via 'git reset --hard ${SECRET_HASH}'..."
echodo git reset --hard "$SECRET_HASH"
git_info

echo "ℹ️  Removing 'Secret data' commit once more so history stays clean for Part 8..."
echodo git reset --hard HEAD~1

# ==============================================================================
# PART 8: RESTORE DELETED FILES
# ==============================================================================
banner "PART 8: Restore Deleted Files"

echo "ℹ️  Case 1A: Tracked file deleted with 'rm app.txt', recovered with 'git restore app.txt'"
rm app.txt
echodo git status
echodo git restore app.txt
git_info

echo "ℹ️  Case 1B: Tracked file deleted with 'rm app.txt', recovered with 'git checkout HEAD -- app.txt'"
rm app.txt
echodo git checkout HEAD -- app.txt
git_info

echo "ℹ️  Case 2: Untracked file deleted BEFORE ever being committed or staged"
echo "Draft notes" > untracked_temp.txt
rm untracked_temp.txt
echo "⚠️  untracked_temp.txt cannot be restored by Git because Git never tracked it! Must use OS backups."

# ==============================================================================
# PART 9: ROLLING BACK RELEASES (TAGS)
# ==============================================================================
banner "PART 9: Rolling Back Releases (Tags v1.0.0 & v2.0.0)"
echo "Creating version.txt for v1.0.0 and buggy v2.0.0, pushing tags, then testing Option 1 & Option 2."

echo "v1.0.0" > version.txt
echodo git add version.txt
echodo git commit -m "v1.0.0"
echodo git tag v1.0.0
echodo git push origin main --tags
git_info

echo "v2.0.0 bug" > version.txt
echodo git commit -am "v2.0.0"
echodo git tag v2.0.0
echodo git push origin main --tags
git_info

echo "ℹ️  Option 1 (SAFE): Rolling back v2.0.0 release using 'git revert HEAD'"
echodo git revert --no-edit HEAD
echodo git push origin main
git_info

echo "ℹ️  Option 2 (DANGEROUS, local demonstration only): 'git reset --hard v1.0.0' rewrites the LOCAL history"
echodo git reset --hard v1.0.0
echodo git status -sb
git_info
echo "⚠️  Local 'main' is now BEHIND 'origin/main': publishing this state would require 'git push --force'."
echo "⚠️  The forced push is NOT executed: it would overwrite the remote history and break the clones"
echo "    of every teammate who already pulled (their commits would no longer exist on the server)."

echo "ℹ️  Returning to the published history (the safe revert of Option 1) with 'git reset --hard origin/main'"
echodo git reset --hard origin/main
git_info

# ==============================================================================
# PART 10: HOTFIX BRANCH STRATEGY (BEST PRACTICE)
# ==============================================================================
banner "PART 10: Hotfix Branch Strategy (Production Best Practice)"
echo "Instead of rewriting production history, create an isolated hotfix branch and merge it back to main."

echodo git checkout -b hotfix
echo "Fix" >> app.txt
echodo git commit -am "Apply hotfix"
git_info

echodo git checkout main
echodo git merge --no-edit hotfix
echodo git push origin main
git_info

echo "ℹ️  Checking out tag v1.0.0 briefly (from Part 12 Cheat Sheet) and returning to main..."
echodo git checkout v1.0.0
echodo git checkout main

banner "✅ ALL LAB EXERCISES COMPLETED! Triggering EXIT trap for full cleanup..."
banner "Theorical questions and answer."
cat "${OLDPWD}"/P05_THEORY_ANSWERS.txt
banner "✅ That is all, folks !"
