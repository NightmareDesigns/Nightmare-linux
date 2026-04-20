#!/usr/bin/env bash
set -euo pipefail

ISO_PATH="${1:-}"
WORKDIR="${WORKDIR:-$(mktemp -d)}"
QEMU_RAM="${QEMU_RAM:-2048}"
QEMU_SMP="${QEMU_SMP:-2}"
LIVE_TIMEOUT="${LIVE_TIMEOUT:-320}"
INSTALL_TIMEOUT="${INSTALL_TIMEOUT:-420}"

cleanup() {
  rm -rf "${WORKDIR}"
}
trap cleanup EXIT

log() {
  echo "[smoke] $*"
}

need_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Missing required command: $1" >&2
    exit 1
  fi
}

need_cmd qemu-system-x86_64
need_cmd qemu-img
need_cmd xorriso
need_cmd timeout

if [ -z "${ISO_PATH}" ]; then
  ISO_PATH="$(ls -1 build/live/*.iso 2>/dev/null | head -n 1 || true)"
fi

if [ -z "${ISO_PATH}" ] || [ ! -f "${ISO_PATH}" ]; then
  echo "Usage: $0 /path/to/nightmare.iso" >&2
  exit 1
fi

extract_from_iso() {
  local iso="$1"
  local src="$2"
  local dest="$3"
  xorriso -indev "${iso}" -osirrox on -extract "${src}" "${dest}" >/dev/null 2>&1
}

LIVE_KERNEL="${WORKDIR}/live-vmlinuz"
LIVE_INITRD="${WORKDIR}/live-initrd.img"
INSTALL_KERNEL="${WORKDIR}/install-vmlinuz"
INSTALL_INITRD="${WORKDIR}/install-initrd.gz"

extract_from_iso "${ISO_PATH}" "/live/vmlinuz" "${LIVE_KERNEL}"
extract_from_iso "${ISO_PATH}" "/live/initrd.img" "${LIVE_INITRD}"
extract_from_iso "${ISO_PATH}" "/install/vmlinuz" "${INSTALL_KERNEL}"
extract_from_iso "${ISO_PATH}" "/install/initrd.gz" "${INSTALL_INITRD}"

if [ ! -s "${LIVE_KERNEL}" ] || [ ! -s "${LIVE_INITRD}" ]; then
  echo "Unable to extract live kernel/initrd from ${ISO_PATH}" >&2
  exit 1
fi

if [ ! -s "${INSTALL_KERNEL}" ] || [ ! -s "${INSTALL_INITRD}" ]; then
  echo "Unable to extract installer kernel/initrd from ${ISO_PATH}" >&2
  exit 1
fi

run_qemu() {
  local log_path="$1"
  shift
  local status=0

  set +e
  "$@" | tee "${log_path}"
  status=${PIPESTATUS[0]}
  set -e

  if [ "${status}" -ne 0 ]; then
    echo "Command failed (status ${status}). Log: ${log_path}" >&2
  fi

  return "${status}"
}

live_sanity() {
  local log_path="${WORKDIR}/live-console.log"
  local live_disk="${WORKDIR}/live-tmp.qcow2"
  qemu-img create -f qcow2 "${live_disk}" 2G >/dev/null

  log "Booting live environment (console on ttyS0)..."
  if ! run_qemu "${log_path}" timeout "${LIVE_TIMEOUT}" qemu-system-x86_64 \
    -m "${QEMU_RAM}" \
    -smp "${QEMU_SMP}" \
    -cdrom "${ISO_PATH}" \
    -kernel "${LIVE_KERNEL}" \
    -initrd "${LIVE_INITRD}" \
    -append "boot=live components console=ttyS0 systemd.show_status=1 quiet splash" \
    -drive file="${live_disk}",if=virtio,format=qcow2 \
    -serial mon:stdio \
    -display none \
    -no-reboot \
    -nodefaults \
    -device virtio-net,netdev=net0 \
    -netdev user,id=net0; then
    return 1
  fi

  if ! grep -E "Reached target (Multi-User System|Graphical Interface)|Started Light Display Manager" "${log_path}" >/dev/null; then
    echo "Live boot did not reach expected targets. See ${log_path}" >&2
    return 1
  fi

  log "Live boot smoke test passed."
}

installer_sanity() {
  local log_path="${WORKDIR}/installer-console.log"
  local disk_path="${WORKDIR}/installer.qcow2"
  qemu-img create -f qcow2 "${disk_path}" 6G >/dev/null

  log "Booting installer (console on ttyS0)..."
  if ! run_qemu "${log_path}" timeout "${INSTALL_TIMEOUT}" qemu-system-x86_64 \
    -m "${QEMU_RAM}" \
    -smp "${QEMU_SMP}" \
    -cdrom "${ISO_PATH}" \
    -kernel "${INSTALL_KERNEL}" \
    -initrd "${INSTALL_INITRD}" \
    -append "console=ttyS0 priority=critical auto=false DEBIAN_FRONTEND=text" \
    -drive file="${disk_path}",if=virtio,format=qcow2 \
    -serial mon:stdio \
    -display none \
    -no-reboot \
    -nodefaults \
    -device virtio-net,netdev=net0 \
    -netdev user,id=net0; then
    return 1
  fi

  if ! grep -Ei "Debian GNU/Linux installer|main-menu" "${log_path}" >/dev/null; then
    echo "Installer did not reach the menu. See ${log_path}" >&2
    return 1
  fi

  log "Installer boot smoke test passed."
}

live_sanity
installer_sanity

log "Smoke tests completed successfully against ${ISO_PATH}"
