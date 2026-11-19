#!/usr/bin/env bash
# Release builds read their config from .env (same file as debug runs).
#   tool/build_release.sh android | ios | all
set -euo pipefail
cd "$(dirname "$0")/.."

ENV_FILE=".env"
target="${1:-all}"

[[ -f "$ENV_FILE" ]] || { echo "✗ $ENV_FILE not found (copy env.example)"; exit 1; }

val() { grep -E "^$1=" "$ENV_FILE" | tail -1 | cut -d= -f2- | tr -d '"' | xargs; }

[[ -n "$(val FAL_AI_API_KEY)" ]] || { echo "✗ FAL_AI_API_KEY is empty in $ENV_FILE"; exit 1; }
for k in REVENUECAT_IOS_KEY REVENUECAT_ANDROID_KEY; do
  [[ -n "$(val "$k")" ]] || { echo "✗ $k is empty in $ENV_FILE"; exit 1; }
done
[[ "$(val REVENUECAT_IOS_KEY)" == appl_* ]] || { echo "✗ REVENUECAT_IOS_KEY must start with appl_"; exit 1; }
[[ "$(val REVENUECAT_ANDROID_KEY)" == goog_* ]] || { echo "✗ REVENUECAT_ANDROID_KEY must start with goog_"; exit 1; }

args=(--release --dart-define-from-file="$ENV_FILE")
case "$target" in
  android) flutter build appbundle "${args[@]}" ;;
  ios)     flutter build ipa "${args[@]}" ;;
  all)     flutter build appbundle "${args[@]}" && flutter build ipa "${args[@]}" ;;
  *) echo "usage: $0 android|ios|all"; exit 1 ;;
esac
