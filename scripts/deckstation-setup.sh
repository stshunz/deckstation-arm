#!/bin/bash
# deckstation-setup.sh
# Descarga e instala emuladores para DeckStation ARM
# Uso: deckstation-setup [--force]

set -euo pipefail

# ============================================================================
# Configuración
# ============================================================================

# Detectar directorio raíz de DeckStation
DECKSTATION_ROOT="${DECKSTATION_ROOT:-/opt/deckstation}"
SCRIPTS_DIR="${DECKSTATION_ROOT}/scripts"
LOG_DIR="${DECKSTATION_ROOT}/logs"
APPS_DIR="${DECKSTATION_ROOT}/Apps"
CONFIGS_DIR="${DECKSTATION_ROOT}/configs"

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Flags
FORCE_DOWNLOAD=false

# ============================================================================
# Funciones auxiliares
# ============================================================================

log() {
    local msg="[$(date '+%Y-%m-%d %H:%M:%S')] $1"
    echo -e "${BLUE}${msg}${NC}"
    echo "$msg" >> "${LOG_DIR}/setup.log" 2>/dev/null || true
}

log_ok() {
    local msg="[$(date '+%Y-%m-%d %H:%M:%S')] [OK] $1"
    echo -e "${GREEN}${msg}${NC}"
    echo "$msg" >> "${LOG_DIR}/setup.log" 2>/dev/null || true
}

log_warn() {
    local msg="[$(date '+%Y-%m-%d %H:%M:%S')] [WARN] $1"
    echo -e "${YELLOW}${msg}${NC}"
    echo "$msg" >> "${LOG_DIR}/setup.log" 2>/dev/null || true
}

log_error() {
    local msg="[$(date '+%Y-%m-%d %H:%M:%S')] [ERROR] $1"
    echo -e "${RED}${msg}${NC}"
    echo "$msg" >> "${LOG_DIR}/setup.log" 2>/dev/null || true
}

check_dependencies() {
    log "Verificando dependencias..."

    local missing=()

    for cmd in python3 curl wget tar; do
        if ! command -v "$cmd" &>/dev/null; then
            missing+=("$cmd")
        fi
    done

    if [[ ${#missing[@]} -gt 0 ]]; then
        log_warn "Faltan dependencias: ${missing[*]}"
        log "Intentando instalar con pacman..."

        if command -v pacman &>/dev/null; then
            sudo pacman -S --needed --noconfirm "${missing[@]}" || {
                log_error "No se pudieron instalar las dependencias"
                log "Instala manualmente: ${missing[*]}"
                return 1
            }
        else
            log_error "No se encontró pacman. Instala manualmente: ${missing[*]}"
            return 1
        fi
    fi

    log_ok "Dependencias verificadas"
}

ensure_directories() {
    log "Creando estructura de directorios..."

    local dirs=(
        "${APPS_DIR}"
        "${LOG_DIR}"
        "${DECKSTATION_ROOT}/saves"
        "${DECKSTATION_ROOT}/settings"
        "${DECKSTATION_ROOT}/Media"
    )

    for dir in "${dirs[@]}"; do
        mkdir -p "$dir"
    done

    log_ok "Directorios creados"
}

download_emulator() {
    local name="$1"
    local url="$2"
    local dest="$3"

    if [[ -f "$dest" ]] && [[ "$FORCE_DOWNLOAD" != true ]]; then
        log_ok "${name} ya existe, omitiendo"
        return 0
    fi

    log "Descargando ${name}..."

    if curl -L --progress-bar -o "${dest}.tmp" "$url"; then
        mv "${dest}.tmp" "$dest"
        chmod +x "$dest"
        log_ok "${name} descargado correctamente"
        return 0
    else
        rm -f "${dest}.tmp"
        log_error "Error descargando ${name}"
        return 1
    fi
}

# ============================================================================
# Setup de emuladores
# ============================================================================

setup_retroarch() {
    local retroarch_dir="${APPS_DIR}/retroarch"
    local retroarch_bin="${retroarch_dir}/retroarch"

    if [[ -f "$retroarch_bin" ]] && [[ "$FORCE_DOWNLOAD" != true ]]; then
        log_ok "RetroArch ya instalado"
        return 0
    fi

    mkdir -p "$retroarch_dir"

    # Detectar arquitectura
    local arch
    arch=$(uname -m)

    # URL de RetroArch para ARM
    local base_url="https://buildbot.libretro.com/stable"
    local retroarch_url=""

    case "$arch" in
        aarch64)
            retroarch_url="${base_url}/1.19.1/android/arm64-v8a/RetroArch_ra32.apk"
            ;;
        armv7l|armhf)
            retroarch_url="${base_url}/1.19.1/android/armeabi-v7a/RetroArch_ra32.apk"
            ;;
        *)
            log_warn "Arquitectura ${arch} no soportada directamente"
            log_warn "Intentando con paquete del sistema..."
            if command -v pacman &>/dev/null; then
                sudo pacman -S --needed --noconfirm retroarch
                return $?
            fi
            return 1
            ;;
    esac

    if [[ -n "$retroarch_url" ]]; then
        log "Descargando RetroArch para ${arch}..."
        curl -L --progress-bar -o "${retroarch_dir}/retroarch.apk" "$retroarch_url"

        # El APK es un ZIP, extraer
        if command -v unzip &>/dev/null; then
            unzip -q -o "${retroarch_dir}/retroarch.apk" -d "${retroarch_dir}/"
            # Buscar el binario
            find "${retroarch_dir}" -name "retroarch" -type f -exec chmod +x {} \;
        fi

        log_ok "RetroArch instalado"
    fi
}

