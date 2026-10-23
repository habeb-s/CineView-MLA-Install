#!/bin/sh
# CineView MLA Smart Installer - Design & Development by habeb-s (c) 2026
# Installs CineView MLA 1.1.2 on Enigma2 images with Python 3.  One package per image family:
#   OpenATV, EGAMI, PurE2 (and other OE-Alliance images the OpenATV family package accepts)  ..._1.1.2+openatv_all.ipk
#   OpenBH, OpenViX                                                                           ..._1.1.2+openbhvix_all.ipk
#   OpenPLi                                                                                   ..._1.1.2+openpli_all.ipk
# Each family package carries CineView's compiled modules for every Python it supports; the image's screen files are
# chosen on the receiver.  What decides is what the image can do (its Python, the Enigma2 skin components and modules
# CineView uses, the package architecture, the image's own feeds for the dependencies) - never the receiver model or
# the multiboot slot.  When the image cannot run CineView, the installer stops before anything is changed and says why.
# usage on the receiver (telnet / ssh):
#   wget -qO /tmp/cineview-install.sh https://raw.githubusercontent.com/habeb-s/CineView-MLA-Install/main/cineview-install.sh && sh /tmp/cineview-install.sh
# options (put them in front of sh):
#   DRYRUN=1      check-only: every check + the package downloaded to /tmp (RAM) and SHA256-verified, then deleted;
#                 nothing is installed, refreshed (opkg update), restarted or changed on the receiver
#   RESTART=0     do not restart the GUI at the end
#   ROLLBACK=1    return to the previous public release (CineView MLA 1.1.1 of the same image family)
#   PKG_DIR=<folder>   install from package files copied to the receiver (USB / FTP), same SHA256 / fingerprint checks
#   ACCEPT_UNTESTED=1  do not ask before installing on an EXPERIMENTAL image (an image outside the six supported
#                 families, or one whose version cannot be read)
#   OAWEATHER=1   also install the optional OAWeather plugin from the image's own feed (never automatic)
#   HDD_CACHE=0   keep the poster cache off the hard disk
# Every check runs before anything is changed.  Never: force options for dependencies, packages from other images or
# feeds, removal or downgrade of other packages.  The one exception is the CineView MLA package itself on ROLLBACK /
# automatic recovery (opkg --force-downgrade of the SHA256-verified previous release).
# A diagnostic report of every run is left in /tmp/cineview-install-report.txt (removed at the next reboot).
export PYTHONDONTWRITEBYTECODE=1  # the checks import modules: never leave byte-code caches on the flash
INSTALLER_VERSION="1.7.1"
PKG="enigma2-plugin-skins-cineview-fhd-mla"
# Distribution point: the packages are assets of GitHub releases of habeb-s/CineView-MLA-Install (not in any repository
# tree): <BASE>/<release tag>/<asset>.  GitHub stores ~ of a file name as . in the asset name (+ is kept).
BASE="${CVMLA_BASE:-https://github.com/habeb-s/CineView-MLA-Install/releases/download}"  # CVMLA_BASE: staging / test hook only
TAG="packages-1.1.2"
BUILD_NAME="1.1.2"
# Device-tested (2026-10-22/23, Vu+ Duo 4K SE multiboot, CineView MLA 1.1.1 = the files 1.1.2 carries unchanged;
# the 1.1.2 package scripts and Depends are verified in simulation with the real opkg 0.6.3 / 0.8.0 / 0.10.0):
# image:version line:Python.
VERIFIED="openatv:8.0:3.14:openvix:6.9:3.14:openbh:6.0:3.14:openpli:9.2:3.9:egami:11.0:3.13:pure2:7.6:3.13"
VERIFIED_TEXT="OpenATV 8.0, OpenViX 6.9, OpenBH 6.0 (Python 3.14); EGAMI 11.0, PurE2 7.6 (Python 3.13); OpenPLi 9.2 (Python 3.9)"
# Supported range - the same table the packages' preinst enforces: image:oldest supported version.  An image of this
# table at / above its minimum, with a Python its family package carries, that passes every capability check below
# is SUPPORTED and installs without a question (device-tested or not).  Below the minimum: stop, nothing changed.
# Images outside this table (other OE-Alliance images, OpenATV screens) or an unreadable version: EXPERIMENTAL (asked).
SUPPORTED_MIN="openatv:7.6 egami:11.0 pure2:7.4 openbh:5.6 openvix:6.7 openpli:9.1"
# Dependencies the packages declare (control: Depends) - re-read from the downloaded package and compared.
DEPS="python3-requests python3-pillow"
# Python modules CineView MLA imports at run time (besides the interpreter core and Enigma2 itself).  Checked by
# importing them with this receiver's Python.  requests / PIL come from the declared dependencies above; any other
# missing module is reported by name and the installation stops (no package is guessed for it).
PYMODS="json threading hashlib gettext zlib xml.etree.ElementTree unicodedata html difflib urllib.request ssl requests PIL.Image twisted"
# CineView MLA 1.1.1 family packages: F_<family>_* (pinned by SHA256 and by the content fingerprint of the installed files)
F_openatv_VERSION="1.1.2+openatv"; F_openatv_FILE="enigma2-plugin-skins-cineview-fhd-mla_1.1.2+openatv_all.ipk"; F_openatv_SHA="bd43297737b7e742f6acd8719cd2906269178a26b6df284e5c0ca58c5813b624"; F_openatv_DIGEST="0226e2e7b142dd2cdef31ed0f8f1a0c87d1abfe9c1a08dee168f4b8dc5d6c9ab"; F_openatv_PY="3.10 3.11 3.12 3.13 3.14"  # OpenATV, EGAMI, PurE2
F_openbhvix_VERSION="1.1.2+openbhvix"; F_openbhvix_FILE="enigma2-plugin-skins-cineview-fhd-mla_1.1.2+openbhvix_all.ipk"; F_openbhvix_SHA="50463f57b78620f313f136b855d06ea3901edf700ef5516d6056704be078b0ca"; F_openbhvix_DIGEST="cee90e8f8edb555744b93d19424afff656d485a6406c18afdc28297449878390"; F_openbhvix_PY="3.10 3.11 3.12 3.13 3.14"  # OpenBH, OpenViX
F_openpli_VERSION="1.1.2+openpli"; F_openpli_FILE="enigma2-plugin-skins-cineview-fhd-mla_1.1.2+openpli_all.ipk"; F_openpli_SHA="c7e1b2e003ee6d3266e227d0ffb62ce37c0d0fe5b661a680580673d0ca0df60c"; F_openpli_DIGEST="3693d0ae65e3c198d76a99c9c3af6858bf5e28543287cac2074482a4797b1fea"; F_openpli_PY="3.9 3.10 3.11 3.12 3.13 3.14"  # OpenPLi
# previous public releases (ROLLBACK=1 / recovery), published with Smart Installer 1.3.11 as assets of packages-1.0.1:
# <IMAGE>_<release>_* = package of the device-tested line, <IMAGE>_<release>_R<py>_* = range package for that Python
# CineView MLA 1.1.1 (packages-1.1.1): previous public release of every family package (ROLLBACK=1 / recovery)
P111_openatv_FILE="packages-1.1.1/enigma2-plugin-skins-cineview-fhd-mla_1.1.1+openatv_all.ipk"; P111_openatv_SHA="ab540bd41da1970a4b3ca5a9a21c01434e4b497c87669b340b59f37237735902"; P111_openatv_DIGEST="9d3b667d7db5acea35d9f825caf494182a14a6e107255d62cf6a8feb116c2ced"
P111_openbhvix_FILE="packages-1.1.1/enigma2-plugin-skins-cineview-fhd-mla_1.1.1+openbhvix_all.ipk"; P111_openbhvix_SHA="468f78343de15f4f731a5f5597bb6489a6813930b1bf099711894288f320f5f7"; P111_openbhvix_DIGEST="7e3fa6263dd6de6234bf2c78d81f785d01d056d972c08a7de0484938d524fcad"
P111_openpli_FILE="packages-1.1.1/enigma2-plugin-skins-cineview-fhd-mla_1.1.1+openpli_all.ipk"; P111_openpli_SHA="1fe9e6f48a08e9208f4097563da9a55636a879d0fbe0a4db4b6531211341d69e"; P111_openpli_DIGEST="eef0d50606f04889435aef4caa5137a5a594845ce62859d6e18fdf1ba53ebc23"
RB_TAG="packages-1.0.1"
OPENATV_PY="3.14"
OPENBH_PY="3.13"
OPENVIX_PY="3.14"
OPENATV_MIN="7.6"; OPENATV_TESTED="8.0"; OPENBH_MIN="5.6"; OPENBH_TESTED="5.6"; OPENVIX_MIN="6.7"; OPENVIX_TESTED="6.9"
OPENATV_108_VERSION="1.0.8"; OPENATV_108_FILE="enigma2-plugin-skins-cineview-fhd-mla_1.0.8_all.ipk"; OPENATV_108_SHA="f013208bbf74ffe1c211faf29153fb798006f44685c450f49a27b482d298b4d4"; OPENATV_108_DIGEST="309db7201c231728de308516620f69309378989e31dab46b2ff0c0521f821b8c"
OPENATV_108_R313_FILE="enigma2-plugin-skins-cineview-fhd-mla_1.0.8~openatv.py313_all.ipk"; OPENATV_108_R313_SHA="46de73a32fa9d5094040f910b415c184bba78d684e2dc6c718be22cce28c9a0d"; OPENATV_108_R313_DIGEST="8041cf8111c7976e61cf0900a9ca3df159235ff7f4458843d7c5880b3ebcd6e2"
OPENATV_108_R314_FILE="enigma2-plugin-skins-cineview-fhd-mla_1.0.8~openatv.py314_all.ipk"; OPENATV_108_R314_SHA="c122bdf04e502e6f0630f553105006f8c55145e88e35160b8d9ad4651b5198d9"; OPENATV_108_R314_DIGEST="3c342d6aad1695d26b868da08b4f5aeda5712358f80d1d004fa977f551113f32"
OPENBH_107_VERSION="1.0.7~openbh1"; OPENBH_107_FILE="enigma2-plugin-skins-cineview-fhd-mla_1.0.7~openbh1_all.ipk"; OPENBH_107_SHA="10c1ef4754f1333dd0ca04283e77143fd523efa41811d9acc163d5d5b0c25020"; OPENBH_107_DIGEST="c5ac6b1736ec1575aea866ae0d7f610ca98f6b7c0200a2b04795bb6c11d9a89b"
OPENBH_107_R313_FILE="enigma2-plugin-skins-cineview-fhd-mla_1.0.7~openbh.py313_all.ipk"; OPENBH_107_R313_SHA="d7583db4e626661da5a66e60ef242c8222746d40f90e4046e31f328344623254"; OPENBH_107_R313_DIGEST="a2570655235b9008a1b4d3d18602f55a980d4c53a9dae5a48daf703ad02573ea"
OPENBH_107_R314_FILE="enigma2-plugin-skins-cineview-fhd-mla_1.0.7~openbh.py314_all.ipk"; OPENBH_107_R314_SHA="89be3b314e8d53ecf54db6af5bd714c80970883c0b9709e89ff8497ebbf4f729"; OPENBH_107_R314_DIGEST="5220d5815797675757c652d99da80ab2f9c95c39f0d31036a848c57fa764e527"
OPENVIX_107_VERSION="1.0.7~openvix1"; OPENVIX_107_FILE="enigma2-plugin-skins-cineview-fhd-mla_1.0.7~openvix1_all.ipk"; OPENVIX_107_SHA="09ea28c0ed9d5bbcbe37d0483573dbae4f00e7aab85512516d5c45e1a2154193"; OPENVIX_107_DIGEST="2ec4dc51d6a6daa7c63073540efa81bff5a46e9f5fa3c5043b48b1e4227e8373"
OPENVIX_107_R312_FILE="enigma2-plugin-skins-cineview-fhd-mla_1.0.7~openvix.py312_all.ipk"; OPENVIX_107_R312_SHA="51a4d9c4f033c3ab967c32fdc55f899f6f473d80bc13e7cf072418c7ba83db52"; OPENVIX_107_R312_DIGEST="aeb15bb861028402479c9e5c3620f32f6e58047caff9c2113d0ccafc1fa8188e"
OPENVIX_107_R313_FILE="enigma2-plugin-skins-cineview-fhd-mla_1.0.7~openvix.py313_all.ipk"; OPENVIX_107_R313_SHA="71694f89b03c0df7e6343db86823a410c79efed176f59b30ca76bdac21e06795"; OPENVIX_107_R313_DIGEST="0255b651fff3af58779cc71c35c82b0de8c98a5b3e48c2bb4efec11617fb7b56"
OPENVIX_107_R314_FILE="enigma2-plugin-skins-cineview-fhd-mla_1.0.7~openvix.py314_all.ipk"; OPENVIX_107_R314_SHA="8235936e3959da694fca6a56b7a2bc3b3331ec1b9d656abdc27491ffd0c00dcc"; OPENVIX_107_R314_DIGEST="80d1c49b13a63fda57f3524649fa6eeac70be46a48eecea64c15a8ebbd192ffe"
KNOWN="1.1.1+openatv|packages-1.1.1/enigma2-plugin-skins-cineview-fhd-mla_1.1.1+openatv_all.ipk|ab540bd41da1970a4b3ca5a9a21c01434e4b497c87669b340b59f37237735902
1.1.1+openbhvix|packages-1.1.1/enigma2-plugin-skins-cineview-fhd-mla_1.1.1+openbhvix_all.ipk|468f78343de15f4f731a5f5597bb6489a6813930b1bf099711894288f320f5f7
1.1.1+openpli|packages-1.1.1/enigma2-plugin-skins-cineview-fhd-mla_1.1.1+openpli_all.ipk|1fe9e6f48a08e9208f4097563da9a55636a879d0fbe0a4db4b6531211341d69e
1.1.2+openatv|packages-1.1.2/enigma2-plugin-skins-cineview-fhd-mla_1.1.2+openatv_all.ipk|bd43297737b7e742f6acd8719cd2906269178a26b6df284e5c0ca58c5813b624
1.1.2+openbhvix|packages-1.1.2/enigma2-plugin-skins-cineview-fhd-mla_1.1.2+openbhvix_all.ipk|50463f57b78620f313f136b855d06ea3901edf700ef5516d6056704be078b0ca
1.1.2+openpli|packages-1.1.2/enigma2-plugin-skins-cineview-fhd-mla_1.1.2+openpli_all.ipk|c7e1b2e003ee6d3266e227d0ffb62ce37c0d0fe5b661a680580673d0ca0df60c
1.0.8|packages-1.0.1/enigma2-plugin-skins-cineview-fhd-mla_1.0.8_all.ipk|f013208bbf74ffe1c211faf29153fb798006f44685c450f49a27b482d298b4d4
1.0.8~openatv.py313|packages-1.0.1/enigma2-plugin-skins-cineview-fhd-mla_1.0.8~openatv.py313_all.ipk|46de73a32fa9d5094040f910b415c184bba78d684e2dc6c718be22cce28c9a0d
1.0.8~openatv.py314|packages-1.0.1/enigma2-plugin-skins-cineview-fhd-mla_1.0.8~openatv.py314_all.ipk|c122bdf04e502e6f0630f553105006f8c55145e88e35160b8d9ad4651b5198d9
1.0.7~openbh1|packages-1.0.1/enigma2-plugin-skins-cineview-fhd-mla_1.0.7~openbh1_all.ipk|10c1ef4754f1333dd0ca04283e77143fd523efa41811d9acc163d5d5b0c25020
1.0.7~openbh.py313|packages-1.0.1/enigma2-plugin-skins-cineview-fhd-mla_1.0.7~openbh.py313_all.ipk|d7583db4e626661da5a66e60ef242c8222746d40f90e4046e31f328344623254
1.0.7~openbh.py314|packages-1.0.1/enigma2-plugin-skins-cineview-fhd-mla_1.0.7~openbh.py314_all.ipk|89be3b314e8d53ecf54db6af5bd714c80970883c0b9709e89ff8497ebbf4f729
1.0.7~openvix1|packages-1.0.1/enigma2-plugin-skins-cineview-fhd-mla_1.0.7~openvix1_all.ipk|09ea28c0ed9d5bbcbe37d0483573dbae4f00e7aab85512516d5c45e1a2154193
1.0.7~openvix.py312|packages-1.0.1/enigma2-plugin-skins-cineview-fhd-mla_1.0.7~openvix.py312_all.ipk|51a4d9c4f033c3ab967c32fdc55f899f6f473d80bc13e7cf072418c7ba83db52
1.0.7~openvix.py313|packages-1.0.1/enigma2-plugin-skins-cineview-fhd-mla_1.0.7~openvix.py313_all.ipk|71694f89b03c0df7e6343db86823a410c79efed176f59b30ca76bdac21e06795
1.0.7~openvix.py314|packages-1.0.1/enigma2-plugin-skins-cineview-fhd-mla_1.0.7~openvix.py314_all.ipk|8235936e3959da694fca6a56b7a2bc3b3331ec1b9d656abdc27491ffd0c00dcc"
# what CineView needs from the image's Enigma2 (extracted from the packages: universal/reqs.py)
REQ_openatv_DEFAULT="Addons/ButtonSequence Addons/ColorButtonsSequence Addons/Pager Converter/ClientsStreaming Converter/ClockToText Converter/ConditionalShowHide Converter/CryptoInfo Converter/EventName Converter/EventTime Converter/FrontendInfo Converter/MovieInfo Converter/PliExtraInfo Converter/ProgressToText Converter/RdsInfo Converter/RemainingToText Converter/SensorToText Converter/ServiceInfo Converter/ServiceName Converter/ServiceOrbitalPosition Converter/ServicePosition Converter/ServiceTime Converter/StringList Converter/TemplatedMultiContent Converter/TransponderInfo Converter/ValueRange Renderer/Canvas Renderer/ChannelNumber Renderer/FixedLabel Renderer/Label Renderer/Listbox Renderer/Pig Renderer/Pixmap Renderer/PositionGauge Renderer/Progress Renderer/RunningText Renderer/VideoSize"
REQ_openatv_MORE="Converter/EMCServicePosition Renderer/Picon"
REQ_openatv_FULLDESC="0"
REQ_openbh_DEFAULT="Addons/ButtonSequence Addons/ColorButtonsSequence Addons/Pager Converter/ClientsStreaming Converter/ClockToText Converter/ConditionalShowHide Converter/CryptoInfo Converter/EventName Converter/EventTime Converter/FrontendInfo Converter/MovieInfo Converter/PliExtraInfo Converter/ProgressToText Converter/RdsInfo Converter/RemainingToText Converter/SensorToText Converter/ServiceInfo Converter/ServiceName Converter/ServiceOrbitalPosition Converter/ServicePosition Converter/ServiceTime Converter/StringList Converter/TemplatedMultiContent Converter/TransponderInfo Converter/ValueRange Renderer/Canvas Renderer/ChannelNumber Renderer/FixedLabel Renderer/Label Renderer/Listbox Renderer/Pig Renderer/Pixmap Renderer/PositionGauge Renderer/Progress Renderer/RunningText Renderer/VideoSize"
REQ_openbh_MORE="Converter/EMCServicePosition Renderer/Picon"
REQ_openbh_FULLDESC="0"
REQ_openvix_DEFAULT="Addons/ButtonSequence Addons/ColorButtonsSequence Addons/Pager Converter/ClientsStreaming Converter/ClockToText Converter/ConditionalShowHide Converter/CryptoInfo Converter/EventName Converter/EventTime Converter/FrontendInfo Converter/MovieInfo Converter/PliExtraInfo Converter/ProgressToText Converter/RdsInfo Converter/RemainingToText Converter/SensorToText Converter/ServiceInfo Converter/ServiceName Converter/ServiceOrbitalPosition Converter/ServicePosition Converter/ServiceTime Converter/StringList Converter/TemplatedMultiContent Converter/TransponderInfo Converter/ValueRange Renderer/Canvas Renderer/ChannelNumber Renderer/FixedLabel Renderer/Label Renderer/Listbox Renderer/Pig Renderer/Pixmap Renderer/PositionGauge Renderer/Progress Renderer/RunningText Renderer/VideoSize"
REQ_openvix_MORE="Converter/EMCServicePosition Renderer/Picon"
REQ_openvix_FULLDESC="0"
# OpenPLi: CineView replaces RunningText with its own renderer there (the image has none) - same lists otherwise
REQ_openpli_DEFAULT="Addons/ButtonSequence Addons/ColorButtonsSequence Addons/Pager Converter/ClientsStreaming Converter/ClockToText Converter/ConditionalShowHide Converter/CryptoInfo Converter/EventName Converter/EventTime Converter/FrontendInfo Converter/MovieInfo Converter/PliExtraInfo Converter/ProgressToText Converter/RdsInfo Converter/RemainingToText Converter/SensorToText Converter/ServiceInfo Converter/ServiceName Converter/ServiceOrbitalPosition Converter/ServicePosition Converter/ServiceTime Converter/StringList Converter/TemplatedMultiContent Converter/TransponderInfo Converter/ValueRange Renderer/Canvas Renderer/ChannelNumber Renderer/FixedLabel Renderer/Label Renderer/Listbox Renderer/Pig Renderer/Pixmap Renderer/PositionGauge Renderer/Progress Renderer/VideoSize"
REQ_openpli_MORE="Converter/EMCServicePosition Renderer/Picon"
REQ_openpli_FULLDESC="0"
REQ_E2CORE_openpli="Components.ActionMap Components.ConfigList Components.Converter.Converter Components.Converter.PliExtraInfo Components.Converter.Poll Components.Converter.ServiceInfo Components.Element Components.Label Components.Pixmap Components.Renderer.Picon Components.Renderer.Renderer Components.Sources.StaticText Components.config Plugins.Plugin Screens.MessageBox Screens.Screen Tools.LoadPixmap"
REQ_E2CORE="Components.ActionMap Components.ConfigList Components.Converter.Converter Components.Converter.PliExtraInfo Components.Converter.Poll Components.Converter.ServiceInfo Components.Element Components.Label Components.Pixmap Components.Renderer.Picon Components.Renderer.Renderer Components.Renderer.RunningText Components.Sources.StaticText Components.config Plugins.Plugin Screens.MessageBox Screens.Screen Tools.LoadPixmap"
REQ_E2OPT="Components.Language Components.MovieList Components.ServiceList Components.Sources.StreamService Screens.ChoiceBox Screens.EpgSelection Screens.EventView Screens.InfoBar Screens.InfoBarGenerics Screens.MovieSelection Screens.PluginBrowser Screens.Setup Screens.Standby Screens.VirtualKeyBoard Tools Tools.Directories Tools.TextBoundary Tools.Transponder skin"
RT="${CVMLA_ROOT:-}"  # CVMLA_ROOT: test hook only (a simulated receiver root for the identification checks)
INFO="${CVMLA_INFO:-$RT/usr/lib/enigma.info}"  # CVMLA_INFO: test hook only (another enigma.info)
NEED_ROOT_KB=61440
NEED_TMP_KB=40960
SKIN_NAME="CineView_FHD_MLA"
SKIN_DIR="/usr/share/enigma2/$SKIN_NAME"
PLG_DIR="/usr/lib/enigma2/python/Plugins/Extensions/CineViewMLA"
STATE="/etc/enigma2/cineview_mla"

