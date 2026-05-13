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
sudo apt-get install -y live-build grub-pc-bin grub-efi-amd64-bin mtools xorriso rsync syslinux-utils build-essential bc bison flex libssl-dev libncurses-dev
```

## Quick start: live ISO
```
./scripts/setup-live-build.sh        # configure live-build for Debian stable (bookworm)
./scripts/build-iso.sh               # produces build/live/*.iso
```
Environment variables you can override:
- `DIST` (default: bookworm)
- `MIRROR`, `SECURITY_MIRROR`
- `ENABLE_SECURITY_REPO` (default: true; set to `false` if your host live-build uses an outdated Debian security suite path)
- `DEBIAN_INSTALLER` (default: live; set to `false` to skip Debian installer integration)
- `ISO_APP_NAME`, `ISO_VOLUME`
- `BUILD_DIR` (default: build/live)

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

Note: GRUB themes are static; true animation (matrix rain or dripping) would need a boot splash stage (e.g., plymouth) added later in the initramfs.

## Desktop + installer defaults
- Live-build package lists and hooks live under `config/live/`:
  - `package-lists/`: base tools, firmware, and XFCE desktop packages.
  - `hooks/normal/installer-defaults.hook.chroot`: seeds live-config defaults (user/locale/timezone), LightDM autologin, and a Debian Installer preseed.
  - `includes.installer/preseed.cfg`: bundled into the installer image for consistent defaults.
- `./scripts/setup-live-build.sh` copies these into the live-build config tree.

## Next steps
- Add a plymouth splash that matches the GRUB theme.
- Add automated smoke tests (boot + installer flow) in CI.
