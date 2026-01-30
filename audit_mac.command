#!/bin/bash

# ==================================================
# Auditoría técnica de equipos macOS
# ==================================================

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SAFE_NAME=$(scutil --get ComputerName | tr ' ' '_')
OUTPUT="$SCRIPT_DIR/audit_${SAFE_NAME}.json"
FECHA=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# ==================================================
# Sistema
# ==================================================
EQUIPO=$(scutil --get ComputerName)
SISTEMA_OPERATIVO="macOS"
VERSION_MACOS=$(sw_vers -productVersion)
BUILD_MACOS=$(sw_vers -buildVersion)
ARQUITECTURA=$(uname -m)

# ==================================================
# Usuarios reales del equipo (UI macOS)
# ==================================================
USUARIOS=$(dscl . list /Users UniqueID | awk '$2 >= 500 {print $1}')

# ==================================================
# Hardware
# ==================================================
CPU=$(sysctl -n machdep.cpu.brand_string)
RAM_GB=$(($(sysctl -n hw.memsize) / 1024 / 1024 / 1024))
MODELO=$(system_profiler SPHardwareDataType | awk -F": " '/Model Identifier/ {print $2}')
TIPO_DISCO=$(system_profiler SPStorageDataType | awk -F": " '/Physical Drive/ {getline; print $2; exit}')
USO_DISCO=$(df -H / | tail -1)
SERIAL_NUMBER=$(system_profiler SPHardwareDataType | awk -F": " '/Serial Number/ {print $2}')

# ==================================================
# Seguridad
# ==================================================
ASK_PASSWORD=$(defaults read com.apple.screensaver askForPassword 2>/dev/null || echo 0)
ASK_DELAY=$(defaults read com.apple.screensaver askForPasswordDelay 2>/dev/null || echo 0)

SCREEN_LOCK_ENABLED=false
SCREEN_LOCK_GRACE=$ASK_DELAY

if [ "$ASK_PASSWORD" == "1" ]; then
  SCREEN_LOCK_ENABLED=true
else
  # Fallback legacy (Intel / macOS antiguos)
  SCREEN_LOCK_DELAY=$(defaults -currentHost read com.apple.screensaver idleTime 2>/dev/null || echo 0)
  if [ "$SCREEN_LOCK_DELAY" -gt 0 ]; then
    SCREEN_LOCK_ENABLED=true
    SCREEN_LOCK_GRACE=$SCREEN_LOCK_DELAY
  fi
fi


SCREEN_TIME_RAW=$(defaults read /Library/Preferences/com.apple.ScreenTime.plist ScreenTimeEnabled 2>/dev/null || echo 0)
[ "$SCREEN_TIME_RAW" == "1" ] && SCREEN_TIME_ENABLED=true || SCREEN_TIME_ENABLED=false

# ==================================================
# Firewall (compatible con macOS antiguos y modernos)
# ==================================================

FIREWALL_ENABLED=false

# Método moderno (Sonoma / Tahoe)
if /usr/libexec/ApplicationFirewall/socketfilterfw --getglobalstate 2>/dev/null | grep -qi "enabled"; then
  FIREWALL_ENABLED=true
else
  # Fallback para macOS antiguos (Ventura y anteriores)
  FIREWALL_STATE=$(defaults read /Library/Preferences/com.apple.alf globalstate 2>/dev/null || echo 0)
  if [[ "$FIREWALL_STATE" == "1" || "$FIREWALL_STATE" == "2" ]]; then
    FIREWALL_ENABLED=true
  fi
fi


# ==================================================
# Actividad (datos legibles)
# ==================================================
IDLE_TIME_SEC=$(ioreg -c IOHIDSystem | awk '/HIDIdleTime/ {print int($NF/1000000000); exit}')

UPTIME_HUMANO=$(uptime | sed 's/.*up \([^,]*\),.*/\1/')

LOAD_RAW=$(sysctl -n vm.loadavg)
LOAD_1=$(echo "$LOAD_RAW" | awk '{print $2}')
LOAD_5=$(echo "$LOAD_RAW" | awk '{print $3}')
LOAD_15=$(echo "$LOAD_RAW" | awk '{print $4}')

# ==================================================
# Aplicaciones instaladas
# ==================================================
APLICACIONES=$(ls /Applications | sed 's/\.app$//g' | sort)

