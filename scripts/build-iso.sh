#!/usr/bin/env bash
set -euo pipefail

BUILD_DIR="${BUILD_DIR:-build/live}"

if ! command -v lb >/dev/null 2>&1; then
  echo "live-build (lb) is required. Install with: sudo apt-get install -y live-build" >&2
  exit 1
fi

if [ ! -d "${BUILD_DIR}/config" ]; then
  echo "No live-build config found in ${BUILD_DIR}. Run ./scripts/setup-live-build.sh first." >&2
  exit 1
fi

cd "${BUILD_DIR}"
echo "[nightmare] cleaning previous build artifacts"
lb clean --purge || true

echo "[nightmare] building ISO (this can take a while)..."
lb build

echo "[nightmare] build complete."
ISO_PATH="$(ls -1t *.iso 2>/dev/null | head -n 1 || true)"
if [ -n "${ISO_PATH}" ]; then
  echo "Latest ISO: ${BUILD_DIR}/${ISO_PATH}"
else
  echo "ISO not found; check live-build logs."
fi
