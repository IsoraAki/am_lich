#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
ROOT_DIR="$( cd "$SCRIPT_DIR/.." && pwd )"
cd "$SCRIPT_DIR"

echo "Starting the release process..."

echo "Updating version code..."
./control_ver_code.sh || echo "Skipping version code update."

echo "Updating version name..."
./control_ver_name.sh || echo "Skipping version name update."

echo "Committing changes..."
before_commit_sha=$(git -C "$ROOT_DIR" rev-parse HEAD)
./commit.sh || echo "Skipping commit."
after_commit_sha=$(git -C "$ROOT_DIR" rev-parse HEAD)

if [[ "$before_commit_sha" == "$after_commit_sha" ]]; then
  echo "No new commit was created. Stopping release flow before merge/deploy."
  exit 0
fi

echo "Creating pull request to main..."
./merge.sh ask "$after_commit_sha"

echo "Starting deployment..."
./deploy.sh

echo "Release process completed!"
cd "$ROOT_DIR"
