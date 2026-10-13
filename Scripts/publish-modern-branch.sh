#!/bin/bash
set -euo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
REMOTE="${REMOTE_REPOSITORY:-https://github.com/master-zen/Mac-QuickLook.git}"
BRANCH="${TARGET_BRANCH:-modern}"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
git ls-remote --exit-code "$REMOTE" HEAD >/dev/null
git clone --quiet --no-checkout "$REMOTE" "$WORK/repo"
cd "$WORK/repo"
if git show-ref --verify --quiet "refs/remotes/origin/$BRANCH"; then
    echo "Target branch already exists: $BRANCH" >&2
    exit 1
fi
git switch --orphan "$BRANCH"
git rm -rfq --ignore-unmatch .
find . -mindepth 1 -maxdepth 1 ! -name .git -exec rm -rf {} +
rsync -a --exclude '.build/' --exclude '.git/' --exclude 'Dist/' --exclude 'MacQuickLookModern.xcodeproj/' "$ROOT/" ./
python3 Scripts/audit.py
git add -A
git -c user.name="${GIT_AUTHOR_NAME:-master-zen}" -c user.email="${GIT_AUTHOR_EMAIL:-118656414+master-zen@users.noreply.github.com}" commit -m 'Rebuild Quick Look as a unified macOS application'
git push --set-upstream origin "$BRANCH"