# ==================================================
# Certificados (modelo seguro macOS)
# ==================================================
CERT_PUBLICOS=$(
for KEYCHAIN in \
  "/Library/Keychains/System.keychain" \
  "$HOME/Library/Keychains/login.keychain-db"
do
  security find-certificate -a "$KEYCHAIN" 2>/dev/null \
  | awk -F\" '/"alis"/ {print $4}'
done | sort -u
)

CANT_IDENTIDADES=$(security find-identity -p all 2>/dev/null | grep -c "\"")

# ==================================================
# Archivos sensibles
# ==================================================
COUNT_PFX=$(find "$HOME" -type f -name "*.pfx" 2>/dev/null | wc -l | tr -d ' ')
COUNT_KEY=$(find "$HOME" -type f -name "*.key" 2>/dev/null | wc -l | tr -d ' ')
COUNT_PEM=$(find "$HOME" -type f -name "*.pem" 2>/dev/null | wc -l | tr -d ' ')
COUNT_PDF=$(find "$HOME" -type f -name "*.pdf" 2>/dev/null | wc -l | tr -d ' ')
COUNT_DMG=$(find "$HOME" -type f -name "*.dmg" 2>/dev/null | wc -l | tr -d ' ')

TOTAL_SENSIBLES=$((COUNT_PFX + COUNT_KEY + COUNT_PEM + COUNT_PDF + COUNT_DMG))

DETALLE_GENERAL=$(find "$HOME" -type f \
  \( -name "*.pfx" -o -name "*.key" -o -name "*.pem" -o -name "*.dmg" \) \
  2>/dev/null | head -20)

DETALLE_PDF=$(find "$HOME" -type f -name "*.pdf" 2>/dev/null | head -20)

# ==================================================
# Velocidad de Internet
# ==================================================
TMP_FILE="/tmp/audit_speed_test_${SAFE_NAME}.bin"
dd if=/dev/urandom of="$TMP_FILE" bs=1m count=5 2>/dev/null

START_DL=$(date +%s)
curl -L -o /dev/null https://speed.hetzner.de/100MB.bin --max-time 20 >/dev/null 2>&1
END_DL=$(date +%s)

TIME_DL=$((END_DL - START_DL))
if [ "$TIME_DL" -gt 0 ]; then
  SPEED_DOWNLOAD_MBPS=$(( (100 * 8) / TIME_DL ))
else
  SPEED_DOWNLOAD_MBPS=0
fi

START_UL=$(date +%s)
curl -X POST --data-binary @"$TMP_FILE" https://httpbin.org/post --max-time 20 >/dev/null 2>&1
END_UL=$(date +%s)

TIME_UL=$((END_UL - START_UL))
if [ "$TIME_UL" -gt 0 ]; then
  SPEED_UPLOAD_MBPS=$(( (5 * 8) / TIME_UL ))
else
  SPEED_UPLOAD_MBPS=0
fi

PING_TIME=$(ping -c 3 8.8.8.8 | awk -F'/' 'END {print $5 " ms"}')
rm -f "$TMP_FILE"

