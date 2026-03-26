# 🏠 Guía Completa de Implementación de Homelab Dual
## Infraestructura self-hosted con dos servidores, monitorización centralizada, alertas en tiempo real y red VPN mesh privada

> 📅 **Última actualización**: Marzo 2026  
> 🛠️ **Basado en implementación real** sobre hardware antiguo  
> 🔒 **Sin información sensible** — todos los valores privados han sido sustituidos por placeholders

---

## 📋 Índice

1. [🌟 Introducción y filosofía del proyecto](#-introducción)
2. [🗺️ Arquitectura general del sistema](#-arquitectura-general)
3. [💻 Requisitos de hardware](#-requisitos-de-hardware)
4. [🖥️ Homelab Principal — Configuración base](#-homelab-principal)
   - [⚙️ Preparación del sistema operativo](#-preparación-del-sistema)
   - [🐳 Docker y estructura de carpetas](#-docker-y-estructura-de-carpetas)
   - [📄 Docker Compose completo](#-docker-compose-completo)
   - [📊 Prometheus — Scraping de métricas](#-prometheus)
   - [🛡️ AdGuard Home — DNS con filtrado](#-adguard-home)
   - [🔀 Nginx Proxy Manager — HTTPS y reverse proxy](#-nginx-proxy-manager)
   - [🔐 Vaultwarden — Gestor de contraseñas](#-vaultwarden)
   - [📈 Grafana — Visualización](#-grafana)
   - [👁️ Uptime Kuma — Disponibilidad](#-uptime-kuma)
   - [📱 ntfy — Notificaciones push](#-ntfy)
   - [⚡ n8n — Automatización de workflows](#-n8n)
   - [🔄 Watchtower — Actualizaciones automáticas](#-watchtower)
   - [🔁 Syncthing — Sincronización](#-syncthing)
   - [🐋 Portainer y Homarr](#-portainer-y-homarr)
5. [🌐 Tailscale — Red VPN Mesh privada](#-tailscale)
6. [🖧 Homelab Secundario — Debian 12 Minimal](#-homelab-secundario)
7. [🪟 Monitorización del PC Windows](#-pc-windows)
8. [📡 Prometheus — Todos los targets integrados](#-todos-los-targets)
9. [📊 Grafana — Dashboards completos](#-dashboards)
10. [🚨 Sistema de alertas completo](#-sistema-de-alertas)
11. [🏠 Homarr — Dashboard de inicio personalizado](#-homarr-configuración)
12. [🔒 Seguridad del sistema](#-seguridad)
13. [⚙️ Configuraciones adicionales avanzadas](#-configuraciones-adicionales)
14. [🐛 Resolución de problemas exhaustiva](#-resolución-de-problemas)
15. [🔧 Mantenimiento y operaciones](#-mantenimiento)
16. [📚 Referencias y recursos](#-referencias)

---

## 🌟 Introducción

Este documento describe en detalle la construcción de una infraestructura homelab compuesta por dos servidores físicos con Debian 12, un PC con Windows 11 monitorizado, y una red privada cifrada mediante Tailscale. El objetivo no es simplemente tener servicios corriendo, sino construir una **plataforma robusta, redundante, monitorizada y con notificación proactiva**.

### 🎯 Por qué construir un homelab dual

Un homelab de un solo servidor tiene un punto único de fallo: si ese servidor se reinicia para aplicar actualizaciones, se cae, o tiene un problema de hardware, **todos los servicios quedan inaccesibles simultáneamente**. La solución es distribuir los servicios entre dos máquinas de forma que los servicios críticos (especialmente el DNS) tengan redundancia.

El planteamiento de este homelab es:

- 🖥️ **Homelab principal**: portátil antiguo (i3, 4GB RAM DDR3) — corre los servicios centrales: monitorización, gestión de contraseñas, automatización, notificaciones y DNS primario
- 🖧 **Homelab secundario**: sobremesa antiguo (Core 2 Duo, 2GB RAM DDR2, placa Gigabyte G31M-ES2L de 2008) — corre los servicios de respaldo: DNS secundario, sincronización, caché DNS y monitorización local
- 🪟 **PC Windows 11**: equipo personal monitorizado con Windows Exporter
- 🌐 **Tailscale**: conecta todo en una red privada segura accesible desde cualquier lugar

### 💡 Filosofía de diseño

Toda la infraestructura sigue estos principios:

1. **Todo en Docker**: facilita backups, migraciones y actualizaciones
2. **Persistencia obligatoria**: ningún servicio importante sin volumen montado
3. **Redundancia DNS**: si el principal cae, el secundario toma el relevo automáticamente
4. **Notificaciones proactivas**: Grafana y Uptime Kuma alertan antes de que los problemas se conviertan en incidentes
5. **Acceso remoto seguro**: Tailscale en lugar de puertos abiertos en el router
6. **Sincronización continua**: Syncthing mantiene copias actualizadas en ambos servidores

---

## 🗺️ Arquitectura general

### 📐 Diagrama del sistema

```
┌──────────────────────────────────────────────────────────────────┐
│                        RED LOCAL (LAN)                            │
│                                                                    │
│  ┌─────────────────────────┐    ┌─────────────────────────┐      │
│  │   🖥️ HOMELAB PRINCIPAL   │    │  🖧 HOMELAB SECUNDARIO   │      │
│  │   (i3 / 4GB RAM DDR3)   │◄──►│  (Core2Duo / 2GB DDR2)  │      │
│  │                         │    │                         │      │
│  │  🛡️ AdGuard Home  :53   │    │  🕳️ Pi-hole       :53   │      │
│  │  📈 Grafana       :3000  │    │  📊 Netdata       :19999│      │
│  │  📡 Prometheus    :9090  │◄───│  📤 Node Exporter :9100 │      │
│  │  👁️ Uptime Kuma   :3001  │    │  💨 Blocky        :5353 │      │
│  │  🐋 Portainer     :9443  │    │  🔁 Syncthing     :8384 │      │
│  │  🔀 NPM :80/:443/:81     │◄──►│  🌐 Tailscale           │      │
│  │  🔐 Vaultwarden   :8082  │    └─────────────────────────┘      │
│  │  📱 ntfy          :8083  │                                       │
│  │  ⚡ n8n           :5678  │    ┌─────────────────────────┐      │
│  │  🔄 Watchtower           │    │     🪟 PC WINDOWS 11     │      │
│  │  🔁 Syncthing     :8384  │◄───│  📤 Win Exporter  :9182 │      │
│  │  🏠 Homarr        :7575  │    └─────────────────────────┘      │
│  │  🌐 Tailscale            │                                       │
│  └─────────────────────────┘                                       │
└──────────────────────────────────────────────────────────────────┘
                               │
              ┌────────────────▼──────────────────┐
              │    🌐 TAILSCALE VPN MESH            │
              │   Acceso remoto seguro desde        │
              │   cualquier red o dispositivo       │
              │   📱 iOS / 🤖 Android / 🪟 Win     │
              └────────────────┬──────────────────-┘
                               │
              ┌────────────────▼──────────────────┐
              │     ✈️ TELEGRAM BOT (HLMonitor)    │
              │   Alertas Grafana + Uptime Kuma    │
              │   via n8n con formato enriquecido  │
              └───────────────────────────────────┘
```

### 🔄 Flujo DNS con redundancia completa

El sistema DNS está diseñado para que **nunca haya un punto único de fallo**. El router tiene configurados dos servidores DNS: el homelab principal como primario y el secundario como fallback. Si el principal cae (por ejemplo, durante una actualización), el router comienza automáticamente a usar Pi-hole del secundario sin ninguna intervención manual:

```
🌐 Router
  ├── 🥇 DNS Primario  ──► AdGuard Home (Homelab Principal :53)
  └── 🥈 DNS Secundario ──► Pi-hole (Homelab Secundario :53)

🛡️ AdGuard Home
  ├── 🥇 Upstream 1 ──► Pi-hole (IP-SECUNDARIO:53)  ← filtrado doble
  └── 🥈 Upstream 2 ──► 1.1.1.1 (Cloudflare)       ← fallback

🕳️ Pi-hole
  ├── 🥇 Upstream 1 ──► AdGuard Home (IP-PRINCIPAL:53)
  └── 🥈 Upstream 2 ──► 1.1.1.1 (Cloudflare)       ← fallback
```

Esto crea **cuatro niveles de redundancia**:
1. 🟢 **Normal**: Router → AdGuard → Pi-hole → Cloudflare
2. 🟡 **AdGuard caído**: Router → Pi-hole → Cloudflare
3. 🟡 **Pi-hole caído**: Router → AdGuard → Cloudflare directamente
4. 🔴 **Ambos caídos**: Router intenta usar Cloudflare directamente (si el ISP lo permite)

### 📬 Flujo de alertas

```
⏱️ Prometheus scrape métricas cada 15s
    │
    ▼
📊 Grafana evalúa reglas cada 1 minuto
    │ Si condición cumplida > 1 minuto (pending period)
    ▼
🔔 Contact Point → Webhook POST
    │
    ▼
⚡ n8n recibe JSON de Grafana
    ├── 📱 HTTP Request ──► ntfy ──► App móvil (notificación push)
    └── ✈️ Telegram ──► Bot HLMonitor ──► Chat privado

👁️ Uptime Kuma detecta caída/recuperación de servicio
    │
    ▼
⚡ n8n recibe JSON de Uptime Kuma
    └── ✈️ Telegram ──► Bot HLMonitor ──► Chat privado
```

---

## 💻 Requisitos de hardware

### 🖥️ Homelab Principal

| Componente | Configuración actual | Mínimo recomendado |
|---|---|---|
| 🧠 CPU | Intel i3 (generación antigua) | 2+ núcleos x86_64 |
| 💾 RAM | 4 GB DDR3 | 4 GB (8 GB ideal) |
| 💿 Disco | SSD/HDD | 60 GB libres |
| 🌐 Red | Ethernet Gigabit | Ethernet (WiFi no recomendado) |
| 🐧 SO | Debian 12 | Debian 12 / Ubuntu 22.04 LTS |

### 🖧 Homelab Secundario

El hardware específico puede identificarse con herramientas de diagnóstico. El homelab secundario usa una **Gigabyte G31M-ES2L** de 2008:

```bash
# Instalar herramientas de diagnóstico
apt install -y inxi dmidecode

# Ver resumen completo del hardware
inxi -Fxxxz

# Ver información de la placa base
dmidecode -t baseboard

# Ver procesador con todos los detalles
dmidecode -t processor

# Ver slots de RAM y módulos instalados físicamente
dmidecode -t memory

# Ver discos y particiones
lsblk
df -h
```

| Componente | Especificaciones detectadas | Límite máximo |
|---|---|---|
| 🏗️ Placa base | Gigabyte G31M-ES2L (2008) | — |
| 🧠 CPU | Intel Core 2 Duo @ 2.4 GHz, Socket LGA775 | — |
| 💾 RAM actual | 2 × 1 GB DDR2 a 800 MT/s (2 GB total) | **4 GB** (2 × 2 GB DDR2) |
| 🎰 Slots RAM | 2 slots DIMM DDR2 | Max 2 GB por slot (chipset G31) |
| 🐧 SO | Debian 12 Minimal | — |

> 💡 **Ampliar la RAM**: Para llegar al máximo de 4 GB, comprar 2 módulos **DDR2 2GB PC2-6400 (800MHz) DIMM**. Son muy económicos en segunda mano (3-5€ cada uno en Wallapop o eBay). Solo hay que sustituir los dos módulos actuales de 1 GB.

---

## 🖥️ Homelab Principal

### ⚙️ Preparación del sistema

El homelab principal corre Debian 12. La instalación es estándar: arrancar desde la ISO netinst, seguir el asistente y en **tasksel** seleccionar únicamente **SSH server** y **standard system utilities**. No es necesario ningún entorno de escritorio.

Tras la instalación, lo primero siempre es actualizar el sistema completo:

```bash
apt update && apt upgrade -y
```

### 🐳 Docker y estructura de carpetas

Docker es el pilar de toda la infraestructura. Se instala con el script oficial que detecta automáticamente la distribución:

```bash
# Instalación oficial de Docker
curl -fsSL https://get.docker.com | sh

# Añadir usuario al grupo docker (evitar sudo en comandos docker)
usermod -aG docker $USER

# Aplicar cambio de grupo en sesión actual
newgrp docker

# Verificar que todo funciona
docker --version
docker compose version
docker run hello-world
```

> ⚠️ **Error frecuente**: Si `docker compose` falla con "command not found", instalar el plugin: `apt install docker-compose-plugin`

La estructura de carpetas es **fundamental**. Toda la infraestructura vive bajo `~/homelab/`:

```
📁 ~/homelab/
├── 📄 docker-compose.yml          ← archivo principal, define todo el stack
├── 📁 prometheus/
│   └── 📄 prometheus.yml          ← configuración de scraping
├── 📁 grafana/
│   └── 📁 data/                   ← dashboards, datasources, alertas (CRÍTICO)
├── 📁 adguard/
│   ├── 📁 work/                   ← datos de trabajo de AdGuard
│   └── 📁 conf/                   ← configuración y listas (CRÍTICO)
├── 📁 npm/
│   ├── 📁 data/                   ← configuración de NPM (CRÍTICO)
│   └── 📁 letsencrypt/            ← certificados SSL
├── 📁 vaultwarden/
│   └── 📁 data/                   ← TODAS LAS CONTRASEÑAS (MUY CRÍTICO)
├── 📁 ntfy/
│   └── 📁 data/                   ← usuarios y caché de mensajes
├── 📁 n8n/
│   └── 📁 data/                   ← workflows, credenciales de Telegram
├── 📁 portainer/
│   └── 📁 data/                   ← configuración de Portainer
├── 📁 syncthing/
│   ├── 📁 config/                 ← identidad y pares de Syncthing
│   └── 📁 data/                   ← carpeta sincronizada
├── 📁 uptime-kuma/                ← monitores y alertas
├── 📁 homarr/
│   ├── 📁 configs/
│   ├── 📁 data/
│   └── 📁 icons/
└── 📁 certs/
    ├── 📄 NOMBRE.crt              ← certificado SSL de Tailscale
    └── 📄 NOMBRE.key              ← clave privada SSL
```

Crear toda la estructura con un único comando:

```bash
mkdir -p ~/homelab/{npm/{data,letsencrypt},adguard/{work,conf},vaultwarden/data,\
prometheus,grafana/data,portainer/data,ntfy/data,n8n/data,\
syncthing/{config,data},uptime-kuma,homarr/{configs,data,icons},certs}
```

Ajustar permisos de las carpetas que los necesitan:

```bash
# Grafana corre con UID 472 — sin esto falla silenciosamente
chown -R 472:472 ~/homelab/grafana/data

# Syncthing corre con UID 1000
chown -R 1000:1000 ~/homelab/syncthing/
```

> ⚠️ **Error muy común**: Si un contenedor no tiene volumen persistente montado, **todos sus datos se pierden al reiniciarlo**. Para verificar: `docker inspect NOMBRE | grep -A 5 "Mounts"`. Si muestra `"Mounts": []`, el contenedor no tiene persistencia.

### 📄 Docker Compose completo

Toda la infraestructura del homelab principal se define en `~/homelab/docker-compose.yml`. Antes de escribirlo hay que generar las contraseñas seguras:

```bash
# Generar contraseña genérica (32 bytes en base64 = ~44 caracteres)
openssl rand -base64 32

# Para el ADMIN_TOKEN de Vaultwarden (necesita mínimo 48 bytes)
openssl rand -base64 48

# Para tokens de API (64 bytes para mayor seguridad)
openssl rand -base64 64
```

El `openssl rand -base64 N` genera `N` bytes de datos aleatorios criptográficamente seguros y los codifica en Base64. Es el método estándar para generar tokens y contraseñas en entornos Linux.

El archivo completo con todos los servicios, volúmenes persistentes y configuración correcta:

```yaml
services:

  # ─── 📊 MONITORIZACIÓN ──────────────────────────────────────────
  node-exporter:
    image: prom/node-exporter:latest
    restart: always
    volumes:
      - /proc:/host/proc:ro
      - /sys:/host/sys:ro
      - /:/rootfs:ro
    command:
      - '--path.procfs=/host/proc'
      - '--path.rootfs=/rootfs'
      - '--path.sysfs=/host/sys'
      - '--collector.filesystem.mount-points-exclude=^/(sys|proc|dev|host|etc)($$|/)'

  adguard-exporter:
    image: ebrianne/adguard-exporter:latest
    container_name: adguard-exporter
    restart: always
    ports:
      - "9617:9617"
    environment:
      - adguard_protocol=http
      - adguard_hostname=adguardhome
      - adguard_port=3000
      - adguard_username=TU_USUARIO_ADGUARD
      - adguard_password=TU_PASSWORD_ADGUARD
      - interval=30s
      - log_limit=10000

  uptime-kuma:
    image: louislam/uptime-kuma:1
    container_name: uptime-kuma
    volumes:
      - ./uptime-kuma:/app/data
    ports:
      - "3001:3001"
    restart: always

  prometheus:
    image: prom/prometheus:latest
    volumes:
      - ./prometheus:/etc/prometheus
    ports:
      - "9090:9090"
    restart: always

  # CRÍTICO: user: "472" y volumen son OBLIGATORIOS para persistencia
  grafana:
    image: grafana/grafana:latest
    ports:
      - "3000:3000"
    restart: always
    user: "472"
    volumes:
      - ./grafana/data:/var/lib/grafana
    environment:
      - GF_SECURITY_ADMIN_USER=admin
      - GF_SECURITY_ADMIN_PASSWORD=TU_PASSWORD_GRAFANA
      - GF_USERS_ALLOW_SIGN_UP=false
      - GF_SECURITY_ALLOW_EMBEDDING=true   # Necesario para iframes en Homarr

  # ─── 🛡️ DNS ────────────────────────────────────────────────────
  adguardhome:
    image: adguard/adguardhome
    container_name: adguardhome
    restart: always
    volumes:
      - ./adguard/work:/opt/adguardhome/work
      - ./adguard/conf:/opt/adguardhome/conf
    ports:
      - "53:53/tcp"
      - "53:53/udp"
      - "3002:3000/tcp"
      - "853:853/tcp"
      - "784:784/udp"

  # ─── 🔀 PROXY Y SEGURIDAD ───────────────────────────────────────
  npm:
    image: jc21/nginx-proxy-manager:latest
    container_name: nginx-proxy-manager
    restart: always
    ports:
      - "80:80"
      - "443:443"
      - "81:81"
    volumes:
      - ./npm/data:/data
      - ./npm/letsencrypt:/etc/letsencrypt

  vaultwarden:
    image: vaultwarden/server:latest
    container_name: vaultwarden
    restart: always
    ports:
      - "8082:80"
    volumes:
      - ./vaultwarden/data:/data
    environment:
      - DOMAIN=https://vault.TU-DOMINIO
      - SIGNUPS_ALLOWED=false
      - ADMIN_TOKEN=GENERA_CON_openssl_rand_-base64_48

  # ─── 📱 NOTIFICACIONES Y AUTOMATIZACIÓN ─────────────────────────
  ntfy:
    image: binwiederhier/ntfy:latest
    container_name: ntfy
    restart: always
    ports:
      - "8083:80"
    volumes:
      - ./ntfy/data:/var/lib/ntfy
    command: serve
    environment:
      - NTFY_BASE_URL=http://TU-IP:8083
      - NTFY_CACHE_FILE=/var/lib/ntfy/cache.db
      - NTFY_AUTH_FILE=/var/lib/ntfy/auth.db
      - NTFY_AUTH_DEFAULT_ACCESS=deny-all

  n8n:
    image: n8nio/n8n:latest
    container_name: n8n
    restart: always
    ports:
      - "5678:5678"
    volumes:
      - ./n8n/data:/home/node/.n8n
    environment:
      - GENERIC_TIMEZONE=Europe/Madrid
      - TZ=Europe/Madrid
      - N8N_HOST=n8n.TU-DOMINIO
      - N8N_PORT=5678
      - N8N_PROTOCOL=https
      - WEBHOOK_URL=https://n8n.TU-DOMINIO/
      - N8N_SECURE_COOKIE=false
      - N8N_HIRING_BANNER_ENABLED=false

  # ─── 🐋 GESTIÓN ─────────────────────────────────────────────────
  portainer:
    image: portainer/portainer-ce:latest
    ports:
      - "9443:9443"
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - ./portainer/data:/data
    restart: always

  homarr:
    container_name: homarr
    image: ghcr.io/ajnart/homarr:latest
    restart: always
    ports:
      - "7575:7575"
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock  # Para autodetección de servicios Docker
      - ./homarr/configs:/app/data/configs
      - ./homarr/data:/data
      - ./homarr/icons:/app/public/icons

  watchtower:
    image: containrrr/watchtower:latest
    container_name: watchtower
    restart: always
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
    environment:
      - WATCHTOWER_SCHEDULE=0 0 4 * * *
      - WATCHTOWER_CLEANUP=true
      - DOCKER_API_VERSION=1.54

  # ─── 🔁 SINCRONIZACIÓN ──────────────────────────────────────────
  syncthing:
    image: syncthing/syncthing:latest
    container_name: syncthing
    restart: unless-stopped
    ports:
      - "8384:8384"
      - "22000:22000/tcp"
      - "22000:22000/udp"
    volumes:
      - ./syncthing/config:/var/syncthing/config
      - ./syncthing/data:/var/syncthing/data
    environment:
      TZ: "Europe/Madrid"
```

Levantar todo el stack:

```bash
cd ~/homelab
docker compose up -d

# Verificar que todos están corriendo
docker compose ps

# Ver logs en tiempo real de todos los servicios
docker compose logs -f
```

### 📊 Prometheus

Prometheus es la base de datos de métricas. Su configuración en `~/homelab/prometheus/prometheus.yml` define los "trabajos" de recolección: a qué servidores contactar, cada cuánto tiempo, y qué etiquetas añadir.

El intervalo de 15 segundos es un buen equilibrio entre granularidad y carga del sistema. Con 4 targets y métricas cada 15 segundos, el volumen de datos es manejable incluso en hardware modesto.

```yaml
global:
  scrape_interval: 15s
  evaluation_interval: 15s

scrape_configs:
  # 🖥️ Homelab principal — Node Exporter en red Docker interna
  - job_name: 'node'
    static_configs:
      - targets: ['node-exporter:9100']

  # 🪟 PC Windows — Windows Exporter
  - job_name: 'windows'
    static_configs:
      - targets: ['IP-PC-WINDOWS:9182']

  # 🛡️ AdGuard Home — métricas DNS
  - job_name: 'adguard'
    static_configs:
      - targets: ['adguard-exporter:9617']

  # 🖧 Homelab secundario — Node Exporter por IP de red local
  - job_name: 'node-gigabyte'
    static_configs:
      - targets: ['IP-HOMELAB-SECUNDARIO:9100']
        labels:
          instance: 'homelab-secundario'
```

> 💡 **Por qué `node-exporter:9100` y no `localhost:9100`**: El Node Exporter del homelab principal y Prometheus comparten la misma red Docker. Dentro de esa red, los contenedores se comunican por nombre. `localhost` dentro del contenedor de Prometheus apuntaría al propio contenedor, no al host.

Tras cualquier cambio al `prometheus.yml`:

```bash
docker compose restart prometheus

# Verificar que todos los targets están UP
# Acceder en: http://TU-IP:9090/targets
```

### 🛡️ AdGuard Home

AdGuard Home filtra publicidad y trackers a nivel DNS para toda la red. Se accede por primera vez en `http://TU-IP:3002` donde aparece el asistente de configuración inicial.

> ⚠️ **Error muy frecuente**: El puerto 53 está ocupado por `systemd-resolved` en Debian 12. Desactivarlo ANTES de arrancar AdGuard:

```bash
systemctl disable systemd-resolved
systemctl stop systemd-resolved
echo "nameserver 1.1.1.1" > /etc/resolv.conf
```

**Configuración de DNS upstream** (Settings → DNS settings → Upstream DNS servers):
```
IP-HOMELAB-SECUNDARIO    ← Pi-hole como upstream principal
1.1.1.1                  ← Cloudflare como fallback
```

**Listas de bloqueo recomendadas** (Filters → DNS blocklists → Add blocklist):
- `https://adguardteam.github.io/AdGuardSDNSFilter/Filters/filter.txt`
- `https://small.oisd.nl`
- `https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts`

**Reescrituras DNS** (Filters → DNS rewrites) — una por cada subdominio interno:
```
grafana.TU-DOMINIO    → IP-DEL-SERVIDOR
vault.TU-DOMINIO      → IP-DEL-SERVIDOR
n8n.TU-DOMINIO        → IP-DEL-SERVIDOR
kuma.TU-DOMINIO       → IP-DEL-SERVIDOR
portainer.TU-DOMINIO  → IP-DEL-SERVIDOR
```

### 🔀 Nginx Proxy Manager

NPM es la puerta de entrada a todos los servicios. Permite acceder a cualquier servicio por subdominio (`grafana.TU-DOMINIO`) en lugar de IP:puerto.

**Credenciales iniciales** (acceder en `http://TU-IP:81`):
- Email: `admin@example.com`
- Password: `changeme`

> 🚨 **Cambiarlas INMEDIATAMENTE** — estas credenciales son públicas y conocidas.

**Para cada servicio** crear un Proxy Host con:
- Domain Names: el subdominio deseado
- Scheme: `http` (solo `https` para Portainer)
- Forward Hostname/IP: nombre del contenedor Docker o IP
- Forward Port: puerto interno del servicio
- ✅ Block Common Exploits
- ✅ Websockets Support (necesario para Grafana, n8n, Uptime Kuma)

En la pestaña **SSL**: seleccionar el certificado de Tailscale y activar **Force SSL**.

### 🔐 Vaultwarden

Vaultwarden es una implementación open source del servidor Bitwarden. Compatible con todos los clientes oficiales: extensión de navegador, app móvil y app de escritorio.

**Generar el ADMIN_TOKEN antes de arrancar**:

```bash
openssl rand -base64 48
```

Este comando genera 48 bytes aleatorios criptográficamente seguros codificados en Base64, produciendo una cadena de ~64 caracteres. Es el estándar de la industria para generar tokens de autenticación.

> 🚨 **CRÍTICO**: Vaultwarden **requiere HTTPS obligatoriamente**. No funciona por HTTP. Configurar NPM con certificado SSL ANTES de intentar usar Vaultwarden.

Proceso completo de puesta en marcha:
1. Generar ADMIN_TOKEN con openssl
2. Configurar NPM con SSL para `vault.TU-DOMINIO`
3. Arrancar el contenedor con `SIGNUPS_ALLOWED=true`
4. Acceder por HTTPS y crear la primera cuenta
5. Cambiar `SIGNUPS_ALLOWED=false` y recrear: `docker compose up -d --force-recreate vaultwarden`

> 🔴 **ADVERTENCIA CRÍTICA**: La contraseña maestra de Vaultwarden **NO se puede recuperar**. Si se pierde, los datos son irrecuperables. Guardar una copia en papel en un lugar físico seguro, completamente separado del propio Vaultwarden.

### 📈 Grafana

Grafana visualiza todas las métricas de Prometheus. El primer paso es añadir Prometheus como datasource:

**Connections → Data sources → Add data source → Prometheus:**
- URL: `http://homelab-prometheus-1:9090`
- Pulsar **Save & test** — debe mostrar "Successfully queried the Prometheus API"

> ⚠️ **Usar el nombre del contenedor**, no `localhost` ni la IP del servidor. Ambos servicios están en la red Docker y se comunican internamente.

**Verificar que el volumen persistente está montado**:

```bash
docker inspect homelab-grafana-1 | grep -A 5 "Mounts"
```

Si muestra `"Mounts": []`, hay pérdida de datos garantizada en el próximo reinicio. Añadir el volumen en docker-compose.yml y recrear.

**Reset de contraseña** (si se pierde acceso):

```bash
docker exec -it $(docker ps -qf name=grafana) grafana cli admin reset-admin-password NUEVA_PASSWORD
```

**Dashboards recomendados** (importar por ID en Dashboards → New → Import):

| ID | Nombre | Para qué sirve |
|---|---|---|
| 1860 | Node Exporter Full | CPU, RAM, disco, red Linux |
| 20763 | Windows RSCs | Métricas completas Windows |

**Habilitar embedding** (necesario para iframes en Homarr):

Añadir en el docker-compose.yml de grafana:
```yaml
environment:
  - GF_SECURITY_ALLOW_EMBEDDING=true
```

### 👁️ Uptime Kuma

Uptime Kuma verifica que los servicios responden correctamente desde el exterior. Complementa a Prometheus (que mide métricas internas) verificando la disponibilidad real tal como la experimentaría un usuario.

Las notificaciones de Uptime Kuma se canalizan a través de n8n para personalizar el formato. En **Settings → Notifications → Add Notification**:
- **Notification Type**: Webhook
- **URL Post**: `http://TU-IP:5678/webhook/uptime-kuma`
- **Request Body**: Preset - application/json
- ✅ Aplicar a todos los monitores existentes

### 📱 ntfy

ntfy es un servidor de notificaciones push HTTP. Cualquier servicio puede enviar una notificación con una simple petición HTTP POST sin depender de servicios de terceros.

**Crear usuario administrador**:

```bash
docker exec -it ntfy ntfy user add --role=admin TU_USUARIO
# El sistema pide la contraseña de forma interactiva

# Verificar usuarios creados
docker exec -it ntfy ntfy user list
```

**Probar que funciona**:

```bash
curl -u "USUARIO:PASSWORD" \
  -H "X-Ntfy-Title: 🧪 Test de notificacion" \
  -H "X-Ntfy-Priority: high" \
  -d "Si ves esto, ntfy funciona correctamente" \
  http://TU-IP:8083/homelab-alerts
```

**En el móvil**: instalar la app ntfy → añadir servidor personalizado → introducir credenciales → suscribirse al topic `homelab-alerts`.

### ⚡ n8n

n8n es la plataforma de automatización que actúa como intermediario inteligente entre todos los sistemas de notificación. Recibe webhooks de Grafana y Uptime Kuma, formatea los mensajes con emojis y estructura Markdown, y los envía a Telegram.

La razón de usarlo como intermediario (en lugar de enviar directamente a Telegram) es el **control total sobre el formato y el contenido** de cada tipo de alerta.

Variables de entorno importantes:
- `N8N_SECURE_COOKIE=false`: necesario cuando se accede sin HTTPS o desde dominio diferente
- `N8N_HIRING_BANNER_ENABLED=false`: elimina el banner de contratación de la interfaz
- `WEBHOOK_URL`: debe ser la URL pública de n8n (con HTTPS si se usa NPM)

> ⚠️ **Importante**: los workflows deben estar en estado **Published** para funcionar en producción. Un workflow en estado "draft" no responde al webhook de producción.

### 🔄 Watchtower

Watchtower mantiene todas las imágenes Docker actualizadas automáticamente cada noche a las 4:00 AM (menor tráfico de red, menor probabilidad de usuarios activos).

`DOCKER_API_VERSION=1.54` es necesario en algunos sistemas para evitar el error:
```
client version 1.25 is too old. Minimum supported API version is 1.40
```

Si este error aparece, actualizar Docker y recrear el contenedor:

```bash
curl -fsSL https://get.docker.com | sh
systemctl restart docker
docker compose stop watchtower
docker compose rm -f watchtower
docker compose up -d watchtower
```

**Excluir un contenedor de las actualizaciones automáticas**:

```yaml
labels:
  - "com.centurylinklabs.watchtower.enable=false"
```

### 🔁 Syncthing

Syncthing mantiene sincronizadas las carpetas de configuración entre ambos servidores, proporcionando backup continuo y automático.

**Error más común** — permisos incorrectos:
```
Failed to correct directory permissions: operation not permitted
Failed to load/generate certificate: permission denied
```

Solución siempre la misma:
```bash
chown -R 1000:1000 ~/homelab/syncthing/
docker compose up -d --force-recreate syncthing
```

**Conectar dos instancias de Syncthing**:
1. En el servidor A: **Acciones → Mostrar ID** → copiar el identificador
2. En el servidor B: **+ Añadir dispositivo remoto** → pegar el ID
3. El servidor A recibe notificación → aceptar
4. Crear carpeta compartida y añadir el dispositivo remoto
5. El servidor B acepta la carpeta compartida

### 🐋 Portainer y Homarr

**Portainer** (`https://TU-IP:9443`) proporciona una interfaz web para gestionar Docker: ver contenedores, logs, redes, volúmenes e imágenes sin línea de comandos.

**Homarr** (`http://TU-IP:7575`) es el dashboard de inicio personalizable. Se configura en detalle en la sección [🏠 Homarr — Dashboard de inicio](#-homarr-configuración).

---

## 🌐 Tailscale

### 📲 Instalación y autenticación

Tailscale crea una red privada (Tailnet) entre todos los dispositivos registrados usando WireGuard como protocolo subyacente. Cada dispositivo recibe una IP fija en `100.x.x.x` que no cambia independientemente de dónde esté conectado:

```bash
# Instalar Tailscale (detecta la distribución automáticamente)
curl -fsSL https://tailscale.com/install.sh | sh

# Autenticar el dispositivo (genera enlace para abrir en navegador)
tailscale up

# Ver estado de la red y dispositivos conectados
tailscale status
```

### 🔐 MagicDNS y certificados SSL

**Activar MagicDNS** en `https://login.tailscale.com/admin/dns` → toggle MagicDNS ON.

**Obtener el nombre DNS completo de la máquina**:

```bash
tailscale status --json | python3 -c "import sys,json; d=json.load(sys.stdin); print(d['Self']['DNSName'])"
# Salida: nombreequipo.tail-XXXXX.ts.net. (el punto final se ignora)
```

**Activar certificados SSL** en el mismo panel → HTTPS Certificates → Enable.

**Generar el certificado**:

```bash
tailscale cert NOMBRE.tail-XXXXX.ts.net

# Los archivos se generan en el directorio actual:
# NOMBRE.tail-XXXXX.ts.net.crt  ← certificado público
# NOMBRE.tail-XXXXX.ts.net.key  ← clave privada

# Moverlos a la carpeta del homelab
mv NOMBRE.tail-XXXXX.ts.net.* ~/homelab/certs/
```

En NPM: **Certificates → Add Certificate → Custom Certificate** → subir `.crt` y `.key`.

> ⏰ **Los certificados expiran cada 90 días**. Crear recordatorio en el calendario para renovarlos antes de que expiren. El mismo comando `tailscale cert` sirve para renovar.

> 💡 **Limitación**: Tailscale solo emite certificados para el dominio exacto (`homelabes.tail-XXXXX.ts.net`), no para subdominios wildcard. Los navegadores mostrarán advertencia en subdominios, pero la comunicación sigue cifrada.

### 🌍 AdGuard como DNS global de Tailscale

Para que todos los dispositivos de la Tailnet resuelvan los subdominios internos, configurar AdGuard como DNS global en `https://login.tailscale.com/admin/dns`:

1. **Add nameserver → Custom** → IP Tailscale del homelab principal
2. Activar **Override DNS servers**
3. **Add nameserver → Cloudflare** como respaldo

**Problema frecuente en Windows** — subdominios dejan de resolver tras activar Override DNS:

```powershell
# Limpiar caché DNS en Windows
ipconfig /flushdns
```

Si persiste, añadir manualmente al archivo hosts en `C:\Windows\System32\drivers\etc\hosts` (como administrador):
```
IP-SERVIDOR  grafana.TU-DOMINIO
IP-SERVIDOR  vault.TU-DOMINIO
IP-SERVIDOR  n8n.TU-DOMINIO
```

---

## 🖧 Homelab Secundario

### 🔧 Instalación y configuración de red

Debian 12 Minimal en hardware antiguo puede tener la interfaz de red en estado DOWN tras la instalación. Diagnosticar:

```bash
# Ver interfaces y su estado
ip link show

# Ver hardware de red detectado por el kernel
lspci | grep -i net

# Ver mensajes del kernel sobre red y firmware
dmesg | grep -i "firmware\|eth\|eno\|enp\|network"
```

En el caso de la placa Gigabyte G31M-ES2L con tarjeta Qualcomm Atheros AR8131, el driver `atl1c` se carga automáticamente pero la interfaz queda en DOWN. La salida de `ip link show` muestra:

```
2: enp2s0: <BROADCAST,MULTICAST> mtu 1500 ... state DOWN
    link/ether 00:24:1d:c3:37:21 brd ff:ff:ff:ff:ff:ff
```

Levantar y configurar permanentemente:

```bash
# Levantar la interfaz y obtener IP
ip link set enp2s0 up
dhclient enp2s0

# Verificar IP obtenida
ip a show enp2s0

# Hacer permanente editando /etc/network/interfaces:
# Añadir al final:
auto enp2s0
iface enp2s0 inet dhcp

# Aplicar
systemctl restart networking
```

> ❌ **Si `lspci | grep -i net` no muestra nada**: puede faltar firmware. Instalar: `apt install firmware-linux-nonfree && reboot`

### 🔒 SSH

```bash
apt update && apt install -y openssh-server
systemctl enable ssh
systemctl start ssh

# Verificar que escucha en puerto 22
ss -tlnp | grep sshd
```

Configuración recomendada en `/etc/ssh/sshd_config`:
```
PermitRootLogin no
PasswordAuthentication yes
Port 22
```

```bash
systemctl reload ssh
```

### 🐳 Docker y Docker Compose del secundario

```bash
curl -fsSL https://get.docker.com | sh
```

**Estructura de carpetas del secundario**:

```bash
mkdir -p ~/homelab/{pihole/{etc-pihole,etc-dnsmasq},blocky,syncthing/{config,data}}
chown -R 1000:1000 ~/homelab/syncthing/
```

**Docker Compose completo** (`~/homelab/docker-compose.yml`):

```yaml
services:

  # ─── 🕳️ DNS SECUNDARIO ──────────────────────────────────────────
  pihole:
    image: pihole/pihole:latest
    container_name: pihole
    restart: unless-stopped
    ports:
      - "53:53/tcp"
      - "53:53/udp"
      - "8080:80"
    environment:
      TZ: "Europe/Madrid"
      WEBPASSWORD: "TU_PASSWORD_PIHOLE"
    volumes:
      - ./pihole/etc-pihole:/etc/pihole
      - ./pihole/etc-dnsmasq:/etc/dnsmasq.d
    cap_add:
      - NET_ADMIN

  # ─── 📊 MONITORIZACIÓN ──────────────────────────────────────────
  # network_mode: host es NECESARIO para métricas de red precisas
  netdata:
    image: netdata/netdata:latest
    container_name: netdata
    restart: unless-stopped
    network_mode: host
    pid: host
    cap_add:
      - SYS_PTRACE
      - SYS_ADMIN
    security_opt:
      - apparmor:unconfined
    volumes:
      - /proc:/host/proc:ro
      - /sys:/host/sys:ro
      - /var/run/docker.sock:/var/run/docker.sock:ro
    environment:
      - NETDATA_CLAIM_TOKEN=
      - DO_NOT_TRACK=1
      - NETDATA_DISABLE_CLOUD=1

  node-exporter:
    image: prom/node-exporter:latest
    container_name: node-exporter
    restart: unless-stopped
    network_mode: host
    pid: host
    volumes:
      - /proc:/host/proc:ro
      - /sys:/host/sys:ro
      - /:/rootfs:ro
    command:
      - '--path.procfs=/host/proc'
      - '--path.rootfs=/rootfs'
      - '--path.sysfs=/host/sys'
      - '--collector.filesystem.mount-points-exclude=^/(sys|proc|dev|host|etc)($$|/)'

  # ─── 💨 DNS CACHÉ ────────────────────────────────────────────────
  blocky:
    image: spx01/blocky:latest
    container_name: blocky
    restart: unless-stopped
    ports:
      - "5353:53/tcp"
      - "5353:53/udp"
      - "4000:4000"
    volumes:
      - ./blocky/config.yml:/app/config.yml:ro

  # ─── 🔁 SINCRONIZACIÓN ──────────────────────────────────────────
  syncthing:
    image: syncthing/syncthing:latest
    container_name: syncthing
    restart: unless-stopped
    ports:
      - "8384:8384"
      - "22000:22000/tcp"
      - "22000:22000/udp"
    volumes:
      - ./syncthing/config:/var/syncthing/config
      - ./syncthing/data:/var/syncthing/data
    environment:
      TZ: "Europe/Madrid"
```

### 🕳️ Pi-hole — DNS secundario

**Panel de administración**: `http://IP-SECUNDARIO:8080/admin`

**Cambiar contraseña** (comando actualizado para Pi-hole v6+):

```bash
# El comando antiguo "pihole -a -p" ya no funciona
docker exec -it pihole pihole setpassword 'NUEVA_PASSWORD'
```

**Configuración DNS upstream** (Settings → DNS):
- Desmarcar todos los servidores por defecto
- Custom 1: `IP-HOMELAB-PRINCIPAL#53`
- Custom 2: `1.1.1.1`

**Listas de bloqueo recomendadas** (Adlists):

```
https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts
https://adaway.org/hosts.txt
https://v.firebog.net/hosts/static/w3kbl.txt
https://raw.githubusercontent.com/PolishFiltersTeam/KADhosts/master/KADhosts.txt
```

Después: **Tools → Update Gravity** (puede tardar varios minutos).

**Error 403 desde Tailscale** — Pi-hole rechaza IPs del rango Tailscale por defecto:

```bash
echo "WEBSERVER_ALLOW_SUBNET=100.64.0.0/10" >> ~/homelab/pihole/etc-pihole/pihole-FTL.conf
docker compose restart pihole
```

### 📊 Netdata

Acceder en `http://IP-SECUNDARIO:19999`. Las versiones recientes muestran un login de la nube. Hay un enlace discreto en la parte inferior derecha: **"Skip and use the dashboard anonymously"**.

Para evitar que pida login en cada acceso, las variables `NETDATA_DISABLE_CLOUD=1` y `DO_NOT_TRACK=1` deben estar en el docker-compose.yml y el contenedor debe recrearse:

```bash
docker compose up -d --force-recreate netdata
```

> 💡 **Por qué `network_mode: host`**: Sin este modo, Netdata solo ve la red interna de Docker y da errores de `Permission denied for client`. Con `network_mode: host`, usa directamente la red del host.

### 📤 Node Exporter del secundario

Verificar que expone métricas correctamente:

```bash
# En el servidor secundario
curl http://localhost:9100/metrics | head -20

# Desde el homelab principal
curl http://IP-HOMELAB-SECUNDARIO:9100/metrics | head -5
```

### 💨 Blocky — DNS caché ultraligero

Archivo de configuración `~/homelab/blocky/config.yml`:

```yaml
upstream:
  default:
    - 1.1.1.1
    - 8.8.8.8

blocking:
  blackLists:
    ads:
      - https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts
  clientGroupsBlock:
    default:
      - ads

port: 53
httpPort: 4000

log:
  level: info
```

Verificar que resuelve (Blocky escucha en puerto 5353 porque Pi-hole ocupa el 53):

```bash
dig google.com @IP-SECUNDARIO -p 5353
```

### 🌐 Tailscale en el secundario

```bash
curl -fsSL https://tailscale.com/install.sh | sh
tailscale up
tailscale status
```

---

## 🪟 PC Windows

### 📥 Instalación de Windows Exporter

Descargar el `.msi` desde `github.com/prometheus-community/windows_exporter/releases` y ejecutar como administrador. Instala un servicio de Windows que arranca automáticamente.

Verificar en: `http://localhost:9182/metrics`

### ⚠️ Métricas de memoria actualizadas

Las métricas de memoria cambiaron en versiones recientes. Las antiguas **ya no existen** y causarán "No data" en Grafana:

| ✅ Métrica correcta (actual) | ❌ Métrica antigua (NO usar) |
|---|---|
| `windows_memory_physical_free_bytes` | `windows_os_physical_memory_free_bytes` |
| `windows_memory_physical_total_bytes` | `windows_cs_physical_memory_bytes` |

Para descubrir qué métricas están disponibles:

```bash
curl -s "http://TU-IP:9090/api/v1/label/__name__/values" | python3 -m json.tool | grep -i windows | grep -i mem
```

---

## 📡 Todos los targets integrados

Con todos los exporters instalados, el `prometheus.yml` final tiene 4 targets cubriendo todos los equipos:

```yaml
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: 'node'           # Homelab principal (Linux)
    static_configs:
      - targets: ['node-exporter:9100']

  - job_name: 'windows'        # PC Windows 11
    static_configs:
      - targets: ['IP-PC-WINDOWS:9182']

  - job_name: 'adguard'        # Métricas DNS de AdGuard
    static_configs:
      - targets: ['adguard-exporter:9617']

  - job_name: 'node-gigabyte'  # Homelab secundario (Linux)
    static_configs:
      - targets: ['IP-HOMELAB-SECUNDARIO:9100']
        labels:
          instance: 'homelab-secundario'
```

Verificar todos los targets en `http://TU-IP:9090/targets` — todos deben aparecer en **UP** 🟢.

---

## 📊 Dashboards

### 🗂️ Organización de dashboards

| Dashboard | ID | Job | Instance |
|---|---|---|---|
| 🖥️ HomeLab Principal (Linux) | 1860 | `node` | `node-exporter:9100` |
| 🖧 HomeLab Secundario (Linux) | 1860 | `node-gigabyte` | `homelab-secundario` |
| 🪟 PC Windows 11 | 20763 | `windows` | `IP:9182` |

El mismo dashboard **Node Exporter Full (1860)** sirve para ambos Linux. Se cambia entre ellos con el filtro `Job` en la parte superior del dashboard.

---

## 🚨 Sistema de alertas

### ⚙️ Contact Point

En Grafana → Alerting → Contact points → Add contact point:

| Campo | Valor |
|---|---|
| Name | `Ntfy_Homelab` |
| Integration | Webhook |
| URL | `http://n8n:5678/webhook/grafana-alerts` |
| HTTP Method | POST |
| Username | usuario de ntfy |
| Password | contraseña de ntfy |

### 📋 Reglas de alerta — Las 9 reglas completas

#### 🖥️ Folder: HomeLab-Principal

**CPU Alta**:
```promql
100 - (avg by(instance) (rate(node_cpu_seconds_total{mode="idle", job="node"}[5m])) * 100)
```
Condición: IS ABOVE `85` | Summary: `CPU alta en HomeLab Principal`

**RAM Alta**:
```promql
(1 - (node_memory_MemAvailable_bytes{job="node"} / node_memory_MemTotal_bytes{job="node"})) * 100
```
Condición: IS ABOVE `90` | Summary: `RAM alta en HomeLab Principal`

**Caída**:
```promql
up{job="node"}
```
Condición: IS BELOW `1` | Summary: `HomeLab Principal caído`

#### 🖧 Folder: Gigabyte

**CPU Alta**:
```promql
100 - (avg by(instance) (rate(node_cpu_seconds_total{mode="idle", job="node-gigabyte"}[5m])) * 100)
```

**RAM Alta**:
```promql
(1 - (node_memory_MemAvailable_bytes{job="node-gigabyte"} / node_memory_MemTotal_bytes{job="node-gigabyte"})) * 100
```

**Caída**:
```promql
up{job="node-gigabyte"}
```

#### 🪟 Folder: Windows-PC

**CPU Alta**:
```promql
100 - (avg by(instance) (rate(windows_cpu_time_total{mode="idle", job="windows"}[5m])) * 100)
```

**RAM Alta**:
```promql
(1 - (windows_memory_physical_free_bytes{job="windows"} / windows_memory_physical_total_bytes{job="windows"})) * 100
```

**Caída**:
```promql
up{job="windows"}
```

> 💡 **Por qué `avg by(instance)` y no solo `avg`**: Sin el `by(instance)`, Prometheus agrupa todas las instancias en un valor global y el label `instance` desaparece de la alerta. Con él, cada instancia genera su propia serie y el label se preserva en la notificación.

**Configuración común para todas las reglas**:
- Evaluation group: `homelab` (crear con intervalo 1m)
- Pending period: `1m` (evita falsos positivos por picos momentáneos)
- Contact point: `Ntfy_Homelab`

**Probar una alerta** — bajar temporalmente el umbral:
1. Editar la alerta → cambiar umbral a `0.1`
2. Guardar y esperar 1-2 minutos
3. Verificar que llega la notificación en Telegram
4. Restaurar el umbral original

### ⚡ Workflow n8n: Grafana → ntfy → Telegram

El workflow tiene 3 nodos:

**Nodo 1 — Webhook**: ruta `/grafana-alerts`

**Nodo 2 — HTTP Request (→ ntfy)**:
```
Method: POST
URL: http://ntfy:8083/homelab-alerts
Auth: Basic Auth (usuario/password ntfy)

Headers:
  X-Ntfy-Priority: high
  X-Ntfy-Title: {{ $('Webhook').item.json.body.alerts[0].labels.alertname }}

Body (Raw, Text/Plain):
{{ $('Webhook').item.json.body.status === 'firing' ? 'ALERTA ACTIVA' : 'RESUELTA' }}

{{ $('Webhook').item.json.body.alerts[0].labels.alertname }}
```

> 🚨 **CRÍTICO**: El header `X-Ntfy-Title` **NUNCA puede contener emojis**. Los emojis son caracteres Unicode que violan la especificación RFC 7230 para headers HTTP. El error resultante es `Invalid character in header content ["x-ntfy-title"]`. Los emojis **sí** pueden usarse libremente en el body del mensaje.

**Nodo 3 — Telegram**: envía el mensaje formateado al bot HLMonitor.

### ⚡ Workflow n8n: Uptime Kuma → Telegram

**Nodo 1 — Webhook**: ruta `/uptime-kuma`

**Nodo 2 — Telegram** con mensaje:
```javascript
{{ $json.body.heartbeat?.status === 1 ? '✅' : '🔴' }} *{{ $json.body.monitor?.name }}*

📡 *Estado:* {{ $json.body.heartbeat?.status === 1 ? 'ONLINE' : 'OFFLINE' }}
🌐 *URL:* {{ $json.body.monitor?.url }}
💬 *Mensaje:* {{ $json.body.msg }}

⏰ *Hora:* {{ new Date($json.body.heartbeat?.time).toLocaleString('es-ES') }}
```

> 💡 El operador `?.` (optional chaining) es necesario porque en los tests de Uptime Kuma los campos vienen como `null`. En alertas reales contienen todos los datos.

---

## 🏠 Homarr — Dashboard de inicio

Homarr es el dashboard de inicio personalizable del homelab. Permite tener todos los servicios accesibles desde un único lugar con widgets de estado, estadísticas DNS, y recursos del servidor.

### ⚙️ Configuración inicial

Acceder en `http://TU-IP:7575` → hacer clic en el icono ✏️ para entrar en modo edición.

**Tema oscuro**: Settings → Appearance → Dark

### 🔧 Configurar servicios (panel lateral)

Para cada servicio: **Add → App** con estos datos:

| Nombre | URL | Icono |
|---|---|---|
| AdGuard | `https://adguard.TU-DOMINIO` | "adguard" |
| NPM | `https://npm.TU-DOMINIO` | "nginx" |
| Vaultwarden | `https://vault.TU-DOMINIO` | "bitwarden" |
| n8n | `https://n8n.TU-DOMINIO` | "n8n" |
| ntfy | `https://ntfy.TU-DOMINIO` | "ntfy" |
| Grafana | `https://grafana.TU-DOMINIO` | "grafana" |
| Portainer | `https://portainer.TU-DOMINIO` | "portainer" |

Para cada app, en la pestaña **Integration** activar el **ping** para que muestre el indicador de estado verde/rojo en tiempo real.

### 📊 Widgets recomendados

**Add → Widget → DNS hole summary** (AdGuard):
- URL: `http://TU-IP:3002`
- Usuario y contraseña de AdGuard

**Add → Widget → DNS hole controls** (control de AdGuard):
- Misma URL y credenciales

**Add → Widget → System Health Monitoring**:
- Muestra CPU y RAM del servidor donde corre Homarr

**Add → Widget → iFrame** (para Grafana embebido):
- Obtener URL de embed: en Grafana → Share → Embed → copiar URL
- Requiere `GF_SECURITY_ALLOW_EMBEDDING=true` en las variables de Grafana

**Add → Widget → Date and Time**:
- Fecha y hora local

### 📐 Layout recomendado

```
┌─────────────────────┬──────────────────┐  ┌──────────┐
│   🛡️ AdGuard Widget  │  📈 Grafana iframe│  │ AdGuard  │
├─────────────────────┤                  │  │   NPM    │
│   🕹️ DNS Controls    ├──────────────────┤  │ Vaultw.  │
├─────────────────────┤  💻 CPU/RAM Widget│  │   n8n    │
│   🕐 Date/Time       │                  │  │   ntfy   │
└─────────────────────┴──────────────────┘  └──────────┘
```

---

## 🔒 Seguridad del sistema

### 🛡️ Principios de seguridad aplicados

1. **Sin puertos expuestos al exterior**: Tailscale gestiona todo el acceso remoto. No hay puertos abiertos en el router.
2. **HTTPS en todos los servicios**: NPM + certificados Tailscale garantizan comunicación cifrada.
3. **Credenciales únicas por servicio**: cada servicio tiene su propio usuario y contraseña, generados con `openssl rand`.
4. **Vaultwarden para gestión de credenciales**: todas las contraseñas del homelab se guardan en Vaultwarden.
5. **Watchtower**: actualiza automáticamente para parchear vulnerabilidades.

### 🔑 Gestión de secretos

Nunca hardcodear contraseñas en el código o en archivos públicos. Todas las contraseñas deben estar en el `docker-compose.yml` como variables de entorno y este archivo nunca debe subirse a repositorios públicos.

Para generar contraseñas seguras siempre usar:
```bash
# Contraseña de 32 bytes (44 caracteres en Base64)
openssl rand -base64 32

# Token largo de 48 bytes (para Vaultwarden ADMIN_TOKEN)
openssl rand -base64 48

# UUID para identificadores únicos
uuidgen
```

### 🔐 SSH hardening básico

En `/etc/ssh/sshd_config`:
```
PermitRootLogin no           # Nunca login directo como root
PasswordAuthentication yes   # O "no" si se usan claves SSH
MaxAuthTries 3               # Máximo 3 intentos fallidos
AllowUsers TU_USUARIO        # Solo permite login a usuarios específicos
```

---

## ⚙️ Configuraciones adicionales

### 📊 cAdvisor — Métricas de contenedores Docker

cAdvisor permite monitorizar el uso de recursos de cada contenedor Docker individualmente desde Grafana. Es especialmente útil para identificar qué contenedor está consumiendo más CPU o RAM.

Añadir al `docker-compose.yml` del homelab principal:

```yaml
  cadvisor:
    image: gcr.io/cadvisor/cadvisor:latest
    container_name: cadvisor
    restart: unless-stopped
    privileged: true
    devices:
      - /dev/kmsg:/dev/kmsg
    volumes:
      - /:/rootfs:ro
      - /var/run:/var/run:ro
      - /sys:/sys:ro
      - /var/lib/docker:/var/lib/docker:ro
    ports:
      - "8080:8080"
```

Añadir en `prometheus.yml`:

```yaml
  - job_name: 'cadvisor'
    static_configs:
      - targets: ['cadvisor:8080']
```

Dashboard de Grafana para cAdvisor: importar ID **14282** (cAdvisor Exporter).

> ⚠️ **Importante**: En el dashboard de cAdvisor, verificar que el datasource seleccionado en el dropdown es el Prometheus local correcto, no un datasource de ejemplo.

### 🔔 Alertas avanzadas de Grafana

Además de las 9 alertas básicas, se pueden añadir alertas más específicas:

**Disco casi lleno** (Linux):
```promql
(1 - (node_filesystem_avail_bytes{fstype!="tmpfs", job="node"} / node_filesystem_size_bytes{fstype!="tmpfs", job="node"})) * 100
```
Condición: IS ABOVE `80`

**Disco casi lleno** (Windows):
```promql
(1 - (windows_logical_disk_free_bytes{volume="C:"} / windows_logical_disk_size_bytes{volume="C:"})) * 100
```
Condición: IS ABOVE `80`

**Load average alto** (Linux — indica sistema saturado):
```promql
node_load1{job="node"}
```
Condición: IS ABOVE `3` (ajustar según número de CPUs)

### 📱 Bot de Telegram avanzado con n8n

Con n8n se puede construir un bot de Telegram que responda a comandos y proporcione información del homelab en tiempo real:

```
/status     → estado de todos los contenedores
/metrics    → CPU y RAM actuales desde Prometheus
/containers → lista de contenedores corriendo/parados
/help       → lista de comandos disponibles
```

El flujo en n8n sería:
```
Telegram Trigger
    └── Switch (por comando /status, /metrics, etc.)
          ├── /status → HTTP Request (API Portainer) → Telegram
          ├── /metrics → HTTP Request (API Prometheus) → Telegram
          └── /containers → HTTP Request (API Portainer) → Telegram
```

Para consultar métricas de Prometheus desde n8n usar la API HTTP:
```
http://homelab-prometheus-1:9090/api/v1/query?query=QUERY_AQUI
```

### 🔁 Backup automatizado con script

Script de backup diario que comprime `~/homelab/` y guarda las últimas 7 copias:

```bash
#!/bin/bash
# Guardar en /usr/local/bin/homelab-backup.sh

BACKUP_DIR="/opt/homelab-backups"
DATE=$(date +%Y%m%d-%H%M)
BACKUP_FILE="$BACKUP_DIR/homelab-$DATE.tar.gz"
MAX_BACKUPS=7

mkdir -p "$BACKUP_DIR"

echo "$(date) — Iniciando backup..."
tar -czf "$BACKUP_FILE" ~/homelab/ 2>/dev/null
echo "$(date) — Backup creado: $BACKUP_FILE ($(du -sh $BACKUP_FILE | cut -f1))"

# Eliminar backups más antiguos que MAX_BACKUPS
ls -t "$BACKUP_DIR"/*.tar.gz | tail -n +$((MAX_BACKUPS + 1)) | xargs -r rm
echo "$(date) — Backup completado. Backups disponibles: $(ls $BACKUP_DIR/*.tar.gz | wc -l)"
```

Hacer ejecutable y programar con cron:

```bash
chmod +x /usr/local/bin/homelab-backup.sh

# Ejecutar cada día a las 3:00 AM
crontab -e
# Añadir: 0 3 * * * /usr/local/bin/homelab-backup.sh >> /var/log/homelab-backup.log 2>&1
```

### 📊 Prometheus — Retención de datos

Por defecto Prometheus guarda 15 días de datos. Para ajustar la retención añadir al command del contenedor en docker-compose.yml:

```yaml
  prometheus:
    image: prom/prometheus:latest
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--storage.tsdb.retention.time=30d'    # 30 días de retención
      - '--storage.tsdb.retention.size=5GB'    # Máximo 5GB de datos
    volumes:
      - ./prometheus:/etc/prometheus
      - ./prometheus/data:/prometheus           # Volumen para datos
    ports:
      - "9090:9090"
    restart: always
```

> ⚠️ Si se añade el volumen de datos de Prometheus, crear la carpeta y ajustar permisos: `mkdir -p ~/homelab/prometheus/data && chown -R 65534:65534 ~/homelab/prometheus/data`

### 🌐 Acceso desde el móvil vía Tailscale

Con Tailscale instalado en el móvil (iOS o Android), todos los servicios del homelab son accesibles desde cualquier red usando las IPs Tailscale:

| Servicio | URL desde Tailscale |
|---|---|
| 🛡️ Pi-hole | `http://100.70.255.51:8080/admin` |
| 📊 Netdata | `http://100.70.255.51:19999` |
| 🔁 Syncthing | `http://100.70.255.51:8384` |
| 📈 Grafana | `https://grafana.TU-DOMINIO` |
| 👁️ Uptime Kuma | `https://kuma.TU-DOMINIO` |

### 🔔 Alertas de renovación de certificados

Para recordar renovar los certificados SSL antes de que expiren, añadir un monitor en Uptime Kuma que verifique la validez del certificado:

1. En Uptime Kuma → Add New Monitor
2. **Monitor Type**: HTTPS
3. **URL**: `https://TU-DOMINIO`
4. Activar **Certificate Expiry Notification**
5. Configurar alerta cuando quedan menos de 14 días

---

## 🐛 Resolución de problemas

### 🐳 Docker y contenedores

#### Contenedor en bucle de reinicios

```bash
# Ver los últimos 50 mensajes de log
docker logs NOMBRE --tail 50

# Ver estado detallado
docker inspect NOMBRE | python3 -m json.tool | grep -A 5 '"State"'
```

| Causa | Síntoma en logs | Solución |
|---|---|---|
| Permisos en carpeta de datos | `permission denied` al abrir archivos | `chown -R UID:UID ~/homelab/SERVICIO/` |
| Error de sintaxis YAML | `did not find expected key` | `docker compose config` para validar |
| Puerto ocupado | `address already in use :PUERTO` | `ss -tlnp \| grep PUERTO` |
| Watchtower API antigua | `client version X is too old` | Añadir `DOCKER_API_VERSION=1.54` |
| Syncthing sin permisos | `operation not permitted` | `chown -R 1000:1000 ~/homelab/syncthing/` |

#### Error de sintaxis YAML en docker-compose.yml

```bash
# Validar sintaxis antes de aplicar
docker compose config

# El error más frecuente es indentación incorrecta en "environment":
# CORRECTO (4 espacios, al nivel de "volumes"):
  servicio:
    volumes:
      - ./datos:/datos
    environment:         ← 4 espacios
      - VARIABLE=valor

# INCORRECTO (2 espacios, al nivel del nombre del servicio):
  servicio:
    volumes:
      - ./datos:/datos
  environment:           ← 2 espacios (ERROR)
      - VARIABLE=valor
```

### 🌐 Red y DNS

#### Puerto 53 ocupado por systemd-resolved

El síntoma es que AdGuard o Pi-hole no arrancan con `address already in use :53`:

```bash
systemctl disable systemd-resolved
systemctl stop systemd-resolved
echo "nameserver 1.1.1.1" > /etc/resolv.conf
docker compose up -d --force-recreate adguardhome
```

#### Interfaz de red en estado DOWN

```bash
# Identificar nombre de la interfaz
ip link show

# Levantar y obtener IP
ip link set enp2s0 up   # sustituir enp2s0 por el nombre real
dhclient enp2s0

# Verificar IP
ip a show enp2s0
```

### 📊 Prometheus y Grafana

#### Target en estado DOWN

```bash
# Verificar conectividad directa
curl http://IP-TARGET:PUERTO/metrics | head -5

# Verificar que el contenedor corre
docker ps | grep NOMBRE

# Ver si escucha en el puerto
ss -tlnp | grep PUERTO
```

#### Grafana muestra "No data"

En este orden:
1. Verificar en `http://TU-IP:9090/targets` que el target está **UP**
2. Comprobar los filtros `Job` e `Instance` en el dashboard
3. Usar **Explore** en Grafana para probar la query directamente
4. Verificar que el contenedor tiene volumen persistente montado

**Para Windows** — verificar métricas disponibles:
```bash
curl -s "http://TU-IP:9090/api/v1/label/__name__/values" | python3 -m json.tool | grep -i windows | grep -i mem
```

#### Dashboards perdidos tras reiniciar Grafana

```bash
# Verificar si hay volumen montado
docker inspect homelab-grafana-1 | grep -A 5 "Mounts"

# Si muestra "Mounts": [] — añadir volumen:
mkdir -p ~/homelab/grafana/data
chown -R 472:472 ~/homelab/grafana/data
# Añadir en docker-compose.yml: - ./grafana/data:/var/lib/grafana
docker compose up -d --force-recreate grafana
```

### ⚡ n8n y notificaciones

#### Error: Invalid character in header content ["x-ntfy-title"]

Causa: emojis en el header HTTP (viola RFC 7230).

```
# CORRECTO — solo texto ASCII en el header
X-Ntfy-Title: {{ $('Webhook').item.json.body.alerts[0].labels.alertname }}

# INCORRECTO — emoji en el header (CAUSA EL ERROR)
X-Ntfy-Title: 🔴 {{ $('Webhook').item.json.body.alerts[0].labels.alertname }}
```

#### Webhook no responde

1. En n8n → Executions: ¿hay ejecuciones recientes?
2. ¿El workflow está en estado **Published**? (no en draft)
3. ¿La URL en Grafana termina en `/webhook/` (producción) y no `/webhook-test/`?
4. ¿El contenedor n8n está corriendo? `docker ps | grep n8n`

#### La instancia aparece vacía en las alertas

Causa: la query de CPU usa `avg()` sin `by(instance)`. Cambiar a `avg by(instance)()`.

### 🕳️ Pi-hole

#### Error 403 desde red Tailscale

```bash
echo "WEBSERVER_ALLOW_SUBNET=100.64.0.0/10" >> ~/homelab/pihole/etc-pihole/pihole-FTL.conf
docker compose restart pihole
```

#### Contraseña incorrecta (v6+)

```bash
# El comando antiguo "pihole -a -p" ya no funciona
docker exec -it pihole pihole setpassword 'NUEVA_PASSWORD'
```

---

## 🔧 Mantenimiento

### ✅ Verificar estado del sistema

```bash
# Estado de todos los contenedores
docker compose ps

# Uso de recursos en tiempo real
docker stats --no-stream

# Logs de un servicio específico
docker compose logs -f SERVICIO --tail 100

# Espacio en disco
df -h
docker system df

# Ver qué carpeta ocupa más
du -sh ~/homelab/*/
```

### 🔄 Actualizaciones manuales

```bash
cd ~/homelab
docker compose pull          # Descargar nuevas imágenes
docker compose up -d         # Recrear contenedores
docker image prune -f        # Eliminar imágenes antiguas
```

### 📅 Renovar certificados SSL de Tailscale

```bash
# Generar nuevo certificado (cada 90 días)
tailscale cert NOMBRE.tail-XXXXX.ts.net
mv NOMBRE.tail-XXXXX.ts.net.* ~/homelab/certs/
# Luego actualizar en NPM: eliminar el antiguo y subir los nuevos archivos
```

### 🧹 Liberar espacio en disco

```bash
# Eliminar imágenes no usadas
docker image prune -f

# Eliminar volúmenes huérfanos (verificar antes)
docker volume ls -f dangling=true
docker volume prune

# Limpiar logs de Docker acumulados
# Ver cuánto ocupan
find /var/lib/docker/containers -name "*.log" | xargs du -sh | sort -h | tail -20

# Truncar log de un contenedor específico
truncate -s 0 $(docker inspect --format='{{.LogPath}}' NOMBRE_CONTENEDOR)
```

### 📋 Tabla de volumenes críticos

| Servicio | Volumen | Consecuencia sin él |
|---|---|---|
| 🔐 Vaultwarden | `./vaultwarden/data:/data` | Todas las contraseñas (IRRECUPERABLE) |
| 📈 Grafana | `./grafana/data:/var/lib/grafana` | Dashboards, alertas, usuarios |
| ⚡ n8n | `./n8n/data:/home/node/.n8n` | Workflows, credenciales Telegram |
| 🛡️ AdGuard | `./adguard/conf:/opt/adguardhome/conf` | Listas, reglas DNS, configuración |
| 🕳️ Pi-hole | `./pihole/etc-pihole:/etc/pihole` | Listas, estadísticas |
| 🔁 Syncthing | `./syncthing/config:/var/syncthing/config` | Identidad, pares, carpetas |
| 🐋 Portainer | `./portainer/data:/data` | Configuración, usuarios |

---

## 📚 Referencias

### 🔗 Herramientas utilizadas

| Herramienta | URL oficial | Para qué se usa |
|---|---|---|
| Docker | docker.com | Contenedores |
| Grafana | grafana.com | Visualización de métricas |
| Prometheus | prometheus.io | Base de datos de métricas |
| AdGuard Home | github.com/AdguardTeam/AdGuardHome | DNS con filtrado |
| Pi-hole | pi-hole.net | DNS secundario con filtrado |
| Tailscale | tailscale.com | VPN mesh |
| Nginx Proxy Manager | nginxproxymanager.com | Reverse proxy + SSL |
| Vaultwarden | github.com/dani-garcia/vaultwarden | Gestor de contraseñas |
| n8n | n8n.io | Automatización de workflows |
| ntfy | ntfy.sh | Notificaciones push |
| Uptime Kuma | github.com/louislam/uptime-kuma | Monitorización de disponibilidad |
| Netdata | netdata.cloud | Monitorización en tiempo real |
| Syncthing | syncthing.net | Sincronización de archivos |
| Watchtower | github.com/containrrr/watchtower | Actualización automática Docker |
| Homarr | homarr.dev | Dashboard de inicio |

### 📖 Recursos adicionales

- 🌐 **awesome-selfhosted**: github.com/awesome-selfhosted/awesome-selfhosted — lista exhaustiva de servicios self-hosted
- 🔧 **Proxmox Helper Scripts**: tteck.github.io/Proxmox — scripts para instalar servicios en LXC
- 👥 **r/homelab**: reddit.com/r/homelab — comunidad de homelabbers
- 👥 **r/selfhosted**: reddit.com/r/selfhosted — comunidad de self-hosting

---

*📅 Documentación generada a partir de implementación real — Marzo 2026*  
*🔒 Sin información sensible: IPs, contraseñas y tokens han sido sustituidos por placeholders*
