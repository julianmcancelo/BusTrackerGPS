class LanusCredentials {
  // URLs del Servidor Municipal Lanús Digital
  static const String defaultServerUrl = 'https://lanusgis-ca546.web.app';
  static const String localServerUrl = 'http://10.0.2.2:3000'; // Emulador Android

  // Rutas de API
  static const String syncTripsPath = '/api/bitacora-gps';
  static const String linesCatalogPath = '/api/lineas-transporte';
  static const String pingConfigPath = '/api/bitacora-gps/sync-config';

  // Identificador y Token Interno Municipal (Uso interno sin login)
  static const String internalApiKey = 'lanus_gps_transporte_internal_2026';
  static const String clientIdentifier = 'BusTrackerGPS-Lanus-Internal';

  // GitHub Auto-Updater (Releases Oficiales)
  static const String githubOwner = 'julianmcancelo';
  static const String githubRepo = 'BusTrackerGPS';
  static const String githubReleasesApi = 'https://api.github.com/repos/julianmcancelo/BusTrackerGPS/releases/latest';
  static const String directApkDownload = 'https://github.com/julianmcancelo/BusTrackerGPS/releases/latest/download/app-release.apk';
}
