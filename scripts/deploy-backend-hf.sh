#!/usr/bin/env bash
#
# Push the `backend/` folder to the Hugging Face Space as its own root tree.
#
# HF Spaces requires the Dockerfile (and the README with frontmatter) at the
# repo root, so we use `git subtree split` to extract `backend/` into a fresh
# branch with the same contents at the top level, then force-push that branch.
#
# Prerequisites:
#   - `hf auth login` already done with a write-scoped token
#   - The Space exists (create with `hf repos create <user>/bike-news-room --type space --space-sdk docker`)
#   - `backend/README.md` includes the YAML frontmatter HF expects
#
# Usage:
#   bash scripts/deploy-backend-hf.sh                   # uses default user/space
#   bash scripts/deploy-backend-hf.sh user/space-name   # override
#
set -euo pipefail

REPO="${1:-michal-giza/bike-news-room}"
HF_REMOTE_URL="https://huggingface.co/spaces/${REPO}"
SPLIT_BRANCH="hf-backend"

echo "▶ Splitting backend/ into ${SPLIT_BRANCH}"
git branch -D "${SPLIT_BRANCH}" 2>/dev/null || true
git subtree split --prefix=backend -b "${SPLIT_BRANCH}"

echo "▶ Force-pushing ${SPLIT_BRANCH} to ${REPO}:main"
if ! git remote get-url hf >/dev/null 2>&1; then
  git remote add hf "${HF_REMOTE_URL}"
fi
git push hf "${SPLIT_BRANCH}:main" --force

echo "▶ Done. Watch the build at:"
echo "    ${HF_REMOTE_URL}"
echo "▶ Once built, the API will be at:"
USER="${REPO%/*}"
NAME="${REPO#*/}"
echo "    https://${USER}-${NAME}.hf.space/api/health"
