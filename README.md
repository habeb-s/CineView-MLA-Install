# CineView MLA — Smart Installer

Design & Development by habeb-s © 2026

**Status: final release — CineView MLA 1.0.1, Smart Installer 1.2.2.**
Installed, reinstalled and rolled back on a real receiver (Vu+ Duo 4K SE) on all three supported images.

| Image | Package installed by the command below | Previous release (`ROLLBACK=1`) |
|---|---|---|
| OpenATV 8.0 (Python 3.14) | 1.0.1 | 1.0.0 |
| OpenBH 5.6 (Python 3.13) | 1.0.1~openbh1 | 1.0.0~openbh17 |
| OpenViX 6.9 (Python 3.14) | 1.0.1~openvix1 | 1.0.0~openvix1 |

The installer identifies the image and its version by itself (from the image's own information and files, wherever
it is installed), checks Python and compatibility, downloads the matching package, verifies its SHA256 and installs
it. Untested image versions are refused. Your design, theme, profiles and settings are kept on update and rollback.

## Install / update (telnet or SSH on the receiver)

```
wget -qO /tmp/cineview-install.sh https://raw.githubusercontent.com/habeb-s/CineView-MLA-Install/main/cineview-install.sh && sh /tmp/cineview-install.sh
```

Options (before `sh`): `DRYRUN=1` checks only · `ROLLBACK=1` previous release · `RESTART=1` restart the GUI without asking

## Uninstall

```
wget -qO /tmp/cineview-uninstall.sh https://raw.githubusercontent.com/habeb-s/CineView-MLA-Install/main/cineview-uninstall.sh && sh /tmp/cineview-uninstall.sh
```

`SHA256SUMS` lists the checksums of the installer and the uninstaller.
