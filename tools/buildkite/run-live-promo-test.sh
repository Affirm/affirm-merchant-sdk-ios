#!/usr/bin/env bash
set -euo pipefail
: "${AFFIRM_PROMO_BASE_URL:?Live Thor URL required}"
: "${AFFIRM_PUBLIC_KEY:?Live merchant key required}"
: "${AFFIRM_EXPECTED_PROMO_TEXT:?Expected live promo text required}"
export AFFIRM_PROMO_BASE_URL AFFIRM_PUBLIC_KEY AFFIRM_EXPECTED_PROMO_TEXT
DESTINATION="${IOS_DESTINATION:-platform=iOS Simulator,name=iPhone 17 Pro,OS=26.5}"
xcodebuild build-for-testing -workspace Examples/Examples.xcworkspace -scheme ExamplesUITests \
  -destination "$DESTINATION" -derivedDataPath build/live-derived
shopt -s nullglob
runs=(build/live-derived/Build/Products/*.xctestrun)
test "${#runs[@]}" -eq 1
python3 tools/buildkite/configure-ios-test-run.py "${runs[0]}"
xcodebuild test-without-building -xctestrun "${runs[0]}" \
  -destination "$DESTINATION" -resultBundlePath build/live-promo.xcresult \
  -only-testing:ExamplesUITests/LivePromoThorTests/testRendersPromoFromLiveThor
xcrun xcresulttool get --legacy --format json --path build/live-promo.xcresult > build/live-promo-result.json
python3 tools/buildkite/verify-ios-test-result.py build/live-promo-result.json
