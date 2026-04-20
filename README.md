# Nightmare-linux
Nightmare-infused Debian stable with a GRUB 2 “nightmare” theme, custom-kernel hook, and live ISO (with installer).

## What this repo contains
- Scripts to configure and build a Debian stable live ISO (GRUB 2, EFI, installer enabled).
- A minimal GRUB theme and menu entries for the Nightmare look.
- A kernel config tuned for common filesystems/firmware/RT and a helper script to build custom kernel .deb packages.
- Desktop package lists, firmware coverage, and installer/live defaults to ship a usable XFCE session out of the box.

## Prereqs (Debian/Ubuntu host)
```
sudo apt-get update
sudo apt-get install -y live-build grub-pc-bin grub-efi-amd64-bin mtools xorriso rsync build-essential bc bison flex libssl-dev libncurses-dev
```

## Quick start: live ISO
```
./scripts/setup-live-build.sh        # configure live-build for Debian stable (bookworm)
./scripts/build-iso.sh               # produces build/live/*.iso
```
Environment variables you can override:
- `DIST` (default: bookworm)
- `MIRROR`, `SECURITY_MIRROR`
- `ISO_APP_NAME`, `ISO_VOLUME`
- `BUILD_DIR` (default: build/live)

Smoke test the resulting ISO with QEMU serial consoles:
```
./scripts/smoke-tests.sh build/live/*.iso
```

## Custom kernel flow
1) Put a full kernel `.config` in `config/kernel/nightmare.config` (copy from `/boot/config-$(uname -r)` and tweak).  
2) Download/extract kernel sources to `build/kernel/linux` (e.g., from kernel.org).  
3) Build packages:
```
./scripts/build-kernel.sh
```
Resulting `.deb` files land in `build/kernel`.

## GRUB theming
- Assets live in `config/grub/nightmare/`:
  - `background.xpm`: dark neon backdrop.
  - `title.xpm`: Nightmare title mark.
  - `unicode.pf2`: bundled font for menu/title rendering.
  - `theme.txt`: colors and layout; references the assets above.
- Menu entries live in `config/grub/grub.cfg`.
- Re-run `./scripts/setup-live-build.sh` to sync assets into the live-build tree.

### Plymouth splash
- Theme lives under `config/live/includes.chroot/usr/share/plymouth/themes/nightmare/` and reuses the GRUB backdrop/title.
- `config/live/includes.chroot/etc/plymouth/plymouthd.conf` sets it as the default theme.
- `config/live/hooks/normal/plymouth-theme.hook.chroot` runs `plymouth-set-default-theme -R nightmare` so the initramfs picks it up.

## Desktop + installer defaults
- Live-build package lists and hooks live under `config/live/`:
  - `package-lists/`: base tools, firmware, and XFCE desktop packages.
  - `hooks/normal/installer-defaults.hook.chroot`: seeds live-config defaults (user/locale/timezone), LightDM autologin, and a Debian Installer preseed.
  - `includes.installer/preseed.cfg`: bundled into the installer image for consistent defaults.
- `./scripts/setup-live-build.sh` copies these into the live-build config tree.

## CI and automation
- `.github/workflows/ci.yml` builds the live ISO on pushes/PRs and publishes it as an artifact, then boots the live image and installer via QEMU for smoke coverage.
- `scripts/smoke-tests.sh` can be run locally against any built ISO to mirror the CI checks.
