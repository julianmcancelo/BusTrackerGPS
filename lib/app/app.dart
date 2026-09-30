import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'router.dart';
import 'theme.dart';
import '../core/services/ota_update_service.dart';
import '../core/services/github_update_service.dart';
import '../core/services/sync_service.dart';
import '../database/database_provider.dart';

class BitacoraGpsApp extends ConsumerStatefulWidget {
  const BitacoraGpsApp({super.key});

  @override
  ConsumerState<BitacoraGpsApp> createState() => _BitacoraGpsAppState();
}

class _BitacoraGpsAppState extends ConsumerState<BitacoraGpsApp> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(otaUpdateProvider.notifier).checkForUpdates();
      ref.read(githubUpdateProvider.notifier).checkForUpdates();
      SyncService.fetchOfficialLines(ref.read(databaseProvider));
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'LANÚS DIGITAL',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: appRouter,
    );
  }
}
