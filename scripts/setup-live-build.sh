#!/usr/bin/env bash
set -euo pipefail

BUILD_DIR="${BUILD_DIR:-build/live}"
DIST="${DIST:-bookworm}"
MIRROR="${MIRROR:-http://deb.debian.org/debian}"
SECURITY_MIRROR="${SECURITY_MIRROR:-http://security.debian.org/debian-security}"
ENABLE_SECURITY_REPO="${ENABLE_SECURITY_REPO:-true}"
ISO_APP_NAME="${ISO_APP_NAME:-Nightmare Linux}"
ISO_VOLUME="${ISO_VOLUME:-NIGHTMARE_LIVE}"
LB_OPTS=(
  --mode debian
  --distribution "${DIST}"
  --archive-areas "main contrib non-free non-free-firmware"
  --architectures amd64
  --binary-images iso-hybrid
  --debian-installer false
  --bootloader grub-efi
  --iso-application "${ISO_APP_NAME}"
  --iso-volume "${ISO_VOLUME}"
  --mirror-bootstrap "${MIRROR}"
  --mirror-binary "${MIRROR}"
  --apt-indices false
  --firmware-binary true
  --firmware-chroot true
  # Disable live-build automatic kernel resolver because some host versions
  # fetch deprecated Contents-amd64.gz metadata and fail on bookworm.
  # Kernel install (linux-image-amd64) is handled via
  # config/live/package-lists/nightmare-base.list.chroot.
  --linux-packages none
)

if ! command -v lb >/dev/null 2>&1; then
  echo "live-build (lb) is required. Install with: sudo apt-get install -y live-build" >&2
  exit 1
fi

# Older live-build builds do not support --updates/--security; add them only
# when available so the script works across Debian and Ubuntu hosts.
if lb config --help 2>/dev/null | grep -q -- "--updates"; then
  LB_OPTS+=(--updates true)
fi
if lb config --help 2>/dev/null | grep -q -- "--security"; then
  if [ "${ENABLE_SECURITY_REPO}" = "true" ]; then
    LB_OPTS+=(--mirror-binary-security "${SECURITY_MIRROR}")
    LB_OPTS+=(--security true)
  else
    LB_OPTS+=(--security false)
  fi
fi

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
mkdir -p "${BUILD_DIR}"
cd "${BUILD_DIR}"

echo "[nightmare] configuring live-build in ${BUILD_DIR}"
lb config "${LB_OPTS[@]}"

# Drop Nightmare GRUB theme and menu entries into includes
THEME_SRC="${ROOT}/config/grub/nightmare"
THEME_DEST="config/includes.binary/boot/grub/themes/nightmare"
mkdir -p "${THEME_DEST}"
rsync -a --delete "${THEME_SRC}/" "${THEME_DEST}/"

GRUB_CFG_SRC="${ROOT}/config/grub/grub.cfg"
GRUB_CFG_DEST="config/includes.binary/boot/grub/grub.cfg"
mkdir -p "$(dirname "${GRUB_CFG_DEST}")"
cp "${GRUB_CFG_SRC}" "${GRUB_CFG_DEST}"

# Kernel config placeholder copy for future custom builds
KERNEL_CFG_SRC="${ROOT}/config/kernel/nightmare.config"
KERNEL_CFG_DEST="config/includes.chroot/usr/src/nightmare/nightmare.config"
mkdir -p "$(dirname "${KERNEL_CFG_DEST}")"
cp "${KERNEL_CFG_SRC}" "${KERNEL_CFG_DEST}"

# Copy package lists, hooks, and installer/live defaults
LIVE_SRC="${ROOT}/config/live"
if [ -d "${LIVE_SRC}/package-lists" ]; then
  mkdir -p config/package-lists
  rsync -a --delete "${LIVE_SRC}/package-lists/" config/package-lists/
fi
if [ -d "${LIVE_SRC}/hooks" ]; then
  mkdir -p config/hooks
  rsync -a --delete "${LIVE_SRC}/hooks/" config/hooks/
fi
if [ -d "${LIVE_SRC}/includes.chroot" ]; then
  mkdir -p config/includes.chroot
  rsync -a --delete "${LIVE_SRC}/includes.chroot/" config/includes.chroot/
fi

cat <<'EOF'
[nightmare] live-build configured.
- To build the ISO: ./scripts/build-iso.sh
- To regenerate config after edits: rerun this script.
EOF
