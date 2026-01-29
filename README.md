# Auditoría técnica de equipos macOS

Este repositorio contiene un script de auditoría técnica para equipos **macOS**, diseñado para generar un reporte detallado del estado del equipo de forma **rápida, local y sin dependencias externas**.

El script genera dos archivos:
- **JSON** → para análisis técnico o integración con sistemas
- **TXT** → para revisión humana y auditorías internas

---

## ¿Qué información recopila?

El script realiza una auditoría **solo en el equipo local** y obtiene:

### Sistema
- Nombre del equipo
- Versión de macOS
- Build del sistema
- Arquitectura (Intel / Apple Silicon)
- Fecha de escaneo

### Usuarios
- Usuarios reales del equipo (excluye cuentas de sistema)

### Hardware
- CPU
- Memoria RAM
- Modelo del equipo
- Tipo de disco
- Uso de disco

### Seguridad
- Estado del bloqueo de pantalla y tiempo configurado
- Estado del firewall
- Estado del tiempo de uso de pantalla

### Actividad
- Tiempo de inactividad
- Tiempo encendido
- Carga promedio del sistema (1, 5 y 15 minutos)

### Certificados
- Certificados instalados en el sistema y usuario
- Cantidad de identidades con clave privada

### Archivos sensibles (solo en el usuario actual)
- Conteo de archivos por tipo:
  - `.pfx`
  - `.key`
  - `.pem`
  - `.pdf`
  - `.dmg`
- Ejemplos de rutas encontradas (limitadas)

---

## Cómo usar el script

### Clonar el repositorio

```bash
git clone https://github.com/Carlos-Macedo/audit-macos.git
cd audit-macos

