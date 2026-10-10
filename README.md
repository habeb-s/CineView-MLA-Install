# CineView MLA — Smart Installer

Design & Development by habeb-s © 2026

**CineView MLA 1.0.6 · Smart Installer 1.3.8**

One installer for **OpenATV 7.6+, OpenBH 5.6+ and OpenViX 6.7+** on any Enigma2 receiver. It is not tied to a
receiver model, brand, multiboot slot or a single image version: it identifies the image, its version and its Python
by itself (wherever it is installed), chooses the matching package, verifies its SHA256 and installs it.

## Install / update (telnet or SSH on the receiver)

```
wget -qO /tmp/cineview-install.sh https://raw.githubusercontent.com/habeb-s/CineView-MLA-Install/main/cineview-install.sh && sh /tmp/cineview-install.sh
```

Options (before `sh`): `DRYRUN=1` checks only · `ROLLBACK=1` previous release · `RESTART=0` no automatic GUI restart

## Compatibility

| Image | Versions | Python | Package | Status |
|---|---|---|---|---|
| OpenATV | 8.0 | 3.14 | 1.0.6 | device-tested (1.0.6: reinstall, rollback to 1.0.5 and upgrade with the Smart Installer, every design, system pages, message boxes, status indicators while zapping) |
| OpenATV | 7.6 | 3.13 | 1.0.6~openatv.py313 | device-tested with 1.0.3 (Octagon SF8008: install, reinstall, posters, temperature); 1.0.6 verified statically¹ |
| OpenATV | 8.1 and newer | 3.14 | 1.0.6~openatv.py314 | verified statically¹ |
| OpenBH | 5.6 | 3.13 | 1.0.6~openbh1 | device-tested (1.0.6: install with the Smart Installer, message boxes, About / Memory / Devices, Green Panel / Fast Plugin, Plugin Browser, designs with picons) |
| OpenBH | 5.7 and newer 5.x | 3.13 | 1.0.6~openbh.py313 | verified statically¹ |
| OpenBH | 6.0 and newer | 3.14 | 1.0.6~openbh.py314 | device-tested on 6.0 with 1.0.5/1.0.6 RC; 1.0.6 final verified statically¹ |
| OpenViX | 6.9 | 3.14 | 1.0.6~openvix1 | device-tested (1.0.6: install with the Smart Installer, message boxes, About / Memory / Devices, Plugin Browser, GUI Skin preview, designs with picons) |
| OpenViX | 6.7 | 3.12 | 1.0.6~openvix.py312 | verified statically¹ |
| OpenViX | 6.8 | 3.13 | 1.0.6~openvix.py313 | verified statically¹ |
| OpenViX | 7.0 and newer | 3.14 | 1.0.6~openvix.py314 | verified statically¹ |

1.0.6 was device-tested on a Vu+ Duo 4K SE (multiboot) with OpenATV 8.0.1, OpenBH 5.6 and OpenViX 6.9.
The same CineView MLA files are in every package; only the Python byte code differs per image line.

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
and rollback (`ROLLBACK=1` returns to the previous release, 1.0.5, on every supported line).

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
