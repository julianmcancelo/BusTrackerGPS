import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';
import '../../../database/database.dart';
import '../data/frequency_repository.dart';

class FrequencyListScreen extends ConsumerStatefulWidget {
  const FrequencyListScreen({super.key});

  @override
  ConsumerState<FrequencyListScreen> createState() => _FrequencyListScreenState();
}

class _FrequencyListScreenState extends ConsumerState<FrequencyListScreen> {
  void _showNewSessionDialog() {
    final titleController = TextEditingController(text: 'Control de Frecuencia');
    final checkpointController = TextEditingController(text: 'Estación Lanús (Yrigoyen)');
    final auditorController = TextEditingController(text: 'Inspector');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.add_chart, color: Color(0xFF0284C7)),
            SizedBox(width: 8),
            Text('Nueva Auditoría en Punto Fijo', style: TextStyle(fontSize: 16)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Título o Motivo de Auditoría',
                  hintText: 'Ej. Control Hora Pico Mañana',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.label_outline),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: checkpointController,
                decoration: const InputDecoration(
                  labelText: 'Punto de Control / Dirección',
                  hintText: 'Ej. Cruce Gerli / Yrigoyen y 25 de Mayo',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_on_outlined),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: auditorController,
                decoration: const InputDecoration(
                  labelText: 'Auditor / Inspector a Cargo',
                  hintText: 'Nombre del inspector',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.badge_outlined),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCELAR')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFF0284C7)),
            onPressed: () async {
              final title = titleController.text.trim().isNotEmpty ? titleController.text.trim() : 'Control de Frecuencia';
              final checkpoint = checkpointController.text.trim().isNotEmpty ? checkpointController.text.trim() : 'Punto de Control';
              final auditor = auditorController.text.trim().isNotEmpty ? auditorController.text.trim() : 'Auditor';

              Navigator.pop(ctx);

              Position? pos;
              try {
                pos = await Geolocator.getCurrentPosition().timeout(const Duration(seconds: 4));
              } catch (_) {}

              final repo = ref.read(frequencyRepositoryProvider);
              final sessionId = await repo.createSession(
                title: title,
                checkpointName: checkpoint,
                auditorName: auditor,
                latitude: pos?.latitude,
                longitude: pos?.longitude,
              );

              if (mounted) {
                context.push('/frequency/session/$sessionId');
              }
            },
            child: const Text('INICIAR AFORO AHORA'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteSession(FrequencySessionEntry session) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Eliminar Auditoría'),
        content: Text('¿Deseas eliminar la auditoría "${session.title}" y todos sus pasos registrados?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCELAR')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(frequencyRepositoryProvider).deleteSession(session.id);
            },
            child: const Text('ELIMINAR'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(frequencyRepositoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('CONTROL DE FRECUENCIAS'),
        centerTitle: true,
      ),
      body: StreamBuilder<List<FrequencySessionEntry>>(
        stream: repo.watchSessions(),
        builder: (context, snapshot) {
          final sessions = snapshot.data ?? [];

          if (sessions.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0284C7).withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.timer_outlined, size: 44, color: Color(0xFF0284C7)),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'No hay auditorías de frecuencia registradas',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Ubícate en una parada o punto de aforo y presiona el botón para iniciar la toma de frecuencias en tiempo real.',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF0284C7),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                      onPressed: _showNewSessionDialog,
                      icon: const Icon(Icons.add),
                      label: const Text('INICIAR NUEVO AFORO', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 85),
            itemCount: sessions.length,
            itemBuilder: (context, index) {
              final session = sessions[index];
              final isCompleted = session.status == 'COMPLETED';
              final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

              return Card(
                elevation: 1.5,
                margin: const EdgeInsets.only(bottom: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: isCompleted ? Colors.grey.withValues(alpha: 0.15) : const Color(0xFF0284C7).withValues(alpha: 0.4),
                  ),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    if (isCompleted) {
                      context.push('/frequency/report/${session.id}');
                    } else {
                      context.push('/frequency/session/${session.id}');
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: (isCompleted ? Colors.grey.shade700 : const Color(0xFF0284C7)).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            isCompleted ? Icons.check_circle_outline : Icons.play_arrow_rounded,
                            color: isCompleted ? Colors.grey.shade800 : const Color(0xFF0284C7),
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                session.title,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                session.checkpointName,
                                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(Icons.calendar_today, size: 10, color: Colors.grey.shade600),
                                  const SizedBox(width: 4),
                                  Text(
                                    dateFormat.format(session.startedAt),
                                    style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: (isCompleted ? Colors.green : Colors.amber.shade800).withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      isCompleted ? 'FINALIZADO' : 'EN VIVO',
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                        color: isCompleted ? Colors.green.shade800 : Colors.amber.shade900,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red, size: 18),
                          tooltip: 'Eliminar',
                          onPressed: () => _confirmDeleteSession(session),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF0284C7),
        foregroundColor: Colors.white,
        onPressed: _showNewSessionDialog,
        icon: const Icon(Icons.add),
        label: const Text('NUEVA AUDITORÍA', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }
}
