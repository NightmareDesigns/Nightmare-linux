#!/usr/bin/env bash
set -euo pipefail

BUILD_DIR="${BUILD_DIR:-build/live}"
DIST="${DIST:-bookworm}"
MIRROR="${MIRROR:-http://deb.debian.org/debian}"
SECURITY_MIRROR="${SECURITY_MIRROR:-http://security.debian.org/debian-security}"
ISO_APP_NAME="${ISO_APP_NAME:-Nightmare Linux}"
ISO_VOLUME="${ISO_VOLUME:-NIGHTMARE_LIVE}"
LB_OPTS=(
  --mode debian
  --distribution "${DIST}"
  --archive-areas "main contrib non-free non-free-firmware"
  --architectures amd64
  --binary-images iso-hybrid
  --debian-installer live
  --bootloader grub-efi
  --iso-application "${ISO_APP_NAME}"
  --iso-volume "${ISO_VOLUME}"
  --mirror-bootstrap "${MIRROR}"
  --mirror-binary "${MIRROR}"
  --mirror-binary-security "${SECURITY_MIRROR}"
  --apt-indices false
  --updates true
  --security true
  --firmware-binary true
  --firmware-chroot true
  --linux-flavours amd64
  --linux-packages linux-image
)

if ! command -v lb >/dev/null 2>&1; then
  echo "live-build (lb) is required. Install with: sudo apt-get install -y live-build" >&2
  exit 1
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

cat <<'EOF'
[nightmare] live-build configured.
- To build the ISO: ./scripts/build-iso.sh
- To regenerate config after edits: rerun this script.
EOF
