#!/bin/bash
set -euo pipefail

ROOT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )"
TARGET_BRANCH="${TARGET_BRANCH:-main}"
BRANCH_NAME=$(git -C "$ROOT_DIR" rev-parse --abbrev-ref HEAD)
RELEASE_COMMIT="${2:-$(git -C "$ROOT_DIR" rev-parse HEAD)}"
WAIT_TIMEOUT_SECONDS="${PR_MERGE_WAIT_SECONDS:-1800}"
POLL_INTERVAL_SECONDS="${PR_MERGE_POLL_INTERVAL:-15}"
mergeChoice="${1:-ask}"

if [[ "$BRANCH_NAME" == "$TARGET_BRANCH" ]]; then
  echo "Current branch is '$TARGET_BRANCH'. Pull request step is not required."
  exit 0
fi

if [[ "$mergeChoice" == "ask" ]]; then
  read -r -p "Do you want to create a pull request to merge '$BRANCH_NAME' into $TARGET_BRANCH? [Y/n] " mergeInput
else
  mergeInput="$mergeChoice"
fi

if [[ -n "$mergeInput" && ! "$mergeInput" =~ ^[Yy]([Ee][Ss])?$ ]]; then
  echo "Merge request canceled. Input received: '$mergeInput'"
  exit 1
fi

if ! command -v gh >/dev/null 2>&1; then
  echo "GitHub CLI (gh) is not installed. Please install it first."
  exit 1
fi

cd "$ROOT_DIR"
echo "Creating a pull request from '$BRANCH_NAME' into '$TARGET_BRANCH'..."

pr_url=$(gh pr list --head "$BRANCH_NAME" --base "$TARGET_BRANCH" --state open --json url --jq '.[0].url')

if [[ -z "$pr_url" ]]; then
  pr_url=$(gh pr create --base "$TARGET_BRANCH" --head "$BRANCH_NAME" \
    --title "Merge '$BRANCH_NAME' into $TARGET_BRANCH" \
    --body "Automated PR after release preparation.")
fi

if [[ -z "$pr_url" ]]; then
  echo "Failed to create or locate a pull request."
  exit 1
fi

echo "Pull request ready: $pr_url"
gh pr view "$pr_url" --web >/dev/null 2>&1 || echo "Unable to open the browser automatically. Open this link manually: $pr_url"

echo "Checking out '$TARGET_BRANCH' and waiting for the pull request to be merged..."
git checkout "$TARGET_BRANCH"
git pull --ff-only origin "$TARGET_BRANCH"

commit_present_on_target() {
  local target_ref="$1"

  if git merge-base --is-ancestor "$RELEASE_COMMIT" "$target_ref" >/dev/null 2>&1; then
    return 0
  fi

  local cherry_output
  cherry_output=$(git cherry "$target_ref" "$RELEASE_COMMIT" 2>/dev/null || true)
  [[ "$cherry_output" == -* ]]
}

elapsed=0

while (( elapsed <= WAIT_TIMEOUT_SECONDS )); do
  git fetch origin "$TARGET_BRANCH"

  if commit_present_on_target "origin/$TARGET_BRANCH"; then
    git pull --ff-only origin "$TARGET_BRANCH"
    echo "Release commit changes are now available on '$TARGET_BRANCH'."
    exit 0
  fi

  pr_state=$(gh pr view "$pr_url" --json state --jq '.state')
  if [[ "$pr_state" == "CLOSED" ]]; then
    echo "Pull request was closed without the release commit changes appearing on '$TARGET_BRANCH'."
    exit 1
  fi

  remaining=$(( WAIT_TIMEOUT_SECONDS - elapsed ))
  echo "Pull request is still open. Waiting for merge... (${remaining}s remaining)"
  sleep "$POLL_INTERVAL_SECONDS"
  elapsed=$(( elapsed + POLL_INTERVAL_SECONDS ))
done

echo "Timed out waiting for the pull request changes to reach '$TARGET_BRANCH'."
exit 1
