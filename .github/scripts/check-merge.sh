#!/usr/bin/env bash
set -euo pipefail

# Merge gate: requires 'lgtm' AND 'approved' labels, blocked by 'hold'.
# Also reports a commit status (context: ci/prow-merge-gate) so branch
# protection can require it. That's what actually stops a Collaborator
# from clicking "Merge" directly and bypassing the label gate — the
# label check alone is only a convention until this status is required.
#
# Expects PR_NUMBER and GH_TOKEN env vars (set by the calling workflow).
# GITHUB_REPOSITORY is provided automatically by the Actions runner.

STATUS_CONTEXT="ci/prow-merge-gate"
REQUIRED_LABELS=("lgtm" "approved")
BLOCKING_LABEL="hold"

sha="$(gh pr view "$PR_NUMBER" --repo "$GITHUB_REPOSITORY" --json headRefOid --jq '.headRefOid')"
labels="$(gh pr view "$PR_NUMBER" --repo "$GITHUB_REPOSITORY" --json labels --jq '.labels[].name')"

has_label() {
  grep -qx "$1" <<< "$labels"
}

set_status() {
  gh api "repos/$GITHUB_REPOSITORY/statuses/$sha" \
    -f state="$1" \
    -f context="$STATUS_CONTEXT" \
    -f description="$2" >/dev/null
}

missing=()
for required in "${REQUIRED_LABELS[@]}"; do
  has_label "$required" || missing+=("$required")
done

held=false
has_label "$BLOCKING_LABEL" && held=true

if [ "${#missing[@]}" -gt 0 ]; then
  set_status "failure" "Missing: ${missing[*]}"
  echo "Missing required label(s): ${missing[*]} — not merging."
  exit 0
fi

if [ "$held" = true ]; then
  set_status "failure" "Blocked by '$BLOCKING_LABEL' label"
  echo "Blocking label '$BLOCKING_LABEL' present — not merging."
  exit 0
fi

set_status "success" "lgtm + approved, not held"
echo "All conditions met — merging PR #$PR_NUMBER"
gh pr merge "$PR_NUMBER" --repo "$GITHUB_REPOSITORY" --squash