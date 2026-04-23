import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api/api_client.dart';
import 'auth/token_storage.dart';
import 'connectivity/connectivity_service.dart';
import 'db/database.dart';

export 'connectivity/connectivity_service.dart' show connectivityServiceProvider;

final tokenStorageProvider = Provider<TokenStorage>((ref) => TokenStorage());

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

/// Provides the ApiClient configured with the stored server URL.
/// Falls back to a placeholder URL if none is stored yet.
final apiClientProvider = Provider<ApiClient>((ref) {
  final tokenStorage = ref.watch(tokenStorageProvider);
  return ApiClient(
    baseUrl: 'https://placeholder.invalid',
    tokenGetter: () => null,
  );
});

/// Creates an ApiClient bound to a specific server URL and live token getter.
ApiClient createApiClient({
  required String baseUrl,
  required String? Function() tokenGetter,
}) {
  return ApiClient(baseUrl: baseUrl, tokenGetter: tokenGetter);
}

/// App-wide selected project ID. Shared across all feature modules so that
/// every screen respects the project chosen on the Dashboard.
final selectedProjectIdProvider = StateProvider<int?>((ref) => null);
