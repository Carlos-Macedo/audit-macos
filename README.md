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

### Velocidad de Internet
- Los valores de descarga, subida y latencia son aproximados y dependen de la red.
- En redes corporativas algunos tests pueden estar bloqueados.

---

## Cómo usar el script

### Clonar el repositorio

```bash
git clone https://github.com/Carlos-Macedo/audit-macos.git
cd audit-macos
```

### Dar permisos de ejecución

```bash
chmod +x audit_mac.command
```

### Ejecutar el script

```bash
./audit_mac.command
```
### También puedes ejecutarlo con doble clic desde la carpeta

- Abre la carpeta `audit-macos`
- Haz doble clic en `audit_mac.command`

## Archivos generados

Al ejecutarse, el script genera en la misma carpeta:

- `audit_<NOMBRE_EQUIPO>.json`
- `audit_<NOMBRE_EQUIPO>.txt`

### Abrir la terminal y entrar a la carpeta del proyecto
```bash
cd audit-macos
```

### Descargar las actualizaciones
```bash
git pull
```
