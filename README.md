# CineView MLA — Smart Installer

Design & Development by habeb-s © 2026

**CineView MLA 1.0.5 · Smart Installer 1.3.5**

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
| OpenATV | 8.0 | 3.14 | 1.0.5 | device-tested (1.0.5: rollback to 1.0.4 and upgrade with the Smart Installer, every design with OAWeather and with CineView's own weather, CineView Designs, OAWeather / MetrixHD untouched) |
| OpenATV | 7.6 | 3.13 | 1.0.5~openatv.py313 | device-tested with 1.0.3 (Octagon SF8008: install, reinstall, posters, temperature); 1.0.5 verified statically¹ |
| OpenATV | 8.1 and newer | 3.14 | 1.0.5~openatv.py314 | verified statically¹ |
| OpenBH | 5.6 | 3.13 | 1.0.5~openbh1 | device-tested (1.0.5: rollback to 1.0.4 and upgrade with the Smart Installer, every design with OAWeather and with CineView's own weather, CineView Designs, Luka FHD / AGlare FHD / OAWeather untouched) |
| OpenBH | 5.7 and newer 5.x | 3.13 | 1.0.5~openbh.py313 | verified statically¹ |
| OpenBH | 6.0 and newer | 3.14 | 1.0.5~openbh.py314 | device-tested on 6.0 (1.0.5: without OAWeather - its feed does not offer it - upgrade from 1.0.3, fresh install, every design, CineView Designs and Weather city, other add-on on the pre-start hook, uninstall) |
| OpenViX | 6.9 | 3.14 | 1.0.5~openvix1 | device-tested (1.0.5: rollback to 1.0.4 and upgrade with the Smart Installer, every design with OAWeather and with CineView's own weather, CineView Designs, Luka FHD / AGlare FHD / OAWeather untouched) |
| OpenViX | 6.7 | 3.12 | 1.0.5~openvix.py312 | verified statically¹ |
| OpenViX | 6.8 | 3.13 | 1.0.5~openvix.py313 | verified statically¹ |
| OpenViX | 7.0 and newer | 3.14 | 1.0.5~openvix.py314 | verified statically¹ |

1.0.5 was device-tested on a Vu+ Duo 4K SE (multiboot) with OpenBH 6.0, OpenBH 5.6, OpenViX 6.9 and OpenATV 8.0.1.
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
and rollback (`ROLLBACK=1` returns to the previous release, 1.0.4, on every supported line; not possible where another add-on owns
`/usr/bin/enigma2_pre_start.sh`, because 1.0.4 still used that file).

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
