# CineView MLA — Smart Installer

Design & Development by habeb-s © 2026

**CineView MLA 1.0.3 · Smart Installer 1.3.3**

One installer for **OpenATV 7.6+, OpenBH 5.6+ and OpenViX 6.7+** on any Enigma2 receiver. It is not tied to a
receiver model, brand, multiboot slot or a single image version: it identifies the image, its version and its Python
by itself (wherever it is installed), chooses the matching package, verifies its SHA256 and installs it.

## Install / update (telnet or SSH on the receiver)

```
wget -qO /tmp/cineview-install.sh https://raw.githubusercontent.com/habeb-s/CineView-MLA-Install/main/cineview-install.sh && sh /tmp/cineview-install.sh
```

Options (before `sh`): `DRYRUN=1` checks only · `ROLLBACK=1` previous release · `RESTART=1` restart the GUI without asking

## Compatibility

| Image | Versions | Python | Package | Status |
|---|---|---|---|---|
| OpenATV | 8.0 | 3.14 | 1.0.3 | device-tested (install, reinstall, rollback) |
| OpenATV | 7.6 | 3.13 | 1.0.3~openatv.py313 | verified statically¹ |
| OpenATV | 8.1 and newer | 3.14 | 1.0.3~openatv.py314 | verified statically¹ |
| OpenBH | 5.6 | 3.13 | 1.0.3~openbh1 | device-tested |
| OpenBH | 5.7 and newer 5.x | 3.13 | 1.0.3~openbh.py313 | verified statically¹ |
| OpenBH | 6.0 and newer | 3.14 | 1.0.3~openbh.py314 | verified statically¹ |
| OpenViX | 6.9 | 3.14 | 1.0.3~openvix1 | device-tested |
| OpenViX | 6.7 | 3.12 | 1.0.3~openvix.py312 | verified statically¹ |
| OpenViX | 6.8 | 3.13 | 1.0.3~openvix.py313 | verified statically¹ |
| OpenViX | 7.0 and newer | 3.14 | 1.0.3~openvix.py314 | verified statically¹ |

Every package carries the same CineView MLA skin, designs, themes and options. The packages for the versions
that were not device-tested are the approved package of that image with only its Python byte-code rebuilt for the
image's Python (3.12 / 3.13 / 3.14) and a version-range check.

¹ The Enigma2 interfaces CineView MLA uses (renderers, converters and their arguments, skin attributes, screens,
enigma API, imported modules) were compared with the image's own Enigma2 source for the first and last release of
each version line: OpenATV 7.6 / current, OpenBH 6.0.004 / current, OpenViX 6.7.000 / 6.7.020 / 6.8.001 /
6.8.009 / 6.9.003. The Python version of each line comes from the image's official package feed. This is a static
check, not a test on a receiver.

**OpenATV 7.5 is not supported for now:** its Enigma2 has no `Components/Addons` (the colour-button bars and
pagers used by every CineView MLA design) and no `FullDescription` in the MovieInfo converter (event descriptions).
The installer refuses it with this reason and changes nothing.

The installer stops, without changing anything, on: an image older than the minimum version, an image it cannot
identify reliably, a Python version without a package (for example a future Python 3.15), missing required
components, or a package that fails the SHA256 check. Your design, theme, profiles and settings are kept on update
and rollback (`ROLLBACK=1` returns to the previous release, 1.0.2, on every supported line).

## Changes

- **1.0.3** — posters with translated EPG titles: many EPG providers (for example Polish satellite EPG) give the
  programme a local title and name the work in the description ("Tytuł oryginalny: …", "US, 2023"). The poster
  engine now searches and compares that original title, recognises more series / year formats, and accepts a
  translated series only when IMDb's answer, the year and the cast in the description agree. Live sport and news
  are not looked up. When the event data cannot identify the work, no poster is shown instead of a wrong one.
- **1.0.2** — receiver temperature: the `CPU: xx°C` label read only three fixed sensor paths and showed `CPU: --°C`
  on receivers whose driver reports the temperature elsewhere (for example Octagon SF8008 / HiSilicon). It now also
  reads other kernel thermal zones, other Enigma2 driver files and the HiSilicon driver, each only if present, and
  shows `CPU: N/A` when there is no valid reading. Nothing else changed.

## Uninstall

```
wget -qO /tmp/cineview-uninstall.sh https://raw.githubusercontent.com/habeb-s/CineView-MLA-Install/main/cineview-uninstall.sh && sh /tmp/cineview-uninstall.sh
```

`SHA256SUMS` lists the checksums of the installer, the uninstaller and every package.
