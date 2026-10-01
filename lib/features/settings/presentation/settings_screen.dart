import 'package:flutter/material.dart';
import 'gps_settings_screen.dart';
import 'general_settings_screen.dart';
import 'backup_settings_screen.dart';
import 'sync_settings_screen.dart';
import 'update_settings_screen.dart';
import '../../../core/widgets/app_bottom_nav_bar.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AJUSTES Y CONFIGURACIÓN'),
        centerTitle: true,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            children: [
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.gps_fixed, color: Colors.blue),
                      title: const Text('GPS y Recorrido', style: TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: const Text('Frecuencia, precisión y detección automática de paradas'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const GpsSettingsScreen()));
                      },
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    ListTile(
                      leading: const Icon(Icons.vibration, color: Colors.teal),
                      title: const Text('Opciones Generales', style: TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: const Text('Vibración e interfaz de usuario'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const GeneralSettingsScreen()));
                      },
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    ListTile(
                      leading: const Icon(Icons.save_alt, color: Colors.deepOrange),
                      title: const Text('Copias de Seguridad', style: TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: const Text('Exportar e importar base de datos local'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const BackupSettingsScreen()));
                      },
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    ListTile(
                      leading: const Icon(Icons.cloud_sync, color: Color(0xFF0284C7)),
                      title: const Text('Sincronización Lanús Digital', style: TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: const Text('Configurar servidor, descargar catálogo y reiniciar app'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const SyncSettingsScreen()));
                      },
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    ListTile(
                      leading: const Icon(Icons.system_update_alt, color: Colors.purple),
                      title: const Text('Actualizaciones de la App', style: TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: const Text('Parches OTA y nuevas versiones APK desde GitHub'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const UpdateSettingsScreen()));
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Center(
                child: Column(
                  children: [
                    Text(
                      'Lanús Digital · Movilidad y Transporte',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade600,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Versión 1.0.20 (Build 20)',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const AppBottomNavBar(currentIndex: 4),
    );
  }
}
