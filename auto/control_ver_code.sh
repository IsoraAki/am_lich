#!/bin/bash
set -euo pipefail

export FASTLANE_SKIP_SCREEN=${FASTLANE_SKIP_SCREEN:-1}
export TTY_SCREEN_WIDTH=${TTY_SCREEN_WIDTH:-120}
export TTY_SCREEN_HEIGHT=${TTY_SCREEN_HEIGHT:-40}

MODE="${1:-ask}"
MANUAL_CODE="${2:-}"
TRACK="${TRACK:-${PLAY_TRACK:-production}}"
do_update=false

if [[ "$MODE" == "yes" ]]; then
  do_update=true
elif [[ "$MODE" == "no" ]]; then
  echo "Skipping version code update."
  exit 0
elif [[ "$MODE" == "manual" ]]; then
  do_update=true
else
  while true; do
    read -r -p "Do you want to update the version code? [Y/n] " versionCodeChoice
    case "${versionCodeChoice}" in
      ''|[Yy]|[Yy][Ee][Ss])
        do_update=true
        break
        ;;
      [Nn]|[Nn][Oo])
        echo "Skipping version code update."
        exit 0
        ;;
      *)
        echo "Please answer Y or n."
        ;;
    esac
  done
fi

if [[ "$do_update" == true ]]; then
  ROOT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )"
  ANDROID_DIR="$ROOT_DIR/android"
  AUTO_DIR="$ROOT_DIR/auto"

  FASTLANE_CMD="fastlane"
  if [[ "${USE_BUNDLER_FASTLANE:-0}" == "1" ]]; then
    if [[ -f "$ANDROID_DIR/Gemfile" ]] && command -v bundle >/dev/null 2>&1; then
      export BUNDLE_GEMFILE="$ANDROID_DIR/Gemfile"
      FASTLANE_CMD="bundle exec fastlane"
    else
      echo "USE_BUNDLER_FASTLANE=1 but android/Gemfile or bundle is unavailable. Falling back to global fastlane."
    fi
  fi

  if ! command -v fastlane >/dev/null 2>&1 && [[ "$FASTLANE_CMD" == "fastlane" ]]; then
    echo "fastlane not found. Install it or ensure bundle exec fastlane works."
    exit 1
  fi

  cd "$ANDROID_DIR"
  echo "Fetching version codes..."

  run_fastlane_lane() {
    FASTLANE_SKIP_SCREEN=1 TTY_SCREEN_WIDTH=$TTY_SCREEN_WIDTH TTY_SCREEN_HEIGHT=$TTY_SCREEN_HEIGHT \
      $FASTLANE_CMD "$@"
  }

  extract_code_from_output() {
    local marker="$1"
    local output="$2"
    echo "$output" | tr -d '\r' | sed -n "s/.*${marker}:\([0-9][0-9]*\).*/\1/p" | tail -n1
  }

  if ! store_output=$(run_fastlane_lane android fetch_version_code_from_play_store track:"$TRACK" 2>&1); then
    printf '%s\n' "Failed to fetch Play Store version code (track: $TRACK)." "$store_output" >&2
    exit 1
  fi
  if ! local_output=$(run_fastlane_lane android get_local_version_code 2>&1); then
    printf '%s\n' "Failed to read local version code." "$local_output" >&2
    exit 1
  fi

  store_code=$(extract_code_from_output "STORE_CODE_ONLY" "$store_output")
  local_code=$(extract_code_from_output "LOCAL_CODE_ONLY" "$local_output")

  if [[ -z "$store_code" || -z "$local_code" ]]; then
    echo "Could not parse version codes. store='$store_code' local='$local_code'"
    echo "---- fetch_version_code_from_play_store output ----"
    echo "$store_output"
    echo "---- get_local_version_code output ----"
    echo "$local_output"
    exit 1
  fi

  store_code=$((10#$store_code))
  local_code=$((10#$local_code))

  echo
  echo "Local versionCode : $local_code"
  echo "Store versionCode : $store_code"
  echo "----------------------------------------"

  if (( local_code < store_code )); then
    echo "Local code ($local_code) is behind Play Store ($store_code)."
  elif (( local_code > store_code )); then
    echo "Local code ($local_code) is ahead of Play Store ($store_code)."
  else
    echo "Local code ($local_code) matches Play Store ($store_code)."
  fi
  echo

  if [[ "$MODE" == "yes" ]]; then
    run_fastlane_lane android bump_version_code track:"$TRACK"
  elif [[ "$MODE" == "manual" ]]; then
    if [[ ! "$MANUAL_CODE" =~ ^[0-9]+$ ]]; then
      echo "Please provide a valid numeric version code for manual mode."
      exit 1
    fi
    run_fastlane_lane android set_version_code version_code:"$MANUAL_CODE"
  else
    while true; do
      echo "1. Auto bump version code (+1 from Play Store)"
      echo "2. Manually set version code"
      echo "3. Skip"
      read -r -p "Choose (1/2/3): " choice
      case "$choice" in
        1)
          run_fastlane_lane android bump_version_code track:"$TRACK"
          break
          ;;
        2)
          while true; do
            read -r -p "Enter new version code: " new_code
            if [[ "$new_code" =~ ^[0-9]+$ ]]; then
              run_fastlane_lane android set_version_code version_code:"$new_code"
              break 2
            else
              echo "Please enter a valid numeric version code."
            fi
          done
          ;;
        3)
          echo "Skipping version code update."
          break
          ;;
        *)
          echo "Invalid choice, please enter 1, 2, or 3."
          ;;
      esac
    done
  fi

  cd "$AUTO_DIR"
else
  echo "Skipping version code update."
fi
