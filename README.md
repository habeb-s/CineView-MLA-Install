# CineView MLA — Smart Installer

Design & Development by habeb-s © 2026

**CineView MLA 1.1.3 · Smart Installer 1.7.2**

One installer for **OpenATV, EGAMI, PurE2, OpenBH, OpenViX and OpenPLi** on any Enigma2 receiver. It is not tied to
a receiver model, brand, multiboot slot or a single image version: it identifies the image and its Python by itself,
checks what CineView needs from the image, chooses the matching family package, verifies its SHA256 and installs it.

## Install / update (telnet or SSH on the receiver)

```
wget -qO /tmp/cineview-install.sh https://raw.githubusercontent.com/habeb-s/CineView-MLA-Install/main/cineview-install.sh && sh /tmp/cineview-install.sh
```

Options (before `sh`): `DRYRUN=1` checks only · `ROLLBACK=1` previous public release · `RESTART=0` no automatic GUI
restart · `PKG_DIR=<folder>` install from package files copied to the receiver

## Packages (release `packages-1.1.3`)

One package per image family; each carries CineView's compiled modules for every Python it supports.

| Images | Package | Python |
|---|---|---|
| OpenATV, EGAMI, PurE2 | `enigma2-plugin-skins-cineview-fhd-mla_1.1.3+openatv_all.ipk` | 3.10 – 3.14 |
| OpenBH, OpenViX | `enigma2-plugin-skins-cineview-fhd-mla_1.1.3+openbhvix_all.ipk` | 3.10 – 3.14 |
| OpenPLi | `enigma2-plugin-skins-cineview-fhd-mla_1.1.3+openpli_all.ipk` | 3.9 – 3.14 |

