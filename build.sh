#!/bin/bash
# Build the ISO and name it smechlinux-<date>-<codename>-amd64.iso. Run as root.
set -euo pipefail
cd "$(dirname "$(readlink -f "$0")")"
./configure.sh

# Stages run separately so a TEMPORARY apt proxy/CA config can be injected into the chroot when building
# behind a TLS-intercepting proxy (hook 0900-clean removes it from the image).
CA=${BUILD_CA_BUNDLE:-}   # path to a CA bundle when building behind a TLS-intercepting proxy
{
lb bootstrap
# Mozilla key must exist before the first apt update (signed-by path in config/archives/mozilla.list)
mkdir -p chroot/etc/apt/keyrings
cp config/includes.chroot_before_packages/etc/apt/keyrings/packages.mozilla.org.asc chroot/etc/apt/keyrings/   # fetched + fingerprint-checked by configure.sh
if [ -f "$CA" ] && [ -n "${HTTPS_PROXY:-}" ]; then
  mkdir -p chroot/etc/apt/apt.conf.d
  cp "$CA" chroot/etc/apt/build-ca.crt
  printf 'Acquire::https::CaInfo "/etc/apt/build-ca.crt";\nAcquire::https::Proxy "%s";\n' "$HTTPS_PROXY" \
    > chroot/etc/apt/apt.conf.d/99build-proxy
fi
lb chroot
lb installer
lb binary
} 2>&1 | tee build.log
CODENAME=$(ubuntu-distro-info --devel)
OUT="smechlinux-$(date +%Y%m%d)-${CODENAME}-amd64.iso"
mv smechlinux-amd64.hybrid.iso "$OUT"
sha256sum "$OUT" > "$OUT.sha256"
ls -l "$OUT"; cat "$OUT.sha256"
SIZE=$(stat -c %s "$OUT")
echo "ISO size: $SIZE bytes"
[ "$SIZE" -lt 2147483648 ] || echo "WARNING: ISO is >= 2 GiB; GitHub release files must be under 2 GiB" >&2
