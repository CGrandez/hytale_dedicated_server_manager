# Hytale Dedicated Server Manager

Un script de gestión automatizada para servidores dedicados de Hytale en Windows.

## 📋 Requisitos del Sistema

| Requisito | Especificación |
|-----------|---------------|
| **Sistema Operativo** | Windows, Linux, macOS (x64, arm64) |
| **Java** | **Java 25** ([Adoptium](https://adoptium.net/) recomendado) |
| **RAM Mínima** | 4GB (uso depende de view distance y jugadores) |
| **Espacio en Disco** | Mínimo 5GB libres |
| **Puerto** | 5520 UDP (QUIC) |

> [!IMPORTANT]
> Hytale usa el protocolo **QUIC sobre UDP**, no TCP. Asegúrate de configurar tu firewall correctamente.

---

## 🚀 Instalación

### Opción 1: Usando este Script (Recomendado)

1. Descarga o clona este repositorio
2. Ejecuta `setup.bat`
3. Selecciona `0. INSTALACIÓN INICIAL` para descargar todo desde cero

### Opción 2: Manual

Copia los archivos desde tu instalación del Launcher:
```
%appdata%\Hytale\install\release\package\game\latest
```

### Opción 3: Hytale Downloader CLI

```bash
# Descargar última versión
hytale-downloader-windows-amd64.exe

# Verificar actualizaciones del downloader
hytale-downloader-windows-amd64.exe -check-update

# Ver versión disponible en la nube
hytale-downloader-windows-amd64.exe -print-version
```

---

## 🔐 Autenticación Inicial

Al iniciar el servidor por primera vez, debes autenticarte:

1. Ejecuta el comando en la consola del servidor:
   ```
   /auth login device
   ```
2. Visita [accounts.hytale.com/device](https://accounts.hytale.com/device)
3. Ingresa el código proporcionado

> [!NOTE]
> La licencia estándar del juego permite hasta **100 servidores**.

---

## 📁 Estructura de Archivos

```
├── setup.bat                            # Script principal de gestión
├── hytale-downloader-windows-amd64.exe  # Herramienta oficial de descarga
├── HytaleServer.jar                     # Servidor (se descarga automáticamente)
├── Assets.zip                           # Assets del juego
├── config.json                          # Configuración del servidor
├── permissions.json                     # Permisos de usuarios
├── whitelist.json                       # Lista blanca
├── bans.json                            # Usuarios baneados
├── .cache/                              # Archivos optimizados
├── logs/                                # Logs del servidor
├── mods/                                # Mods (.zip o .jar)
├── universe/                            # Datos del mundo y jugadores
│   └── worlds/                          # Mundos individuales
│       └── [world_name]/
│           └── config.json              # Configuración por mundo
└── backups_actualizacion/               # Backups automáticos
```

---

## 🎮 Menú del Script (setup.bat)

| Opción | Función | Descripción |
|--------|---------|-------------|
| **0** | Instalación Inicial | Descarga el servidor desde cero |
| **1** | Comprobar Actualizaciones | Compara versión local vs nube |
| **2** | Actualizar Servidor | Descarga e instala automáticamente |
| **3** | Regenerar Esquemas | Ejecuta `--generate-schema` |
| **4** | Backup Manual | Crea un ZIP del mundo actual |
| **5** | Iniciar Servidor | Arranca con configuración óptima |
| **6** | Salir | Cierra el gestor |

### Variables Personalizables

Edita `setup.bat` para cambiar:

```batch
set WORLD_NAME=KKs 4K          :: Nombre del mundo
set OWNER=CGrandez              :: Propietario del servidor
```

---

## ⚙️ Configuración del Servidor

### Comando de Inicio del Script

```bash
java -Xms2G -Xmx4G --enable-native-access=ALL-UNNAMED -jar HytaleServer.jar \
    --assets Assets.zip \
    --universe universe \
    --owner-name "OWNER_NAME" \
    --backup \
    --backup-dir backup \
    --backup-max-count 4 \
    --backup-frequency 1440
```

### Optimización de Rendimiento (AOT Cache)

Para mejorar tiempos de arranque:

```bash
java -XX:AOTCache=HytaleServer.aot -jar HytaleServer.jar --assets Assets.zip
```

---

## 📚 Opciones de Línea de Comandos

### Configuración de Red

| Opción | Descripción | Valor por defecto |
|--------|-------------|-------------------|
| `-b, --bind <InetSocketAddress>` | Puerto de escucha | `0.0.0.0:5520` |
| `-t, --transport <TransportType>` | Tipo de transporte | `QUIC` |
| `--auth-mode <mode>` | Modo de autenticación | `AUTHENTICATED` |

**Modos de autenticación:**
- `authenticated` - Requiere cuenta Hytale válida
- `offline` - Sin autenticación online
- `insecure` - Sin verificación (solo desarrollo)

### Archivos y Directorios

| Opción | Descripción | Valor por defecto |
|--------|-------------|-------------------|
| `--assets <Path>` | Directorio/archivo de assets | `..\HytaleAssets` |
| `--universe <Path>` | Directorio del universo | - |
| `--mods <Path>` | Directorios de mods | - |
| `--world-gen <Path>` | Directorio de generación | - |
| `--prefab-cache <Path>` | Caché de prefabs | - |

### Backups Automáticos

| Opción | Descripción | Valor por defecto |
|--------|-------------|-------------------|
| `--backup` | Habilita backups automáticos | - |
| `--backup-dir <Path>` | Directorio de backups | - |
| `--backup-frequency <Integer>` | Frecuencia (minutos) | `30` |
| `--backup-max-count <Integer>` | Máximo de backups | `5` |

### Propietario y Permisos

| Opción | Descripción |
|--------|-------------|
| `--owner-name <String>` | Nombre del propietario |
| `--owner-uuid <UUID>` | UUID del propietario |
| `--allow-op` | Permite operadores |

### Validación y Depuración

| Opción | Descripción |
|--------|-------------|
| `--validate-assets` | Valida assets (sale con error si hay inválidos) |
| `--validate-prefabs [Option]` | Valida prefabs |
| `--validate-world-gen` | Valida generación de mundo |
| `--shutdown-after-validate` | Cierra después de validar |
| `--generate-schema` | Genera esquemas JSON y finaliza |
| `--disable-sentry` | Desactiva reportes (útil para desarrollo) |
| `--log <KeyValueHolder>` | Establece nivel de log |

### Opciones Avanzadas

| Opción | Descripción |
|--------|-------------|
| `--bare` | Ejecuta sin cargar mundos ni enlazar puertos |
| `--boot-command <String>` | Ejecuta comandos al iniciar |
| `--singleplayer` | Modo jugador único |
| `--disable-file-watcher` | Desactiva vigilancia de archivos |
| `--disable-asset-compare` | Desactiva comparación de assets |
| `--force-network-flush <Boolean>` | Fuerza flush de red (default: `true`) |

### Plugins (Experimental)

> [!WARNING]
> Los plugins están en fase experimental y pueden causar inestabilidad.

| Opción | Descripción |
|--------|-------------|
| `--accept-early-plugins` | Reconoce que cargar early plugins es experimental |
| `--early-plugins <Path>` | Directorios de early plugins |

---

## 🌐 Configuración de Firewall

### Windows Defender

```powershell
New-NetFirewallRule -DisplayName "Hytale Server" -Direction Inbound -Protocol UDP -LocalPort 5520 -Action Allow
```

### Linux (iptables)

```bash
sudo iptables -A INPUT -p udp --dport 5520 -j ACCEPT
```

### Linux (ufw)

```bash
sudo ufw allow 5520/udp
```

---

## 🎯 Configuración de Mundo

Cada mundo en `universe/worlds/[nombre]/config.json` puede configurar:

- Ticking habilitado/deshabilitado
- PvP activado/desactivado
- Daño por caída
- Configuración de world-gen

---

## ⚡ Mejores Prácticas

| Área | Recomendación |
|------|---------------|
| **View Distance** | Máximo **12 chunks** (384 bloques) - Mayor que Minecraft por defecto |
| **AOT Cache** | Usa `-XX:AOTCache=HytaleServer.aot` para arranques rápidos |
| **Desarrollo** | Usa `--disable-sentry` para evitar reportes de crashes de desarrollo |
| **Mods** | Coloca archivos `.zip` o `.jar` en la carpeta `mods/` |

---

## 🔗 Arquitectura Multiservidor

Hytale soporta nativamente (sin proxies externos como BungeeCord):

- **Player Referral** - Referir jugadores entre servidores
- **Connection Redirect** - Redirigir conexiones
- **Disconnect Fallback** - Fallback al desconectarse

Los desarrolladores pueden crear proxies personalizados usando Netty QUIC y los packets incluidos en `HytaleServer.jar`.

---

## 🔮 Características Futuras

- **Server Discovery Catalogue** - Catálogo de descubrimiento de servidores
- **Party System** - Sistema de party cross-server
- **Integrated Payment System** - Sistema de pagos integrado
- **First-Party API Endpoints** - Endpoints para datos de jugadores y telemetría

---

## 🔧 Solución de Problemas

| Problema | Solución |
|----------|----------|
| No se encuentra HytaleServer.jar | Ejecuta opción `0. INSTALACIÓN INICIAL` |
| Espacio insuficiente | Libera al menos **5GB** |
| Error de esquemas | Usa opción `3. REGENERAR ESQUEMAS` |
| No conecta | Verifica firewall UDP:5520 y NAT |
| Java no encontrado | Instala [Java 25 Adoptium](https://adoptium.net/) |

---

## 📌 Información de Versiones

| Componente | Versión |
|------------|---------|
| Downloader | `2026.01.09-49e5904` |
| HytaleServer | `v2026.01.17-4b0f30090 (release)` |

---

## 📖 Documentación Oficial

- [Hytale Server Manual](https://support.hytale.com/hc/en-us/articles/45326769420827-Hytale-Server-Manual)
- [Hytale Support](https://support.hytale.com)

---

## 📝 Licencia

Este script es un proyecto personal y no está afiliado oficialmente con Hypixel Studios.

Hytale es una marca registrada de Hypixel Studios.
