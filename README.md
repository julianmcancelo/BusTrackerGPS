# 🚍 BITÁCORA GPS — FLUTTER

Aplicación móvil Android desarrollada en Flutter para la captura profesional y relevamiento de recorridos reales de colectivos mediante GPS en tiempo real.

Diseñada bajo el principio **100% OFFLINE-FIRST**, sin cuentas, sin login, sin servidores obligatorios y sin dependencia de conexión a internet.

---

## 📱 CARACTERÍSTICAS PRINCIPALES

- **Captura GPS en Segundo Plano**: Funciona de forma ininterrumpida mediante un *Foreground Service* Android, permitiendo registrar el trayecto completo incluso con la pantalla del teléfono apagada o si la aplicación se minimiza.
- **Base de Datos Reactiva (Drift / SQLite)**: Almacenamiento local persistente con todas las reglas de negocio, índices optimizados y recuperación automática del viaje en caso de reinicio de la app.
- **Principio de Calidad de Datos**: Los puntos GPS originales nunca se sobrescriben ni se eliminan. Se clasifican reactivamente en `GOOD`, `LOW_ACCURACY` u `OUTLIER` para cálculos y filtros visuales.
- **Operación a Una Mano**: Interfaz basada en Material 3 con botones grandes de acción directa (📍 PARADA, ⚠ INCIDENCIA, 📷 FOTO, 🎤 AUDIO, + PUNTO).
- **Detección Automática de Paradas**: Detección inteligente por tiempo de detención del colectivo con diálogo de confirmación/ignorar sin pausar el rastreo GPS.
- **Exportación Multi-Formato**: Generación e intercambio inmediato en formatos **GeoJSON**, **GPX**, **KML**, **CSV** y paquetes comprimidos **ZIP** con metadatos multimedia.
- **Copias de Seguridad Completa**: Exportación e importación de Backups completos (`.zip`) con validación de datos previa.
- **Mapas Offline**: Soporte para fuentes de mapas online y offline (MBTiles y regiones descargadas localmente).

---

## 🛠 REQUISITOS DE DESARROLLO

- **Flutter SDK**: 3.24+ (Channel Stable)
- **Dart SDK**: 3.5+
- **Android SDK**: API level 34 / 37 (Android 14 / 15 support)
- **Java / JDK**: Java 17

---

## 📂 ESTRUCTURA DEL PROYECTO

```text
lib/
  main.dart

  app/
    app.dart
    router.dart
    theme.dart

  core/
    constants/app_constants.dart
    permissions/permissions_handler.dart
    utils/geo_utils.dart
    utils/haptics_utils.dart

  database/
    database.dart
    database_provider.dart
    tables/

  features/
    transport/          # Gestión de Líneas y Ramales
    capture/            # Rastreo GPS, Foreground Task, Interfaz de Campo
    trips/              # Historial, Filtros, Búsqueda y Detalle de Viaje
    map/                # Visualización FlutterMap y Polylines
    offline_maps/       # Descarga y Administración de Mapas Offline
    export/             # Exporters GeoJSON, GPX, KML, CSV, ZIP, Share
    media/              # Captura de Fotos y Grabación de Notas de Audio
    backup/             # Backup y Restauración de Base de Datos y Multimedia
    settings/           # Parámetros de Captura GPS, Paradas y Ajustes
```

---

## 🚀 INSTALACIÓN Y COMPILACIÓN

### 1. Obtener dependencias
```bash
flutter pub get
```

### 2. Generar código de Drift / SQLite
```bash
dart run build_runner build --delete-conflicting-outputs
```

### 3. Ejecutar pruebas unitarias y de base de datos
```bash
flutter test
```

### 4. Compilar APK Debug
```bash
flutter build apk --debug
```

### 5. Compilar APK Release
```bash
flutter build apk --release
```

El ejecutable generado se encontrará en:
`build/app/outputs/flutter-apk/app-release.apk`

---

## 📄 LICENCIA & ATRIBUCIÓN

- **Datos de mapa**: © Colaboradores de [OpenStreetMap](https://www.openstreetmap.org/copyright).