The packages can also be installed by hand (`opkg update`, then `opkg install /tmp/<package>.ipk`). They enforce the
same rules as the installer: opkg itself refuses another image family, an image older than the minimum and a Python
the package has no compiled modules for, before anything is installed. The remaining checks run in the package's
preinst (OpenPLi's minimum version, the Enigma2 components CineView needs); when one fails there, opkg has already
installed the image's own python3-requests / python3-pillow and lists CineView MLA as half-installed - no CineView
file is installed, and `opkg remove enigma2-plugin-skins-cineview-fhd-mla` clears the entry. The installer checks all
of this before it changes anything.

## Compatibility

| Image | Device-tested (Vu+ Duo 4K SE, Oct 2026) | Python | Supported from |
|---|---|---|---|
| OpenATV | 8.0.1 | 3.14 | 7.6 |
| EGAMI | 11.0 | 3.13 | 11.0 |
| PurE2 | 7.6 | 3.13 | 7.4 |
| OpenBH | 6.0 | 3.14 | 5.6 |
| OpenViX | 6.9 | 3.14 | 6.7 |
| OpenPLi | 9.2 | 3.9 | 9.1 |

Device-tested = CineView MLA 1.1.1 seen running on that image (1.1.3 carries the same files apart from one System 2
screen, device-tested on OpenBH 5.6). Every version from the
minimum on, with a Python its family package carries, is supported: the installer
checks what CineView needs from the image's Enigma2 before anything is changed and installs without a question; a
version that was not device-tested is shown as SUPPORTED (not device-tested). Older versions are refused before any
change: EGAMI 10.6 and OpenPLi 9.0 lack the Enigma2 ColorButtonsSequence addon the factory design's screens use.
Images outside these six families (other OE-Alliance images, on the OpenATV screens) are EXPERIMENTAL: the installer
asks first (`ACCEPT_UNTESTED=1` skips the question).
`ROLLBACK=1` returns to CineView MLA 1.1.2 (release `packages-1.1.2`) of the same family, design kept.

The installer stops, without changing anything, on: an image whose Enigma2 lacks components CineView's screens need,
a Python version without compiled modules, a package that fails the SHA256 check, or a download address that cannot
be reached or resolved (DNS).

## Weather

The Classic, Details and Cinema designs show the weather (city, temperature, icon). Since 1.0.5 these fields use
CineView MLA's own weather components (own code and icons, CineView names), so a design never depends on another
add-on to load or to show the weather. Nothing of OAWeather is copied, replaced, changed or removed, and the skins
that use OAWeather (for example Luka FHD, AGlare FHD) are not touched.

- **Location** — only one you have set, never a guess (a time zone does not say where you are):
  1. the location saved in **OAWeather**'s settings, when there is one;
  2. otherwise the city you choose in **CineView Designs › Weather city** (OK, type the name in English or Arabic
     letters, pick it from the list — saved at once);
  3. neither: no weather is shown until a city is chosen.
- **Data** — while OAWeather runs with its saved location, its own data is shown as it is (city, temperature, the
  icon of its icon set). Otherwise CineView MLA looks up the weather itself at [Open-Meteo](https://open-meteo.com)
  (free, no account or key), once an hour, in the background. Celsius, or Fahrenheit when OAWeather is set to it.
  Weather data by [Open-Meteo.com](https://open-meteo.com/) (CC BY 4.0).
- **Smart Installer** — checks OAWeather (package, files, byte code for the image's Python): missing → installed
  from the image's own feed when the feed offers it (OpenBH 6.0's feed does not); installed and healthy → used as
  it is; incomplete or built for another Python → left as it is, CineView's own weather is used. When no location is
  set yet, it says where to choose the city.
- Weather switched off in OAWeather's settings → OAWeather's location is not used.

## Changes

- **Smart Installer 1.7.2 · CineView MLA 1.1.3** — fixes a GUI crash on OpenBH 5.6 / 6.0 with System 2: simple message
  boxes (for example "No event info found, recording indefinitely." on an instant recording, conflicting-timer
  messages, "Stop recording?") fell back to the image's own MessageBoxSimple screen, which crashed on OpenBH
  (`KeyError: 'ErrorPixmap'`). System 2 now has its own MessageBoxSimple, the same design as its other message boxes,
  on every image. Nothing else changed: designs, themes, settings, package rules and installer checks are those of
  1.1.2. `ROLLBACK=1` → 1.1.2.

- **Smart Installer 1.7.1 · CineView MLA 1.1.2** — corrective compatibility release; the designs, screens, code and
  previews are those of 1.1.1, unchanged. One set of compatibility rules for the installer and the packages:
  minimums OpenATV 7.6, OpenViX 6.7, OpenBH 5.6, PurE2 7.4, EGAMI 11.0 (was 10.6), OpenPLi 9.1 (was 9.0). Every
  supported version installs without the EXPERIMENTAL question (1.7.0 asked on every version that was not
  device-tested and stopped without a terminal - for example OpenBH 5.6); older versions are refused before anything
  is changed. Packages: the image family, its minimum and the Python range are package dependencies, so opkg refuses
  them before installing anything; the preinst also checks the Enigma2 components. `ROLLBACK=1` → 1.1.1.

- **Smart Installer 1.7.0 · CineView MLA 1.1.1** — three family packages (OpenATV / EGAMI / PurE2, OpenBH / OpenViX,
  OpenPLi) from the release `packages-1.1.1`; OpenPLi, EGAMI and PurE2 supported; Python 3.9 – 3.14; image detection by
  capability (no image whitelist); clear message when the download server name cannot be resolved (DNS); the same
  SHA256 and content-fingerprint verification, recovery and automatic GUI restart as before.

- **Smart Installer 1.3.11** — release chosen per image: OpenATV 1.0.8 (`ROLLBACK=1` → 1.0.7), OpenBH and OpenViX 1.0.7
  (`ROLLBACK=1` → 1.0.6) until 1.0.8 is device-tested on them. The installer shows which release it selected and why.
  A newer CineView MLA already installed than the release approved for the image is kept as it is (no automatic
  downgrade). Image, version, Python, SHA256 and rollback checks are unchanged.

- **1.0.8** (OpenATV) — the ECM line shows only on encrypted channels and is read only when the softcam changes it;
  poster and IMDb lookups run on a small bounded queue; the poster cache stays within 300 MB on a disk (15 MB in RAM)
  and removes expired entries; repeated colours are theme names (colours unchanged); the MovieSelection description
  no longer shows a cut line (Classic and Cover); CineView Designs asks "Restart the GUI now?" before restarting
  (Yes restarts, No keeps the settings saved for the next restart). Recovery after a real failure is unchanged.

- **Smart Installer 1.3.10** — CineView MLA 1.0.7 (`ROLLBACK=1` → 1.0.6). When the package manager reports an error,
  the installer now checks CineView MLA's real state (package manager status, version, installed files identical
  to the official package). If the error came from another add-on that the package manager configured in the same
  run (for example an add-on left half-installed), CineView MLA is reported as installed correctly, with a separate
  warning naming that add-on — which is left unchanged. A real CineView MLA failure is still reported and repaired
  as before. After the package manager has run, a stop no longer says "Nothing was changed".

- **1.0.7** — CineView Designs: GREEN saves and applies at once and restarts the GUI by itself when the design or theme
  changed (no Yes/No, no "keep this design?" question, no countdown); settings that need no restart are just saved.
  A new design is kept for good once the GUI has run on it. It goes back to the previous design only on a real
  failure: an Enigma2 crash during its first session (crash logs as each image names them), the skin not loading,
  or repeated starts that never reach a working GUI — never because of elapsed time, a power cut or a normal
  restart. The SNR bars of the Classic and Details InfoBar / Second InfoBar (also the simple Second InfoBar of
  OpenBH / OpenViX) are graded red → orange → yellow → green with a grey unfilled part; sizes and positions unchanged.

- **Smart Installer 1.3.8** — fully automatic: after a successful installation or update, and only after every
  final check has passed (package SHA256, installed files identical to the official package), the installer
  restarts the Enigma2 GUI by itself (never the whole receiver) - no question to answer. It uses the image's own
  clean GUI restart and, if that is not available, the init system's GUI stop / start (OpenATV, OpenBH, OpenViX).
  No restart when nothing was installed (official version already installed), when the installation or a check
  failed, with `DRYRUN=1`, or while a recording is running (then it says so). `RESTART=0` disables the restart.

- **Smart Installer 1.3.7** — the same version number is no longer taken as "installed": the installer compares
  the files CineView MLA installed (the package's own file list) with a content fingerprint of the official package,
  pinned in the installer like the SHA256. A test build with the same number, a missing or a changed file is
  reported (how many files differ, with examples) and replaced by the official package (SHA256-verified; design,
  theme, profiles, settings and poster cache kept). After every installation the installed files must match the
  official package. Your settings, design selection, posters and logs are not part of the fingerprint.
  `DRYRUN=1` shows the result without changing anything. The packages are unchanged.

- **1.0.6** — one visual identity on every screen, nothing else changed in how CineView MLA works:
  - **System pages:** About › Memory / Devices / Storage full screen (FHD 1920×1080) on every image; one title per
    page (some pages drew it twice), one title size and one button-text size on all system pages; the OpenATV
    information pages no longer draw their key labels twice.
  - **Message boxes:** new CineView icons for question, information, warning, error and message (the message icon
    was missing), gold accent line; texts and functions unchanged.
  - **Status indicators:** HD, 16:9, 4K, 4:3, multichannel (5.1), teletext, HbbTV, sub-services, PDC, encrypted and
    recording redrawn in one 3D badge style with transparent edges; same sizes, same dynamic conditions.
  - **InfoBar / SecondInfoBar / EventView / channel lists:** the orbital position and the provider appear once per
    screen in every design (they were repeated next to the transponder line, which already carries the orbital
    position); the frequency block of the Details design is one font step larger.
  - **Picons:** shown in proportion and centred in every design on every image (220×132 is the reference size;
    other picon sizes are no longer stretched; your picon files are not changed).
  - **Skin Settings preview** with the CineView MLA identity.

- **1.0.5** — weather without depending on OAWeather (see *Weather*): on images without OAWeather (for example
  OpenBH 6.0, whose feed does not offer it) a design could not be applied ("converter OAWeather not installed /
  renderer OAWeatherPixmap not installed" in EventView, InfoBar, SecondInfoBar, SecondInfoBarSimple); 1.0.4 left the
  weather out. Now every design applies and shows the weather with or without OAWeather, at the location you set.
  New in CineView Designs: *Weather city*.
  CineView MLA also coexists with other add-ons that use Enigma2's pre-start hook. Every image runs exactly
  one pre-start hook, the single file `/usr/bin/enigma2_pre_start.sh`, and only one package can own it. Earlier
  versions owned it, so an add-on using it could not be installed next to CineView MLA, and the Smart Installer
  stopped with "…belongs to another add-on". CineView MLA's boot guardian now starts from Python's standard start-up
  hook (a `.pth` file in the image's `site-packages`, the same mechanism the images use for their own
  `distutils-precedence.pth`). It acts only inside the `enigma2` process, before the settings and the skin are
  loaded — the same moment as before — and shares no file with other add-ons. A hook file left by an earlier
  CineView MLA is removed on update only if it is still CineView's own and no other package owns it. Designs,
  options and the protection levels (last-known-good, factory design, default skin) are unchanged. The uninstaller
  no longer stops the GUI while a recording is running.
- **1.0.4** — weather is optional: the Classic, Details and Cinema designs show the weather of the OAWeather plugin,
  which is not installed on every image. Without it a design could not be applied ("converter OAWeather not
  installed"). Now the weather fields are simply left out while OAWeather is missing — everything else in the design
  stays the same — and they come back by themselves after the next GUI restart once OAWeather is installed. The
  Smart Installer installs OAWeather from the image's own package feed when the feed offers it (optional; if it is
  not available the skin works without the weather). Every other component is still checked strictly before a
  design is applied. The installer no longer restarts the GUI while a recording is running.
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
