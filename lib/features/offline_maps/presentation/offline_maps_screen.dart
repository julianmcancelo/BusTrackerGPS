import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../database/database_provider.dart';
import '../data/offline_maps_service.dart';
import '../../../database/database.dart';

class OfflineMapsScreen extends ConsumerStatefulWidget {
  const OfflineMapsScreen({super.key});

  @override
  ConsumerState<OfflineMapsScreen> createState() => _OfflineMapsScreenState();
}

class _OfflineMapsScreenState extends ConsumerState<OfflineMapsScreen> {
  late OfflineMapsService _mapsService;
  bool _isDownloading = false;
  double _downloadProgress = 0.0;
  String _statusText = '';

  @override
  void initState() {
    super.initState();
    _mapsService = OfflineMapsService(ref.read(databaseProvider));
  }

  void _showDownloadNewRegionDialog() {
    final nameController = TextEditingController(text: 'Lanús Centro');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Descargar Mapa Offline'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Nombre de la Región'),
            ),
            const SizedBox(height: 12),
            const Text('Zoom: 12 a 16 (Detalle Urbano)'),
            const SizedBox(height: 8),
            const Text('Estimación: ~180 MB', style: TextStyle(color: Colors.grey)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCELAR')),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final regionId = await _mapsService.createRegion(
                name: nameController.text.trim().isNotEmpty ? nameController.text.trim() : 'Zona Offline',
                minLat: -34.720,
                minLng: -58.420,
                maxLat: -34.670,
                maxLng: -58.350,
                minZoom: 12,
                maxZoom: 15,
              );

              setState(() {
                _isDownloading = true;
                _downloadProgress = 0.0;
                _statusText = 'Iniciando descarga...';
              });

              await _mapsService.downloadRegionTiles(
                regionId: regionId,
                onProgress: (done, total) {
                  if (mounted) {
                    setState(() {
                      _downloadProgress = total > 0 ? done / total : 0.0;
                      _statusText = 'Descargando tiles: $done de $total (${(_downloadProgress * 100).toStringAsFixed(0)}%)';
                    });
                  }
                },
              );

              if (mounted) {
                setState(() {
                  _isDownloading = false;
                  _statusText = 'Descarga completada con éxito';
                });
              }
            },
            child: const Text('DESCARGAR'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MAPAS OFFLINE'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showDownloadNewRegionDialog,
        icon: const Icon(Icons.download),
        label: const Text('NUEVA ZONA'),
      ),
      body: Column(
        children: [
          if (_isDownloading)
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.blue.shade100,
              child: Column(
                children: [
                  Text(_statusText, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(value: _downloadProgress),
                ],
              ),
            ),

          Expanded(
            child: StreamBuilder<List<OfflineMapRegionEntry>>(
              stream: _mapsService.watchRegions(),
              builder: (context, snapshot) {
                final regions = snapshot.data ?? [];
                if (regions.isEmpty) {
                  return const Center(
                    child: Text('No hay mapas offline descargados'),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: regions.length,
                  itemBuilder: (context, idx) {
                    final r = regions[idx];
                    final mbSize = r.sizeBytes != null ? (r.sizeBytes! / (1024 * 1024)).toStringAsFixed(1) : '?';

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: Icon(
                          r.isDownloaded ? Icons.map : Icons.downloading,
                          color: r.isDownloaded ? Colors.green : Colors.orange,
                          size: 32,
                        ),
                        title: Text(r.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('Zoom ${r.minZoom}-${r.maxZoom} · $mbSize MB'),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                          onPressed: () => _mapsService.deleteRegion(r.id),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
