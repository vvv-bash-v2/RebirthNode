# 🏠 RebirthNode - Homelab Dual — Infraestructura Self-Hosted Completa

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Docker](https://img.shields.io/badge/Docker-Compose-blue)](https://docs.docker.com/compose/)
[![Debian](https://img.shields.io/badge/OS-Debian%2012-red)](https://www.debian.org/)
[![Tailscale](https://img.shields.io/badge/VPN-Tailscale-blue)](https://tailscale.com/)

Infraestructura homelab completa con dos servidores físicos, monitorización centralizada, alertas en tiempo real vía Telegram, red VPN mesh privada y DNS redundante. Todo sobre hardware antiguo con Docker.

---

## 📋 Índice

- [🌟 Características](#-características)
- [🗺️ Arquitectura](#️-arquitectura)
- [💻 Hardware utilizado](#-hardware-utilizado)
- [🚀 Inicio rápido](#-inicio-rápido)
- [📁 Estructura del repositorio](#-estructura-del-repositorio)
- [📚 Documentación](#-documentación)
- [🤝 Contribuir](#-contribuir)
- [📄 Licencia](#-licencia)

---

## 🌟 Características

- 🛡️ **DNS redundante** — AdGuard Home (primario) + Pi-hole (secundario)
- 📊 **Monitorización completa** — Prometheus + Grafana para 3 equipos (2x Linux + 1x Windows)
- 🚨 **Alertas proactivas** — 9 reglas de alerta vía Telegram con formato enriquecido
- 🔐 **Acceso seguro** — Tailscale VPN mesh, sin puertos abiertos en el router
- 🔑 **Contraseñas self-hosted** — Vaultwarden (compatible con Bitwarden)
- 📱 **Notificaciones push** — ntfy sin dependencias externas
- ⚡ **Automatización** — n8n como intermediario inteligente de notificaciones
- 🔁 **Sincronización** — Syncthing mantiene backup continuo entre servidores
- 🔄 **Actualizaciones automáticas** — Watchtower actualiza imágenes cada noche
- 🏠 **Dashboard unificado** — Homarr con widgets de AdGuard, Grafana y estado de servicios

---

## 🗺️ Arquitectura

```
┌─────────────────────────────────────────────────────────────────┐
│                        RED LOCAL (LAN)                           │
│                                                                   │
│  ┌─────────────────────────┐    ┌─────────────────────────┐     │
│  │   🖥️ HOMELAB PRINCIPAL   │    │  🖧 HOMELAB SECUNDARIO   │     │
│  │   (Linux / ~4GB RAM)    │◄──►│  (Linux / ~2GB RAM)     │     │
│  │                         │    │                         │     │
│  │  🛡️ AdGuard Home  :53   │    │  🕳️ Pi-hole       :53   │     │
│  │  📈 Grafana       :3000  │    │  📊 Netdata       :19999│     │
│  │  📡 Prometheus    :9090  │◄───│  📤 Node Exporter :9100 │     │
│  │  👁️ Uptime Kuma   :3001  │    │  💨 Blocky        :5353 │     │
│  │  🔀 NPM           :81   │    │  🔁 Syncthing     :8384 │     │
│  │  🔐 Vaultwarden   :8082  │◄──►│  🌐 Tailscale           │     │
│  │  📱 ntfy          :8083  │    └─────────────────────────┘     │
│  │  ⚡ n8n           :5678  │                                      │
│  │  🔄 Watchtower           │    ┌─────────────────────────┐     │
│  │  🏠 Homarr        :7575  │    │     🪟 PC WINDOWS 11     │     │
│  │  🌐 Tailscale            │◄───│  📤 Win Exporter  :9182 │     │
│  └─────────────────────────┘    └─────────────────────────┘     │
└─────────────────────────────────────────────────────────────────┘
                               │
              ┌────────────────▼──────────────────┐
              │    🌐 TAILSCALE VPN MESH            │
              │   Acceso remoto seguro              │
              └────────────────┬──────────────────-┘
                               │
              ┌────────────────▼──────────────────┐
              │     ✈️ TELEGRAM BOT                │
              │   Alertas vía n8n                  │
              └───────────────────────────────────┘
```

### 🔄 Flujo de alertas

```
Prometheus → Grafana → Webhook → n8n → ntfy + Telegram
Uptime Kuma → Webhook → n8n → Telegram
```

### 🌐 Flujo DNS

```
Router
  ├── DNS Primario  → AdGuard Home (Homelab Principal)
  └── DNS Secundario → Pi-hole (Homelab Secundario)

AdGuard Home → Pi-hole → Cloudflare (fallback)
Pi-hole → AdGuard Home → Cloudflare (fallback)
```

---

## 💻 Hardware utilizado

| Componente | Homelab Principal | Homelab Secundario |
|---|---|---|
| CPU | Intel i3 (antigua gen.) | Intel Core 2 Duo |
| RAM | 4 GB DDR3 | 2 GB DDR2 |
| SO | Debian 12 | Debian 12 Minimal |
| Rol | Servicios centrales | Servicios de respaldo |

> 💡 Todo el stack funciona sobre hardware antiguo y de bajo coste.

---

## 🚀 Inicio rápido

### Requisitos previos

- Debian 12 instalado en ambos servidores
- Acceso SSH
- Cuenta en [Tailscale](https://tailscale.com) (gratuita)
- Bot de Telegram creado vía [@BotFather](https://t.me/botfather)

### 1. Clonar el repositorio

```bash
git clone https://github.com/TU-USUARIO/homelab-dual.git
cd homelab-dual
```

### 2. Instalar Docker

```bash
curl -fsSL https://get.docker.com | sh
usermod -aG docker $USER
newgrp docker
```

### 3. Configurar el homelab principal

```bash
# Copiar configuración
cp -r config/homelab-principal ~/homelab

# Editar variables (sustituir todos los TU_* por valores reales)
nano ~/homelab/docker-compose.yml
nano ~/homelab/prometheus/prometheus.yml

# Crear carpetas y ajustar permisos
mkdir -p ~/homelab/grafana/data
chown -R 472:472 ~/homelab/grafana/data
chown -R 1000:1000 ~/homelab/syncthing/

# Levantar el stack
cd ~/homelab
docker compose up -d
docker compose ps
```

### 4. Configurar el homelab secundario

```bash
cp -r config/homelab-secundario ~/homelab
nano ~/homelab/docker-compose.yml
nano ~/homelab/blocky/config.yml
cd ~/homelab
docker compose up -d
```

### 5. Instalar Tailscale en ambos servidores

```bash
curl -fsSL https://tailscale.com/install.sh | sh
tailscale up
```

### 6. Verificar

```bash
# Todos los targets deben estar UP
curl http://TU-IP:9090/targets

# Ver estado de contenedores
docker compose ps
```

---

## 📁 Estructura del repositorio

```
homelab-dual/
├── 📄 README.md                          ← Este archivo
├── 📄 .gitignore                         ← Excluye credenciales y datos
├── 📄 .env.example                       ← Plantilla de variables de entorno
│
├── 📁 config/
│   ├── 📁 homelab-principal/
│   │   ├── 📄 docker-compose.yml         ← Stack completo del principal
│   │   └── 📁 prometheus/
│   │       └── 📄 prometheus.yml         ← Configuración de scraping
│   │
│   └── 📁 homelab-secundario/
│       ├── 📄 docker-compose.yml         ← Stack del secundario
│       └── 📁 blocky/
│           └── 📄 config.yml             ← Configuración de Blocky
│
├── 📁 scripts/
│   ├── 📄 setup.sh                       ← Script de instalación automatizada
│   ├── 📄 backup.sh                      ← Script de backup diario
│   └── 📄 renew-certs.sh                 ← Renovación de certificados SSL
│
├── 📁 docs/
│   ├── 📄 guia-completa.md               ← Documentación completa (Markdown)
│   ├── 📄 alertas-grafana.md             ← Referencia de reglas de alerta
│   ├── 📄 resolucion-problemas.md        ← Troubleshooting exhaustivo
│   └── 📄 puertos-referencia.md          ← Tabla de todos los puertos
│
└── 📁 .github/
    └── 📄 ISSUE_TEMPLATE.md              ← Plantilla para reportar issues
```

---

## 📚 Documentación

| Documento | Descripción |
|---|---|
| [Guía completa](docs/guia-completa.md) | Instalación y configuración paso a paso |
| [Alertas de Grafana](docs/alertas-grafana.md) | Las 9 reglas de alerta con queries PromQL |
| [Resolución de problemas](docs/resolucion-problemas.md) | Errores frecuentes y soluciones |
| [Referencia de puertos](docs/puertos-referencia.md) | Tabla de todos los servicios y puertos |

---

## 🔧 Variables de entorno

Copiar `.env.example` a `.env` y rellenar los valores:

```bash
cp .env.example .env
nano .env
```

> ⚠️ **NUNCA subir el archivo `.env` con valores reales a Git.** Está incluido en `.gitignore`.

---

## 🤝 Contribuir

Las contribuciones son bienvenidas. Por favor:

1. Haz fork del repositorio
2. Crea una rama: `git checkout -b feature/mi-mejora`
3. Haz commit: `git commit -m 'feat: añadir mi mejora'`
4. Haz push: `git push origin feature/mi-mejora`
5. Abre un Pull Request

---

## 📄 Licencia

Este proyecto está bajo la licencia MIT. Ver [LICENSE](LICENSE) para más detalles.

---

*Construido sobre hardware antiguo. Documentado con detalle. Probado en producción.*
