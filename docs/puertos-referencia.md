# 🔌 Referencia de puertos

## 🖥️ Homelab Principal

| Servicio | Puerto externo | Puerto interno | Protocolo |
|---|---|---|---|
| AdGuard Home (DNS) | 53 | 53 | TCP/UDP |
| AdGuard Home (UI) | 3002 | 3000 | TCP |
| Prometheus | 9090 | 9090 | TCP |
| Grafana | 3000 | 3000 | TCP |
| Uptime Kuma | 3001 | 3001 | TCP |
| Node Exporter | — | 9100 | TCP (solo Docker) |
| AdGuard Exporter | 9617 | 9617 | TCP |
| Nginx Proxy Manager (HTTP) | 80 | 80 | TCP |
| Nginx Proxy Manager (HTTPS) | 443 | 443 | TCP |
| Nginx Proxy Manager (UI) | 81 | 81 | TCP |
| Vaultwarden | 8082 | 80 | TCP |
| ntfy | 8083 | 80 | TCP |
| n8n | 5678 | 5678 | TCP |
| Portainer | 9443 | 9443 | TCP |
| Homarr | 7575 | 7575 | TCP |
| Syncthing (UI) | 8384 | 8384 | TCP |
| Syncthing (sync) | 22000 | 22000 | TCP/UDP |

## 🖧 Homelab Secundario

| Servicio | Puerto externo | Protocolo | Notas |
|---|---|---|---|
| Pi-hole (DNS) | 53 | TCP/UDP | DNS secundario |
| Pi-hole (UI) | 8080 | TCP | Panel admin |
| Netdata | 19999 | TCP | `network_mode: host` |
| Node Exporter | 9100 | TCP | `network_mode: host` |
| Blocky (DNS) | 5353 | TCP/UDP | DNS caché alternativo |
| Blocky (API) | 4000 | TCP | Estadísticas |
| Syncthing (UI) | 8384 | TCP | |
| Syncthing (sync) | 22000 | TCP/UDP | |

## 🪟 PC Windows

| Servicio | Puerto | Protocolo |
|---|---|---|
| Windows Exporter | 9182 | TCP |

## 🌐 Tailscale

Todos los servicios son accesibles desde la IP Tailscale de cada equipo (rango `100.x.x.x`).
No es necesario abrir ningún puerto en el router.
