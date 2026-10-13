#!/usr/bin/env bash
# ==============================================================================
# Cyberpunk Scarlet Protocol Rice - Installer
# Author: AkumaRyujin
# Target: Arch Linux / Omarchy / Hyprland
# ==============================================================================

set -euo pipefail

# ANSI color codes
CYAN='\033[38;2;0;240;255m'
SCARLET='\033[38;2;255;42;109m'
WHITE='\033[38;2;255;255;255m'
GREEN='\033[38;2;0;255;128m'
YELLOW='\033[38;2;255;215;0m'
NC='\033[0m' # No Color
BOLD='\033[1m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
BACKUP_DIR="${HOME}/.config/rice_backups_${TIMESTAMP}"

DO_BACKUP=true
DO_DRY_RUN=false
DO_RELOAD=true

print_banner() {
    cat << "EOF"
  ____                 _      _     ____            _                  _ 
 / ___|  ___ __ _ _ __| | ___| |_  |  _ \ _ __ ___ | |_ ___   ___ ___ | |
 \___ \ / __/ _` | '__| |/ _ \ __| | |_) | '__/ _ \| __/ _ \ / __/ _ \| |
  ___) | (_| (_| | |  | |  __/ |_  |  __/| | | (_) | || (_) | (_| (_) | |
 |____/ \___\__,_|_|  |_|\___|\__| |_|   |_|  \___/ \__\___/ \___\___/|_|
                   CYBERPUNK SCARLET PROTOCOL RICE
EOF
}

log_info() {
    echo -e "${CYAN}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[OK]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${SCARLET}[ERROR]${NC} $1" >&2
}

show_help() {
    cat << EOF
Uso: ./install.sh [OPCIONES]

Opciones:
  -n, --dry-run      Muestra las acciones que se realizarían sin modificar ningún archivo.
  --no-backup        Omite la creación de copias de seguridad de las configuraciones existentes.
  --no-reload        No recarga Hyprland ni Quickshell al finalizar la instalación.
  -h, --help         Muestra este mensaje de ayuda.

EOF
}

# Procesar argumentos
while [[ $# -gt 0 ]]; do
    case "$1" in
        -n|--dry-run)
            DO_DRY_RUN=true
            shift
            ;;
        --no-backup)
            DO_BACKUP=false
            shift
            ;;
        --no-reload)
            DO_RELOAD=false
            shift
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            log_error "Opción desconocida: $1"
            show_help
            exit 1
            ;;
    esac
done

echo -e "${SCARLET}"
print_banner
echo -e "${NC}"

log_info "Iniciando instalación del tema Cyberpunk Scarlet Protocol..."

# 1. Comprobar dependencias recomendadas
log_info "Verificando entorno y dependencias..."
for cmd in hyprland quickshell; do
    if command -v "$cmd" >/dev/null 2>&1; then
        log_success "Encontrado: $cmd"
    else
        log_warn "Comando no encontrado en PATH: $cmd (Asegúrate de tenerlo instalado)"
    fi
done

# 2. Respaldos
if [ "$DO_BACKUP" = true ]; then
    log_info "Creando copias de seguridad en: ${BACKUP_DIR}"
    if [ "$DO_DRY_RUN" = false ]; then
        mkdir -p "${BACKUP_DIR}"
        for dir in hypr omarchy alacritty kitty; do
            if [ -d "${HOME}/.config/${dir}" ]; then
                cp -rp "${HOME}/.config/${dir}" "${BACKUP_DIR}/${dir}"
                log_success "Respaldado ~/.config/${dir} -> ${BACKUP_DIR}/${dir}"
            fi
        done
    else
        log_info "[DRY-RUN] Se crearía respaldo en ${BACKUP_DIR}"
    fi
else
    log_warn "Omitiendo respaldos (--no-backup)"
fi

# 3. Instalación de configuraciones
install_configs() {
    log_info "Instalando configuraciones de Hyprland..."
    mkdir -p "${HOME}/.config/hypr"
    if [ "$DO_DRY_RUN" = false ]; then
        cp -rp "${SCRIPT_DIR}/config/hypr/"* "${HOME}/.config/hypr/"
        log_success "Archivos de Hyprland copiados."
    else
        log_info "[DRY-RUN] Se copiaría ${SCRIPT_DIR}/config/hypr/ a ~/.config/hypr/"
    fi

    log_info "Instalando configuraciones de Omarchy (Shell, Plugins y Tema)..."
    mkdir -p "${HOME}/.config/omarchy/plugins"
    mkdir -p "${HOME}/.config/omarchy/themes"
    mkdir -p "${HOME}/.config/omarchy/extensions"

    if [ "$DO_DRY_RUN" = false ]; then
        cp -p "${SCRIPT_DIR}/config/omarchy/shell.toml" "${HOME}/.config/omarchy/"
        cp -p "${SCRIPT_DIR}/config/omarchy/shell.json" "${HOME}/.config/omarchy/"
        
        if [ -f "${SCRIPT_DIR}/config/omarchy/extensions/omarchy-menu.jsonc" ]; then
            cp -p "${SCRIPT_DIR}/config/omarchy/extensions/omarchy-menu.jsonc" "${HOME}/.config/omarchy/extensions/"
        fi

        # Plugins personalizados
        cp -rp "${SCRIPT_DIR}/config/omarchy/plugins/"* "${HOME}/.config/omarchy/plugins/"

        # Tema Scarlet Protocol
        cp -rp "${SCRIPT_DIR}/config/omarchy/themes/scarletprotocol" "${HOME}/.config/omarchy/themes/"
        log_success "Configuraciones, plugins y tema de Omarchy instalados."
    else
        log_info "[DRY-RUN] Se copiarían configuraciones de Omarchy."
    fi

    # Terminales
    log_info "Instalando configuraciones de terminales (Alacritty / Kitty)..."
    if [ "$DO_DRY_RUN" = false ]; then
        mkdir -p "${HOME}/.config/alacritty" "${HOME}/.config/kitty"
        cp -p "${SCRIPT_DIR}/config/alacritty/alacritty.toml" "${HOME}/.config/alacritty/"
        cp -p "${SCRIPT_DIR}/config/kitty/kitty.conf" "${HOME}/.config/kitty/"
        log_success "Configuraciones de terminales instaladas."
    else
        log_info "[DRY-RUN] Se copiarían configuraciones de terminales."
    fi

    # Binarios y scripts
    if [ -d "${SCRIPT_DIR}/bin" ]; then
        log_info "Instalando scripts auxiliares en ~/.local/bin/..."
        if [ "$DO_DRY_RUN" = false ]; then
            mkdir -p "${HOME}/.local/bin"
            cp -rp "${SCRIPT_DIR}/bin/"* "${HOME}/.local/bin/"
            chmod +x "${HOME}/.local/bin/"audioviewer-* 2>/dev/null || true
            log_success "Scripts instalados en ~/.local/bin/."
        else
            log_info "[DRY-RUN] Se copiarían scripts a ~/.local/bin/"
        fi
    fi
}

install_configs

# 4. Aplicar tema y recargar entorno
if [ "$DO_RELOAD" = true ] && [ "$DO_DRY_RUN" = false ]; then
    log_info "Recargando configuraciones en tiempo real..."
    
    # Recargar Quickshell Omarchy si está en ejecución
    if command -v omarchy-shell >/dev/null 2>&1; then
        omarchy-shell shell reloadConfig >/dev/null 2>&1 || true
        log_success "Quickshell reloadConfig ejecutado."
    fi

    # Recargar Hyprland
    if command -v hyprctl >/dev/null 2>&1; then
        hyprctl reload >/dev/null 2>&1 || true
        log_success "Hyprland recargado."
    fi
fi

echo ""
echo -e "${GREEN}${BOLD}✔ ¡Instalación de Cyberpunk Scarlet Protocol completada con éxito!${NC}"
echo -e "${CYAN}Disfruta de tu rice: barra superior escarlata con píldoras cian, menú cyberpunk y bordes iluminados.${NC}"

