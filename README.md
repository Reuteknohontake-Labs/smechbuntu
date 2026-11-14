# Smech Linux ISO (first build, 2026-11-14)

This branch holds the ISO as a ZIP cut into 90 MiB parts (GitHub rejects files over 100 MiB).
It is a binary-only branch; the build config lives on `main`.

Rejoin, extract, and verify:

```bash
cat smechlinux-20261114-tenacious-amd64.zip.part* > smechlinux-20261114-tenacious-amd64.zip
unzip smechlinux-20261114-tenacious-amd64.zip
sha256sum -c smechlinux-20261114-tenacious-amd64.iso.sha256
```

Known issues in this build: the boot menu still shows the Debian splash and `os-release` still has
Canonical's vendor fields (both fixed in `main`, not in this ISO). Booting to the desktop was not yet confirmed.
