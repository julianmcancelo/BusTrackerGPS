import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';

import '../../../database/database.dart';
import '../../../core/utils/transport_utils.dart';
import '../../../core/utils/haptics_utils.dart';
import '../../transport/data/transport_repository.dart';
import '../data/frequency_repository.dart';
import '../domain/frequency_models.dart';

class FrequencySessionScreen extends ConsumerStatefulWidget {
  final int sessionId;
  const FrequencySessionScreen({super.key, required this.sessionId});

  @override
  ConsumerState<FrequencySessionScreen> createState() => _FrequencySessionScreenState();
}

class _FrequencySessionScreenState extends ConsumerState<FrequencySessionScreen> {
  FrequencySessionEntry? _session;
  List<LineEntry> _lines = [];

  // Active selections
  LineEntry? _selectedLine;
  BranchEntry? _selectedBranch;
  String _selectedDirection = 'IDA';
  int _selectedLoad = 2; // 1: Baja, 2: Media, 3: Alta, 4: Colapso

  // Per-line memory context
  final Map<int, List<BranchEntry>> _branchesCache = {};
  final Map<int, BranchEntry?> _lastSelectedBranch = {};
  final Map<int, String> _lastSelectedDirection = {};

  final TextEditingController _internalController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  Timer? _stopwatchTimer;
  Duration _elapsed = Duration.zero;
  Position? _currentPosition;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _startStopwatch();
    _fetchLocation();
  }

  @override
  void dispose() {
    _stopwatchTimer?.cancel();
    _internalController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _startStopwatch() {
    _stopwatchTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_session != null && mounted) {
        final now = DateTime.now();
        final start = _session!.startedAt;
        setState(() {
          _elapsed = now.difference(start);
        });
      }
    });
  }

  Future<void> _fetchLocation() async {
    try {
      final pos = await Geolocator.getCurrentPosition().timeout(const Duration(seconds: 4));
      if (mounted) setState(() => _currentPosition = pos);
    } catch (_) {}
  }

  Future<void> _loadInitialData() async {
    final freqRepo = ref.read(frequencyRepositoryProvider);
    final transportRepo = ref.read(transportRepositoryProvider);

    final session = await freqRepo.getSession(widget.sessionId);
    final lines = await transportRepo.getAllLines();

    LineEntry? initialLine;
    if (lines.isNotEmpty) {
      initialLine = lines.first;
      // Pre-cache branches for all lines
      for (final line in lines) {
        final branches = await transportRepo.getBranchesForLineEntity(line);
        _branchesCache[line.id] = branches;
        if (branches.isNotEmpty) {
          _lastSelectedBranch[line.id] = branches.first;
        }
        _lastSelectedDirection[line.id] = 'IDA';
      }
    }

    if (mounted) {
      setState(() {
        _session = session;
        _lines = lines;
        _selectedLine = initialLine;
        if (initialLine != null) {
          _selectedBranch = _lastSelectedBranch[initialLine.id];
          _selectedDirection = _lastSelectedDirection[initialLine.id] ?? 'IDA';
        }
        _isLoading = false;
      });
    }
  }

  void _onLineSelected(LineEntry line) {
    if (_selectedLine?.id == line.id) return;
    HapticsUtils.vibrateShort();

    // Save state for previous line
    if (_selectedLine != null) {
      _lastSelectedBranch[_selectedLine!.id] = _selectedBranch;
      _lastSelectedDirection[_selectedLine!.id] = _selectedDirection;
    }

    final branches = _branchesCache[line.id] ?? [];
    final rememberedBranch = _lastSelectedBranch[line.id] ?? (branches.isNotEmpty ? branches.first : null);
    final rememberedDir = _lastSelectedDirection[line.id] ?? 'IDA';

    setState(() {
      _selectedLine = line;
      _selectedBranch = rememberedBranch;
      _selectedDirection = rememberedDir;
    });
  }

  void _onBranchSelected(BranchEntry branch) {
    HapticsUtils.vibrateShort();
    setState(() {
      _selectedBranch = branch;
      if (_selectedLine != null) {
        _lastSelectedBranch[_selectedLine!.id] = branch;
      }
    });
  }

  void _onDirectionSelected(String dir) {
    HapticsUtils.vibrateShort();
    setState(() {
      _selectedDirection = dir;
      if (_selectedLine != null) {
        _lastSelectedDirection[_selectedLine!.id] = dir;
      }
    });
  }

  void _onLoadSelected(int load) {
    HapticsUtils.vibrateShort();
    setState(() {
      _selectedLoad = load;
    });
  }

  Future<void> _logBusPass() async {
    if (_selectedLine == null || _selectedBranch == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona una línea y un ramal antes de registrar')),
      );
      return;
    }

    final repo = ref.read(frequencyRepositoryProvider);
    final internal = _internalController.text.trim();
    final notes = _notesController.text.trim();

    await HapticsUtils.vibrateSuccess();

    await repo.logBusPass(
      sessionId: widget.sessionId,
      lineId: _selectedLine!.id,
      branchId: _selectedBranch!.id,
      direction: _selectedDirection,
      internalNumber: internal.isNotEmpty ? internal : null,
      passengerLoad: _selectedLoad,
      latitude: _currentPosition?.latitude,
      longitude: _currentPosition?.longitude,
      notes: notes.isNotEmpty ? notes : null,
    );

    _internalController.clear();
    _notesController.clear();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.greenAccent, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Pasada registrada: Línea ${_selectedLine!.number} · ${_selectedBranch!.name} ($_selectedDirection)',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            ],
          ),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _confirmFinishSession() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Finalizar Auditoría de Frecuencias'),
        content: const Text(
          '¿Deseas cerrar la toma de datos en este punto de control y generar el informe oficial de servicio?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('CONTINUAR RELEVANDO')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFF0284C7)),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('FINALIZAR E INFORMAR'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final repo = ref.read(frequencyRepositoryProvider);
      await repo.finishSession(widget.sessionId);
      if (mounted) {
        context.pushReplacement('/frequency/report/${widget.sessionId}');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Cargando consola de aforo...')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_session == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Sesión no encontrada')),
        body: const Center(child: Text('No existe la sesión de aforo solicitada.')),
      );
    }

    final repo = ref.watch(frequencyRepositoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _session!.title.toUpperCase(),
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, letterSpacing: 0.5),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.assessment_outlined),
            tooltip: 'Ver informe actual',
            onPressed: () => context.push('/frequency/report/${widget.sessionId}'),
          ),
          IconButton(
            icon: const Icon(Icons.stop_circle_outlined, color: Colors.redAccent),
            tooltip: 'Cerrar auditoría',
            onPressed: _confirmFinishSession,
          ),
        ],
      ),
      body: StreamBuilder<List<FrequencyRecordWithDetails>>(
        stream: repo.watchSessionRecords(widget.sessionId),
        builder: (context, snapshot) {
          final records = snapshot.data ?? [];

          // Precompute counts per line
          final Map<int, int> sightingsPerLine = {};
          for (final r in records) {
            sightingsPerLine[r.line.id] = (sightingsPerLine[r.line.id] ?? 0) + 1;
          }

          return Column(
            children: [
              // HUD Header with Stopwatch & Statistics
              _buildHudHeader(records),

              // Multi-line Tactile Recording Deck
              _buildMultiLineDeck(records, sightingsPerLine),

              // Live Sightings Timeline Feed Header
              Container(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
                child: Row(
                  children: [
                    const Icon(Icons.history, size: 16, color: Colors.blueGrey),
                    const SizedBox(width: 6),
                    Text(
                      'PASADAS REGISTRADAS EN VIVO (${records.length})',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Colors.blueGrey,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const Spacer(),
                    if (records.isNotEmpty)
                      Text(
                        'Más reciente arriba',
                        style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                      ),
                  ],
                ),
              ),

              // Records Timeline List
              Expanded(
                child: records.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.directions_bus_filled_outlined, size: 48, color: Colors.grey.shade300),
                            const SizedBox(height: 10),
                            const Text(
                              'Aún no hay unidades registradas',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Selecciona una línea arriba y presiona "REGISTRAR PASADA"',
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
                        itemCount: records.length,
                        itemBuilder: (context, idx) {
                          final item = records[idx];
                          return _buildTimelineItem(item, repo);
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  // HUD: Checkpoint, Stopwatch & Executive Telemetry
  Widget _buildHudHeader(List<FrequencyRecordWithDetails> records) {
    final hours = _elapsed.inHours.toString().padLeft(2, '0');
    final minutes = (_elapsed.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (_elapsed.inSeconds % 60).toString().padLeft(2, '0');

    final elapsedHours = _elapsed.inSeconds > 0 ? _elapsed.inSeconds / 3600.0 : 0.0;
    final vehiclesPerHour = elapsedHours > 0.05 ? (records.length / elapsedHours).toStringAsFixed(1) : '-';
    final bunchingCount = records.where((r) => r.record.isBunching).length;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A), // Dark Slate
        border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.08))),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.location_on, color: Color(0xFF38BDF8), size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  _session!.checkpointName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (_currentPosition != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'GPS ±${_currentPosition!.accuracy.toStringAsFixed(0)}m',
                    style: const TextStyle(color: Color(0xFF34D399), fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              // Live Stopwatch
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.timer_outlined, color: Color(0xFFFBBF24), size: 14),
                    const SizedBox(width: 4),
                    Text(
                      '$hours:$minutes:$seconds',
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Total Sightings Pill
              _buildHudPill('UNIDADES', records.length.toString(), const Color(0xFF38BDF8)),
              const SizedBox(width: 6),
              // Frequency Rate Pill
              _buildHudPill('FREQ', '$vehiclesPerHour v/h', const Color(0xFF34D399)),
              const SizedBox(width: 6),
              // Bunching Pill
              _buildHudPill('ACOLCHONADO', bunchingCount.toString(), bunchingCount > 0 ? Colors.amberAccent : Colors.white60),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHudPill(String label, String value, Color valueColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: const TextStyle(color: Colors.white60, fontSize: 8, fontWeight: FontWeight.bold),
            ),
            Text(
              value,
              style: TextStyle(color: valueColor, fontSize: 11, fontWeight: FontWeight.w900),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // Multi-Line Deck Console
  Widget _buildMultiLineDeck(List<FrequencyRecordWithDetails> records, Map<int, int> sightingsPerLine) {
    final activeColor = _selectedLine != null ? TransportUtils.getLineColor(_selectedLine!.number) : const Color(0xFF0284C7);
    final branches = _selectedLine != null ? (_branchesCache[_selectedLine!.id] ?? []) : <BranchEntry>[];

    // Calculate Headway Preview for the selected combination
    FrequencyRecordWithDetails? lastPass;
    if (_selectedLine != null && _selectedBranch != null) {
      lastPass = records.where((r) =>
          r.line.id == _selectedLine!.id &&
          r.branch.id == _selectedBranch!.id &&
          r.record.direction == _selectedDirection).firstOrNull;
    }

    return Card(
      margin: const EdgeInsets.fromLTRB(10, 8, 10, 0),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: activeColor.withValues(alpha: 0.35), width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Line Selector Bar (Tactile Horizontal Carousel)
            Row(
              children: [
                const Text(
                  'LÍNEA:',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.blueGrey, letterSpacing: 0.5),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: SizedBox(
                    height: 42,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _lines.length,
                      itemBuilder: (context, idx) {
                        final line = _lines[idx];
                        final isSelected = _selectedLine?.id == line.id;
                        final lineColor = TransportUtils.getLineColor(line.number);
                        final count = sightingsPerLine[line.id] ?? 0;

                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: InkWell(
                            onTap: () => _onLineSelected(line),
                            borderRadius: BorderRadius.circular(10),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: isSelected ? lineColor : lineColor.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isSelected ? lineColor : lineColor.withValues(alpha: 0.3),
                                  width: isSelected ? 2 : 1,
                                ),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: lineColor.withValues(alpha: 0.35),
                                          blurRadius: 6,
                                          offset: const Offset(0, 2),
                                        )
                                      ]
                                    : null,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    line.number,
                                    style: TextStyle(
                                      color: isSelected ? Colors.white : lineColor,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 15,
                                    ),
                                  ),
                                  if (count > 0) ...[
                                    const SizedBox(width: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                      decoration: BoxDecoration(
                                        color: isSelected ? Colors.white24 : lineColor.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        '$count',
                                        style: TextStyle(
                                          color: isSelected ? Colors.white : lineColor,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // 2. Branch & Direction Row
            if (branches.isNotEmpty) ...[
              SizedBox(
                height: 36,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: branches.length,
                  itemBuilder: (context, idx) {
                    final b = branches[idx];
                    final isSelected = _selectedBranch?.id == b.id;

                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ChoiceChip(
                        label: Text(
                          b.name,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            color: isSelected ? Colors.white : Colors.black87,
                          ),
                        ),
                        selected: isSelected,
                        selectedColor: activeColor,
                        backgroundColor: Colors.grey.shade100,
                        visualDensity: VisualDensity.compact,
                        showCheckmark: false,
                        onSelected: (_) => _onBranchSelected(b),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
            ],

            // 3. Direction & Live Headway Row
            Row(
              children: [
                // Direction Toggle
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    children: [
                      _buildDirectionButton('IDA', Icons.arrow_forward),
                      _buildDirectionButton('VUELTA', Icons.arrow_back),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Live Headway Preview Card
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                    decoration: BoxDecoration(
                      color: lastPass != null && (DateTime.now().difference(lastPass.record.observedAt).inSeconds <= 120)
                          ? Colors.amber.shade50
                          : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: lastPass != null && (DateTime.now().difference(lastPass.record.observedAt).inSeconds <= 120)
                            ? Colors.amber.shade400
                            : Colors.grey.shade300,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.history_toggle_off,
                              size: 13,
                              color: lastPass != null && (DateTime.now().difference(lastPass.record.observedAt).inSeconds <= 120)
                                  ? Colors.amber.shade800
                                  : Colors.blueGrey,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              lastPass != null ? 'ÚLTIMA PASADA' : 'PRIMERA UNIDAD',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                color: lastPass != null && (DateTime.now().difference(lastPass.record.observedAt).inSeconds <= 120)
                                    ? Colors.amber.shade900
                                    : Colors.blueGrey,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          lastPass != null
                              ? 'Hace ${_formatDuration(DateTime.now().difference(lastPass.record.observedAt))}${lastPass.record.internalNumber != null ? ' · Int. ${lastPass.record.internalNumber}' : ''}'
                              : 'Sin registros previos en este sentido',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: lastPass != null && (DateTime.now().difference(lastPass.record.observedAt).inSeconds <= 120)
                                ? Colors.amber.shade900
                                : Colors.black87,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // 4. Passenger Load Selector (4 Visual States)
            Row(
              children: [
                _buildLoadCard(1, 'BAJA', 'Asientos libres', const Color(0xFF059669)),
                const SizedBox(width: 4),
                _buildLoadCard(2, 'MEDIA', 'Sentados', const Color(0xFF0284C7)),
                const SizedBox(width: 4),
                _buildLoadCard(3, 'ALTA', 'De pie', const Color(0xFFD97706)),
                const SizedBox(width: 4),
                _buildLoadCard(4, 'COLAPSO', 'Excedido', const Color(0xFFDC2626)),
              ],
            ),
            const SizedBox(height: 8),

            // 5. Interno Field & Mega Action Button
            Row(
              children: [
                SizedBox(
                  width: 100,
                  height: 48,
                  child: TextField(
                    controller: _internalController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                    decoration: InputDecoration(
                      labelText: 'INTERNO',
                      labelStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                      hintText: 'Ej. 42',
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      suffixIcon: _internalController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 16),
                              onPressed: () => setState(() => _internalController.clear()),
                            )
                          : null,
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: activeColor,
                        foregroundColor: Colors.white,
                        elevation: 4,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                      onPressed: _logBusPass,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.add_task, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'REGISTRAR PASADA · LÍNEA ${_selectedLine?.number ?? ''} ($_selectedDirection)',
                              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 0.5),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDirectionButton(String dir, IconData icon) {
    final isSelected = _selectedDirection == dir;
    final activeColor = _selectedLine != null ? TransportUtils.getLineColor(_selectedLine!.number) : const Color(0xFF0284C7);

    return InkWell(
      onTap: () => _onDirectionSelected(dir),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? activeColor : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: isSelected ? Colors.white : Colors.black87),
            const SizedBox(width: 4),
            Text(
              dir,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black87,
                fontWeight: FontWeight.w900,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadCard(int load, String title, String subtitle, Color color) {
    final isSelected = _selectedLoad == load;

    return Expanded(
      child: InkWell(
        onTap: () => _onLoadSelected(load),
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
          decoration: BoxDecoration(
            color: isSelected ? color : color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? color : color.withValues(alpha: 0.3),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: isSelected ? Colors.white : color,
                  fontWeight: FontWeight.w900,
                  fontSize: 10,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  color: isSelected ? Colors.white70 : Colors.black54,
                  fontSize: 8,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Timeline Item Card
  Widget _buildTimelineItem(FrequencyRecordWithDetails item, FrequencyRepository repo) {
    final timeStr = DateFormat('HH:mm:ss').format(item.record.observedAt);
    final lineColor = TransportUtils.getLineColor(item.line.number);

    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: item.record.isBunching
              ? Colors.amber.shade600
              : item.record.isDelayed
                  ? Colors.red.shade400
                  : Colors.grey.shade200,
          width: item.record.isBunching || item.record.isDelayed ? 1.5 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          children: [
            // Line Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: lineColor,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                item.line.number,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13),
              ),
            ),
            const SizedBox(width: 8),
            // Info Column
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.branch.name,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          item.record.direction,
                          style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        timeStr,
                        style: TextStyle(fontFamily: 'monospace', fontSize: 11, color: Colors.grey.shade700),
                      ),
                      if (item.record.internalNumber != null) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: Colors.blue.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Int. ${item.record.internalNumber}',
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blue),
                          ),
                        ),
                      ],
                      const SizedBox(width: 6),
                      Text(
                        _getLoadLabel(item.record.passengerLoad),
                        style: TextStyle(fontSize: 10, color: _getLoadColor(item.record.passengerLoad), fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            // Headway Badge
            if (item.record.headwaySeconds != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: item.record.isBunching
                      ? Colors.amber.shade100
                      : item.record.isDelayed
                          ? Colors.red.shade100
                          : Colors.green.shade50,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: item.record.isBunching
                        ? Colors.amber.shade600
                        : item.record.isDelayed
                            ? Colors.red.shade400
                            : Colors.green.shade400,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'H: ${(item.record.headwaySeconds! / 60).toStringAsFixed(1)}m',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.w900,
                        fontSize: 11,
                        color: item.record.isBunching
                            ? Colors.amber.shade900
                            : item.record.isDelayed
                                ? Colors.red.shade900
                                : Colors.green.shade900,
                      ),
                    ),
                    Text(
                      item.record.isBunching
                          ? 'Acolchonado'
                          : item.record.isDelayed
                              ? 'Demorado'
                              : 'Regular',
                      style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                        color: item.record.isBunching
                            ? Colors.amber.shade900
                            : item.record.isDelayed
                                ? Colors.red.shade900
                                : Colors.green.shade800,
                      ),
                    ),
                  ],
                ),
              ),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 18, color: Colors.grey),
              tooltip: 'Eliminar pasada',
              onPressed: () => _confirmDeleteRecord(item, repo),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDeleteRecord(FrequencyRecordWithDetails item, FrequencyRepository repo) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar registro'),
        content: Text('¿Deseas anular la pasada de la Línea ${item.line.number} (${item.branch.name})?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('CANCELAR')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('ELIMINAR'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await repo.deleteRecord(item.record.id);
    }
  }

  String _formatDuration(Duration d) {
    if (d.inHours > 0) {
      return '${d.inHours}h ${d.inMinutes % 60}m';
    }
    return '${d.inMinutes}m ${d.inSeconds % 60}s';
  }

  String _getLoadLabel(int load) {
    switch (load) {
      case 1:
        return 'Baja';
      case 2:
        return 'Media';
      case 3:
        return 'Alta';
      case 4:
        return 'Colapso';
      default:
        return 'Media';
    }
  }

  Color _getLoadColor(int load) {
    switch (load) {
      case 1:
        return const Color(0xFF059669);
      case 2:
        return const Color(0xFF0284C7);
      case 3:
        return const Color(0xFFD97706);
      case 4:
        return const Color(0xFFDC2626);
      default:
        return Colors.blueGrey;
    }
  }
}
