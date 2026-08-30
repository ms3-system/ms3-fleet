#!/usr/bin/env bash
set -euo pipefail

# Custom /approve handling.
#
# The official action's /approve command tries to create a real GitHub
# review with APPROVE state. GitHub blocks GITHUB_TOKEN from doing that
# ("GitHub Actions is not permitted to approve pull requests") — a hard
# platform restriction, not a permissions issue. This applies the
# 'approved' label directly instead, which is all our merge gate needs.
#
# Expects PR_NUMBER, COMMENT_BODY, GH_TOKEN env vars.

APPROVE_LABEL="approved"

if grep -qE '^/approve cancel\b' <<< "$COMMENT_BODY"; then
  gh pr edit "$PR_NUMBER" --repo "$GITHUB_REPOSITORY" --remove-label "$APPROVE_LABEL" || true
  echo "Removed '$APPROVE_LABEL' label."
elif grep -qE '^/approve\b' <<< "$COMMENT_BODY"; then
  gh pr edit "$PR_NUMBER" --repo "$GITHUB_REPOSITORY" --add-label "$APPROVE_LABEL"
  echo "Added '$APPROVE_LABEL' label."
fi