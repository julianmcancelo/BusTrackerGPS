import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/sync_service.dart';
import '../../../database/database_provider.dart';

class SyncSettingsScreen extends ConsumerStatefulWidget {
  const SyncSettingsScreen({super.key});

  @override
  ConsumerState<SyncSettingsScreen> createState() => _SyncSettingsScreenState();
}

class _SyncSettingsScreenState extends ConsumerState<SyncSettingsScreen> {
  String _serverUrl = 'https://www.lanus.digital';

  @override
  void initState() {
    super.initState();
    _loadServerUrl();
  }

  Future<void> _loadServerUrl() async {
    final url = await SyncService.getServerUrl();
    setState(() => _serverUrl = url);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9), // slate-100
      appBar: AppBar(
        title: const Text('Sincronización Lanús Digital', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.indigo.shade800,
        elevation: 0,
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'SERVIDOR MUNICIPAL Y CATÁLOGO DE LÍNEAS',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: Colors.blueGrey,
                letterSpacing: 1.0,
              ),
            ),
          ),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.dns, color: Color(0xFF0284C7)),
                  title: const Text('URL del Servidor Municipal'),
                  subtitle: Text(_serverUrl),
                  trailing: const Icon(Icons.edit, size: 20),
                  onTap: () async {
                    final controller = TextEditingController(text: _serverUrl);
                    final newUrl = await showDialog<String>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Configurar Servidor Lanús'),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'Ingrese la URL base del backend de Lanús Digital:',
                              style: TextStyle(fontSize: 13),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: controller,
                              decoration: const InputDecoration(
                                labelText: 'URL del Servidor',
                                hintText: 'https://tu-servidor.com',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ],
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('CANCELAR'),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
                            child: const Text('GUARDAR'),
                          ),
                        ],
                      ),
                    );

                    if (newUrl != null && newUrl.isNotEmpty) {
                      await SyncService.setServerUrl(newUrl);
                      setState(() => _serverUrl = newUrl);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Servidor actualizado: $newUrl')),
                        );
                      }
                    }
                  },
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                ListTile(
                  leading: const Icon(Icons.alt_route, color: Color(0xFF0284C7)),
                  title: const Text('Catálogo de Colectivos'),
                  subtitle: const Text('Descargar líneas y ramales oficiales de Lanús (Opcional)'),
                  trailing: const Icon(Icons.download_rounded),
                  onTap: () async {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Descargando catálogo...')));
                    final count = await SyncService.fetchOfficialLines(ref.read(databaseProvider));
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            count > 0
                                ? 'Catálogo actualizado: $count ramales incorporados'
                                : 'No se encontraron líneas nuevas o el servidor aún no está disponible.',
                          ),
                          backgroundColor: count > 0 ? const Color(0xFF16A34A) : Colors.orange.shade800,
                        ),
                      );
                    }
                  },
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                ListTile(
                  leading: const Icon(Icons.delete_forever, color: Colors.red),
                  title: const Text('Reiniciar App de 0', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                  subtitle: const Text('Borra todo (trazas locales, recorridos) y resincroniza solo relevamientos de usuarios', style: TextStyle(fontSize: 12)),
                  trailing: const Icon(Icons.warning_amber_rounded, color: Colors.red),
                  onTap: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('¿Reiniciar App de 0?'),
                        content: const Text(
                          'Esto borrará TODA tu base de datos local (incluyendo tus relevamientos actuales que no hayas exportado) y volverá a descargar el catálogo de líneas y las trazas hechas por otros usuarios (ignorando las trazas viejas de Lanús Digital).\n\n¿Estás completamente seguro?',
                          style: TextStyle(fontSize: 14),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text('CANCELAR'),
                          ),
                          FilledButton(
                            style: FilledButton.styleFrom(backgroundColor: Colors.red),
                            onPressed: () => Navigator.pop(ctx, true),
                            child: const Text('REINICIAR TODO'),
                          ),
                        ],
                      ),
                    );

                    if (confirm == true && mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Borrando base de datos y descargando...')),
                      );
                      try {
                        final db = ref.read(databaseProvider);
                        await db.customStatement('PRAGMA foreign_keys = OFF;');
                        await db.customStatement('DELETE FROM reference_routes;');
                        await db.customStatement('DELETE FROM branches;');
                        await db.customStatement('DELETE FROM lines;');
                        await db.customStatement('DELETE FROM incidents;');
                        await db.customStatement('DELETE FROM points;');
                        await db.customStatement('DELETE FROM trips;');
                        await db.customStatement('PRAGMA foreign_keys = ON;');
                        
                        await SyncService.fetchBitacoraGpsSurveys(db);
                        
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('¡App reiniciada de 0 exitosamente!')),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error al reiniciar: $e')),
                          );
                        }
                      }
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
