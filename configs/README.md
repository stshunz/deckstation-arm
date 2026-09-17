# Configs de emuladores — DeckStation ARM

Configuraciones personalizadas importadas desde el proyecto DeckStation ARM
(`/run/media/fransis/8TB/deckstation-arm/`) al repo portable deckstation-arm.

> **Esto es una COPIA DE REFERENCIA, no la configuración activa.** El setup
> (`deckstation-setup.sh`) **no despliega** esta carpeta: cada emulador usa la
> configuración de su propio `.AppImage.home` (semi-portable, dentro de DeckStation).
> Estas copias sirven para consultar cómo quedó cada config saneada y para restaurarla
> a mano si hace falta. Ver `CAMBIOS-REALIZADOS.md`.
>
> El despliegue real lo hace el **Updater**: descarga un `payload/` desde MediaFire
> (carpeta compartida `1ixylxeqkr0wo`) con los emuladores y sus `.AppImage.home` ya
> configurados, y lo aplica dejando registro en `update/.installed/`.

## Qué se copió y por qué

| Emulador | Archivo(s) | Origen | Notas |
|---|---|---|---|---|
| RetroArch | `retroarch/retroarch.cfg` | `.backup-configs-20260624_182554/retroarch.cfg.bak` | Config principal personalizada (116 KB). Sin paths hardcodeados. |
| RetroArch | `retroarch/autoconfig/` | `Apps/RetroArch/.../.config/retroarch/autoconfig/` | Configs de mandos (hid/, udev/, linuxraw/, parport/, sdl2/, x/ + 2 .cfg sueltos). 611 archivos. |
| ES-DE | `es-de/custom_systems/es_find_rules.xml` | `DeckStation.AppImage.home/ES-DE/custom_systems/` | Reglas de detección de emuladores. Rutas adaptadas a ARM (`./Apps/...`). |
| ES-DE | `es-de/custom_systems/es_systems.xml` | `DeckStation.AppImage.home/ES-DE/custom_systems/` | Definición de sistemas (171 KB). Paths de ROMs convertidos a `%ROMPATH%`. |
| ES-DE | `es-de/settings/es_settings.xml` | `DeckStation.AppImage.home/ES-DE/settings/` | Configuración de ES-DE (8 KB). Sin paths hardcodeados. |
| DuckStation | `duckstation/settings.ini` | `Apps/Duckstation/.../.local/share/duckstation/settings.ini` | Config personalizada (idioma es-ES, fullscreen, etc.). |
| DuckStation | `duckstation/duckstation.ini` | `.backup-configs-20260624_182554/duckstation.ini.bak` | Backup de configuración. |
| DuckStation | `duckstation/qt.conf` | `Apps/Duckstation/qt.conf` | Plugins relativos (`./QtPlugins`), portable. |
| Azahar | `azahar/qt-config.ini` | `.backup-configs-20260624_182554/azahar-qt-config.ini.bak` | Paths nand/sdmc/screenshots convertidos a relativos. |
| Citron | `citron/qt-config.ini` | `.backup-configs-20260624_182554/citron-qt-config.ini.bak` | Paths nand/sdmc/load/dump/tas relativos; paths de ROMs eliminados. |
| Citron | `citron/custom/*.ini` | `Apps/Citron/.../.config/citron/custom/` | Configs por juego (10 títulos). |
| Dolphin | `dolphin/dolphin.ini` | `.backup-configs-20260624_182554/dolphin.ini.bak` | Eliminado `ISOPath1` (apuntaba a ROMs del usuario). |
| PCSX2 | `pcsx2/pcsx2.ini` | `.backup-configs-20260624_182554/pcsx2.ini.bak` | Eliminado `RecursivePaths` (apuntaba a ROMs del usuario). |
| PPSSPP | `ppsspp/ppsspp.ini` | `.backup-configs-20260624_182554/ppsspp.ini.bak` | `CurrentDirectory` convertido a relativo (`./`). |
| Flycast | `flycast/emu.cfg` | `Apps/Flycast/.../.config/flycast/emu.cfg` | Config limpia, sin paths hardcodeados. |
| DOSBox Pure | `dosboxpure/DOSBoxPure.cfg` | `Apps/DosBoxPure/.../.config/DOSBoxPure/DOSBoxPure.cfg` | `interface_contentpath` → `./ROMs/dos`. |
| RMG | `rmg/mupen64plus.cfg` | `Apps/RMG/.../.config/RMG/mupen64plus.cfg` | Config limpia. |
| ZSNES | `zsnes/*.cfg` | `Apps/ZSNES/.../.config/zsnes/` | Configs de input y video (zmovie, zinput, zsnesl). |
| Supermodel | `supermodel/Supermodel.ini` | `Apps/Supermodel/.../.config/supermodel/Config/Supermodel.ini` | Config limpia. |
| AntiMicroX | `antimicrox/antimicrox_settings.ini` | `Apps/Antimicrox/.../.config/antimicrox/` | Paths de perfiles convertidos a relativos. |
| Vita3K | `vita3k/*.xml` | `Apps/Vita3K/.../.config/Vita3K/config/` | Configs por juego (3 títulos). |

## Qué NO se copió (y por qué)

- **AppImages** — binarios grandes que se descargan con `setup_arm64_apps.py`.
- **ROMs / saves / memcards / savestates** — contenido del usuario, privado.
- **Caches** (shader cache, mesa) — se regeneran en runtime.
- **`QtProject.conf`** de DuckStation/Azahar — solo estado de UI con paths
  hardcodeados del sistema original.
- **`es_find_rules.xml` / `es_systems.xml` del proyecto ARM** — no existen en
  `deckstation-arm/` (búsqueda exhaustiva). Se importaron los del PC original
  (ROMS16TB) y se adaptaron las rutas de emuladores a ARM.

## Nota sobre `configs/es-de-home/`

Este directorio está reservado para el home portable de ES-DE (`.emulationstation/`
o similar). Los configs de ES-DE importados viven en `configs/es-de/`
(`custom_systems/` y `settings/`), con rutas relativas (`./Apps/...` y
`%ROMPATH%/...`).