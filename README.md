# DeckStation ARM

**Sistema de emulación portable para arquitectura ARM (aarch64/armv7h)**

> **DeckStation** es un proyecto independiente de emulación portable.
> Creado por **stshunz** — https://github.com/stshunz
> Esta es la adaptación para arquitecturas ARM.

---

## Documentación

- **`CAMBIOS-REALIZADOS.md`** — registro de los cambios de portabilidad y saneado
  (rutas, saves/logs centralizados, Updater). Equivale al `.CAMBIOS_REALIZADOS.md`
  de la versión x86_64.
- **`configs/README.md`** — detalle fichero a fichero de cada configuración saneada.
- **`updater/README.md`** — el actualizador de AppImages.
- **`docs/INSTALACION.md`** — instalación.

---

## ¿Qué es?

DeckStation ARM es un sistema de emulación portable que transforma cualquier
dispositivo **ARM64** (AYN Odin 3, Raspberry Pi, tablets, etc.) en una consola de
emulación completa. Está inspirado en Steam Deck y DeckStation, pero diseñado para
funcionar en hardware ARM.

Es un proyecto **independiente de cualquier sistema operativo**: no depende de
ninguna distribución concreta y todo queda autocontenido en su propia carpeta.

## Filosofía

- **Todo autocontenido**: Todo vive dentro de `/opt/deckstation/`
- **Nada en el sistema host**: No toca `/home/`, `/etc/` ni configs del usuario
- **Portable**: Mover el directorio funciona en otro dispositivo
- **Sin dependencias del sistema**: Se auto-descarga todo lo necesario
- **Modular**: Cada emulador es independiente

## Arquitecturas

| Arquitectura | Estado |
|---|---|
| **aarch64 (ARM64)** | ✅ Este repo — adaptación ARM |
| **armv7h (ARM32)** | ⚠️ Parcial (depende del emulador) |
| **x86_64** | ❌ Ver repo `deckstation-x86_64` (proyecto original) |

## Estructura del repo

```
deckstation-arm/
├── README.md
├── .gitignore
├── PKGBUILD                       # Paquete Arch (aarch64/armv7h)
├── deckstation-arm.install        # Hooks de instalación
├── scripts/
│   ├── deckstation-setup.sh       # Prepara el entorno (assets, cores, configs, BIOS) + abre el Updater
│   ├── deckstation-launcher.sh    # Launcher portable (fija SDL_VIDEODRIVER)
│   ├── deckstation-update.sh      # Actualizador
│   ├── deckstation-configs.sh     # Despliega la config base en cada emulador
│   ├── deckstation-bios.sh        # Reparte las BIOS del usuario
│   ├── deckstation-cores.sh       # Enlaza los cores del sistema a la carpeta portable
│   └── lanzar.sh                  # Wrapper portable por emulador
├── overlay/
│   └── usr/bin/deckstation        # Comando del sistema
├── configs/                       # Configs portable de emuladores (ver configs/README.md)
│   ├── retroarch/                 #   + autoconfig (610 configs de mandos)
│   ├── es-de/                     #   ES-DE: es_find_rules.xml, es_systems.xml, es_settings.xml
│   ├── duckstation/  azahar/  citron/  dolphin/
│   ├── pcsx2/  ppsspp/  flycast/  dosboxpure/
│   ├── rmg/  zsnes/  supermodel/  antimicrox/  vita3k/
│   └── es-de-home/
└── docs/
    └── INSTALACION.md
```

## Estructura en ejecución (`/opt/deckstation/`)

```
/opt/deckstation/
├── DeckStation.AppImage        # La AppImage principal (ES-DE)
├── DeckStation.sh              # Script de lanzamiento
├── Apps/                       # Emuladores descargados (ARM64)
├── saves/                      # Saves del usuario
├── logs/                       # Logs de ejecución
├── Media/                      # Assets multimedia
├── settings/                   # Configuraciones
├── scripts/                    # Scripts de gestión
└── configs/                    # Configs del sistema
```

## Cómo funciona

1. **Instalación**: El paquete Arch instala la estructura base
2. **Setup**: `deckstation-setup` descarga los emuladores ARM64 necesarios
3. **Uso**: `deckstation` lanza el sistema completo
4. **Actualización**: `deckstation-update` actualiza todo

## Instalación

### Arch Linux ARM
```bash
# Compilar e instalar
makepkg -si

# O instalar desde pre-compilado
sudo pacman -U deckstation-arm-*.pkg.tar.zst
```

### Post-instalación
```bash
# Descargar emuladores ARM64
deckstation-setup

# Lanzar
deckstation
```

## Actualización
```bash
deckstation-update
```

## Licencia

GPL v2+

## Créditos

- **stshunz** — creador original de DeckStation (https://github.com/stshunz)
- **DeckStation ARM** — adaptación para arquitecturas ARM
- **Emuladores**: RetroArch, Dolphin, DuckStation, PPSSPP, etc. (versiones ARM64)
