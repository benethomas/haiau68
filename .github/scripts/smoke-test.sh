#!/usr/bin/env bash
#
# Post-deploy smoke test: confirms the site is reachable over HTTPS and that the
# CloudFront security headers are present. Retries briefly to absorb CloudFront
# invalidation/propagation lag.
#
# Usage: smoke-test.sh <url>
set -euo pipefail

URL="${1:?usage: smoke-test.sh <url>}"
MAX_ATTEMPTS=6
SLEEP_SECONDS=10

echo "Smoke testing ${URL}"

# 1. Reachability — expect HTTP 200, retrying through propagation lag.
code=""
for attempt in $(seq 1 "$MAX_ATTEMPTS"); do
  code=$(curl -sS -o /dev/null -w "%{http_code}" --max-time 15 "$URL" || echo "000")
  if [ "$code" = "200" ]; then
    echo "OK: HTTP 200 (attempt ${attempt})"
    break
  fi
  echo "attempt ${attempt}/${MAX_ATTEMPTS}: got HTTP ${code}, retrying in ${SLEEP_SECONDS}s..."
  sleep "$SLEEP_SECONDS"
done

if [ "$code" != "200" ]; then
  echo "FAIL: ${URL} did not return HTTP 200 (last: ${code})"
  exit 1
fi

# 2. Security headers — must be served by the CloudFront response-headers policy.
headers=$(curl -sSI --max-time 15 "$URL")
echo "--- response headers ---"
echo "$headers"
echo "------------------------"

fail=0
require_header() {
  if ! grep -iq "^$1:" <<<"$headers"; then
    echo "FAIL: missing response header '$1'"
    fail=1
  fi
}

require_header "strict-transport-security"
require_header "content-security-policy"
require_header "x-content-type-options"

if [ "$fail" -ne 0 ]; then
  exit 1
fi

echo "Smoke test passed for ${URL}"