if [ -t 1 ] || [ "${CVMLA_COLOR:-0}" = "1" ]; then
	B=$(printf '\033[1m'); N=$(printf '\033[0m'); G=$(printf '\033[32m'); Y=$(printf '\033[33m'); R=$(printf '\033[31m'); C=$(printf '\033[36m'); W=$(printf '\033[37m')
else
	B=""; N=""; G=""; Y=""; R=""; C=""; W=""
fi
TMPD=$(mktemp -d /tmp/.cvmla.XXXXXX 2>/dev/null || echo /tmp/.cvmla.$$)
mkdir -p "$TMPD"
IPK="$TMPD/cineview-mla.ipk"
LOG="$TMPD/opkg.log"
SELF="$0"
FPY="$TMPD/cvfp.py"
cat > "$FPY" <<'CVFPEOF'
import hashlib, io, os, subprocess, sys, tarfile
# CineView MLA package content fingerprint (the same code runs inside the Smart Installer on the receiver).
# Covers exactly the files and symbolic links the package installs (opkg's own file list of the package): regular
# file -> "F path sha256", link -> "L path target", listed but absent -> "M path"; directories are skipped.
# Runtime data (design generations, settings, poster cache, logs) are not package files and never change it.
#   ipk <file.ipk>            fingerprint of an official package file (build time)
#   installed <pkg>           fingerprint of what is installed for <pkg>
#   diff <pkg> <file.ipk>     installed files compared with the official package: "changed missing extra" + examples


