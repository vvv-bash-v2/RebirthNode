# 🐛 Resolución de problemas

## 🐳 Docker

### Contenedor en bucle de reinicios
```bash
docker logs NOMBRE --tail 50
docker inspect NOMBRE | grep -A 10 '"State"'
```

| Causa | Solución |
|---|---|
| Permisos en carpeta de datos | `chown -R UID:UID ~/homelab/SERVICIO/` |
| Error YAML (`environment must be a mapping`) | `docker compose config` para validar |
| Puerto 53 ocupado | Ver sección DNS abajo |
| Watchtower: `client version X is too old` | Añadir `DOCKER_API_VERSION=1.54` |
| Syncthing: `permission denied` | `chown -R 1000:1000 ~/homelab/syncthing/` |
| Grafana: sin datos tras reinicio | Añadir volumen + `chown -R 472:472 ~/homelab/grafana/data` |

### Error de indentación YAML
```yaml
# CORRECTO (4 espacios para environment, al nivel de volumes)
  servicio:
    volumes:
      - ./datos:/datos
    environment:        ← 4 espacios
      - VARIABLE=valor

# INCORRECTO (2 espacios — ERROR)
  servicio:
    volumes:
      - ./datos:/datos
  environment:          ← 2 espacios = ERROR
      - VARIABLE=valor
```

---

## 🌐 Red y DNS

### Puerto 53 ocupado (`address already in use :53`)
```bash
systemctl disable systemd-resolved
systemctl stop systemd-resolved
echo "nameserver 1.1.1.1" > /etc/resolv.conf
docker compose restart adguardhome
```

### Interfaz de red en estado DOWN (Debian 12 minimal)
```bash
ip link show                          # Ver nombre de la interfaz
ip link set enp2s0 up                 # Levantar (sustituir nombre)
dhclient enp2s0                       # Obtener IP por DHCP
# Hacer permanente en /etc/network/interfaces:
# auto enp2s0
# iface enp2s0 inet dhcp
systemctl restart networking
```

### Pi-hole error 403 desde Tailscale
```bash
echo "WEBSERVER_ALLOW_SUBNET=100.64.0.0/10" >> ~/homelab/pihole/etc-pihole/pihole-FTL.conf
docker compose restart pihole
```

### Cambiar contraseña de Pi-hole (v6+)
```bash
# El comando antiguo "pihole -a -p" ya no funciona en v6+
docker exec -it pihole pihole setpassword 'NUEVA_PASSWORD'
```

---

## 📊 Prometheus y Grafana

### Target en estado DOWN
```bash
curl http://IP-TARGET:PUERTO/metrics | head -5
docker ps | grep NOMBRE_CONTENEDOR
ss -tlnp | grep PUERTO
```

### "No data" en paneles de Grafana
1. Verificar que el target está **UP** en `http://TU-IP:9090/targets`
2. Comprobar los filtros `Job` e `Instance` del dashboard
3. Usar **Explore** en Grafana para probar la query directamente
4. Verificar que el contenedor tiene volumen persistente montado

### Dashboards perdidos tras reiniciar Grafana
```bash
docker inspect homelab-grafana-1 | grep -A 5 "Mounts"
# Si muestra "Mounts": [] — añadir volumen:
mkdir -p ~/homelab/grafana/data
chown -R 472:472 ~/homelab/grafana/data
# Añadir en docker-compose.yml: - ./grafana/data:/var/lib/grafana
docker compose up -d --force-recreate grafana
```

### Reset de contraseña de Grafana
```bash
docker exec -it $(docker ps -qf name=grafana) grafana cli admin reset-admin-password NUEVA_PASSWORD
```

### Métricas de Windows no disponibles
```bash
# Ver qué métricas de memoria existen realmente:
curl -s "http://TU-IP:9090/api/v1/label/__name__/values" \
  | python3 -m json.tool | grep -i windows | grep -i mem
```

---

## ⚡ n8n y notificaciones

### `Invalid character in header content ["x-ntfy-title"]`
**Causa**: emojis en el header HTTP (viola RFC 7230).  
**Solución**: eliminar completamente los emojis del valor del header `X-Ntfy-Title`. Los emojis **sí** pueden usarse en el body.

```
# CORRECTO
X-Ntfy-Title: {{ $('Webhook').item.json.body.alerts[0].labels.alertname }}

# INCORRECTO (CAUSA EL ERROR)
X-Ntfy-Title: 🔴 {{ $('Webhook').item.json.body.alerts[0].labels.alertname }}
```

### Webhook no recibe datos de Grafana
1. ¿El workflow está en estado **Published**? (no draft)
2. ¿La URL termina en `/webhook/` (producción) y no en `/webhook-test/`?
3. ¿El contenedor n8n está corriendo? `docker ps | grep n8n`

### La instancia aparece vacía en las alertas
**Causa**: la query de CPU usa `avg()` sin `by(instance)`.  
**Solución**: cambiar a `avg by(instance)()` en todas las queries de CPU.

---

## 🔄 Watchtower

### Error `client version X is too old`
```bash
# Actualizar Docker
curl -fsSL https://get.docker.com | sh
systemctl restart docker

# Recrear Watchtower
docker compose stop watchtower
docker compose rm -f watchtower
docker compose up -d watchtower
```

---

## 🔁 Syncthing

### Error de permisos al arrancar
```bash
chown -R 1000:1000 ~/homelab/syncthing/
docker compose up -d --force-recreate syncthing
```
