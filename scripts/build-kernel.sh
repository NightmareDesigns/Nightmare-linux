#!/usr/bin/env bash
set -euo pipefail

# Minimal helper to build a custom kernel .deb using the provided config.
# Assumes kernel sources are available in ${KERNEL_SRC} (defaults to ./build/kernel/linux).

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
KERNEL_CFG="${KERNEL_CFG:-${ROOT}/config/kernel/nightmare.config}"
WORKDIR="${WORKDIR:-${ROOT}/build/kernel}"
KERNEL_SRC="${KERNEL_SRC:-${WORKDIR}/linux}"

mkdir -p "${WORKDIR}"

if [ ! -d "${KERNEL_SRC}" ]; then
  cat <<'EOF' >&2
Kernel source not found.
- Download and extract a kernel tarball into ${KERNEL_SRC}, e.g.:
  mkdir -p ${WORKDIR} && cd ${WORKDIR}
  wget https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-6.6.0.tar.xz
  tar -xf linux-6.6.0.tar.xz
  mv linux-6.6.0 linux
Then rerun this script.
EOF
  exit 1
fi

if [ ! -f "${KERNEL_CFG}" ]; then
  echo "Kernel config ${KERNEL_CFG} missing." >&2
  exit 1
fi

cd "${KERNEL_SRC}"
echo "[nightmare] applying kernel config"
cp "${KERNEL_CFG}" .config
yes "" | make olddefconfig

echo "[nightmare] building deb packages (may take time)..."
make -j"$(nproc)" bindeb-pkg

echo "[nightmare] build complete. Packages are in ${WORKDIR}"