def ipk_entries(path):
    raw = open(path, "rb").read()
    pos, data = 8, None
    while pos + 60 <= len(raw):
        name = raw[pos:pos + 16].decode("ascii", "replace").strip().rstrip("/")
        size = int(raw[pos + 48:pos + 58].decode("ascii").strip())
        if name.startswith("data.tar"):
            data = raw[pos + 60:pos + 60 + size]
        pos += 60 + size + (size % 2)
    out = {}
    with tarfile.open(fileobj=io.BytesIO(data)) as t:
        for m in t.getmembers():
            p = "/" + m.name.lstrip("./")
            if m.issym():
                out[p] = "L %s %s" % (p, m.linkname)
            elif m.isreg():
                out[p] = "F %s %s" % (p, hashlib.sha256(t.extractfile(m).read()).hexdigest())
    return out


def pkg_paths(pkg):
    try:
        txt = subprocess.run(["opkg", "files", pkg], capture_output=True, text=True).stdout
    except OSError:
        txt = ""
    return [l.strip() for l in txt.splitlines() if l.startswith("/")]


def installed_entries(paths):
    out = {}
    for p in paths:
        if os.path.islink(p):
            out[p] = "L %s %s" % (p, os.readlink(p))
        elif os.path.isdir(p):
            continue
        elif os.path.isfile(p):
            h = hashlib.sha256()
            with open(p, "rb") as f:
                for b in iter(lambda: f.read(65536), b""):
                    h.update(b)
            out[p] = "F %s %s" % (p, h.hexdigest())
        else:
            out[p] = "M %s" % p
    return out


def fingerprint(entries):
    return hashlib.sha256("\n".join(entries[k] for k in sorted(entries)).encode()).hexdigest()


def main(argv):
    if argv[0] == "ipk":
        print(fingerprint(ipk_entries(argv[1])))
    elif argv[0] == "installed":
        paths = pkg_paths(argv[1])
        print(fingerprint(installed_entries(paths)) if paths else "none")
    elif argv[0] == "diff":
        off = ipk_entries(argv[2])
        cur = installed_entries(pkg_paths(argv[1]))
        changed = sorted(p for p in off if p in cur and cur[p] != off[p] and not cur[p].startswith("M "))
        missing = sorted(p for p in off if p not in cur or cur[p].startswith("M "))
        extra = sorted(p for p in cur if p not in off)
        print("%d %d %d" % (len(changed), len(missing), len(extra)))
        short = lambda p: p.replace("/usr/share/enigma2/CineView_FHD_MLA/", "skin/").replace("/usr/lib/enigma2/python/", "")
        for tag, lst in (("different", changed), ("missing", missing), ("not in the official package", extra)):
            for p in lst[:3]:
                print("%s: %s" % (tag, short(p)))


if __name__ == "__main__":
    main(sys.argv[1:])
CVFPEOF
FETCH="$TMPD/cvfetch.py"
cat > "$FETCH" <<'CVFETCHEOF'
import os, socket, ssl, sys, time, urllib.error, urllib.request
# CineView MLA download from the distribution point (public HTTPS, no token, no login).
# Exit: 0 ok, 11 refused, 12 file missing, 13 network, 14 certificate, 15 server name not resolved (DNS).   usage: fetch.py check|get <base-url> <file> [<out>]
mode, base, name = sys.argv[1:4]
out = sys.argv[4] if len(sys.argv) > 4 else None
url = base.rstrip("/") + "/" + name
UA = {"User-Agent": "cineview-mla-installer"}
dns = False
for n in range(3):
    try:
        req = urllib.request.Request(url, headers=UA, method="HEAD" if mode == "check" else "GET")
        with urllib.request.urlopen(req, timeout=60) as r:
            if mode == "check":
                sys.exit(0)
            with open(out + ".part", "wb") as f:
                while True:
                    b = r.read(65536)
                    if not b:
                        break
                    f.write(b)
        os.replace(out + ".part", out)
        sys.exit(0)
    except urllib.error.HTTPError as e:
        if e.code == 404:
            sys.exit(12)
        if e.code in (401, 403):
            sys.exit(11)
    except urllib.error.URLError as e:
        if isinstance(getattr(e, "reason", None), ssl.SSLError) or "CERTIFICATE" in str(e).upper():
            sys.exit(14)
        dns = isinstance(getattr(e, "reason", None), socket.gaierror)
    except (OSError, ValueError):
        pass
    time.sleep(3 * (n + 1))
