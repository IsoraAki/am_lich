#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
ROOT_DIR="$( cd "$SCRIPT_DIR/.." && pwd )"

on_interrupt() {
  echo
  echo "Commit interrupted. Skipping commit and moving to next step."
  exit 0
}

trap on_interrupt INT

commitChoice="ask"
if [[ "${1:-}" == "--yes" ]]; then
  commitChoice="yes"
  shift
fi

if [[ "$commitChoice" == "ask" ]]; then
  read -r -p "Do you want to commit the changes? [Y/n] " commitChoice
  commitChoice=$(echo "$commitChoice" | xargs)
fi

if [[ -z "$commitChoice" || "$commitChoice" =~ ^[Yy]([Ee][Ss])?$ ]]; then
  cd "$ROOT_DIR"

  if [ $# -ge 1 ]; then
    COMMIT_MESSAGE="$1"
  else
    read -r -p "Enter commit message: " COMMIT_MESSAGE
    COMMIT_MESSAGE=$(echo "$COMMIT_MESSAGE" | xargs)
  fi

  if [[ -z "$COMMIT_MESSAGE" ]]; then
    echo "Commit message cannot be empty. Skipping commit."
    exit 0
  fi

  if [ $# -ge 3 ]; then
    COMMIT_DESCRIPTION="$3"
  else
    read -r -p "Enter commit description (optional): " COMMIT_DESCRIPTION
    COMMIT_DESCRIPTION=$(echo "$COMMIT_DESCRIPTION" | xargs)
  fi

  if [ $# -ge 2 ]; then
    BRANCH_NAME="$2"
  else
    read -r -p "Enter branch name (leave empty to use current branch): " input_branch
    input_branch=$(echo "$input_branch" | xargs)
    if [ -z "$input_branch" ]; then
      BRANCH_NAME=$(git rev-parse --abbrev-ref HEAD)
    else
      BRANCH_NAME="$input_branch"
    fi
  fi

  echo "Commit message: $COMMIT_MESSAGE"
  if [[ -n "$COMMIT_DESCRIPTION" ]]; then
    echo "Commit description: $COMMIT_DESCRIPTION"
  fi
  echo "Branch name: $BRANCH_NAME"

  git add .
  if [[ -n "$COMMIT_DESCRIPTION" ]]; then
    git commit -m "$COMMIT_MESSAGE" -m "$COMMIT_DESCRIPTION"
  else
    git commit -m "$COMMIT_MESSAGE"
  fi
  git push origin "$BRANCH_NAME"

  cd "$SCRIPT_DIR"
  echo "Changes committed and pushed to '$BRANCH_NAME'."
else
  echo "Skipping commit."
fi