setup_pcsx2() {
    log "Verificando AetherSX2/PCSX2..."

    local pcsx2_dir="${APPS_DIR}/pcsx2"
    mkdir -p "$pcsx2_dir"

    # Nota: AetherSX2 no tiene builds oficiales para Linux ARM
    # Se puede compilar desde fuente o usar versiones alternativas
    log_warn "AetherSX2/PCSX2 requiere compilación manual para ARM"
    log "Ver docs/INSTALACION.md para instrucciones"
}

setup_dolphin() {
    log "Verificando Dolphin..."

    local dolphin_dir="${APPS_DIR}/dolphin"
    mkdir -p "$dolphin_dir"

    if command -v dolphin-emu &>/dev/null; then
        ln -sf "$(which dolphin-emu)" "${dolphin_dir}/dolphin-emu"
        log_ok "Dolphin encontrado en el sistema"
        return 0
    fi

    if command -v pacman &>/dev/null; then
        log "Dolphin no encontrado. Instalar con:"
        echo "  sudo pacman -S dolphin-emu"
    fi
}

setup_extra_cores() {
    local cores_dir="${APPS_DIR}/retroarch/cores"

    if [[ -d "$cores_dir" ]] && [[ "$(ls -A "$cores_dir" 2>/dev/null)" ]]; then
        log_ok "Cores de RetroArch ya instalados"
        return 0
    fi

    mkdir -p "$cores_dir"

    log "Descargando cores adicionales de RetroArch..."
    log_warn "Los cores se descargarán al lanzar RetroArch por primera vez"
}

# Despliega el wrapper portable lanzar.sh a cada carpeta de emulador que contenga
# un AppImage. ES-DE (es_find_rules.xml) apunta a ./Apps/*/lanzar.sh en vez del
# AppImage directo, así que el wrapper debe existir para que el lanzamiento sea
# portable (HOME redirigido al .home, SDL fijado al compositor).
deploy_lanzar_sh() {
    local lanzar_src="${SCRIPTS_DIR}/lanzar.sh"
    local app_dir found

    [ -f "${lanzar_src}" ] || {
        log_warn "Plantilla lanzar.sh no encontrada (${lanzar_src}); se omite"
        return 0
    }

    log "Desplegando lanzar.sh a los emuladores..."
    for app_dir in "${APPS_DIR}"/*/; do
        [ -d "${app_dir}" ] || continue
        found="$(find "${app_dir}" -maxdepth 1 \( -iname "*.AppImage" -o -iname "*.appimage" \) 2>/dev/null | head -1)"
        [ -n "${found}" ] || continue
        install -m755 "${lanzar_src}" "${app_dir}lanzar.sh" 2>/dev/null \
            && log_ok "lanzar.sh -> $(basename "${app_dir}")" || true
    done
}

# ============================================================================
# Main
# ============================================================================

main() {
    echo ""
    echo "=========================================="
    echo "  DeckStation - Setup"
    echo "=========================================="
    echo ""

    # Parsear argumentos
    while [[ $# -gt 0 ]]; do
        case $1 in
            --force)
                FORCE_DOWNLOAD=true
                shift
                ;;
            --help|-h)
                echo "Uso: deckstation-setup [--force]"
                echo ""
                echo "Opciones:"
                echo "  --force   Forzar re-descarga de emuladores"
                echo "  --help    Mostrar esta ayuda"
                exit 0
                ;;
            *)
                log_error "Opción desconocida: $1"
                exit 1
                ;;
        esac
    done

    # Crear directorios
    ensure_directories

    # Verificar dependencias
    check_dependencies || exit 1

    # Setup de cada emulador
    echo ""
    log "Iniciando setup de emuladores..."
    echo ""

    setup_retroarch
    setup_pcsx2
    setup_dolphin
    setup_extra_cores
    deploy_lanzar_sh

    # Configs base (ES-DE, RetroArch, DuckStation, ...): la configuracion
    # "de fabrica" de DeckStation, para que una instalacion nueva quede
    # reproducible. No destructivo: solo rellena lo que falte.
    echo ""
    if [ -x "${SCRIPTS_DIR}/deckstation-configs.sh" ]; then
        log "Desplegando configs base de DeckStation..."
        "${SCRIPTS_DIR}/deckstation-configs.sh" || log_warn "Fallo al desplegar los configs base"
    else
        log_warn "No encuentro ${SCRIPTS_DIR}/deckstation-configs.sh; se omiten los configs base"
    fi

    # Resumen
    echo ""
    echo "=========================================="
    echo "  Setup completado!"
    echo "=========================================="
    echo ""
    echo "Emuladores instalados en: ${APPS_DIR}"
    echo "Logs en: ${LOG_DIR}/setup.log"
    echo ""
    echo "Para lanzar:"
    echo "  deckstation"
    echo ""
}

# Ejecutar
main "$@"
