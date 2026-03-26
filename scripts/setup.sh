#!/bin/bash
# ══════════════════════════════════════════════════════════════════
# setup.sh — Instalación automatizada del Homelab
# Ejecutar como root: bash setup.sh [principal|secundario]
# ══════════════════════════════════════════════════════════════════

set -e

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; NC='\033[0m'; BOLD='\033[1m'

log()  { echo -e "${GREEN}[✓]${NC} $1"; }
warn() { echo -e "${YELLOW}[!]${NC} $1"; }
err()  { echo -e "${RED}[✗]${NC} $1"; exit 1; }
info() { echo -e "${BLUE}[i]${NC} $1"; }

ROLE=${1:-"principal"}

echo -e "${BOLD}"
echo "╔══════════════════════════════════════════════════════════╗"
echo "║         🏠 HOMELAB DUAL — Setup automatizado             ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo -e "${NC}"
echo "Rol seleccionado: ${BOLD}$ROLE${NC}"
echo ""

# ── Verificar root ───────────────────────────────────────────────
[[ $EUID -ne 0 ]] && err "Ejecutar como root: sudo bash setup.sh $ROLE"

# ── Actualizar sistema ───────────────────────────────────────────
info "Actualizando el sistema..."
apt update -qq && apt upgrade -y -qq
log "Sistema actualizado"

# ── Instalar dependencias básicas ────────────────────────────────
info "Instalando dependencias..."
apt install -y -qq curl wget nano net-tools dnsutils python3 git
log "Dependencias instaladas"

# ── Instalar Docker ──────────────────────────────────────────────
if command -v docker &>/dev/null; then
    warn "Docker ya está instalado ($(docker --version))"
else
    info "Instalando Docker..."
    curl -fsSL https://get.docker.com | sh
    log "Docker instalado"
fi

# ── Añadir usuario al grupo docker ──────────────────────────────
SUDO_USER=${SUDO_USER:-$USER}
if [[ "$SUDO_USER" != "root" ]]; then
    usermod -aG docker "$SUDO_USER"
    log "Usuario $SUDO_USER añadido al grupo docker"
fi

# ── Deshabilitar systemd-resolved (libera puerto 53) ─────────────
if systemctl is-active --quiet systemd-resolved; then
    info "Desactivando systemd-resolved (ocupa el puerto 53)..."
    systemctl disable systemd-resolved
    systemctl stop systemd-resolved
    echo "nameserver 1.1.1.1" > /etc/resolv.conf
    log "systemd-resolved desactivado"
fi

# ── Crear estructura de carpetas ─────────────────────────────────
HOMELAB_DIR="$HOME/homelab"
if [[ "$SUDO_USER" != "root" ]]; then
    HOMELAB_DIR="/home/$SUDO_USER/homelab"
fi

info "Creando estructura de carpetas en $HOMELAB_DIR..."

if [[ "$ROLE" == "principal" ]]; then
    mkdir -p "$HOMELAB_DIR"/{npm/{data,letsencrypt},adguard/{work,conf},\
vaultwarden/data,prometheus,grafana/data,portainer/data,\
ntfy/data,n8n/data,syncthing/{config,data},\
uptime-kuma,homarr/{configs,data,icons},certs}
    chown -R 472:472 "$HOMELAB_DIR/grafana/data" 2>/dev/null || true
    chown -R 1000:1000 "$HOMELAB_DIR/syncthing/" 2>/dev/null || true
else
    mkdir -p "$HOMELAB_DIR"/{pihole/{etc-pihole,etc-dnsmasq},blocky,\
syncthing/{config,data}}
    chown -R 1000:1000 "$HOMELAB_DIR/syncthing/" 2>/dev/null || true
fi

log "Estructura de carpetas creada en $HOMELAB_DIR"

# ── Copiar configuración ─────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$SCRIPT_DIR/../config/homelab-$ROLE"

if [[ -d "$CONFIG_DIR" ]]; then
    cp -r "$CONFIG_DIR/." "$HOMELAB_DIR/"
    log "Configuración copiada"
else
    warn "No se encontró configuración en $CONFIG_DIR"
    warn "Copia manualmente los archivos de config/homelab-$ROLE/"
fi

# ── Instalar Tailscale ────────────────────────────────────────────
if command -v tailscale &>/dev/null; then
    warn "Tailscale ya está instalado"
else
    info "Instalando Tailscale..."
    curl -fsSL https://tailscale.com/install.sh | sh
    log "Tailscale instalado"
fi

# ── Resumen ──────────────────────────────────────────────────────
echo ""
echo -e "${BOLD}══════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}✓ Instalación completada${NC}"
echo -e "${BOLD}══════════════════════════════════════════════════════════${NC}"
echo ""
echo "Pasos siguientes:"
echo ""
echo "  1. Editar la configuración:"
echo "     nano $HOMELAB_DIR/docker-compose.yml"
if [[ "$ROLE" == "principal" ]]; then
    echo "     nano $HOMELAB_DIR/prometheus/prometheus.yml"
fi
echo ""
echo "  2. Autenticar Tailscale:"
echo "     tailscale up"
echo ""
echo "  3. Levantar el stack:"
echo "     cd $HOMELAB_DIR && docker compose up -d"
echo ""
echo "  4. Verificar que todo corre:"
echo "     docker compose ps"
echo ""
if [[ "$SUDO_USER" != "root" ]]; then
    warn "Cierra y vuelve a abrir la sesión para aplicar el grupo docker"
fi
