import 'package:go_router/go_router.dart';

import '../features/capture/presentation/main_map_screen.dart';
import '../features/capture/presentation/capture_screen.dart';
import '../features/trips/presentation/trip_list_screen.dart';
import '../features/trips/presentation/trip_detail_screen.dart';
import '../features/trips/presentation/reference_route_detail_screen.dart';
import '../features/transport/presentation/transport_management_screen.dart';
import '../features/offline_maps/presentation/offline_maps_screen.dart';
import '../features/settings/presentation/settings_screen.dart';
import '../features/frequency/presentation/frequency_list_screen.dart';
import '../features/frequency/presentation/frequency_session_screen.dart';
import '../features/frequency/presentation/frequency_report_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      name: 'home',
      builder: (context, state) => const MainMapScreen(),
    ),
    GoRoute(
      path: '/capture',
      name: 'capture',
      builder: (context, state) => const CaptureScreen(),
    ),
    GoRoute(
      path: '/trips',
      name: 'trips',
      builder: (context, state) => const TripListScreen(),
    ),
    GoRoute(
      path: '/trips/:id',
      name: 'trip_detail',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return TripDetailScreen(tripId: id);
      },
    ),
    GoRoute(
      path: '/reference-routes/:id',
      name: 'reference_route_detail',
      builder: (context, state) {
        final id = int.tryParse(state.pathParameters['id'] ?? '0') ?? 0;
        return ReferenceRouteDetailScreen(routeId: id);
      },
    ),
    GoRoute(
      path: '/reference-route/:id',
      builder: (context, state) {
        final id = int.tryParse(state.pathParameters['id'] ?? '0') ?? 0;
        return ReferenceRouteDetailScreen(routeId: id);
      },
    ),
    GoRoute(
      path: '/reference_routes/:id',
      builder: (context, state) {
        final id = int.tryParse(state.pathParameters['id'] ?? '0') ?? 0;
        return ReferenceRouteDetailScreen(routeId: id);
      },
    ),
    GoRoute(
      path: '/reference_route/:id',
      builder: (context, state) {
        final id = int.tryParse(state.pathParameters['id'] ?? '0') ?? 0;
        return ReferenceRouteDetailScreen(routeId: id);
      },
    ),
    GoRoute(
      path: '/transport',
      name: 'transport',
      builder: (context, state) => const TransportManagementScreen(),
    ),
    GoRoute(
      path: '/maps',
      name: 'maps',
      builder: (context, state) => const OfflineMapsScreen(),
    ),
    GoRoute(
      path: '/settings',
      name: 'settings',
      builder: (context, state) => const SettingsScreen(),
    ),
    GoRoute(
      path: '/frequency',
      name: 'frequency',
      builder: (context, state) => const FrequencyListScreen(),
    ),
    GoRoute(
      path: '/frequency/session/:id',
      builder: (context, state) {
        final id = int.tryParse(state.pathParameters['id'] ?? '0') ?? 0;
        return FrequencySessionScreen(sessionId: id);
      },
    ),
    GoRoute(
      path: '/frequency/report/:id',
      builder: (context, state) {
        final id = int.tryParse(state.pathParameters['id'] ?? '0') ?? 0;
        return FrequencyReportScreen(sessionId: id);
      },
    ),
  ],
);
