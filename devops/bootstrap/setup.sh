#!/usr/bin/env bash
# Development environment bootstrap for the pure-Dart workspace and docs.
# The Flutter app additionally needs a local Flutter SDK; see
# docs/src/devops/environment-bootstrap.rst.
set -euo pipefail

cd "$(dirname "$0")/../.."

command -v dart >/dev/null || {
  echo "error: Dart SDK >= 3.9 is required (https://dart.dev/get-dart)" >&2
  exit 1
}

dart pub get
dart analyze

if command -v python3 >/dev/null; then
  python3 -m pip install --quiet sphinx furo
  sphinx-build -W --keep-going -b html docs/src docs/build/html
else
  echo "warning: python3 not found; skipping documentation build" >&2
fi

echo "bootstrap complete"
