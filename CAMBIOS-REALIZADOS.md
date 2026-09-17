# Cambios realizados en DeckStation ARM

Registro de los cambios de **portabilidad y saneado** hechos sobre la configuración
original, para que el proyecto funcione desde cualquier ruta y en cualquier
dispositivo ARM. Equivale al `.CAMBIOS_REALIZADOS.md` de la versión x86_64.

**Regla de oro**: nada de rutas absolutas. Todo lo que se pueda, relativo a la raíz
de DeckStation (`./Apps/...`) o al propio directorio de configuración (`../...`).

---

## 1. Saneado de rutas en las configuraciones

Muchas configs venían con rutas del equipo donde se configuraron por primera vez
(`/home/deck/...`, `/run/media/...`, `C:/users/...`). Se han convertido a relativas
o se han eliminado. El detalle fichero a fichero está en **`configs/README.md`**.

> **IMPORTANTE — qué es `configs/` y qué no**
> `configs/` es una **copia de referencia** (un snapshot versionado) de las configuraciones
> que se dejaron saneadas. **NO se despliega automáticamente**: el setup
> (`deckstation-setup.sh`) solo despliega los wrappers `lanzar.sh`
> (`deploy_lanzar_sh`); no hay ninguna función que copie `configs/` a los
> `.AppImage.home`. Cada emulador usa la configuración que tiene en su propio
> `.AppImage.home` (semi-portable: vive dentro de DeckStation, no en el `$HOME`).
>
> Sirve por tanto para **consultar y restaurar**: si un emulador queda mal
> configurado, aquí está la versión conocida-buena. Para aplicarla hay que copiarla a
> mano a su `.AppImage.home`.
>
> **Cómo se despliega de verdad**: el **Updater** (`Apps/Updater/`) tiene un
> auto-actualizador de DeckStation que descarga un `payload/` desde una carpeta de
> **MediaFire** (`update/`, con `.installed/` como registro de lo ya aplicado). Ese
> payload trae los emuladores **con sus `.AppImage.home` ya configurados** — es el
> mecanismo real de distribución de configuraciones, no `configs/`.
> `update_dir = <raíz DeckStation>/update`.

| Emulador | Fichero | Qué se cambió |
|---|---|---|
| **PPSSPP** | `ppsspp/ppsspp.ini` | `CurrentDirectory` → `./` (antes absoluta al equipo del autor) |
| **Citron** | `citron/qt-config.ini` | `nand_directory`, `sdmc_directory`, `load_directory`, `dump_directory`, `tas_directory` → relativas (`../../.local/share/citron/...`). Paths de ROMs del usuario eliminados. |
| **Azahar** | `azahar/qt-config.ini` | `nand_directory`, `sdmc_directory`, `screenshots` → relativas (`../../.local/share/azahar-emu/...`) |
| **Dolphin** | `dolphin/dolphin.ini` | Eliminado `ISOPath1` (apuntaba a ROMs del usuario). Eliminados los restos de la versión **Windows**: `BIOS` y `SavesPath` (`C:/users/steamuser/AppData/...`) vaciados y `ISOPath0 = H:/Downloads/Triforce` borrado (`ISOPaths` 2 → 1). |
| **PCSX2** | `pcsx2/pcsx2.ini` | Eliminado `RecursivePaths` (ROMs del usuario). `Textures` → `../textures` (relativa al directorio del config; antes era relativa al directorio de trabajo, que es frágil) |
| **DOSBox Pure** | `dosboxpure/DOSBoxPure.cfg` | `interface_contentpath` → `./ROMs/dos` |
| **AntiMicroX** | `antimicrox/antimicrox_settings.ini` | Paths de perfiles → relativos |
| **DuckStation** | `duckstation/qt.conf` | Plugins relativos (`./QtPlugins`) |
| **RetroArch** | `retroarch/retroarch.cfg` | `savefile_directory`, `savestate_directory`, `screenshot_directory`, `log_dir` → `~/.config/retroarch/...`. `core_updater_buildbot_cores_url` apuntando al buildbot **aarch64**. |
| **ES-DE** | `es-de/settings/es_settings.xml` | Sin paths hardcodeados |
| **ES-DE (systems)** | `es-de/custom_systems/es_find_rules.xml` | Apunta a los wrappers `./Apps/*/lanzar.sh` y a las rutas de cores dentro de los `.AppImage.home` |
| **Flycast** | `flycast/emu.cfg` | Ya era limpia |
| **RMG** | `rmg/mupen64plus.cfg` | Rutas `./Apps/RMG/...` (relativas a la raíz, funcionan con el `lanzar.sh`) |
| **Vita3K, ZSNES, Supermodel** | — | Sin rutas problemáticas |

