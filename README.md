# Smech Linux

A live/installable ISO built from Ubuntu's current development series (`devel`, presently
`tenacious` / 27.04) with a vanilla KDE Plasma desktop, Mozilla's Firefox, and the Calamares installer.

## Build

On an Ubuntu host with `debootstrap xorriso squashfs-tools mtools dosfstools syslinux isolinux
grub-pc-bin grub-efi-amd64-bin ubuntu-distro-info` installed, as root:

```bash
./build.sh
```

`configure.sh` installs Debian's live-build 20250814 (Ubuntu's packaged 3.0~a57 is too old),
checks the Mozilla key fingerprint, and runs `lb config`. `build.sh` then runs `lb build` and
renames the result to `smechlinux-<date>-<codename>-amd64.iso` plus a `.sha256` file.

## Layout

- `config/package-lists/smech.list.chroot` - package list (`--apt-recommends false`)
- `config/archives/mozilla.{list,pref}` - Mozilla APT repo, pinned at 1000; Ubuntu's `firefox*` snap stub at -1
- `config/includes.chroot_before_packages/` - Mozilla signing key, downloaded and fingerprint-checked by `configure.sh` (not committed)
- `config/includes.chroot_after_packages/etc/calamares/` - Calamares `settings.conf` and module configs
- `config/includes.chroot_after_packages/usr/share/calamares/branding/smechlinux/` - installer branding
- `config/hooks/live/` - display manager setup, build-time assertions, cleanup

## Deviations from the plain spec (and why)

- **SDDM instead of Plasma Login Manager.** PLM is not in the Ubuntu devel archive (no package,
  source, or file path named `plasma-login*`/`plasmalogin*` in any component or pocket as of 2026-11-14).
  SDDM is a documented exception; swap in PLM when it lands.
- **Debian live-build + live-boot/live-config** (not Ubuntu's casper/livecd-rootfs). The squashfs is
  `live/filesystem.squashfs`, mounted by live-boot at `/run/live/medium`; Calamares `unpackfs` reads it from there.
- **Bootstrap vs. `devel` alias.** debootstrap rejects the alias `devel`, so bootstrap uses the codename;
  the final image's apt sources use `devel`.
- **Calamares config is hand-written.** `calamares-settings-ubuntu-common` assumes casper and depends on
  `snapd-seed-glue`; `calamares-settings-kubuntu` depends on it.

## Release

The ISO is 2,132,803,584 bytes, just under GitHub's 2 GiB release-file limit, so it ships as a single file with its
SHA-256 (`sha256sum -c smechlinux-20261114-tenacious-amd64.iso.sha256`). To fit, the live image carries a firmware
subset (AMD, Intel, NVIDIA, Realtek, MediaTek, Broadcom, Qualcomm Wi-Fi, misc) and the concrete kernel packages instead of
`linux-image-generic` (which hard-depends on the full `linux-firmware`). Calamares installs `linux-image-generic` and the
full `linux-firmware` on the installed system when it has network access. `build.sh` warns if the ISO reaches 2 GiB.

## Known issues

- Boot-tested only in QEMU with software emulation (no KVM): UEFI GRUB menu, kernel/live-boot, SDDM autologin to
  Plasma Wayland, and Firefox were confirmed on the final build. Calamares starts and loads its welcome module; the full install was not run.
- Plasma Login Manager is not in the archive yet, so SDDM is used.

## Live session

User `smech`, created at boot by live-config, auto-logged in by SDDM, passwordless sudo (live only; both
removed from the installed system by Calamares). No SSH keys, tokens, or personal data are included.
US English locale.
