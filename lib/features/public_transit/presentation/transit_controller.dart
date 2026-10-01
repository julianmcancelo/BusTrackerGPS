import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../data/models/transit_models.dart';
import '../data/transit_repository.dart';
import '../../../core/services/sync_service.dart';

class TransitState {
  final List<TransitLineSummary> allLines;
  final Set<int> enabledLineIds;
  final int? focusedLineId;
  final int? focusedBranchId;
  final TransitDirectionFilter directionFilter;
  final List<TransitStop> stops;
  final TransitStop? selectedStop;
  final LatLng? userLocation;
  final bool isLoading;
  final bool isFollowingUser;
  final String searchQuery;
  final bool showStops;
  final List<TransitStop> nearbyStops;

  const TransitState({
    this.allLines = const [],
    this.enabledLineIds = const {},
    this.focusedLineId,
    this.focusedBranchId,
    this.directionFilter = TransitDirectionFilter.both,
    this.stops = const [],
    this.selectedStop,
    this.userLocation,
    this.isLoading = true,
    this.isFollowingUser = false,
    this.searchQuery = '',
    this.showStops = true,
    this.nearbyStops = const [],
  });

  TransitState copyWith({
    List<TransitLineSummary>? allLines,
    Set<int>? enabledLineIds,
    int? focusedLineId,
    bool clearFocusedLine = false,
    int? focusedBranchId,
    bool clearFocusedBranch = false,
    TransitDirectionFilter? directionFilter,
    List<TransitStop>? stops,
    TransitStop? selectedStop,
    bool clearSelectedStop = false,
    LatLng? userLocation,
    bool? isLoading,
    bool? isFollowingUser,
    String? searchQuery,
    bool? showStops,
    List<TransitStop>? nearbyStops,
  }) {
    return TransitState(
      allLines: allLines ?? this.allLines,
      enabledLineIds: enabledLineIds ?? this.enabledLineIds,
      focusedLineId: clearFocusedLine ? null : (focusedLineId ?? this.focusedLineId),
      focusedBranchId: clearFocusedBranch ? null : (focusedBranchId ?? this.focusedBranchId),
      directionFilter: directionFilter ?? this.directionFilter,
      stops: stops ?? this.stops,
      selectedStop: clearSelectedStop ? null : (selectedStop ?? this.selectedStop),
      userLocation: userLocation ?? this.userLocation,
      isLoading: isLoading ?? this.isLoading,
      isFollowingUser: isFollowingUser ?? this.isFollowingUser,
      searchQuery: searchQuery ?? this.searchQuery,
      showStops: showStops ?? this.showStops,
      nearbyStops: nearbyStops ?? this.nearbyStops,
    );
  }

  TransitLineSummary? get focusedLine {
    if (focusedLineId == null) return null;
    return allLines.where((l) => l.id == focusedLineId).firstOrNull;
  }

  TransitBranchSummary? get focusedBranch {
    final line = focusedLine;
    if (line == null) return null;
    if (focusedBranchId != null) {
      return line.branches.where((b) => b.branch.id == focusedBranchId).firstOrNull;
    }
    return line.primaryBranch;
  }

  List<TransitLineSummary> get filteredLines {
    if (searchQuery.trim().isEmpty) return allLines;
    final q = searchQuery.trim().toLowerCase();
    return allLines.where((l) {
      return l.number.toLowerCase().contains(q) ||
          l.name.toLowerCase().contains(q) ||
          l.branches.any((b) => b.branch.name.toLowerCase().contains(q));
    }).toList();
  }
}

final transitControllerProvider =
    NotifierProvider<TransitNotifier, TransitState>(TransitNotifier.new);

class TransitNotifier extends Notifier<TransitState> {
  StreamSubscription<Position>? _positionSub;

  TransitRepository get repo => ref.read(transitRepositoryProvider);

  @override
  TransitState build() {
    ref.onDispose(() {
      _positionSub?.cancel();
    });

    Future.microtask(() => _init());
    return const TransitState();
  }