sys.exit(15 if dns else 13)
CVFETCHEOF
# fetch <mode> <tag/asset> [<out>]: from the distribution point, or from PKG_DIR (a file of the same name or asset name)
fetch() {
	if [ -n "${PKG_DIR:-}" ]; then
		_b=${2##*/}; _f=""
		for _c in "$PKG_DIR"/*.ipk; do [ -f "$_c" ] && [ "$(basename "$_c" | tr '~' '.')" = "$_b" ] && { _f="$_c"; break; }; done
		[ -n "$_f" ] || return 12
		[ "$1" = "check" ] && return 0
		cp "$_f" "$3" 2>/dev/null || return 13
		return 0
	fi
	python3 "$FETCH" "$1" "$BASE" "$2" ${3:+"$3"}
}
DLHOST=$(printf '%s' "$BASE" | sed 's#^[a-z]*://##; s#[/:].*##')
fetch_fail() {  # $1 exit code of fetch
	case "$1" in
		11) fail "The download server refused the request ($DLHOST). Please try again later." ;;
		12) [ -n "${PKG_DIR:-}" ] && fail "The package $2 is not in $PKG_DIR (copy the package file of your image there)."
			fail "The package is missing at the download address: $2. This installer may be out of date - download the current installer and run it again." ;;
		15) fail "The name of the download server ($DLHOST) could not be resolved on this receiver (DNS). Check the receiver's network settings (DNS / name server: Menu > Setup > Network), then run the command again." ;;
		14) fail "The secure connection to GitHub could not be verified (HTTPS certificate). Update the image's ca-certificates and try again." ;;
		*) fail "The download server ($DLHOST) could not be reached. Please check the internet connection and run the command again." ;;
	esac
}
# fingerprint of the files this package installed (opkg's own file list); "none" when not installed
fp_installed() { python3 "$FPY" installed "$PKG" 2>/dev/null || echo error; }
# CineView itself installed correctly, whatever opkg's exit status says: package manager state, version, files (fingerprint)
# and no error from CineView's own package scripts in the log ($1)
cv_installed_ok() {
	opkg status "$PKG" 2>/dev/null | grep -q "^Status: .* installed$" || return 1
	[ "$(opkg status "$PKG" 2>/dev/null | sed -n 's/^Version: //p')" = "$VERSION" ] || return 1
	[ -z "$PKG_DIGEST" ] || [ "$(fp_installed)" = "$PKG_DIGEST" ] || return 1
	! grep -q "CineView MLA: .*Stopped\|installation stopped\|$PKG\.p[a-z]*inst returned\|package \"$PKG\" p[a-z]* script returned" "$1" 2>/dev/null
}
# other packages whose scripts failed in this opkg run (named by opkg itself)
other_errors() {
	sed -n 's/.*opkg_configure: \([^ ]*\)\.postinst returned.*/\1/p; s/.*package "\([^"]*\)" [a-z]* script returned.*/\1/p' "$1" 2>/dev/null \
		| grep -v "^$PKG\$" | sort -u | tr '\n' ' ' | sed 's/ $//'
}
ext_warn() {
	ok "CineView MLA $VERSION was installed correctly (package manager: installed; files identical to the official package)"
	warn "The package manager also reported an error from another add-on: ${1:-not named in its output}. It is not part of CineView MLA and was left unchanged."
}
write_report() {  # diagnostic report of this run: /tmp, readable by root only, gone after a reboot
	[ -d "$TMPD" ] || return 0
	RPT=/tmp/cineview-install-report.txt
	{
		echo "CineView MLA installer report - $(date '+%Y-%m-%d %H:%M:%S')"
		echo "installer $INSTALLER_VERSION | build $BUILD_NAME | release $TAG | exit code $1"
		echo "options: DRYRUN=${DRYRUN:-0} ROLLBACK=${ROLLBACK:-0} RESTART=${RESTART:-1} ACCEPT_UNTESTED=${ACCEPT_UNTESTED:-0} OAWEATHER=${OAWEATHER:-0}"
		echo "image: ${IMG:-?} ${IVER:-} | distro ${DISTRO:-?} | code base like:${LIKE:- -} | receiver: ${NAME:-?} | arch: ${ARCH:-?}"
		echo "python: ${PYV:-?} | screen set: ${SET:-?} | package: ${VERSION:-?} | level: ${LEVEL:-?}"
		echo "CineView before: ${CUR:-none} | after: $(opkg status "$PKG" 2>/dev/null | sed -n 's/^Version: //p') | mode: ${MODE:-?}"
		echo "capability stop: ${CAPFAIL:-none} | missing components: ${MISSING:-none} | other designs missing:${MORE:- none} | optional modules missing:${MODS:- none}"
		echo "active skin: $(sed -n 's/^config.skin.primary_skin=//p' "$RT/etc/enigma2/settings" 2>/dev/null)"
		echo "feeds: $(cat "$RT"/etc/opkg/*.conf 2>/dev/null | sed -n 's/^src[^ ]* \([^ ]*\) \(.*\)$/\1=\2/p' | tr '\n' ' ')"
		echo; echo "--- messages"; cat "$TMPD/report" 2>/dev/null
		for f in "$TMPD"/opkg.log* "$TMPD/deps.dry" "$TMPD/cv.dry" "$TMPD/opkg.update"; do
			[ -s "$f" ] && { echo; echo "--- $(basename "$f") (last 40 lines)"; tail -n 40 "$f"; }
		done
		CL=$(ls -t /home/root/logs/*crash*.log 2>/dev/null | head -n 1)
		[ -n "$CL" ] && [ "$CL" != "${CRASH0:-}" ] && { echo; echo "--- new crash log $CL (last 60 lines)"; tail -n 60 "$CL"; }
	} > "$RPT" 2>/dev/null
	chmod 600 "$RPT" 2>/dev/null
	printf '  Diagnostic report: %s\n\n' "$RPT"
}
cleanup() {  # temporary files and this script only - never the poster cache, profiles, settings or backups
	RC0=$?; TOK=""
	write_report "$RC0"
	rm -rf "$TMPD" 2>/dev/null
	[ "${HAVELOCK:-0}" = "1" ] && rm -rf /tmp/.cvmla.lock 2>/dev/null
	case "$SELF" in /tmp/cineview-install*.sh) rm -f "$SELF" 2>/dev/null ;; esac
}
trap cleanup EXIT
trap 'exit 130' INT TERM HUP

section() { printf '\n%s%s%s\n' "$B$C" "$1" "$N"; printf '\n%s\n' "$1" >> "$TMPD/report" 2>/dev/null; }
ok()   { printf '  %s[OK]%s %s\n' "$G" "$N" "$1"; printf '  [OK] %s\n' "$1" >> "$TMPD/report" 2>/dev/null; }
info() { printf '  %s[..]%s %s\n' "$C" "$N" "$1"; printf '  [..] %s\n' "$1" >> "$TMPD/report" 2>/dev/null; }
warn() { printf '  %s[!!]%s %s\n' "$Y" "$N" "$1"; printf '  [!!] %s\n' "$1" >> "$TMPD/report" 2>/dev/null; }
fail() {
	printf '  %s[XX]%s %s\n' "$R" "$N" "$1"
	printf '  [XX] %s\n' "$1" >> "$TMPD/report" 2>/dev/null
	if [ "${PKG_RAN:-0}" = "1" ]; then  # the package manager has already run: something may have changed
		printf '\n%s%sThe CineView MLA installation was not completed.%s Run the installer again (it repairs the installation).%s\n\n' "$B" "$R" "$N" "${BK:+ Your settings restore point: $BK}"
	elif [ "${DEPS_RAN:-0}" = "1" ]; then
		printf '\n%s%sCineView MLA was not installed.%s Only missing image components were installed from the image feed: %s\n\n' "$B" "$R" "$N" "$MISSING"
	else
		printf '\n%s%sCineView MLA was not installed.%s Nothing was changed on this receiver.\n\n' "$B" "$R" "$N"
	fi
	exit 1
}
kv()   { sed -n "s/^$1='\{0,1\}\([^']*\)'\{0,1\}$/\1/p" "$INFO" 2>/dev/null | head -n 1; }

printf '\n%s%s  CineView MLA Smart Installer  %s  %sversion %s%s\n' "$B" "$W" "$N" "$C" "$INSTALLER_VERSION" "$N"
printf '  %sDesign & Development by habeb-s (c) 2026%s\n' "$W" "$N"

LOCK=/tmp/.cvmla.lock  # one installer at a time; a lock left by a run that was killed is taken over
if ! mkdir "$LOCK" 2>/dev/null; then
	OP=$(cat "$LOCK/pid" 2>/dev/null)
	if [ -n "$OP" ] && [ "$OP" != "$$" ] && kill -0 "$OP" 2>/dev/null && grep -q "cineview" "/proc/$OP/cmdline" 2>/dev/null; then
		fail "Another CineView MLA installation is running. Please wait until it has finished."
	fi
	rm -rf "$LOCK"; mkdir "$LOCK" 2>/dev/null || fail "/tmp is not writable."
fi
echo $$ > "$LOCK/pid"; HAVELOCK=1
for d in /tmp/.cvmla.*; do [ -d "$d" ] && [ "$d" != "$LOCK" ] && [ "$d" != "$TMPD" ] && rm -rf "$d" 2>/dev/null; done

# Recovery after a failed installation or a failed start: back to EXACTLY the CineView MLA package installed before
# when it is one of the pinned packages (1.1.1 family packages, previous public releases - SHA256-verified; its own
# package scripts keep the design), otherwise to the previous public release of this image - or, when no
# CineView MLA was installed before, removal of CineView MLA again.  Only the CineView MLA package is touched.
recover() {
	section "Recovery"
	info "Reason: $1"
	RECOVERED=0
	if [ "${ROLLBACK:-0}" = "1" ]; then
		warn "The return to the official release itself failed. ${BK:+Your settings restore point: $BK}"; return
	fi
	if [ -z "$CUR" ]; then
		for i in $(seq 1 30); do pidof opkg >/dev/null 2>&1 || break; sleep 2; done
		opkg remove "$PKG" >"$LOG.rm" 2>&1
		if opkg status "$PKG" 2>/dev/null | grep -q "^Status:.* installed$"; then
			warn "CineView MLA could not be removed again - please remove it with the image's plugin manager."
		else
			ok "CineView MLA removed again - CineView MLA is not installed, as before"; RECOVERED=1
		fi
		return
	fi
	KL=$(printf '%s\n' "$KNOWN" | awk -F'|' -v v="$CUR" '$1 == v' | head -n 1)
	if [ -n "$KL" ]; then  # the exact package that was installed before
		PREV_VERSION="$CUR"; PREV_FILE=$(printf '%s' "$KL" | cut -d'|' -f2); PREV_SHA=$(printf '%s' "$KL" | cut -d'|' -f3)
		info "Returning to CineView MLA $PREV_VERSION - exactly the package installed before"
	elif [ -n "$PREV_FILE" ]; then
		info "CineView MLA $CUR (installed before) is not among the kept packages - returning to the official $PREV_VERSION"
	else
		warn "There is no package to return to (CineView MLA $CUR is not among the kept packages). ${BK:+Your settings restore point: $BK}"; return
	fi
	RA=$(printf '%s' "$PREV_FILE" | tr '~' '.')
	fetch get "$RA" "$TMPD/rollback.ipk" >/dev/null 2>&1 || { warn "The package could not be downloaded. ${BK:+Your settings restore point: $BK}"; return; }
	[ "$(sha256sum "$TMPD/rollback.ipk" 2>/dev/null | cut -d' ' -f1)" = "$PREV_SHA" ] || { warn "The package failed the SHA256 check - not installed."; return; }
	for i in $(seq 1 30); do pidof opkg >/dev/null 2>&1 || break; sleep 2; done
	RO=""; CV=$(opkg status "$PKG" 2>/dev/null | sed -n 's/^Version: //p')
	[ -n "$CV" ] && opkg compare-versions "$CV" '>>' "$PREV_VERSION" 2>/dev/null && RO="--force-downgrade"  # CineView MLA only
	opkg install $RO "$TMPD/rollback.ipk" >"$LOG.rb" 2>&1
	if opkg status "$PKG" 2>/dev/null | grep -q "^Status:.* installed$" \
		&& [ "$(opkg status "$PKG" 2>/dev/null | sed -n 's/^Version: //p')" = "$PREV_VERSION" ]; then
		ok "Returned to CineView MLA $PREV_VERSION (design and settings kept)"; RECOVERED=1
	else
		warn "The return to CineView MLA $PREV_VERSION did not complete. ${BK:+Your settings restore point: $BK}"
	fi
}
section "Device"
[ -x "$RT/usr/bin/enigma2" ] && [ -d "$RT/usr/lib/enigma2/python/Components" ] || fail "Enigma2 was not found on this receiver."
BRAND=$(kv displaybrand); MODEL=$(kv displaymodel); MB=$(kv machinebuild); BR=$(kv brand)
# The package is the same for every receiver model (architecture 'all'), so the model never decides or blocks the
# installation (a legitimate receiver of any brand must not be refused).  It is shown as the image reports it and
# cross-checked with the receiver driver's own model file, read in the order the image itself uses (OpenATV
# Tools/StbHardware.getBoxProc).  Vu+: vu<vumodel>; /proc/stb/info/model is never used on Vu+ (its driver reports a
# fixed legacy value there: dm8000 on a Duo 4K SE).  No model is ever invented: an unknown model is shown as unknown.
SI="$RT/proc/stb/info"
rd() { [ -f "$1" ] && head -n 1 "$1" 2>/dev/null | tr 'A-Z' 'a-z' | tr -d '\r\000' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//'; }
lc() { printf '%s' "$1" | tr 'A-Z' 'a-z' | tr -cd 'a-z0-9'; }
VUM=$(rd "$SI/vumodel"); DRV=""; DSRC=""; SAME=0
if [ -n "$VUM" ]; then
	DRV="$VUM"; DSRC="vumodel"; [ "$MB" = "vu$VUM" ] && SAME=1
else
	for f in hwmodel gbmodel boxtype; do v=$(rd "$SI/$f"); [ -n "$v" ] && { DRV="$v"; DSRC="$f"; break; }; done
	[ -z "$DRV" ] && [ -f "$SI/azmodel" ] && { DRV=$(rd "$SI/model"); DSRC="model"; }
	[ -z "$DRV" ] && { DRV=$(rd "$RT/proc/boxtype"); [ -n "$DRV" ] && DSRC="/proc/boxtype"; }
	[ -z "$DRV" ] && { DRV=$(rd "$SI/model"); [ -n "$DRV" ] && DSRC="model"; }
	A=$(lc "$MB"); D=$(lc "$DRV")
	if [ -n "$A" ] && [ -n "$D" ]; then
		case "$A" in *"$D"*) SAME=1 ;; *) case "$D" in *"$A"*) SAME=1 ;; esac ;; esac
	fi
fi
NAME="${BRAND:+$BRAND }${MODEL:-${MB:-unknown model}}"
if [ -z "$MB" ]; then
	info "Receiver: ${DRV:+$DRV (receiver driver) - }the image does not report its model (not needed: one package fits every model)"
elif [ "$SAME" = "1" ]; then
	ok "$NAME ($MB, confirmed by the receiver driver)"
elif [ -n "$DRV" ]; then
	info "$NAME ($MB; the receiver driver reports '$DRV' - not needed: one package fits every model)"
else
	ok "$NAME ($MB)"
fi

section "Image"
E="$RT/usr/lib/enigma2/python"
DISTRO=""; IVER=""
[ -r "$INFO" ] && { DISTRO=$(kv distro); IVER=$(kv imageversion); }
if [ -z "$DISTRO" ]; then  # no /usr/lib/enigma.info: not a reason to stop - only shown
	DISTRO="unknown"
	IMG=$(head -n 1 "$RT/etc/issue" 2>/dev/null | sed 's/\\[a-z]//g;s/[[:space:]]*$//')
	IMG=${IMG:-"this image"}
	info "The image does not describe itself in /usr/lib/enigma.info - shown as '$IMG' (not needed to install)"
else
	case "$DISTRO" in
		openatv) IMG="OpenATV" ;; openbh) IMG="OpenBH" ;; openvix) IMG="OpenViX" ;; openpli) IMG="OpenPLi" ;;
		egami) IMG="EGAMI" ;; pure2) IMG="PurE2" ;;
		*) IMG=$(kv displaydistro); IMG=${IMG:-$DISTRO} ;;
	esac
	ok "$IMG ${IVER:-(version not stated)}"
fi
# Code base resemblance (information only): files only that image's own enigma2 ships
many() { for m in "$@"; do ls "$E/$m.py" "$E/$m.pyc" 2>/dev/null | grep -q . && return 0; done; return 1; }
LIKE=""
many "Components/International" "Components/Opkg" && LIKE="$LIKE OpenATV"
many "Screens/BpBlue" "Plugins/SystemPlugins/OBH/plugin" && LIKE="$LIKE OpenBH"
many "Plugins/SystemPlugins/ViX/plugin" "Plugins/SystemPlugins/ViX/ImageManager" && LIKE="$LIKE OpenViX"
# Screen set: CineView's skin composes its screens for the image named in enigma.info (openatv / openbh / openvix /
# openpli have their own screen files); for every other image it composes the OpenATV screens.
# Family package: OpenATV family (OpenATV, EGAMI, PurE2, other OE-Alliance images) / OpenBH-OpenViX / OpenPLi.
case "$DISTRO" in
	openatv|openbh|openvix|openpli) SET="$DISTRO"; ok "Screen set: $IMG (made for this image)" ;;
	*) SET="openatv"
		case "$DISTRO" in
			egami|pure2) ok "Screen set: OpenATV family (CineView's OpenATV screens, checked on $IMG)" ;;
			*) info "Screen set: OpenATV - CineView has no screens made for '$DISTRO'; its skin uses the OpenATV screens on any"
				info "other image"
				[ -n "$LIKE" ] && info "This image's Enigma2 code resembles:$LIKE" ;;
		esac ;;
esac
case "$SET" in openbh|openvix) FAM=openbhvix ;; openpli) FAM=openpli ;; *) FAM=openatv ;; esac

section "Python"
PYV=${CVMLA_PYV:-$(python3 -c 'import sys; print("%d.%d" % sys.version_info[:2])' 2>/dev/null)}  # CVMLA_PYV: test hook only
[ -n "$PYV" ] || fail "Python 3 was not found. CineView MLA runs on Enigma2 images with Python 3 (3.9 to 3.14)."
PK=$(echo "$PYV" | tr -d .)
eval "VERSION=\${F_${FAM}_VERSION:-}; PKG_FILE=\${F_${FAM}_FILE:-}; PKG_SHA=\${F_${FAM}_SHA:-}; PKG_DIGEST=\${F_${FAM}_DIGEST:-}; FPY_LIST=\${F_${FAM}_PY:-}"
case " $FPY_LIST " in
	*" $PYV "*) ;;
	*) warn "This image has Python $PYV. CineView MLA's modules are compiled byte code; the $FAM family package has them"
		warn "for Python $FPY_LIST."
		fail "No compatible CineView MLA package for Python $PYV. To adapt: a build compiled for Python $PYV. Nothing was changed." ;;
esac
[ -d "$RT/usr/lib/python$PYV/site-packages" ] \
	|| fail "/usr/lib/python$PYV/site-packages is missing: CineView's boot guardian (its start-up safety) could not be installed. To adapt: the guardian's start-up hook for this image's Python layout. Nothing was changed."
ok "Python $PYV - included in the $FAM family package (Python $FPY_LIST)"
# previous public release (ROLLBACK=1 / recovery when the package installed before is not pinned): CineView MLA 1.1.1
# of the same family package (same files as 1.1.2, the earlier package scripts)
eval "PREV_FILE=\${P111_${FAM}_FILE:-}; PREV_SHA=\${P111_${FAM}_SHA:-}; PREV_DIGEST=\${P111_${FAM}_DIGEST:-}"
PREV_VERSION="1.1.1+$FAM"

section "Compatibility level"
VMAJ=${IVER%%.*}; VREST=${IVER#*.}; VMNR=${VREST%%.*}; VMNR=${VMNR%%[!0-9]*}
UNTESTED=0; LEVEL=""; SMIN=""
for _m in $SUPPORTED_MIN; do [ "${_m%%:*}" = "$DISTRO" ] && SMIN=${_m#*:}; done
case "$VMAJ:$VMNR" in *[!0-9:]*|:*|*:) VOK=0 ;; *) VOK=1 ;; esac
if [ -n "$SMIN" ] && [ "$VOK" = "1" ]; then
	if [ "$VMAJ" -lt "${SMIN%%.*}" ] || { [ "$VMAJ" -eq "${SMIN%%.*}" ] && [ "$VMNR" -lt "${SMIN#*.}" ]; }; then
		CAPFAIL="below the minimum version ($SMIN)"
		fail "$IMG $IVER is older than $IMG $SMIN, the oldest version CineView MLA supports. Update the image to $IMG $SMIN or newer. Nothing was changed."
	fi
fi
case ":$VERIFIED:" in
	*":$DISTRO:$VMAJ.$VMNR:$PYV:"*)
		LEVEL=verified
		ok "VERIFIED: CineView MLA (this build's skin and code) ran on $IMG $VMAJ.$VMNR / Python $PYV" ;;
	*) if [ -n "$SMIN" ] && [ "$VOK" = "1" ]; then
		LEVEL=supported
		ok "SUPPORTED: $IMG $IVER ($IMG $SMIN and newer are supported) with Python $PYV ($FAM family package)"
		info "Not device-tested on this exact version (device-tested: $VERIFIED_TEXT)."
		info "The checks below confirm what CineView needs from this image before anything is changed."
	else
		LEVEL=experimental; UNTESTED=1
		[ -n "$SMIN" ] && warn "The version of $IMG ('${IVER:-not stated}') cannot be read - its minimum ($IMG $SMIN) cannot be checked."
		warn "EXPERIMENTAL: CineView MLA has not been seen running on $IMG ${IVER} / Python $PYV."
		warn "Device-tested: $VERIFIED_TEXT. The checks below test what CineView needs from this image;"
		warn "they cannot prove every screen of this image's Enigma2 accepts CineView's screens. Risks: a screen may look"
		warn "wrong or fail to open; if the GUI cannot start with CineView, its boot guardian returns to the previous skin."
	fi ;;
esac
if [ "${ROLLBACK:-0}" = "1" ]; then  # the previous public release of this image / Python, pinned by its SHA256
	[ -n "$PREV_FILE" ] || fail "There is no earlier public CineView MLA release for $IMG / Python $PYV to return to. Nothing was changed."
	VERSION="$PREV_VERSION"; PKG_FILE="$PREV_FILE"; PKG_SHA="$PREV_SHA"; PKG_DIGEST="$PREV_DIGEST"; FORCE=1
	info "Rollback requested: the previous public CineView MLA $VERSION ($IMG, Python $PYV)"
else
	PKG_FILE="$TAG/$PKG_FILE"
fi
ASSET=$(printf '%s' "$PKG_FILE" | tr '~' '.')  # GitHub stores ~ as . in asset names (+ is kept: verified on the packages-1.1.1 release)
case "$PKG_SHA:$VERSION:$PKG_FILE:$PKG_DIGEST" in *@*|:*|*::*|*:) fail "This installer is incomplete (package table)." ;; esac
ok "Package: CineView MLA $VERSION (${FAM} family package)"

section "Architecture"
ARCH=$(kv architecture); [ -n "$ARCH" ] || ARCH=$(uname -m)
opkg print-architecture 2>/dev/null | grep -q "^arch all " || fail "This receiver does not accept architecture-independent packages."
ok "Architecture: $ARCH (CineView MLA is architecture-independent)"

section "Compatibility"
# /usr/bin/enigma2_pre_start.sh is the images' ONE pre-start hook.  CineView MLA does not use it (its boot guardian
# starts from Python's start-up hook), so an add-on that owns this file stays installed and working, untouched.
H="$RT/usr/bin/enigma2_pre_start.sh"
if [ -e "$H" ] && ! grep -q "CineView MLA guardian" "$H" 2>/dev/null; then
	HOWNER=$(opkg search /usr/bin/enigma2_pre_start.sh 2>/dev/null | sed -n '1s/ - .*//p')
	ok "Pre-start hook of ${HOWNER:-another add-on} found - kept as it is (CineView MLA does not use that file)"
fi
# Capabilities, measured on this image (lists extracted from the packages at build time):
#  * every Converter / Renderer / Addon the factory design's screens use - a missing one breaks those screens: STOP
#  * MovieInfo 'FullDescription' (event descriptions) when the factory design uses it: STOP when missing
#  * components only other designs use, and Enigma2 modules CineView's code imports: reported (experimental)
has_comp() {  # $1 = Converter/X | Renderer/X | Addons/X
	ls "$E/Components/$1.py" "$E/Components/$1.pyc" "$E/Components/$1.so" "$E/Components/${1%/*}/__pycache__/${1#*/}".*.pyc 2>/dev/null | grep -q .
}
has_mod() {  # $1 = dotted module name below the Enigma2 Python tree
	_p=$(printf '%s' "$1" | tr . /)
	ls "$E/$_p.py" "$E/$_p.pyc" "$E/$_p.so" "$E/$_p/__init__.py" "$E/$_p/__init__.pyc" 2>/dev/null | grep -q . || [ -d "$E/$_p" ]
}
eval "RQ=\$REQ_${SET}_DEFAULT; RM=\$REQ_${SET}_MORE; FD=\$REQ_${SET}_FULLDESC"
MISS=""; NRQ=0
for c in $RQ; do NRQ=$((NRQ + 1)); has_comp "$c" || MISS="$MISS $c"; done
if [ -n "$MISS" ]; then
	warn "This image's Enigma2 does not have skin components CineView's screens use:$MISS"
	CAPFAIL="skin components missing:$MISS"
	fail "No compatible CineView MLA package for this image yet: its screens would fail to open here. To adapt: a CineView screen set without these components for this image (report this list). Nothing was changed."
fi
ok "Skin components of the factory design: all $NRQ present in this image's Enigma2"
if [ "$FD" = "1" ]; then
	grep -aq "FullDescription" "$E/Components/Converter/MovieInfo.py" "$E/Components/Converter/MovieInfo.pyc" 2>/dev/null || {
		CAPFAIL="MovieInfo FullDescription missing"
		fail "This image's MovieInfo converter has no 'FullDescription' (event descriptions in CineView's screens). To adapt: CineView screens without it for this image. Nothing was changed."; }
	ok "Event descriptions supported (MovieInfo FullDescription)"
fi
eval "E2C=\${REQ_E2CORE_${SET}:-\$REQ_E2CORE}"; CORE=""; for m in $E2C; do has_mod "$m" || CORE="$CORE $m"; done
if [ -n "$CORE" ]; then
	warn "This image's Enigma2 does not have modules CineView's code needs to load:$CORE"
	CAPFAIL="Enigma2 modules missing:$CORE"
	fail "No compatible CineView MLA package for this image yet: CineView's converters / plugin would not load. To adapt: CineView code without these modules for this image (report this list). Nothing was changed."
fi
ok "Enigma2 modules CineView's code loads: all present"
MORE=""; PLUGC=""
for c in $RM; do
	has_comp "$c" && continue
	case "${c#*/}" in
		EMC*) PLUGC="$PLUGC $c" ;;  # shipped by the EnhancedMovieCenter plugin itself, used only in its player screen
		*) MORE="$MORE $c" ;;
	esac
done
[ -n "$PLUGC" ] && info "Optional:$PLUGC - part of the EnhancedMovieCenter plugin (not installed); CineView's EMC player screen uses it only when that plugin is installed. Not required."
[ -n "$MORE" ] && warn "Some other designs use components this image does not have:$MORE - those designs may not display correctly"
MODS=""; for m in $REQ_E2OPT; do has_mod "$m" || MODS="$MODS $m"; done
[ -n "$MODS" ] && warn "Optional Enigma2 modules CineView uses when present are missing:$MODS - the related functions are unavailable"
[ -z "$MORE$MODS" ] && ok "Components of the other designs and optional Enigma2 modules present"
# Experimental environment: asked here - before the package lists are refreshed or anything else is touched.
# Anything already waiting in the terminal (e.g. the line break of a pasted command) is discarded first, and only an
# explicit y / n counts: an empty line asks again.
ask_yes() {
	python3 -c 'import os, termios
try:
    fd = os.open("/dev/tty", os.O_RDWR | os.O_NOCTTY); termios.tcflush(fd, termios.TCIFLUSH); os.close(fd)
except Exception:
    pass' 2>/dev/null
	_n=0
	while [ "$_n" -lt 4 ]; do
		printf '\n  %sInstall CineView MLA on this EXPERIMENTAL combination? Nothing has been changed so far. [y/n] %s' "$Y" "$N"
		ANS=""
		if ! { read -r ANS </dev/tty; } 2>/dev/null; then
			ANSWER="no terminal"; return 1
		fi
		ANS=$(printf '%s' "$ANS" | tr -d '\r\t ' | tr 'A-Z' 'a-z')
		case "$ANS" in
			y|yes) ANSWER="yes"; return 0 ;;
			n|no) ANSWER="no"; return 1 ;;
			"") printf '  Please type y (install) or n (cancel), then press Enter.\n' ;;
			*) printf '  "%s" is not an answer - please type y or n, then press Enter.\n' "$ANS" ;;
		esac
		_n=$((_n + 1))
	done
	ANSWER="no valid answer"; return 1
}
if [ "${UNTESTED:-0}" = "1" ] && [ "${DRYRUN:-0}" != "1" ] && [ "${ACCEPT_UNTESTED:-0}" != "1" ] && [ "${ROLLBACK:-0}" != "1" ]; then
	if ask_yes; then
		ok "Confirmed: experimental installation"
	else
		printf '  [..] experimental installation not confirmed (answer: %s)\n' "$ANSWER" >> "$TMPD/report" 2>/dev/null
		[ "$ANSWER" = "no terminal" ] && printf '\n  No terminal to ask on - to install anyway, put ACCEPT_UNTESTED=1 in front of the command.\n'
		printf '\n%sNothing was changed.%s\n\n' "$B" "$N"; exit 0
	fi
