#!/bin/zsh
set -euo pipefail

device_id="$1"
output_dir="$2"
app_path="/private/tmp/PawprintDiaryMarketingBuild/Build/Products/Debug-iphonesimulator/PawprintDiary.app"
bundle_id="com.anto.PawprintDiary"

mkdir -p "$output_dir"

if ! xcrun simctl boot "$device_id" 2>/dev/null; then
  true
fi
xcrun simctl bootstatus "$device_id" -b
xcrun simctl install "$device_id" "$app_path"
xcrun simctl status_bar "$device_id" override \
  --time "9:41" \
  --batteryState charged \
  --batteryLevel 100 \
  --wifiBars 3 \
  --cellularBars 4

capture_tab() {
  local file_name="$1"
  local tab="$2"
  xcrun simctl terminate "$device_id" "$bundle_id" 2>/dev/null || true
  xcrun simctl launch "$device_id" "$bundle_id" \
    --ui-test-sample-data \
    --ui-test-expanded-add-sheet \
    "--ui-test-tab=$tab"
  sleep 2
  xcrun simctl io "$device_id" screenshot "$output_dir/$file_name.png"
}

capture_tab "01-home" 0
capture_tab "02-records" 1
capture_tab "03-add-record" 2
capture_tab "04-taste-ranking" 3
capture_tab "05-pets-sharing" 4
