#!/usr/bin/env bash
# Rebuild the Smech Linux ISO from the two release files (GitHub caps each release file at 2 GiB),
# verify it against the published SHA-256, and leave the ISO next to this script.
#
#   ./reassemble.sh              # use files already in this directory
#   ./reassemble.sh <tag>        # first download them from the GitHub release <tag>
set -euo pipefail
cd "$(dirname "$(readlink -f "$0")")"

ISO=smechlinux-20261114-tenacious-amd64.iso
PARTS=("$ISO.part-aa" "$ISO.part-ab")
SUMS="$ISO.sha256"
REPO=Reuteknohontake-Labs/smechbuntu

if [ -n "${1:-}" ]; then
  for f in "${PARTS[@]}" "$SUMS"; do
    [ -s "$f" ] && continue
    url="https://github.com/$REPO/releases/download/$1/$f"
    echo "downloading $f"
    if command -v curl >/dev/null; then curl -fL --retry 3 -o "$f" "$url"
    elif command -v wget >/dev/null; then wget -q -O "$f" "$url"
    else echo "need curl or wget" >&2; exit 1; fi
  done
fi

for f in "${PARTS[@]}" "$SUMS"; do [ -s "$f" ] || { echo "missing $f" >&2; exit 1; }; done
echo "joining..."
cat "${PARTS[@]}" > "$ISO"
echo "verifying SHA-256..."
sha256sum -c "$SUMS"
echo "Done: $PWD/$ISO"