fi
# Dependencies (checked here; nothing is installed before the package itself is downloaded and verified):
#  * every package CineView MLA declares (control: Depends) - installed / available from THIS image's configured feeds
#  * every Python module CineView MLA imports at run time - importable by this receiver's Python
# Only the image's own package manager and its configured feeds are used: no feed is added, nothing is forced, no
# other package is removed or downgraded; a dependency that is installed and working is never reinstalled.
MISSING=""
for d in $DEPS; do
	opkg status "$d" 2>/dev/null | grep -q "^Status:.* installed$" || MISSING="$MISSING $d"
done
for m in $PYMODS; do
	python3 -c "import $m" >/dev/null 2>&1 && continue
	case "$m" in
		requests) DP=python3-requests ;;
		PIL.Image) DP=python3-pillow ;;
		*) fail "The Python module '$m' is missing from this image's Python. CineView MLA needs it; it is part of the image, so no package is guessed for it." ;;
	esac
	case " $MISSING " in
		*" $DP "*) ;;  # not installed yet: installed with the other missing dependencies
		*) fail "$DP is installed but its module '$m' cannot be loaded (broken installation). Repair it from the image first (this installer never forces a reinstall)." ;;
	esac
done
MISSING="${MISSING# }"
if [ -n "$MISSING" ]; then
	FEEDOK=1
	for d in $MISSING; do opkg list 2>/dev/null | grep -q "^$d " || FEEDOK=0; done
	if [ "$FEEDOK" = "0" ] && [ "${DRYRUN:-0}" = "1" ]; then
		# check-only run: the package lists on the receiver are never refreshed (opkg update writes them)
		DEPS_UNCHECKED=1
		warn "Missing components: $MISSING - not in the receiver's cached package lists"
		info "Check-only run: the package lists are not refreshed. An installation refreshes them from this image's own"
		info "configured feeds first, then checks availability and conflicts before anything is installed."
	else
		if [ "$FEEDOK" = "0" ]; then
			info "Refreshing the package lists of this image's configured feeds"
			opkg update >"$TMPD/opkg.update" 2>&1 || warn "The package lists could not be refreshed completely (see the image's feed settings)"
		fi
		for d in $MISSING; do
			opkg list 2>/dev/null | grep -q "^$d " || fail "Required component '$d' is not installed and this image's feeds do not offer it."
		done
		opkg install --noaction $MISSING >"$TMPD/deps.dry" 2>&1
		if grep -qi "cannot satisfy\|conflict\|incompatible\|collected errors\|unknown package\|cannot install" "$TMPD/deps.dry"; then
			grep -i "cannot satisfy\|conflict\|incompatible\|unknown package\|cannot install" "$TMPD/deps.dry" | head -n 3 | while read -r l; do warn "$l"; done
			fail "The missing components ($MISSING) cannot be installed from this image's feeds without a conflict."
		fi
		if [ "${DRYRUN:-0}" = "1" ]; then
			warn "Missing components: $MISSING - available from this image's own feed, no conflict (an installation installs them)"
		else
			warn "Missing components will be installed from this image's own feed: $MISSING"
		fi
	fi
