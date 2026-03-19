#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

if command -v fvm >/dev/null 2>&1; then
  FLUTTER_CMD=(fvm flutter)
else
  FLUTTER_CMD=(flutter)
fi

"${FLUTTER_CMD[@]}" test \
  test/providers/auth_oauth_model_test.dart \
  test/widgets/login_page_oauth_test.dart \
  test/providers/flash_sale_model_test.dart \
  test/providers/purchase_state_flash_sale_test.dart \
  test/widgets/flash_sale_product_page_test.dart \
  "$@"

