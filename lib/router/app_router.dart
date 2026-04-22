import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/presentation/providers/auth_provider.dart';
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/auth/presentation/screens/token_management_screen.dart';
import '../features/building/presentation/screens/building_inspection_detail_screen.dart';
import '../features/building/presentation/screens/building_inspections_screen.dart';
import '../features/building/presentation/screens/building_list_screen.dart';
import '../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../features/keys/presentation/screens/keys_screen.dart';
import '../features/klima/presentation/screens/klima_screen.dart';
import '../features/mm/presentation/screens/mm_detail_screen.dart';
import '../features/mm/presentation/screens/mm_list_screen.dart';
import '../features/nea/presentation/screens/nea_dashboard_screen.dart';
import '../features/nea/presentation/screens/nea_inspection_detail_screen.dart';
import '../features/nea/presentation/screens/nea_inspections_screen.dart';
import '../features/nea/presentation/screens/nea_systems_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final isAuth = authState.valueOrNull?.isAuthenticated ?? false;
      final isLoading = authState.isLoading;
      final isLoginPage = state.matchedLocation == '/login';

      if (isLoading) return null;
      if (!isAuth && !isLoginPage) return '/login';
      if (isAuth && isLoginPage) return '/';
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/', builder: (_, __) => const DashboardScreen()),
      GoRoute(path: '/tokens', builder: (_, __) => const TokenManagementScreen()),
      GoRoute(path: '/nea', builder: (_, __) => const NeaDashboardScreen()),
      GoRoute(path: '/nea/systems', builder: (_, __) => const NeaSystemsScreen()),
      GoRoute(
        path: '/nea/inspections',
        builder: (_, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return NeaInspectionsScreen(
            systemId: extra?['systemId'] as int?,
            systemName: extra?['systemName'] as String?,
          );
        },
      ),
      GoRoute(
        path: '/nea/inspection/:id',
        builder: (_, state) =>
            NeaInspectionDetailScreen(id: int.parse(state.pathParameters['id']!)),
      ),
      GoRoute(path: '/mm', builder: (_, __) => const MmListScreen()),
      GoRoute(
        path: '/mm/:uid',
        builder: (_, state) =>
            MmDetailScreen(uid: state.pathParameters['uid']!),
      ),
      GoRoute(path: '/building', builder: (_, __) => const BuildingListScreen()),
      GoRoute(
        path: '/building/:id/inspections',
        builder: (_, state) => BuildingInspectionsScreen(
            buildingId: int.parse(state.pathParameters['id']!)),
      ),
      GoRoute(
        path: '/building/inspection/:id',
        builder: (_, state) => BuildingInspectionDetailScreen(
            id: int.parse(state.pathParameters['id']!)),
      ),
      GoRoute(path: '/klima', builder: (_, __) => const KlimaScreen()),
      GoRoute(path: '/keys', builder: (_, __) => const KeysScreen()),
    ],
  );
});
