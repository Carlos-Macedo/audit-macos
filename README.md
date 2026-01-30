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
- Número de serie

### Seguridad
- Estado del bloqueo de pantalla y tiempo configurado
- Estado del firewall
- Estado del tiempo de uso de pantalla (No permitido por el sistema operativo)

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

### FileVault (cifrado de disco)
- Verifica si el disco del equipo está cifrado con FileVault.
- El cifrado protege la información en caso de pérdida o robo del equipo.
- Se reporta únicamente el estado (activado / desactivado).

### SIP – System Integrity Protection
- Comprueba el estado de SIP, una tecnología de seguridad de macOS que protege archivos y procesos críticos del sistema.
- SIP evita modificaciones no autorizadas incluso por usuarios con privilegios de administrador.
- Se reporta como activado o desactivado.

### SSH (acceso remoto)
- Verifica si el servicio SSH está habilitado en el equipo.
- Cuenta la cantidad de sesiones SSH activas al momento de la auditoría.
- Útil para detectar accesos remotos o sesiones abiertas.

### SSH (acceso remoto)
- Verifica si el servicio SSH está habilitado en el equipo.
- Cuenta la cantidad de sesiones SSH activas al momento de la auditoría.
- Útil para detectar accesos remotos o sesiones abiertas.

---

## Limitaciones conocidas

Debido a las políticas de seguridad y privacidad de macOs, existen ciertos datos que no pueden ser obtenidos automáticamente por scripts, especialmente en versiones modernas del SO y en equipos con Apple Silicon (M1, M2, M3,...)

### Tiempo de uso de pantalla (Screen Time)
- macOS restringe el acceso programático a la información detallada de Tiempo de uso.
- No es posible obtener:
  - Uso diario por aplicación
  - Uso semanal
  - Historial de actividad por horas
- El script únicamente puede indicar si la funcionalidad está configurada o no verificable, dependiendo de la versión del sistema.

### Bloqueo de pantalla
- En equipos Apple Silicon y versiones recientes de macOS (Sonoma / Tahoe), Apple limita el acceso a ciertos parámetros del bloqueo de pantalla.
- El script puede:
  - Detectar configuraciones básicas
  - Informar cuando la verificación completa no es posible automáticamente
- En equipos Intel y versiones anteriores, la detección suele ser más precisa.

### Firewall y configuraciones del sistema
- Algunas preferencias ya no se almacenan en archivos .plist accesibles directamente.
- El script utiliza métodos alternativos y compatibles según la versión de macOS, pero en algunos casos solo puede reportar el estado general (activado / desactivado).

### Permisos del sistema
- El script no solicita permisos elevados ni desactiva protecciones del sistema.
- No intenta acceder a bases de datos internas protegidas por macOS.
- Esto es intencional para mantener la auditoría:
  - Segura
  - No intrusiva
  - Apta para uso corporativo

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

## Jalar cambios nuevos al script

### Abrir la terminal del SO y entrar a la carpeta del proyecto
```bash
cd audit-macos
```

### Descargar las actualizaciones
```bash
git pull
```
