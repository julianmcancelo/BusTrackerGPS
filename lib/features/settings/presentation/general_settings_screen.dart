import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/settings_repository.dart';

class GeneralSettingsScreen extends ConsumerStatefulWidget {
  const GeneralSettingsScreen({super.key});

  @override
  ConsumerState<GeneralSettingsScreen> createState() => _GeneralSettingsScreenState();
}

class _GeneralSettingsScreenState extends ConsumerState<GeneralSettingsScreen> {
  bool _isLoading = true;
  
  bool _hapticsEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = ref.read(settingsRepositoryProvider);
    _hapticsEnabled = await prefs.getSetting('haptics_enabled').then((v) => v == 'true' || v == null);
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
        appBar: AppBar(title: const Text('Opciones Generales')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Opciones Generales')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildSectionHeader(Icons.vibration, 'INTERFAZ Y FEEDBACK', 'Vibración y experiencia táctil'),
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: SwitchListTile(
                  secondary: const Icon(Icons.touch_app, color: Colors.teal),
                  title: const Text('Respuesta Háptica (Vibración)'),
                  subtitle: const Text('Vibrar al capturar paradas, fotos e incidencias'),
                  value: _hapticsEnabled,
                  onChanged: (val) {
                    setState(() => _hapticsEnabled = val);
                    _saveSetting('haptics_enabled', val.toString());
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
