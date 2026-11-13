#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
ROOT_DIR="$( cd "$SCRIPT_DIR/.." && pwd )"
ANDROID_DIR="$ROOT_DIR/android"

echo "Deployment Options"

rawArg1="${1:-ask}"
rawArg2="${2:-}"
rawArg3="${3:-}"
rawArg4="${4:-}"
chplayChoice=""
updateDescription=""
playImagesChoice=""

ask_choice() {
  local prompt="$1"
  local var
  read -r -p "$prompt [Y/n] " var
  normalize_choice "${var}"
}

normalize_choice() {
  local raw="$1"
  local normalized
  normalized=$(printf '%s' "$raw" | tr '[:upper:]' '[:lower:]')
  case "$normalized" in
    ""|ask) echo "ask" ;;
    1|true|y|yes) echo "yes" ;;
    0|false|n|no) echo "no" ;;
    *) echo "invalid" ;;
  esac
}

extract_version_code() {
  local pubspec_path="$ROOT_DIR/pubspec.yaml"
  [[ -f "$pubspec_path" ]] || return 1
  sed -nE 's/^[[:space:]]*version:[[:space:]]*[^+]+[+]([0-9]+)[[:space:]]*$/\1/p' "$pubspec_path" | head -n1
}

fastlane_cmd() {
  if [[ "${USE_BUNDLER_FASTLANE:-0}" == "1" ]]; then
    if [[ -f "$ANDROID_DIR/Gemfile" ]] && command -v bundle >/dev/null 2>&1; then
      export BUNDLE_GEMFILE="$ANDROID_DIR/Gemfile"
      echo "bundle exec fastlane"
      return
    fi
    echo "USE_BUNDLER_FASTLANE=1 but android/Gemfile or bundle is unavailable. Falling back to global fastlane." >&2
  fi
  echo "fastlane"
}

run_fastlane_lane() {
  local cmd
  cmd="$(fastlane_cmd)"
  FASTLANE_SKIP_SCREEN=1 TTY_SCREEN_WIDTH="${TTY_SCREEN_WIDTH:-120}" TTY_SCREEN_HEIGHT="${TTY_SCREEN_HEIGHT:-40}" \
    $cmd "$@"
}

arg1Choice=$(normalize_choice "${rawArg1}")
arg2Choice=$(normalize_choice "${rawArg2}")

if [[ "$arg1Choice" == "invalid" ]]; then
  echo "Invalid first argument: '${rawArg1}'. Use ask|yes|no."
  exit 1
fi

useLegacyArgs="false"
if [[ "${DEPLOY_LEGACY_ARGS:-0}" == "1" ]]; then
  useLegacyArgs="true"
elif [[ -n "$rawArg3" && ( "${arg2Choice}" == "yes" || "${arg2Choice}" == "no" ) ]]; then
  useLegacyArgs="true"
fi

if [[ "$useLegacyArgs" == "true" ]]; then
  chplayChoice="${arg2Choice}"
  updateDescription="${rawArg3}"
  playImagesChoice=$(normalize_choice "${UPLOAD_PLAY_IMAGES:-${rawArg4:-ask}}")
else
  chplayChoice="${arg1Choice}"
  updateDescription="${rawArg2}"
  playImagesChoice=$(normalize_choice "${UPLOAD_PLAY_IMAGES:-${rawArg3:-ask}}")
fi

if [[ "$playImagesChoice" == "invalid" ]]; then
  echo "Invalid Play images choice. Use ask|yes|no, or UPLOAD_PLAY_IMAGES=1|0."
  exit 1
fi

if [[ "$chplayChoice" == "ask" ]]; then
  if [[ ! -t 0 ]]; then
    echo "No interactive terminal detected. Pass first argument as yes or no."
    exit 1
  fi
  chplayChoice=$(ask_choice "Do you want to upload to Google Play?")
  if [[ "$chplayChoice" == "invalid" || "$chplayChoice" == "ask" ]]; then
    echo "Invalid response. Please answer yes or no."
    exit 1
  fi
fi
echo

current_dir=$(pwd)

if [[ "$chplayChoice" == "yes" ]]; then
  echo "Uploading to Google Play..."

  versionCode="$(extract_version_code || true)"
  existingChangelogPath=""
  if [[ -n "$versionCode" ]]; then
    candidateChangelogPath="$ROOT_DIR/android/fastlane/metadata/android/vi/changelogs/${versionCode}.txt"
    if [[ -s "$candidateChangelogPath" ]]; then
      existingChangelogPath="$candidateChangelogPath"
      echo "Found existing changelog for version code ${versionCode}: ${existingChangelogPath}"
    fi
  fi

  if [[ -z "$updateDescription" && -z "$existingChangelogPath" ]]; then
    if [[ -t 0 ]]; then
      read -r -p "Enter Google Play update description (What's new): " updateDescription
    else
      echo "Update description is required in non-interactive mode unless a versioned changelog exists."
      exit 1
    fi
  fi

  if [[ -z "$updateDescription" && -z "$existingChangelogPath" ]]; then
    echo "Update description is required, or create a changelog file by version code. Exiting."
    exit 1
  fi

  if [[ "$playImagesChoice" == "ask" ]]; then
    if [[ -t 0 ]]; then
      playImagesChoice=$(ask_choice "Upload Play listing images/app icon/screenshots?")
      if [[ "$playImagesChoice" == "invalid" || "$playImagesChoice" == "ask" ]]; then
        echo "Invalid response. Please answer yes or no."
        exit 1
      fi
    else
      playImagesChoice="yes"
    fi
  fi

  uploadPlayImagesEnv="0"
  if [[ "$playImagesChoice" == "yes" ]]; then
    uploadPlayImagesEnv="1"
    dart "$SCRIPT_DIR/check_play_images.dart"
  else
    echo "Skipping Play listing images/app icon/screenshots upload."
  fi

  cd "$ANDROID_DIR" || exit 1

  if [[ -n "$updateDescription" ]]; then
    UPLOAD_PLAY_IMAGES="$uploadPlayImagesEnv" SKIP_PLAY_IMAGE_CHECK=1 \
      run_fastlane_lane android upload_to_chplay update_description:"${updateDescription}"
  else
    UPLOAD_PLAY_IMAGES="$uploadPlayImagesEnv" SKIP_PLAY_IMAGE_CHECK=1 \
      run_fastlane_lane android upload_to_chplay
  fi

  cd "$current_dir" || exit 1
else
  echo "Skipping Google Play upload (choice: no)."
fi

echo "Deployment process completed!"
