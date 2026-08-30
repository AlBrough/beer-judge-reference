#!/usr/bin/env bash
set -euo pipefail

app_path="${1:?Usage: validate-ios-archive.sh <path-to-app-bundle>}"
info_plist="$app_path/Info.plist"

if [[ ! -f "$info_plist" ]]; then
  echo "Missing archived Info.plist: $info_plist" >&2
  exit 1
fi

validate_orientations() {
  local key="$1"
  shift
  local configured

  if ! configured="$(/usr/bin/plutil -extract "$key" json -o - "$info_plist")"; then
    echo "Missing required Info.plist key: $key" >&2
    exit 1
  fi

  for orientation in "$@"; do
    if [[ "$configured" != *"\"$orientation\""* ]]; then
      echo "$key is missing $orientation: $configured" >&2
      exit 1
    fi
  done
}

validate_orientations \
  UISupportedInterfaceOrientations \
  UIInterfaceOrientationPortrait \
  UIInterfaceOrientationLandscapeLeft \
  UIInterfaceOrientationLandscapeRight

validate_orientations \
  'UISupportedInterfaceOrientations~ipad' \
  UIInterfaceOrientationPortrait \
  UIInterfaceOrientationPortraitUpsideDown \
  UIInterfaceOrientationLandscapeLeft \
  UIInterfaceOrientationLandscapeRight

echo "Archived app declares all required iPhone and iPad orientations."
