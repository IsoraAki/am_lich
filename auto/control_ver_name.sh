#!/bin/bash
set -euo pipefail

export FASTLANE_SKIP_SCREEN=${FASTLANE_SKIP_SCREEN:-1}
export TTY_SCREEN_WIDTH=${TTY_SCREEN_WIDTH:-120}
export TTY_SCREEN_HEIGHT=${TTY_SCREEN_HEIGHT:-40}

MODE="${1:-ask}"
MANUAL_VERSION="${2:-}"
update_name=false

if [[ "$MODE" == "yes" ]]; then
  update_name=true
elif [[ "$MODE" == "no" ]]; then
  echo "Skipping version name update."
  exit 0
elif [[ "$MODE" == "manual" ]]; then
  update_name=true
else
  while true; do
    read -r -p "Do you want to update the version name? [Y/n] " versionNameChoice
    case "$versionNameChoice" in
      ''|[Yy]|[Yy][Ee][Ss])
        update_name=true
        break
        ;;
      [Nn]|[Nn][Oo])
        echo "Skipping version name update."
        exit 0
        ;;
      *)
        echo "Please answer Y or n."
        ;;
    esac
  done
fi

if [[ "$update_name" == true ]]; then
  ROOT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )"
  ANDROID_DIR="$ROOT_DIR/android"
  AUTO_DIR="$ROOT_DIR/auto"
  cd "$ANDROID_DIR"

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
    echo "fastlane not found. Install it or add to your PATH."
    exit 1
  fi

  run_fastlane_lane() {
    FASTLANE_SKIP_SCREEN=1 TTY_SCREEN_WIDTH=$TTY_SCREEN_WIDTH TTY_SCREEN_HEIGHT=$TTY_SCREEN_HEIGHT \
      $FASTLANE_CMD "$@"
  }

  extract_version_name_from_output() {
    local output="$1"
    echo "$output" | tr -d '\r' | sed -n 's/.*VERSION_NAME_ONLY:\([^[:space:]][^[:space:]]*\).*/\1/p' | tail -n1
  }

  bump_version_name() {
    local current="$1"
    local prefix=""
    local ver="$current"

    if [[ "$current" == *_* ]]; then
      prefix="${current%%_*}_"
      ver="${current#*_}"
    fi

    if [[ ! "$ver" =~ ^[0-9]+(\.[0-9]+)*$ ]]; then
      return 1
    fi

    IFS='.' read -ra parts <<< "$ver"
    last_index=$(( ${#parts[@]} - 1 ))
    parts[$last_index]=$(( ${parts[$last_index]} + 1 ))

    new_version="${parts[0]}"
    for ((i=1; i<${#parts[@]}; i++)); do
      new_version+=".${parts[$i]}"
    done

    echo "${prefix}${new_version}"
  }

  echo "Fetching current version name..."
  if ! output=$(run_fastlane_lane android get_version_name 2>&1); then
    printf '%s\n' "Failed to retrieve version name." "$output" >&2
    exit 1
  fi
  CURRENT_VERSION_NAME=$(extract_version_name_from_output "$output")

  if [[ -z "$CURRENT_VERSION_NAME" ]]; then
    echo "Failed to retrieve version name."
    echo "---- get_version_name output ----"
    echo "$output"
    exit 1
  fi

  echo "Current Version Name: $CURRENT_VERSION_NAME"
  echo "----------------------------------------"

  if [[ "$MODE" == "yes" ]]; then
    NEW_VERSION_NAME=$(bump_version_name "$CURRENT_VERSION_NAME") || {
      echo "Cannot auto bump version name '$CURRENT_VERSION_NAME'. Use manual mode."
      exit 1
    }
    echo "Auto bumped version name to: $NEW_VERSION_NAME"
    run_fastlane_lane android update_version_name version_name:"$NEW_VERSION_NAME"
  elif [[ "$MODE" == "manual" && -n "$MANUAL_VERSION" ]]; then
    run_fastlane_lane android update_version_name version_name:"$MANUAL_VERSION"
  else
    while true; do
      echo "1. Auto bump version name"
      echo "2. Manually set version name"
      echo "3. Skip"
      read -r -p "Choose an option (1/2/3): " choice

      case "$choice" in
        1)
          NEW_VERSION_NAME=$(bump_version_name "$CURRENT_VERSION_NAME") || {
            echo "Cannot auto bump version name '$CURRENT_VERSION_NAME'. Choose manual mode."
            continue
          }
          echo "Auto bumped version name to: $NEW_VERSION_NAME"
          run_fastlane_lane android update_version_name version_name:"$NEW_VERSION_NAME"
          break
          ;;
        2)
          read -r -p "Enter the new version name: " NEW_VERSION_NAME
          run_fastlane_lane android update_version_name version_name:"$NEW_VERSION_NAME"
          break
          ;;
        3)
          echo "Skipping version name update."
          break
          ;;
        *)
          echo "Invalid choice, please enter 1, 2, or 3."
          ;;
      esac
    done
  fi
fi

cd "$AUTO_DIR"
