#!/usr/bin/env bash
set -euo pipefail
: "${AFFIRM_PROMO_BASE_URL:?Live Thor URL required}"
: "${AFFIRM_PUBLIC_KEY:?Live merchant key required}"
: "${AFFIRM_EXPECTED_PROMO_TEXT:?Expected live promo text required}"
export AFFIRM_PROMO_BASE_URL AFFIRM_PUBLIC_KEY AFFIRM_EXPECTED_PROMO_TEXT
DESTINATION="${IOS_DESTINATION:?Select an available simulator before running the live test}"
mkdir -p build
# Check connectivity from the actual macOS runner, independently of XCTest.
curl --fail-with-body --silent --show-error --connect-timeout 20 --max-time 45 \
  --get "$AFFIRM_PROMO_BASE_URL/api/promos/v2/$AFFIRM_PUBLIC_KEY" \
  -H 'Affirm-User-Agent: Affirm-iOS-SDK' \
  --data-urlencode field=ala --data-urlencode amount=50000 \
  --data-urlencode is_sdk=true --data-urlencode show_cta=true \
  --data-urlencode locale=en_US > build/live-promo-preflight.json
xcodebuild build-for-testing -workspace Examples/Examples.xcworkspace -scheme ExamplesUITests \
  -destination "$DESTINATION" -derivedDataPath build/live-derived
shopt -s nullglob
runs=(build/live-derived/Build/Products/*.xctestrun)
test "${#runs[@]}" -eq 1
python3 tools/buildkite/configure-ios-test-run.py "${runs[0]}"
native_status=0
xcodebuild test-without-building -xctestrun "${runs[0]}" \
  -destination "$DESTINATION" -resultBundlePath build/live-promo.xcresult \
  -only-testing:ExamplesUITests/LivePromoThorTests/testRendersPromoFromLiveThor || native_status=$?
xcrun xcresulttool get --legacy --format json --path build/live-promo.xcresult > build/live-promo-result.json
python3 tools/buildkite/verify-ios-test-result.py build/live-promo-result.json
exit "$native_status"