else
	ok "Required components present ($DEPS; Python modules: all importable)"
fi
# Weather: the Classic, Details and Cinema designs show the weather (city, temperature, icon).  Since 1.0.5 these widgets
# use CineView MLA's own weather components: OAWeather's own data while OAWeather runs with its saved location,
# CineView's own lookup (Open-Meteo) otherwise - a design never needs OAWeather to load or to show the weather.  OAWeather (oe-alliance
# plugin, package enigma2-plugin-extensions-oaweather) is checked here and is never removed, replaced or changed:
#   installed and healthy (package installed, every module present, byte code for THIS Python) -> used as it is
#   not installed -> installed from the image's OWN feed when the feed offers it (opkg, with the dependencies the image
#                    declares, built for this image and Python) - nothing is fetched from anywhere else
#   installed but incomplete, half-installed or built for another Python -> left as it is; CineView's own weather is used
oaw_state() {  # ok | missing | broken:<reason>
	OST=$(opkg status enigma2-plugin-extensions-oaweather 2>/dev/null | sed -n 's/^Status: //p' | head -n 1)
	python3 - "$RT/usr/lib/enigma2/python" "$OST" <<'PYEOF' 2>/dev/null || echo "broken:its check could not run"
import importlib.util, os, sys
E, status = sys.argv[1], sys.argv[2].strip()
need = ("Components/Sources/OAWeather", "Components/Converter/OAWeather", "Components/Renderer/OAWeatherPixmap",
	"Plugins/Extensions/OAWeather/__init__", "Plugins/Extensions/OAWeather/plugin", "Tools/Weatherinfo")
have = {}
for n in need:
	for ext in (".py", ".pyc"):  # Python imports the source when both exist
		if os.path.isfile(os.path.join(E, n + ext)):
			have[n] = os.path.join(E, n + ext)
			break
if not status and not have:
	print("missing")
elif status and not status.endswith(" installed"):
	print("broken:its package is not completely installed (%s)" % status)
elif len(have) < len(need):
	print("broken:files are missing (%s)" % ", ".join(n.split("/")[-1] for n in need if n not in have))
else:
	bad = ""
	for n, p in sorted(have.items()):
		try:
			if p.endswith(".pyc"):
				with open(p, "rb") as f:
					if f.read(4) != importlib.util.MAGIC_NUMBER:
						bad = "%s is built for another Python version" % os.path.basename(p)
			else:
				with open(p, encoding="utf-8") as f:
					compile(f.read(), p, "exec")
		except Exception as e:
			bad = "%s cannot be read by this Python (%s)" % (os.path.basename(p), e.__class__.__name__)
		if bad:
			break
	print("broken:" + bad if bad else "ok")
PYEOF
}
WEATHER=""
OAW=$(oaw_state)
case "$OAW" in
	ok) ok "Weather: OAWeather installed and built for this image's Python - its weather data is used as it is" ;;
	missing)
		if [ "${OAWEATHER:-0}" != "1" ]; then
			info "Weather: OAWeather (optional) is not installed - CineView's own weather (Open-Meteo) is used"
		else
			opkg list 2>/dev/null | grep -q "^enigma2-plugin-extensions-oaweather " \
				|| { [ "${DRYRUN:-0}" = "1" ] || opkg update >/dev/null 2>&1; }
			if opkg list 2>/dev/null | grep -q "^enigma2-plugin-extensions-oaweather "; then
				WEATHER=1; info "Weather: OAWeather will be installed from the image's own feed (OAWEATHER=1)"
			else
				info "Weather: OAWeather is not in this image's (cached) package lists - CineView's own weather (Open-Meteo) is used"
			fi
		fi ;;
	*) warn "Weather: OAWeather is installed but ${OAW#broken:} - it is left as it is; CineView's own weather (Open-Meteo) is used" ;;
esac
# The weather location is only one the user has set - the location saved in OAWeather, or the city chosen in CineView
# Designs > Weather city - never a guess (a time zone does not say where the receiver is).
if ! grep -q '^config.plugins.OAWeather.weatherlocation=' "$RT/etc/enigma2/settings" 2>/dev/null \
	&& ! grep -q '"weather_city"' "$RT$STATE/runtime.json" 2>/dev/null; then
	info "Weather: no location set yet - choose your city once in CineView Designs > Weather city (or save a location in OAWeather)"
fi
ok "Package matches this receiver ($IMG $IVER, Python $PYV, $ARCH)"

section "Storage"
FREE=$(df -Pk / | awk 'NR==2 {print $4}')
TFREE=$(df -Pk /tmp | awk 'NR==2 {print $4}')
[ -n "$FREE" ] && [ "$FREE" -ge "$NEED_ROOT_KB" ] || fail "Not enough free space: $(( ${FREE:-0} / 1024 )) MB free, $(( NEED_ROOT_KB / 1024 )) MB needed."
[ -n "$TFREE" ] && [ "$TFREE" -ge "$NEED_TMP_KB" ] || fail "Not enough free space in /tmp for the download."
STOR=$(python3 - "${HDD_CACHE:-1}" "$FREE" <<'PYEOF'
# Storage, read only: which device holds the image's root filesystem (where the package goes), and where CineView's
# poster renderer (CineViewMLAPosterX._mla_cache_plan) will keep its cache - the same decision, plus the physical
# device behind it.  Nothing is created, mounted or changed.
import json, os, re, sys
hdd_cache, free_kb = sys.argv[1], int(sys.argv[2] or 0)
mounts = []
for l in open("/proc/mounts"):
    p = l.split()
    if len(p) >= 4:
        mounts.append((p[0], p[1].replace("\\040", " "), p[2], p[3].split(",")))
cmd = open("/proc/cmdline").read()
try:
    root_dev = os.stat("/").st_dev
except OSError:
    root_dev = None
def disk_of(src):
    m = re.match(r"/dev/((?:sd[a-z]+)|(?:mmcblk\d+)|(?:nvme\d+n\d+))", src or "")
    return m.group(1) if m else None
def describe(src):
    d = disk_of(src)
    if not d:
        return src or "?", ""
    def r(f):
        try:
            return open("/sys/block/%s/%s" % (d, f)).read().strip()
        except OSError:
            return ""
    model = " ".join(x for x in (r("device/vendor"), r("device/model")) if x)
    try:
        sysp = os.path.realpath("/sys/block/" + d)
    except OSError:
        sysp = ""
    kind = "internal flash" if d.startswith("mmcblk") else "USB" if "/usb" in sysp else "SATA" if "/ata" in sysp else "disk"
    try:
        gb = int(r("size") or 0) * 512 / 1e9
    except ValueError:
        gb = 0
    return src, "%s%s%s" % (kind, ", " + model if model else "", ", %.0f GB" % gb if gb else "")
def multiboot(mp):
    try:
        names = os.listdir(mp)
    except OSError:
        return False
    return any(n == "STARTUP" or n.startswith("STARTUP_") or n.startswith("linuxrootfs") for n in names)
# root filesystem (multiboot images name it on the kernel command line)
rsrc = re.search(r"\broot=(\S+)", cmd)
rsrc = rsrc.group(1) if rsrc else next((s for s, mp, f, o in mounts if mp == "/" and s.startswith("/dev/")), "?")
sub = re.search(r"\brootsubdir=(\S+)", cmd)
s, d = describe(rsrc)
print("ROOT|%s|%s|%s" % (s, d, sub.group(1) if sub else ""))
# poster cache - the renderer's decision
def real(mp, opts, src):
    try:
        return "rw" in opts and os.path.ismount(mp) and os.stat(mp).st_dev != root_dev and src.startswith(("/dev/", "UUID=", "LABEL="))
    except OSError:
        return False
rt = {}
try:
    rt = json.load(open("/etc/enigma2/cineview_mla/runtime.json"))
except Exception:
    pass
plan, src_used = None, None
if rt.get("poster_cache"):
    plan, how = rt["poster_cache"], "kept"
    best = max((m for m in mounts if plan == m[1] or plan.startswith(m[1].rstrip("/") + "/")), key=lambda m: len(m[1]), default=None)
    src_used = best[0] if best else None
else:
    for src, mp, fs, opts in (mounts if hdd_cache != "0" else []):  # HDD_CACHE=0: the hard disk is skipped (pinned later)
        if mp == "/media/hdd" and real(mp, opts, src):
            plan, how, src_used = "/media/hdd/poster", "hdd", src
            break
    if not plan:
        usb = []
        for src, mp, fs, opts in mounts:
            if not mp.startswith("/media/") or mp == "/media/hdd" or fs in ("tmpfs", "devtmpfs", "proc", "sysfs", "overlay", "squashfs", "nfs", "nfs4", "cifs", "smbfs", "fuse.sshfs"):
                continue
            if real(mp, opts, src) and not any(n == "STARTUP" or n.startswith("STARTUP_") for n in (os.listdir(mp) if os.path.isdir(mp) else [])):
                usb.append((0 if "usb" in mp else 1, mp, src))
        if usb:
            usb.sort()
            plan, how, src_used = os.path.join(usb[0][1], "poster"), "usb", usb[0][2]
    if not plan:
        plan, how = "/tmp/CINEVIEW-MLA/poster", "tmpopt" if hdd_cache == "0" else "tmp"
s, d = describe(src_used) if src_used else ("tmpfs", "RAM")
mpt = max((m[1] for m in mounts if plan.startswith(m[1].rstrip("/") + "/")), key=len, default="/")
n = 0
try:
    for _, _, f in os.walk(plan):
        n += len(f)
        if n > 100000:
            break
except OSError:
    pass
risk = ""
if how in ("hdd", "usb", "kept") and mpt != "/" and multiboot(mpt):
    risk = "multiboot"
elif how in ("hdd", "kept") and d.startswith("USB"):
    risk = "usb-as-hdd"
print("CACHE|%s|%s|%s|%s|%d|%s" % (how, plan, s, d, n, risk))
PYEOF
)
ROOTL=$(printf '%s\n' "$STOR" | sed -n 's/^ROOT|//p')
R_SRC=$(printf '%s' "$ROOTL" | cut -d'|' -f1); R_DESC=$(printf '%s' "$ROOTL" | cut -d'|' -f2); R_SUB=$(printf '%s' "$ROOTL" | cut -d'|' -f3)
ok "Free space for the package: $(( FREE / 1024 )) MB on the image's root filesystem - ${R_SRC}${R_DESC:+ ($R_DESC)}${R_SUB:+, image folder $R_SUB}"
CL=$(printf '%s\n' "$STOR" | sed -n 's/^CACHE|//p')
C_HOW=$(printf '%s' "$CL" | cut -d'|' -f1); C_PATH=$(printf '%s' "$CL" | cut -d'|' -f2); C_SRC=$(printf '%s' "$CL" | cut -d'|' -f3)
C_DESC=$(printf '%s' "$CL" | cut -d'|' -f4); C_N=$(printf '%s' "$CL" | cut -d'|' -f5); C_RISK=$(printf '%s' "$CL" | cut -d'|' -f6)
CACHE="$C_HOW|$C_PATH"
C_EXIST=""; [ "${C_N:-0}" -gt 0 ] 2>/dev/null && C_EXIST=", existing cache with $C_N files is kept"
case "$C_HOW" in
	hdd) ok "Poster cache (chosen by CineView at run time): $C_PATH - $C_SRC${C_DESC:+ ($C_DESC)}$C_EXIST" ;;
	usb) ok "Poster cache (chosen by CineView at run time): $C_PATH - $C_SRC${C_DESC:+ ($C_DESC)}$C_EXIST" ;;
	kept) ok "Poster cache: $C_PATH (your setting in runtime.json) - $C_SRC${C_DESC:+ ($C_DESC)}$C_EXIST" ;;
	tmpopt) warn "Poster cache: /tmp (HDD_CACHE=0 and no USB storage - posters are fetched again after a reboot)" ;;
	*) warn "Poster cache: /tmp (no hard disk or USB storage found - posters are fetched again after a reboot)" ;;