**Comprobación**: `grep -rnE "[A-Za-z]:[/\\\\]|AppData|steamuser" configs/` no debe
devolver nada (salvo URLs `http://`).

---

## 2. Wrappers `lanzar.sh` por emulador

Cada emulador tiene su `Apps/<Emulador>/lanzar.sh` que:

- Limpia las variables del AppImage (`APPIMAGE`, `APPDIR`, `OWD`).
- Redirige `HOME` al `.AppImage.home` del emulador, de forma que sus configs, saves
  y logs quedan **dentro de DeckStation** y no en el `$HOME` del usuario.
- Fuerza `SDL_VIDEODRIVER` para que funcione bajo gamescope/Game Mode.

Así los emuladores son portables: mover la carpeta de DeckStation a otro dispositivo
no rompe nada. **No hay que tocar los `lanzar.sh` para arreglar rutas**: eso se hace
en las configs del punto 1.

---

## 3. Centralización de saves y logs

`scripts/deckstation-launcher.sh` crea en cada arranque la estructura centralizada y
los symlinks de compatibilidad:

```
saves/                       logs/
├── retroarch/               ├── retroarch/
│   ├── saves/               └── pcsx2/
│   ├── states/
│   └── screenshots/
├── duckstation/
│   ├── savestates/
│   ├── screenshots/
│   └── memcards/
└── pcsx2/
    ├── memcards/
    ├── sstates/
    └── snaps/
```

En la raíz se crean los symlinks `Logs → logs` y `Saves → saves`, porque algunos
emuladores escriben en el directorio de trabajo. Dentro de cada `.AppImage.home` se
redirigen los directorios reales a estos centralizados.

**Motivo**: hacer copia de seguridad de las partidas es copiar una sola carpeta.

---

## 4. Lanzador portable

- **`DeckStation.sh`** (x86_64) / **`scripts/deckstation-launcher.sh`** (ARM): calculan
  la raíz de DeckStation dinámicamente, así que funcionan desde cualquier ubicación.
  No hay que ejecutar el AppImage directamente.
- **`/usr/bin/deckstation`**: comando del sistema que llama al lanzador.

---

## 5. Updater (actualizador de AppImages)

Portado a aarch64 desde la versión x86_64. Vive en `updater/` y se instala en
`/opt/deckstation/Apps/Updater/`. Detalle completo en **`updater/README.md`**.

- `updater.py`: lee `updater/git.txt`, consulta los releases (GitHub/GitLab/Gitea),
  con caché de 30 min, escáner en segundo plano, temas y backup antes de actualizar.
- **Detección de arquitectura en runtime**: el mismo código sirve en aarch64 y x86_64.
  La elección de asset premia la arquitectura propia y **descarta** la contraria y los
  binarios de macOS/Windows.
- `git.txt`: fuentes **aarch64** (17 emuladores con build Linux ARM). Los que solo
  publican x86_64 quedan comentados y listos para activar.
- `launcher.sh`: usa el Python del sistema, no un Python portable descargado.

---

## 6. Notas para el creador

- Los ficheros modificados de cada emulador tienen su backup en
  `.backup-configs-20260624_182554/` (en la instalación de origen).
- **No se han tocado** los emuladores que ya usaban rutas relativas correctamente.
- El saneado se hace **solo en los ficheros de configuración**, nunca en los binarios
  ni en los AppImage.
- Para añadir un emulador nuevo: crear su `lanzar.sh`, su config saneada en `configs/`
  y documentarlo en `configs/README.md`.
- **Pendiente/decidir**: `configs/` es hoy solo referencia. Opciones: (a) dejarlo como
  snapshot documentado, (b) hacer que el setup lo despliegue de verdad (copiar cada
  config a su `.AppImage.home` tras descargar el emulador), o (c) eliminarlo si se
  considera ruido. Además, `deckstation-setup.sh` declara `CONFIGS_DIR` y **no lo usa**
  (variable muerta): limpiar si se opta por (a) o (c).