# ==================================================
# Generación del JSON
# ==================================================
cat <<EOF > "$OUTPUT"
{
  "equipo": "$EQUIPO",
  "sistema_operativo": "$SISTEMA_OPERATIVO",
  "version_macos": "$VERSION_MACOS",
  "build_macos": "$BUILD_MACOS",
  "arquitectura": "$ARQUITECTURA",
  "fecha_escaneo": "$FECHA",

  "usuarios_equipo": [
$(echo "$USUARIOS" | sed 's/^/    "/;s/$/",/' | sed '$ s/,$//')
  ],

  "hardware": {
    "cpu": "$CPU",
    "ram_gb": $RAM_GB,
    "modelo": "$MODELO",
    "tipo_disco": "$TIPO_DISCO",
    "uso_disco": "$USO_DISCO",
    "numero_serie": "$SERIAL_NUMBER"
  },

  "seguridad": {
    "bloqueo_pantalla": {
      "activado": $SCREEN_LOCK_ENABLED,
      "tiempo_segundos": $SCREEN_LOCK_DELAY
    },
    "firewall_activado": $FIREWALL_ENABLED,
    "tiempo_uso_pantalla_activado": "estado": "no verificable automáticamente (restricción macOS)"
  },

  "actividad": {
    "tiempo_inactividad_segundos": $IDLE_TIME_SEC,
    "tiempo_actividad": "$UPTIME_HUMANO",
    "media_actividad": {
      "1_min": $LOAD_1,
      "5_min": $LOAD_5,
      "15_min": $LOAD_15
    }
  },
  "internet": {
    "descarga_mbps": $SPEED_DOWNLOAD_MBPS,
    "subida_mbps": $SPEED_UPLOAD_MBPS,
    "latencia": "$PING_TIME"
  },

  "certificados": {
    "certificados_publicos": [
$(echo "$CERT_PUBLICOS" | sed 's/^/      "/;s/$/",/' | sed '$ s/,$//')
    ],
    "identidades_con_clave_privada": $CANT_IDENTIDADES
  },

  "archivos_sensibles": {
    "total": $TOTAL_SENSIBLES,
    "por_tipo": {
      "pfx": $COUNT_PFX,
      "key": $COUNT_KEY,
      "pem": $COUNT_PEM,
      "pdf": $COUNT_PDF,
      "dmg": $COUNT_DMG
    },
    "ejemplos": {
      "general": [
$(echo "$DETALLE_GENERAL" | sed 's/^/        "/;s/$/",/' | sed '$ s/,$//')
      ],
      "pdf": [
$(echo "$DETALLE_PDF" | sed 's/^/        "/;s/$/",/' | sed '$ s/,$//')
      ]
    }
  }
}
EOF

OUTPUT_TXT="$SCRIPT_DIR/audit_${SAFE_NAME}.txt"
# ==================================================
# Generación del TXT amigable
# ==================================================
cat <<EOF > "$OUTPUT_TXT"
========================================
AUDITORÍA TÉCNICA DE EQUIPO macOS
========================================

Equipo            : $EQUIPO
Fecha de escaneo  : $FECHA

----------------------------------------
SISTEMA
----------------------------------------
Sistema Operativo : $SISTEMA_OPERATIVO
Versión macOS     : $VERSION_MACOS
Build             : $BUILD_MACOS
Arquitectura      : $ARQUITECTURA

----------------------------------------
USUARIOS DEL EQUIPO
----------------------------------------
$(echo "$USUARIOS" | sed 's/^/- /')

----------------------------------------
HARDWARE
----------------------------------------
CPU               : $CPU
Memoria RAM       : ${RAM_GB} GB
Modelo            : $MODELO
Disco             : $TIPO_DISCO
Uso de disco      : $USO_DISCO
Número de serie   : $SERIAL_NUMBER

----------------------------------------
SEGURIDAD
----------------------------------------
Bloqueo pantalla  : $( [ "$SCREEN_LOCK_ENABLED" = true ] && echo "Activado ($SCREEN_LOCK_DELAY segundos)" || echo "Desactivado" )
Firewall          : $( [ "$FIREWALL_ENABLED" = true ] && echo "Activado" || echo "Desactivado" )
Tiempo de uso     : No verificable automáticamente, macOS restringe el acceso a esta información

----------------------------------------
ACTIVIDAD
----------------------------------------
Tiempo encendido  : $UPTIME_HUMANO
Inactividad       : $IDLE_TIME_SEC segundos

Carga promedio:
  - Último 1 min  : $LOAD_1
  - Últimos 5 min : $LOAD_5
  - Últimos 15 min: $LOAD_15

----------------------------------------
CERTIFICADOS
----------------------------------------
Certificados instalados:
$(echo "$CERT_PUBLICOS" | sed 's/^/- /')

Identidades con clave privada: $CANT_IDENTIDADES

----------------------------------------
ARCHIVOS SENSIBLES
----------------------------------------
Total encontrados : $TOTAL_SENSIBLES

Por tipo:
- PFX : $COUNT_PFX
- KEY : $COUNT_KEY
- PEM : $COUNT_PEM
- PDF : $COUNT_PDF
- DMG : $COUNT_DMG

----------------------------------------
VELOCIDAD DE INTERNET
----------------------------------------

- Descarga: $SPEED_DOWNLOAD_MBPS
- Subida: $SPEED_UPLOAD_MBPS
- Latencia: $PING_TIME

========================================
Fin del reporte
========================================
EOF

echo "Auditoría completada correctamente"
echo "Archivo generado:"
echo "   $OUTPUT"
echo "Archivo TXT generado:"
echo "   $OUTPUT_TXT"