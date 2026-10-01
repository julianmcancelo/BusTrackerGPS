import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../database/database_provider.dart';
import '../data/offline_maps_service.dart';
import '../../../database/database.dart';
import '../../../core/widgets/app_bottom_nav_bar.dart';

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
  String _currentDownloadingName = '';

  @override
  void initState() {
    super.initState();
    _mapsService = OfflineMapsService(ref.read(databaseProvider));
  }

  Future<void> _startDownloadRegion({
    required String name,
    required double minLat,
    required double minLng,
    required double maxLat,
    required double maxLng,
    int minZoom = 12,
    int maxZoom = 16,
  }) async {
    if (_isDownloading) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ya hay una descarga de mapa en curso')),
      );
      return;
    }

    setState(() {
      _isDownloading = true;
      _downloadProgress = 0.0;
      _currentDownloadingName = name;
      _statusText = 'Iniciando descarga de $name...';
    });

    try {
      final regionId = await _mapsService.createRegion(
        name: name,
        minLat: minLat,
        minLng: minLng,
        maxLat: maxLat,
        maxLng: maxLng,
        minZoom: minZoom,
        maxZoom: maxZoom,
      );

      await _mapsService.downloadRegionTiles(
        regionId: regionId,
        onProgress: (done, total) {
          if (mounted) {
            setState(() {
              _downloadProgress = total > 0 ? done / total : 0.0;
              _statusText = 'Descargando tiles: $done / $total (${(_downloadProgress * 100).toStringAsFixed(0)}%)';
            });
          }
        },
      );

      if (mounted) {
        setState(() {
          _isDownloading = false;
          _statusText = 'Descarga completada con éxito';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Mapa "$name" descargado y disponible sin internet')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isDownloading = false;
          _statusText = 'Error en descarga';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al descargar mapa: $e')),
        );
      }
    }
  }

  void _showCustomRegionDialog() {
    final nameController = TextEditingController(text: 'Zona Personalizada');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Descargar Zona Personalizada'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Nombre del sector',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.map),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Zona: Cobertura Urbana Lanús / AMBA Sur\nNivel de Detalle: Zoom 12 a 16 (Calles y Avenidas)',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCELAR')),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              _startDownloadRegion(
                name: nameController.text.trim().isNotEmpty ? nameController.text.trim() : 'Zona Personalizada',
                minLat: -34.730,
                minLng: -58.430,
                maxLat: -34.660,
                maxLng: -58.340,
                minZoom: 12,
                maxZoom: 16,
              );
            },
            child: const Text('INICIAR DESCARGA'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteRegion(OfflineMapRegionEntry region) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Eliminar Mapa Offline'),
        content: Text('¿Deseas eliminar el paquete de mapa "${region.name}" del dispositivo para liberar espacio?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCELAR')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              await _mapsService.deleteRegion(region.id);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Mapa "${region.name}" eliminado')),
                );
              }
            },
            child: const Text('ELIMINAR'),
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
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_location_alt_outlined),
            tooltip: 'Zona Personalizada',
            onPressed: _showCustomRegionDialog,
          ),
        ],
      ),
      body: StreamBuilder<List<OfflineMapRegionEntry>>(
        stream: _mapsService.watchRegions(),
        builder: (context, snapshot) {
          final regions = snapshot.data ?? [];
          final downloadedRegions = regions.where((r) => r.isDownloaded).toList();
          double totalMB = 0.0;
          for (final r in downloadedRegions) {
            if (r.sizeBytes != null) {
              totalMB += (r.sizeBytes! / (1024 * 1024));
            }
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 85),
            children: [
              // Active Download Card
              if (_isDownloading)
                Card(
                  elevation: 2,
                  margin: const EdgeInsets.only(bottom: 10),
                  color: Colors.blue.shade50,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.blue.shade200),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2.2),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _currentDownloadingName,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              '${(_downloadProgress * 100).toStringAsFixed(0)}%',
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF0284C7),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: _downloadProgress,
                            minHeight: 6,
                            backgroundColor: Colors.blue.shade100,
                            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF0284C7)),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _statusText,
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),

              // Storage Overview Card
              Card(
                elevation: 1,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(color: Colors.grey.withValues(alpha: 0.15)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(9),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0284C7).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.download_for_offline, color: Color(0xFF0284C7), size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Almacenamiento Offline',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${downloadedRegions.length} mapas guardados · ${totalMB.toStringAsFixed(1)} MB en uso',
                              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilledButton.tonalIcon(
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          visualDensity: VisualDensity.compact,
                          minimumSize: const Size(0, 32),
                        ),
                        onPressed: _showCustomRegionDialog,
                        icon: const Icon(Icons.add, size: 14),
                        label: const Text('ZONA', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
              ),

              // Preconfigured Section Header
              _buildSectionHeader('ZONAS RECOMENDADAS PARA RELEVAMIENTO', Icons.layers_outlined),
              const SizedBox(height: 6),

              _buildQuickDownloadCard(
                title: 'Lanús Centro y Este',
                description: 'Estación Lanús, Gerli, Monte Chingolo y vías troncales.',
                zoomRange: 'Zoom 12-16',
                sizeEstimate: '~35 MB',
                isDownloaded: regions.any((r) => r.name.contains('Centro') && r.isDownloaded),
                onDownload: () => _startDownloadRegion(
                  name: 'Lanús Centro y Este',
                  minLat: -34.725,
                  minLng: -58.400,
                  maxLat: -34.680,
                  maxLng: -58.350,
                  minZoom: 12,
                  maxZoom: 16,
                ),
              ),

              _buildQuickDownloadCard(
                title: 'Lanús Oeste y R. de Escalada',
                description: 'Valle Central, Alsina, Caraza y Remedios de Escalada.',
                zoomRange: 'Zoom 12-16',
                sizeEstimate: '~40 MB',
                isDownloaded: regions.any((r) => r.name.contains('Oeste') && r.isDownloaded),
                onDownload: () => _startDownloadRegion(
                  name: 'Lanús Oeste y Escalada',
                  minLat: -34.735,
                  minLng: -58.435,
                  maxLat: -34.685,
                  maxLng: -58.390,
                  minZoom: 12,
                  maxZoom: 16,
                ),
              ),

              _buildQuickDownloadCard(
                title: 'Corredor Sur Completo (AMBA)',
                description: 'Avellaneda, Lanús, Lomas de Zamora, Quilmes y accesos principales.',
                zoomRange: 'Zoom 11-15',
                sizeEstimate: '~85 MB',
                isDownloaded: regions.any((r) => r.name.contains('Corredor') && r.isDownloaded),
                onDownload: () => _startDownloadRegion(
                  name: 'Corredor Sur Completo',
                  minLat: -34.760,
                  minLng: -58.450,
                  maxLat: -34.650,
                  maxLng: -58.300,
                  minZoom: 11,
                  maxZoom: 15,
                ),
              ),

              const SizedBox(height: 14),
              // Downloaded Maps Header
              _buildSectionHeader('MAPAS GUARDADOS (${downloadedRegions.length})', Icons.folder_outlined),
              const SizedBox(height: 6),

              if (downloadedRegions.isEmpty)
                Card(
                  elevation: 0,
                  color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.grey.withValues(alpha: 0.15)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                    child: Column(
                      children: [
                        Icon(Icons.cloud_off_outlined, size: 36, color: Colors.grey.shade400),
                        const SizedBox(height: 8),
                        Text(
                          'No hay zonas descargadas',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey.shade700),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Descarga una de las zonas recomendadas para navegar y relevar sin conexión.',
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              else
                ...downloadedRegions.map((r) {
                  final mbSize = r.sizeBytes != null ? (r.sizeBytes! / (1024 * 1024)).toStringAsFixed(1) : '?';
                  return Card(
                    elevation: 0.8,
                    margin: const EdgeInsets.only(bottom: 6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: BorderSide(color: Colors.grey.withValues(alpha: 0.14)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.check_circle_outline, color: Colors.green, size: 18),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  r.name,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Zoom ${r.minZoom}-${r.maxZoom} · $mbSize MB',
                                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                            tooltip: 'Eliminar del dispositivo',
                            visualDensity: VisualDensity.compact,
                            onPressed: () => _confirmDeleteRegion(r),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
            ],
          );
        },
      ),
      bottomNavigationBar: const AppBottomNavBar(currentIndex: 3),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: Row(
        children: [
          Icon(icon, size: 15, color: Colors.grey.shade600),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade600,
                letterSpacing: 0.5,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: Colors.grey.shade700),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.grey.shade700),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickDownloadCard({
    required String title,
    required String description,
    required String zoomRange,
    required String sizeEstimate,
    required bool isDownloaded,
    required VoidCallback onDownload,
  }) {
    return Card(
      elevation: 0.8,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isDownloaded ? Colors.green.withValues(alpha: 0.35) : Colors.grey.withValues(alpha: 0.15),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: (isDownloaded ? Colors.green : const Color(0xFF0284C7)).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    isDownloaded ? Icons.cloud_done : Icons.cloud_download_outlined,
                    size: 18,
                    color: isDownloaded ? Colors.green : const Color(0xFF0284C7),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                if (isDownloaded)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.green.withValues(alpha: 0.25)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check, size: 12, color: Colors.green),
                        SizedBox(width: 4),
                        Text(
                          'DESCARGADO',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.green),
                        ),
                      ],
                    ),
                  )
                else
                  FilledButton.tonal(
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      visualDensity: VisualDensity.compact,
                      minimumSize: const Size(0, 30),
                    ),
                    onPressed: _isDownloading ? null : onDownload,
                    child: const Text('DESCARGAR', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              description,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600, height: 1.25),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                _buildMiniChip(Icons.zoom_in, zoomRange),
                _buildMiniChip(Icons.sd_storage_outlined, sizeEstimate),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
