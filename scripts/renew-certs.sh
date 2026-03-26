#!/bin/bash
# ══════════════════════════════════════════════════════════════════
# renew-certs.sh — Renovar certificados SSL de Tailscale
# Los certificados expiran cada 90 días
# Uso: bash renew-certs.sh NOMBRE.tail-XXXXX.ts.net
# ══════════════════════════════════════════════════════════════════

CERT_NAME="$1"
CERT_DIR="${HOMELAB_DIR:-$HOME/homelab}/certs"

if [[ -z "$CERT_NAME" ]]; then
    echo "Uso: $0 NOMBRE.tail-XXXXX.ts.net"
    echo ""
    echo "Para obtener el nombre de tu máquina:"
    echo "  tailscale status --json | python3 -c \"import sys,json; d=json.load(sys.stdin); print(d['Self']['DNSName'])\""
    exit 1
fi

echo "$(date '+%Y-%m-%d %H:%M:%S') — Renovando certificado para $CERT_NAME..."

mkdir -p "$CERT_DIR"

if tailscale cert "$CERT_NAME"; then
    mv "${CERT_NAME}.crt" "$CERT_DIR/" 2>/dev/null || true
    mv "${CERT_NAME}.key" "$CERT_DIR/" 2>/dev/null || true
    echo "$(date '+%Y-%m-%d %H:%M:%S') — Certificado renovado en $CERT_DIR"
    echo ""
    echo "Pasos siguientes:"
    echo "  1. Abrir Nginx Proxy Manager"
    echo "  2. Ir a Certificates → seleccionar el certificado anterior → Edit"
    echo "  3. Subir los nuevos archivos .crt y .key de $CERT_DIR"
    echo "  4. Guardar"
else
    echo "$(date '+%Y-%m-%d %H:%M:%S') — ERROR: No se pudo renovar el certificado"
    exit 1
fi
