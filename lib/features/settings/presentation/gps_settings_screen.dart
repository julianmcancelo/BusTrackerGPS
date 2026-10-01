import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/settings_repository.dart';

class GpsSettingsScreen extends ConsumerStatefulWidget {
  const GpsSettingsScreen({super.key});

  @override
  ConsumerState<GpsSettingsScreen> createState() => _GpsSettingsScreenState();
}

class _GpsSettingsScreenState extends ConsumerState<GpsSettingsScreen> {
  bool _isLoading = true;
  
  // State variables for settings
  int _gpsInterval = 5;
  double _minDistance = 2.0;
  bool _snapToRoadsEnabled = false;
  bool _autoStopEnabled = true;
  int _autoStopMinSeconds = 20;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = ref.read(settingsRepositoryProvider);
    
    _gpsInterval = await prefs.getSetting('gps_interval_seconds').then((v) => int.tryParse(v ?? '5') ?? 5);
    _minDistance = await prefs.getSetting('gps_min_distance').then((v) => double.tryParse(v ?? '2.0') ?? 2.0);
    _snapToRoadsEnabled = await prefs.getSetting('snap_to_roads_enabled').then((v) => v == 'true');
    _autoStopEnabled = await prefs.getSetting('auto_stop_enabled').then((v) => v == 'true' || v == null);
    _autoStopMinSeconds = await prefs.getSetting('auto_stop_min_seconds').then((v) => int.tryParse(v ?? '20') ?? 20);
    
    setState(() => _isLoading = false);
  }

  Future<void> _saveSetting(String key, String value) async {
    await ref.read(settingsRepositoryProvider).setSetting(key, value);
  }

  Widget _buildSectionHeader(IconData icon, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8, left: 4, right: 4),
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary, size: 22),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, letterSpacing: 0.5),
              ),
              Text(
                subtitle,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('GPS y Recorrido')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('GPS y Recorrido')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildSectionHeader(Icons.gps_fixed, 'GPS Y CAPTURA DE TRACKS', 'Configuración de frecuencia y precisión'),
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.timer_outlined, color: Colors.blue),
                      title: const Text('Intervalo de Lectura GPS'),
                      subtitle: Text('Actualización cada $_gpsInterval segundo(s)'),
                      trailing: DropdownButton<int>(
                        value: _gpsInterval,
                        borderRadius: BorderRadius.circular(12),
                        items: const [
                          DropdownMenuItem(value: 1, child: Text('1 s (Alta prec.)')),
                          DropdownMenuItem(value: 2, child: Text('2 s (Recomendado)')),
                          DropdownMenuItem(value: 5, child: Text('5 s (Equilibrado)')),
                          DropdownMenuItem(value: 10, child: Text('10 s (Ahorro)')),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _gpsInterval = val);
                            _saveSetting('gps_interval_seconds', val.toString());
                          }
                        },
                      ),
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    ListTile(
                      leading: const Icon(Icons.filter_alt_outlined, color: Colors.blue),
                      title: const Text('Distancia Mínima de Filtrado'),
                      subtitle: Text('${_minDistance.toStringAsFixed(0)} metros'),
                      trailing: SizedBox(
                        width: 140,
                        child: Slider(
                          value: _minDistance,
                          min: 1.0,
                          max: 20.0,
                          divisions: 19,
                          onChanged: (val) {
                            setState(() => _minDistance = val);
                            _saveSetting('gps_min_distance', val.toString());
                          },
                        ),
                      ),
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    SwitchListTile(
                      secondary: const Icon(Icons.alt_route, color: Colors.blue),
                      title: const Text('Alineación a Calles en Vivo (Snap-to-Roads)'),
                      subtitle: const Text('Filtro Kalman 2D y alineación al eje vial'),
                      value: _snapToRoadsEnabled,
                      onChanged: (val) {
                        setState(() => _snapToRoadsEnabled = val);
                        _saveSetting('snap_to_roads_enabled', val.toString());
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),
              _buildSectionHeader(Icons.motion_photos_paused_outlined, 'DETECCIÓN DE PARADAS', 'Alertas automáticas al detener la unidad'),
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Column(
                  children: [
                    SwitchListTile(
                      secondary: const Icon(Icons.hail, color: Colors.orange),
                      title: const Text('Detección Automática de Paradas'),
                      subtitle: const Text('Notificar cuando el colectivo permanece detenido'),
                      value: _autoStopEnabled,
                      onChanged: (val) {
                        setState(() => _autoStopEnabled = val);
                        _saveSetting('auto_stop_enabled', val.toString());
                      },
                    ),
                    if (_autoStopEnabled) ...[
                      const Divider(height: 1, indent: 16, endIndent: 16),
                      ListTile(
                        leading: const Icon(Icons.access_time, color: Colors.orange),
                        title: const Text('Tiempo Mínimo de Detención'),
                        subtitle: Text('Detención confirmada tras $_autoStopMinSeconds s'),
                        trailing: DropdownButton<int>(
                          value: _autoStopMinSeconds,
                          borderRadius: BorderRadius.circular(12),
                          items: const [
                            DropdownMenuItem(value: 15, child: Text('15 seg')),
                            DropdownMenuItem(value: 20, child: Text('20 seg')),
                            DropdownMenuItem(value: 30, child: Text('30 seg')),
                            DropdownMenuItem(value: 60, child: Text('60 seg')),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _autoStopMinSeconds = val);
                              _saveSetting('auto_stop_min_seconds', val.toString());
                            }
                          },
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