esac
case "$C_RISK" in
	multiboot) warn "That storage holds multiboot images (STARTUP / linuxrootfs): CineView would keep its posters there. Nothing is created by this installer; tell me before using CineView if that is not the disk you want." ;;
	usb-as-hdd) warn "/media/hdd is a USB device on this image, not a SATA disk: CineView would keep its posters there. Nothing is created by this installer; tell me before using CineView if that is not the disk you want." ;;
esac

section "Existing installation"
CUR=$(opkg status "$PKG" 2>/dev/null | sed -n 's/^Version: //p')
PST=$(opkg status "$PKG" 2>/dev/null | sed -n 's/^Status: //p')
MODE=install
# A maintainer script that failed leaves CineView's package entry incomplete (half-installed / unpacked /
# half-configured): the database names the new version while the old files are still in place.  Repair = one
# reinstall of the verified package; only CineView's own entry is involved.
case "$PST" in
	*half-installed*|*unpacked*|*half-configured*)
		warn "An earlier CineView MLA installation was not completed (package state: $PST)"
		MODE=repair ;;
esac
if [ "$MODE" = "repair" ]; then
	fail "Repairing it would need a forced reinstall, which this installer never does. Run the command with ROLLBACK=1 (previous public release, design kept) or remove CineView MLA with the image's plugin manager and install it again."
elif [ -z "$CUR" ]; then
	info "No earlier CineView MLA installation"
else
	info "Current version: $CUR"
	info "Approved version for $IMG: $VERSION"
	if [ "$CUR" = "$VERSION" ] && [ "${FORCE:-0}" != "1" ]; then
		IFP=$(fp_installed)
		if [ "$IFP" = "$PKG_DIGEST" ]; then
			MODE=same; ok "Installed files match the official CineView MLA $VERSION (content fingerprint)"
		else
			# same version number, other content: a test build, an incomplete or a damaged installation.  Replaced
			# by the official package (SHA256-verified); design, theme, profiles, settings and poster cache are kept.
			warn "The installed files are not the official CineView MLA $VERSION (same version number, different content)"
			fail "Replacing them would need a forced reinstall, which this installer never does."
		fi
	elif opkg compare-versions "$CUR" '<<' "$VERSION" 2>/dev/null; then
		MODE=upgrade; ok "Upgrade: your design, theme, profiles, settings and poster cache are kept"
	elif [ "${FORCE:-0}" = "1" ] && [ "$CUR" = "$VERSION" ]; then
		MODE=same; ok "The official CineView MLA $VERSION is already installed - nothing to roll back"
	elif [ "${FORCE:-0}" = "1" ]; then
		MODE=downgrade; warn "Return to the earlier version $VERSION requested (your design, theme and profiles are kept)"
	else
		warn "CineView MLA $CUR is installed - newer than $VERSION, the release this installer carries"
		info "It is not downgraded automatically: your installation stays as it is. Nothing was changed."
		printf '\n%s%sCineView MLA %s stays installed.%s The approved release for %s is %s.\n\n' "$B" "$Y" "$CUR" "$N" "$IMG" "$VERSION"
		exit 0
	fi
fi
[ -d /usr/share/enigma2/CineView_FHD ] && info "CineView FHD (classic edition) found - it stays installed and independent"

section "Download"
fetch check "$ASSET"; RC=$?
[ "$RC" -eq 0 ] || fetch_fail "$RC" "$ASSET"
[ -n "${PKG_DIR:-}" ] && ok "Package file found in $PKG_DIR" || ok "Download server reachable ($DLHOST) - ${ASSET##*/} is available"
if [ "${DRYRUN:-0}" = "1" ]; then
	section "Package check (check-only)"
	info "Downloading $ASSET to /tmp (RAM, deleted at the end) ..."
	fetch get "$ASSET" "$IPK" >/dev/null 2>&1; RC=$?
	[ "$RC" -eq 0 ] || fetch_fail "$RC" "$ASSET"
	[ "$(sha256sum "$IPK" 2>/dev/null | cut -d' ' -f1)" = "$PKG_SHA" ] \
		|| fail "The downloaded package failed the SHA256 check (damaged or not the approved file)."
	ok "Download works - package verified (SHA256 $(printf '%.16s' "$PKG_SHA")...)"
	# the dependencies the downloaded package declares must be exactly the ones checked above
	PDEPS=$(python3 - "$IPK" <<'PYEOF'
import io, re, sys, tarfile
raw = open(sys.argv[1], "rb").read()
pos = 8
while pos + 60 <= len(raw):
    name = raw[pos:pos + 16].decode("ascii", "replace").strip().rstrip("/")
    size = int(raw[pos + 48:pos + 58].decode("ascii").strip())
    if name.startswith("control.tar"):
        with tarfile.open(fileobj=io.BytesIO(raw[pos + 60:pos + 60 + size])) as t:
            for m in t.getmembers():
                if m.name.rstrip("/").endswith("control"):
                    for l in t.extractfile(m).read().decode("utf-8", "replace").splitlines():
                        if l.startswith("Depends:"):
                            print(" ".join(re.sub(r"\(.*?\)", "", d).replace(" ", "") for d in l[8:].split(",") if d.strip()))
    pos += 60 + size + (size % 2)
PYEOF
)
	for d in $PDEPS; do
		case "$d" in
			*"|"*)  # the image-family check of the package: one of these must be installed
				_ok=0; for a in $(printf '%s' "$d" | tr '|' ' '); do opkg status "$a" 2>/dev/null | grep -q "^Status:.* installed$" && _ok=1; done
				[ "$_ok" = "1" ] || fail "This package is for another image family (it needs one of: $(printf '%s' "$d" | sed 's/|/, /g')). Nothing was changed." ;;
			python3-core) ;;  # the Python range: checked above (Python section)
			*) case " $DEPS " in *" $d "*) ;; *) fail "The package declares a dependency this installer did not check ($d)." ;; esac ;;
		esac
	done
	ok "Declared dependencies: $( [ -n "$PDEPS" ] || echo none; printf '%s\n' $PDEPS | awk '!s[$0]++' | tr '\n' ' ' | sed 's/ $//') (all checked)"
	# conflicts: the package manager's own dry run of exactly this installation (no change)
	if [ "$MODE" = "same" ]; then
		info "Package manager dry run not needed: this exact version is already installed"
	elif [ "${DEPS_UNCHECKED:-0}" = "1" ]; then  # check-only run, missing components not in the cached lists
		info "Package manager dry run skipped: it needs the missing components in the package lists, which a check-only"
		info "run does not refresh. An installation runs it after refreshing the lists, before anything is installed."
	else
		DOPT=""; [ "$MODE" = "downgrade" ] && DOPT="--force-downgrade"
		opkg install --noaction $DOPT "$IPK" >"$TMPD/cv.dry" 2>&1
		if grep -qi "cannot satisfy\|conflict\|incompatible\|collected errors\|cannot install\|not compatible" "$TMPD/cv.dry"; then
			grep -i "cannot satisfy\|conflict\|incompatible\|cannot install\|not compatible" "$TMPD/cv.dry" | head -n 3 | while read -r l; do warn "$l"; done
			fail "The package manager reports a conflict for CineView MLA $VERSION on this receiver."
		fi
		ok "No conflicts (package manager dry run)"
	fi
	printf '\n%s%sAll checks passed.%s Check-only run: nothing was installed, refreshed, restarted or changed on this receiver.\n\n' "$B" "$G" "$N"
	exit 0
fi

if [ "$WEATHER" = "1" ]; then  # before the skin package; never fatal (CineView's own weather works without it)
	section "Weather"
	for i in $(seq 1 30); do pidof opkg >/dev/null 2>&1 || break; sleep 2; done
	opkg install enigma2-plugin-extensions-oaweather >"$LOG.weather" 2>&1
	OAW=$(oaw_state)
	if [ "$OAW" = "ok" ]; then
		ok "OAWeather installed from the image's own feed (its weather data is used after the next GUI restart)"
	else
		warn "OAWeather could not be installed completely (${OAW#broken:}) - CineView's own weather (Open-Meteo) is used"
	fi
fi

