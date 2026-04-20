# Nightmare-linux
Nightmare-infused Debian stable with a GRUB 2 “nightmare” theme, custom-kernel hook, and live ISO (with installer).

## What this repo contains
- Scripts to configure and build a Debian stable live ISO (GRUB 2, EFI, installer enabled).
- A minimal GRUB theme and menu entries for the Nightmare look.
- A placeholder kernel config and helper script to build custom kernel .deb packages.

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
  - `background.xpm`: matrix-style backdrop (static).
  - `title.xpm`: blood-drip Nightmare title (static).
  - `theme.txt`: colors and layout; references the assets above.
- Menu entries live in `config/grub/grub.cfg`.
- Re-run `./scripts/setup-live-build.sh` to sync assets into the live-build tree.

Note: GRUB themes are static; true animation (matrix rain or dripping) would need a boot splash stage (e.g., plymouth) added later in the initramfs.

## Next steps
- Flesh out the kernel config for required features (filesystem targets, firmware, RT, etc.).
- Add branding assets (background, fonts) to `config/grub/nightmare/`.
- Add package lists and hooks for desktop environment and installer defaults.
