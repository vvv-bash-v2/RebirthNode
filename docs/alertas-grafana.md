# 🚨 Alertas de Grafana — Referencia completa

Las 9 reglas de alerta del homelab cubren los 3 equipos monitorizados. Todas usan el mismo Contact Point (`Ntfy_Homelab`) y el mismo Evaluation Group (`homelab`, intervalo 1m, pending period 1m).

## ⚙️ Contact Point

| Campo | Valor |
|---|---|
| Name | `Ntfy_Homelab` |
| Integration | Webhook |
| URL | `http://n8n:5678/webhook/grafana-alerts` |
| HTTP Method | POST |
| Username | usuario de ntfy |
| Password | contraseña de ntfy |

## 📋 Reglas de alerta

### 🖥️ Folder: HomeLab-Principal

| Nombre | Query | Condición |
|---|---|---|
| HomeLab - CPU Alta | `100 - (avg by(instance) (rate(node_cpu_seconds_total{mode="idle", job="node"}[5m])) * 100)` | IS ABOVE `85` |
| HomeLab - RAM Alta | `(1 - (node_memory_MemAvailable_bytes{job="node"} / node_memory_MemTotal_bytes{job="node"})) * 100` | IS ABOVE `90` |
| HomeLab - Caída | `up{job="node"}` | IS BELOW `1` |

### 🖧 Folder: Gigabyte

| Nombre | Query | Condición |
|---|---|---|
| Gigabyte - CPU Alta | `100 - (avg by(instance) (rate(node_cpu_seconds_total{mode="idle", job="node-secundario"}[5m])) * 100)` | IS ABOVE `85` |
| Gigabyte - RAM Alta | `(1 - (node_memory_MemAvailable_bytes{job="node-secundario"} / node_memory_MemTotal_bytes{job="node-secundario"})) * 100` | IS ABOVE `90` |
| Gigabyte - Caída | `up{job="node-secundario"}` | IS BELOW `1` |

### 🪟 Folder: Windows-PC

| Nombre | Query | Condición |
|---|---|---|
| Windows - CPU Alta | `100 - (avg by(instance) (rate(windows_cpu_time_total{mode="idle", job="windows"}[5m])) * 100)` | IS ABOVE `85` |
| Windows - RAM Alta | `(1 - (windows_memory_physical_free_bytes{job="windows"} / windows_memory_physical_total_bytes{job="windows"})) * 100` | IS ABOVE `90` |
| Windows - Caída | `up{job="windows"}` | IS BELOW `1` |

## ⚠️ Notas importantes

### ¿Por qué `avg by(instance)` y no `avg()`?

Sin `by(instance)`, Prometheus agrupa todas las instancias y el label `instance` desaparece de la alerta. Con él, el label se preserva y la notificación incluye información sobre qué equipo disparó la alerta.

### ¿Las alertas se repiten mientras el equipo está caído?

**No.** Grafana dispara la notificación una vez al pasar a estado `Firing` y otra al recuperarse (`Normal/OK`). Si quieres recordatorios mientras sigue caído, configurar **"Resend alert notifications every: 1h"** en la regla.

### Métricas de Windows — Versiones recientes

| ✅ Usar | ❌ No usar (obsoleto) |
|---|---|
| `windows_memory_physical_free_bytes` | `windows_os_physical_memory_free_bytes` |
| `windows_memory_physical_total_bytes` | `windows_cs_physical_memory_bytes` |

### Header X-Ntfy-Title — Sin emojis

El header HTTP `X-Ntfy-Title` **nunca puede contener emojis**. Causa el error `Invalid character in header content ["x-ntfy-title"]`. Los emojis sí pueden usarse en el body del mensaje.

## 🧪 Probar una alerta

1. Editar la alerta → cambiar umbral a `0.1`
2. Guardar y esperar ~1-2 minutos
3. Verificar que llega la notificación en Telegram
4. Restaurar el umbral original