  Future<void> _init() async {
    state = state.copyWith(isLoading: true);
    var network = await repo.getTransitNetwork();

    // Si aún no hay trazas guardadas, sincroniza automáticamente con Lanús Digital
    if (network.isEmpty || network.every((l) => !l.hasRoutes)) {
      try {
        await SyncService.fetchOfficialLines(repo.db);
        network = await repo.getTransitNetwork();
      } catch (_) {}
    }

    final allIds = network.map((l) => l.id).toSet();
    final firstLineWithRoutes =
        network.where((l) => l.hasRoutes).firstOrNull ?? network.firstOrNull;

    state = state.copyWith(
      allLines: network,
      enabledLineIds: allIds,
      focusedLineId: firstLineWithRoutes?.id,
      focusedBranchId: firstLineWithRoutes?.primaryBranch?.branch.id,
      isLoading: false,
    );

    await _refreshStops();
    _startLocationUpdates();
  }

  Future<int> syncWithLanusDigital() async {
    state = state.copyWith(isLoading: true);
    int count = 0;
    try {
      count = await SyncService.fetchOfficialLines(repo.db);
    } catch (_) {}
    await refreshNetwork();
    return count;
  }

  void _startLocationUpdates() async {
    try {
      final perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.always || perm == LocationPermission.whileInUse) {
        final pos = await Geolocator.getCurrentPosition();
        final loc = LatLng(pos.latitude, pos.longitude);
        state = state.copyWith(userLocation: loc);
        _refreshNearbyStops(loc);

        _positionSub = Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 10,
          ),
        ).listen((p) {
          final l = LatLng(p.latitude, p.longitude);
          state = state.copyWith(userLocation: l);
          _refreshNearbyStops(l);
        });
      }
    } catch (_) {}
  }

  Future<void> _refreshNearbyStops(LatLng loc) async {
    try {
      final nearby = await repo.getNearbyStops(loc);
      state = state.copyWith(nearbyStops: nearby);
    } catch (_) {}
  }

  Future<void> refreshNetwork() async {
    state = state.copyWith(isLoading: true);
    final network = await repo.getTransitNetwork();
    state = state.copyWith(
      allLines: network,
      isLoading: false,
    );
    await _refreshStops();
  }

  void toggleLineVisibility(int lineId) {
    final next = Set<int>.from(state.enabledLineIds);
    if (next.contains(lineId)) {
      next.remove(lineId);
    } else {
      next.add(lineId);
    }
    state = state.copyWith(enabledLineIds: next);
  }

  void showAllLines() {
    state = state.copyWith(
      enabledLineIds: state.allLines.map((l) => l.id).toSet(),
    );
  }

  void hideAllLines() {
    state = state.copyWith(enabledLineIds: {});
  }

  void focusLine(int lineId) {
    final line = state.allLines.where((l) => l.id == lineId).firstOrNull;
    final nextEnabled = Set<int>.from(state.enabledLineIds)..add(lineId);
    state = state.copyWith(
      focusedLineId: lineId,
      focusedBranchId: line?.primaryBranch?.branch.id,
      enabledLineIds: nextEnabled,
      clearSelectedStop: true,
    );
    _refreshStops();
  }

  void selectBranch(int branchId) {
    state = state.copyWith(
      focusedBranchId: branchId,
      clearSelectedStop: true,
    );
    _refreshStops();
  }

  void setDirectionFilter(TransitDirectionFilter filter) {
    state = state.copyWith(
      directionFilter: filter,
      clearSelectedStop: true,
    );
    _refreshStops();
  }

  void toggleStopsVisibility() {
    state = state.copyWith(showStops: !state.showStops);
  }

  void selectStop(TransitStop? stop) {
    if (stop == null) {
      state = state.copyWith(clearSelectedStop: true);
    } else {
      state = state.copyWith(selectedStop: stop);
    }
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void toggleFollowUser() {
    state = state.copyWith(isFollowingUser: !state.isFollowingUser);
  }

  Future<void> _refreshStops() async {
    final line = state.focusedLine;
    final branch = state.focusedBranch;
    if (line == null || branch == null) {
      state = state.copyWith(stops: []);
      return;
    }

    final stops = await repo.getStopsForBranch(
      line: line,
      branch: branch,
      direction: state.directionFilter,
    );

    state = state.copyWith(stops: stops);
  }
}
