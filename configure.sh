#!/bin/bash
# Prepare host + run `lb config` for Smech Linux. Run as root from the repo directory.
set -euo pipefail
cd "$(dirname "$(readlink -f "$0")")"

# --- live-build: Ubuntu's packaged 3.0~a57 is too old; install Debian's 20250814 (replaces the Ubuntu one on this build host)
if ! dpkg-query -W -f='${Version}' live-build 2>/dev/null | grep -q '^20250814'; then
  LB_SRC=${LB_SRC:-/opt/lb-src}; mkdir -p "$LB_SRC"
  ( cd "$LB_SRC"
    [ -f live-build_20250814_all.deb ] || curl -fsSL -O http://deb.debian.org/debian/pool/main/l/live-build/live-build_20250814_all.deb
    echo "a4bffb8e6436ffba260f2e1c37be9dd04a4dacf52c38d7bbe454ec826ba52a4b  live-build_20250814_all.deb" | sha256sum -c -
    dpkg -r live-build 2>/dev/null || true
    dpkg -i live-build_20250814_all.deb )
fi

# --- debootstrap has no script named "devel"; alias it to the current devel series
DEVEL=$(ubuntu-distro-info --devel)
[ -e /usr/share/debootstrap/scripts/devel ] || ln -s "$DEVEL" /usr/share/debootstrap/scripts/devel

# NOTE: debootstrap refuses suite alias 'devel' (Release says tenacious), so bootstrap uses the codename;
# everything configured inside the chroot/image (sources.list) uses the 'devel' alias.

# --- fetch the Mozilla APT key and verify its fingerprint (value published on hacks.mozilla.org / Mozilla's install docs)
EXPECT=35BAA0B33E9EB396F59CA838C0BA5CE6DC6315A3
KEYDIR=config/includes.chroot_before_packages/etc/apt/keyrings
mkdir -p "$KEYDIR"
curl -fsSL https://packages.mozilla.org/apt/repo-signing-key.gpg -o "$KEYDIR/packages.mozilla.org.asc"
gpg --show-keys --with-colons "$KEYDIR/packages.mozilla.org.asc" | grep -q "^fpr:::::::::$EXPECT:" \
  || { echo "ERROR: Mozilla key fingerprint mismatch"; exit 1; }

# --- Kernel: linux-image-generic hard-depends on the full linux-firmware (~700 MiB), which pushes the ISO over GitHub's
# 2 GiB release-file limit. Install the concrete kernel packages it points at, plus a chosen firmware subset
# (see config/package-lists/smech.list.chroot). The installed system gets linux-image-generic + full firmware via Calamares.
KVER_DEPS=$(curl -fsSL "http://archive.ubuntu.com/ubuntu/dists/$DEVEL/main/binary-amd64/Packages.xz" | xzcat \
  | awk '$0=="Package: linux-image-generic"{f=1} f&&/^Depends:/{print; f=0}' | sed 's/^Depends: //' | tr ',' '\n' \
  | sed 's/^ *//; s/ .*//' | grep -E '^linux-(image|modules)-[0-9]')
[ -n "$KVER_DEPS" ] || { echo "ERROR: could not resolve kernel packages"; exit 1; }
printf '%s\n' $KVER_DEPS > config/package-lists/kernel.list.chroot
KFLAV=$(printf '%s\n' $KVER_DEPS | sed -n 's/^linux-image-//p' | head -1)   # e.g. 7.3.0-9-generic

MIRROR=http://archive.ubuntu.com/ubuntu/
lb config noauto \
  --mode debian \
  --distribution "$DEVEL" --parent-distribution "$DEVEL" \
  --distribution-chroot "$DEVEL" --parent-distribution-chroot "$DEVEL" \
  --distribution-binary devel --parent-distribution-binary devel \
  --architectures amd64 \
  --archive-areas "main universe" \
  --parent-archive-areas "main universe" \
  --mirror-bootstrap "$MIRROR" --mirror-chroot "$MIRROR" --mirror-binary "$MIRROR" \
  --parent-mirror-bootstrap "$MIRROR" --parent-mirror-chroot "$MIRROR" --parent-mirror-binary "$MIRROR" \
  --parent-mirror-chroot-security none --parent-mirror-binary-security none \
  --mirror-chroot-security none --mirror-binary-security none \
  --security false --updates false --backports false \
  --debootstrap-options "--variant=minbase --keyring=/usr/share/keyrings/ubuntu-archive-keyring.gpg" \
  --apt-recommends false --apt-indices false --apt-secure true \
  --linux-flavours "$KFLAV" --linux-packages "linux-image" \
  --firmware-chroot false --firmware-binary false \
  --initramfs live-boot --initsystem systemd \
  --bootloaders "syslinux,grub-efi" --binary-image iso-hybrid \
  --iso-application "Smech Linux" --iso-publisher "Smech Linux" --iso-volume SMECHLINUX \
  --image-name smechlinux \
  --bootappend-live "boot=live components quiet splash username=smech user-fullname=Smech hostname=smechlinux locales=en_US.UTF-8 keyboard-layouts=us timezone=UTC" \
  --memtest none --win32-loader false --checksums sha256 \
  --compression xz --zsync false