if [ "$MODE" != "same" ]; then
	section "Package"
	info "Downloading $ASSET ..."
	fetch get "$ASSET" "$IPK" >/dev/null 2>&1; RC=$?
	[ "$RC" -eq 0 ] || fetch_fail "$RC" "$ASSET"
	[ "$(sha256sum "$IPK" 2>/dev/null | cut -d' ' -f1)" = "$PKG_SHA" ] \
		|| fail "The downloaded package failed the SHA256 check (damaged or not the approved file)."
	ok "Package verified (SHA256)"
	if [ "${FPDIFF:-0}" = "1" ]; then  # show what differs from the official package before replacing it
		python3 "$FPY" diff "$PKG" "$IPK" > "$TMPD/fpdiff" 2>/dev/null
		read -r FC FM FX < "$TMPD/fpdiff" 2>/dev/null
		info "Compared with the official package: ${FC:-?} file(s) different, ${FM:-?} missing, ${FX:-?} not in the official package"
		tail -n +2 "$TMPD/fpdiff" 2>/dev/null | while read -r l; do info "  $l"; done
	fi
	# the dependencies the downloaded package declares must be exactly the ones checked above
	PDEPS=$(python3 - "$IPK" <<'PYEOF'
import io, re, sys, tarfile
raw = open(sys.argv[1], "rb").read()
pos = 8
while pos + 60 <= len(raw):
    name = raw[pos:pos + 16].decode("ascii", "replace").strip().rstrip("/")
    size = int(raw[pos + 48:pos + 58].decode("ascii").strip())
    if name.startswith("control.tar"):
        with tarfile.open(fileobj=io.BytesIO(raw[pos + 60:pos + 60 + size])) as t:
            for m in t.getmembers():
                if m.name.rstrip("/").endswith("control"):
                    for l in t.extractfile(m).read().decode("utf-8", "replace").splitlines():
                        if l.startswith("Depends:"):
                            print(" ".join(re.sub(r"\(.*?\)", "", d).replace(" ", "") for d in l[8:].split(",") if d.strip()))
    pos += 60 + size + (size % 2)
PYEOF
)
	for d in $PDEPS; do
		case "$d" in
			*"|"*)  # the image-family check of the package: one of these must be installed
				_ok=0; for a in $(printf '%s' "$d" | tr '|' ' '); do opkg status "$a" 2>/dev/null | grep -q "^Status:.* installed$" && _ok=1; done
				[ "$_ok" = "1" ] || fail "This package is for another image family (it needs one of: $(printf '%s' "$d" | sed 's/|/, /g')). Nothing was changed." ;;
			python3-core) ;;  # the Python range: checked above (Python section)
			*) case " $DEPS " in *" $d "*) ;; *) fail "The package declares a dependency this installer did not check ($d)." ;; esac ;;
		esac
	done
	ok "Declared dependencies: $( [ -n "$PDEPS" ] || echo none; printf '%s\n' $PDEPS | awk '!s[$0]++' | tr '\n' ' ' | sed 's/ $//') (all checked)"
	# conflicts: the package manager's own dry run of exactly this installation (no change)
	if [ "$MODE" = "same" ]; then
		info "Package manager dry run not needed: this exact version is already installed"
	elif [ "${DEPS_UNCHECKED:-0}" = "1" ]; then  # check-only run, missing components not in the cached lists
		info "Package manager dry run skipped: it needs the missing components in the package lists, which a check-only"
		info "run does not refresh. An installation runs it after refreshing the lists, before anything is installed."
	else
		DOPT=""; [ "$MODE" = "downgrade" ] && DOPT="--force-downgrade"
		opkg install --noaction $DOPT "$IPK" >"$TMPD/cv.dry" 2>&1
		if grep -qi "cannot satisfy\|conflict\|incompatible\|collected errors\|cannot install\|not compatible" "$TMPD/cv.dry"; then
			grep -i "cannot satisfy\|conflict\|incompatible\|cannot install\|not compatible" "$TMPD/cv.dry" | head -n 3 | while read -r l; do warn "$l"; done
			fail "The package manager reports a conflict for CineView MLA $VERSION on this receiver."
		fi
		ok "No conflicts (package manager dry run)"
	fi
	if [ -n "$MISSING" ]; then
		section "Dependencies"
		for i in $(seq 1 30); do pidof opkg >/dev/null 2>&1 || break; sleep 2; done
		DEPS_RAN=1
		opkg install $MISSING >"$LOG.deps" 2>&1
		for d in $MISSING; do
			opkg status "$d" 2>/dev/null | grep -q "^Status:.* installed$" \
				|| fail "The component '$d' could not be installed from this image's feed ($(grep -i "error\|cannot" "$LOG.deps" | head -n 1))."
			ok "$d installed from the image's feed"
		done
		for m in $PYMODS; do python3 -c "import $m" >/dev/null 2>&1 || fail "The Python module '$m' still cannot be loaded after installing the components."; done
		ok "All Python modules CineView MLA needs can be loaded"
	fi
	[ "${CVMLA_FETCH_ONLY:-0}" = "1" ] && { printf '\nfetch-only test: package downloaded and verified; nothing was installed.\n'; exit 0; }  # test hook only

	section "Installing"
	if [ -d "$STATE" ] || [ -f /etc/enigma2/settings ]; then  # small restore point (settings + CineView state)
		BK="$STATE/backup/$(date +%Y%m%d-%H%M%S)"
		mkdir -p "$BK" 2>/dev/null && cp -p /etc/enigma2/settings "$BK/settings" 2>/dev/null
		if [ -d "$STATE" ]; then
			tar -C /etc/enigma2 --exclude=cineview_mla/backup -czf "$BK/cineview_mla.tgz" cineview_mla 2>/dev/null \
				|| tar -C "$STATE" -czf "$BK/cineview_mla.tgz" $(ls "$STATE" | grep -v '^backup$') 2>/dev/null
		fi
		ok "Restore point saved"
	fi
	for i in $(seq 1 30); do pidof opkg >/dev/null 2>&1 || break; sleep 2; done  # another package operation: wait for it
	OPT=""; [ "$MODE" = "downgrade" ] && OPT="--force-downgrade"  # ROLLBACK=1 only: CineView MLA itself, nothing else
	PKG_RAN=1
	if ! opkg install $OPT "$IPK" >"$LOG" 2>&1; then
		PST=$(opkg status "$PKG" 2>/dev/null | sed -n 's/^Status: //p')
		if cv_installed_ok "$LOG"; then
			# opkg's error came from another package configured in the same run: CineView itself is installed correctly
			ext_warn "$(other_errors "$LOG")"
		else
			REASON=$(grep -h "CineView MLA:\|Collected errors\|cannot\|Cannot\|error" "$LOG" | grep -v "^ \* opkg_" | grep -v "CineView MLA: image " | head -n 3)
			OE=$(other_errors "$LOG")
			[ -n "$OE" ] && warn "The package manager also reported an error from another add-on: $OE. It is not part of CineView MLA and was left unchanged."
			warn "CineView MLA $VERSION was not installed correctly${REASON:+: $REASON}"
			recover "the installation failed"
			exit 1
		fi
	fi
	PST=$(opkg status "$PKG" 2>/dev/null | sed -n 's/^Status: //p')
	case "$PST" in *" installed") ;; *) warn "The package state after installing is '${PST:-none}' (expected: installed)."; recover "the installation was incomplete"; exit 1 ;; esac
	grep -q "factory design (Classic, Navy) is active" "$LOG" && warn "The previous design could not be kept: the factory design (Classic, Navy) is active"
	ok "CineView MLA $VERSION installed"
	if [ "${HDD_CACHE:-1}" = "0" ] && [ "${CACHE%%|*}" != "kept" ]; then
		python3 - "${CACHE#*|}" <<'PYEOF'
import json, os, sys
p = "/etc/enigma2/cineview_mla/runtime.json"
try:
    rt = json.load(open(p))
except Exception:
    rt = {}
rt["poster_cache"] = sys.argv[1]
os.makedirs(os.path.dirname(p), exist_ok=True)
json.dump(rt, open(p, "w"), indent=1)
PYEOF
	fi
fi

section "Verification"
V=$(opkg status "$PKG" 2>/dev/null | sed -n 's/^Version: //p')
[ "$V" = "$VERSION" ] && ok "Package version $V" || fail "Installed version is '${V:-none}', expected $VERSION."
if [ -n "$PKG_DIGEST" ]; then
	IFP=$(fp_installed)
	if [ "$IFP" = "$PKG_DIGEST" ]; then
		ok "Installed files identical to the official package (content fingerprint)"
	else
		warn "The installed files do not match the approved CineView MLA $VERSION package."
		recover "the installed files are not the approved ones"; exit 1
	fi
fi
[ -f "$SKIN_DIR/skin.xml" ] && [ -e "$SKIN_DIR/active/theme.xml" ] && ok "Skin files present" || fail "Skin files are incomplete."
if python3 - "$PLG_DIR/abi/cp$PK/Plugins/Extensions/CineViewMLA/plugin.pyc" "$PLG_DIR/plugin.pyc" "$PLG_DIR/plugin.py" <<'PYEOF'
import importlib.util, marshal, os, sys
for f in sys.argv[1:]:
    if os.path.isfile(f):
        if f.endswith(".pyc"):
            data = open(f, "rb").read()
            if data[:4] != importlib.util.MAGIC_NUMBER:
                sys.exit(1)
            marshal.loads(data[16:])
        else:
            compile(open(f).read(), f, "exec")
        sys.exit(0)
sys.exit(1)
PYEOF
then ok "Plugin loadable"; else fail "The CineView Designs plugin cannot be loaded by this Python."; fi
[ -s "$PLG_DIR/plugin.png" ] && ok "Plugin icon present" || fail "Plugin icon is missing."
grep -aq "CineView Designs" "$PLG_DIR"/plugin.py* "$PLG_DIR/abi/cp$PK/Plugins/Extensions/CineViewMLA/plugin.pyc" 2>/dev/null && ok "CineView Designs available in the Plugin Browser" || fail "CineView Designs entry not found."

section "Result"
SKIN=$(sed -n 's/^config.skin.primary_skin=//p' /etc/enigma2/settings 2>/dev/null)
if [ "$MODE" = "same" ]; then
	# nothing was installed: no restart
	printf '  %s%sCineView MLA %s is already installed and verified.%s\n\n' "$B" "$G" "$VERSION" "$N"
	exit 0
fi
printf '  %s%sCineView MLA %s installed successfully.%s\n' "$B" "$G" "$VERSION" "$N"
case "$SKIN" in
	$SKIN_NAME/*) ACTIVE=1 ;;
	*) ACTIVE=0
		printf '\n  %sNext step:%s Menu > Setup > User Interface > Skin > %s%s%s\n' "$C" "$N" "$B" "$SKIN_NAME" "$N"
		info "Then open CineView Designs from the Plugin Browser to choose designs and themes." ;;
esac
# Automatic GUI restart (Enigma2 only, never a reboot of the receiver): reached only after the package was installed
# AND every check of the "Verification" section passed (each failure exits before this point).  Not while recording.
gui_pid() { pidof enigma2 2>/dev/null | awk '{print $1}'; }
recording() { wget -qO - "http://127.0.0.1/api/statusinfo" 2>/dev/null | grep -q '"isRecording": "true"'; }
timer_soon() {  # a timer that starts within 10 minutes (or is running)
	wget -qO - "http://127.0.0.1/api/timerlist" 2>/dev/null | python3 -c '
import json, sys, time
try:
    t = json.load(sys.stdin).get("timers", [])
except Exception:
    sys.exit(1)
now = time.time()
sys.exit(0 if any(x.get("state", 0) in (1, 2) or (x.get("state", 0) == 0 and not x.get("disabled") and 0 <= x.get("begin", 0) - now < 600) for x in t) else 1)'
}
if [ "${RESTART:-1}" = "0" ]; then
	info "RESTART=0: the GUI is not restarted (Menu > Standby / Restart > Restart GUI)"
elif [ "$ACTIVE" = "0" ]; then
	info "The GUI is not restarted: CineView MLA is not the active skin (it loads when you select it)"
elif [ -z "$(gui_pid)" ]; then
	info "The GUI is not running - CineView MLA is loaded when it starts"
elif recording || timer_soon; then
	warn "A recording is running or a timer starts within 10 minutes - the GUI is not restarted now. Restart it later (Menu > Standby / Restart > Restart GUI)."
else
	printf '\n  %s%sThe GUI restarts automatically now to load CineView MLA %s ...%s\n' "$B" "$C" "$VERSION" "$N"
	OLD=$(gui_pid); NEW=""
	CRASH0=$(ls -t /home/root/logs/*crash*.log 2>/dev/null | head -n 1)
	sleep 2
	# 1) the image's own clean restart through its web interface (OpenWebif / its API: settings are saved first)
	if [ "${CVMLA_RESTART_METHOD:-auto}" != "init" ]; then  # CVMLA_RESTART_METHOD: test hook only
		wget -qO /dev/null "http://127.0.0.1/api/powerstate?newstate=3" 2>/dev/null
		for i in $(seq 1 45); do sleep 1; NEW=$(gui_pid); [ -n "$NEW" ] && [ "$NEW" != "$OLD" ] && break; done
	fi
	# 2) not restarted (web interface missing, protected or busy): the init system's own GUI stop / start - the
	#    method every OE-Alliance image (OpenATV, OpenBH, OpenViX) supports; Enigma2 saves its settings on stop
	if [ -z "$NEW" ] || [ "$NEW" = "$OLD" ]; then
		init 4 2>/dev/null
		for i in $(seq 1 30); do pidof enigma2 >/dev/null 2>&1 || break; sleep 1; done
		init 3 2>/dev/null
		for i in $(seq 1 40); do sleep 1; NEW=$(gui_pid); [ -n "$NEW" ] && [ "$NEW" != "$OLD" ] && break; done
	fi
	if [ -n "$NEW" ] && [ "$NEW" != "$OLD" ]; then
		ok "GUI restarted - checking that CineView MLA $VERSION starts cleanly ..."
		ACTOK=0; P2=""
		for i in $(seq 1 24); do  # up to 2 minutes: Enigma2 runs and its web interface answers
			sleep 5; P2=$(gui_pid)
			[ -n "$P2" ] && wget -qO /dev/null "http://127.0.0.1/api/statusinfo" 2>/dev/null && { ACTOK=1; break; }
		done
		if [ "$ACTOK" = "1" ]; then sleep 20; [ "$(gui_pid)" = "$P2" ] || ACTOK=0; fi  # still the same process: no crash loop
		CRASH1=$(ls -t /home/root/logs/*crash*.log 2>/dev/null | head -n 1)
		[ "$CRASH1" != "$CRASH0" ] && ACTOK=0
		if [ "$ACTOK" = "1" ]; then
			ok "CineView MLA $VERSION is running (GUI stable, no new crash log)"
		elif [ "$ACTIVE" = "1" ]; then
			warn "The GUI did not start cleanly with CineView MLA $VERSION${CRASH1:+ (crash log: $CRASH1)}"
			recover "the GUI did not start cleanly"
			if [ "${RECOVERED:-0}" = "1" ]; then
				P4=$(gui_pid)
				wget -qO /dev/null "http://127.0.0.1/api/powerstate?newstate=3" 2>/dev/null || { init 4; sleep 5; init 3; }
				P5=""; for i in $(seq 1 60); do sleep 1; P5=$(gui_pid); [ -n "$P5" ] && [ "$P5" != "$P4" ] && break; done
				if [ -n "$P5" ] && [ "$P5" != "$P4" ]; then ok "GUI restarted with CineView MLA $PREV_VERSION"
				else warn "Please restart the GUI: Menu > Standby / Restart > Restart GUI"; fi
			fi
			printf '\n'; exit 1
		else
			warn "The GUI did not start cleanly${CRASH1:+ (crash log: $CRASH1)} - CineView MLA is not the active skin, so it is not the cause"
		fi
	else
		warn "The GUI could not be restarted automatically. Please restart it: Menu > Standby / Restart > Restart GUI"
	fi
fi
printf '\n'
exit 0
