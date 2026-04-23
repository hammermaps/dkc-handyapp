import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/api_client.dart';
import '../../../../core/auth/token_storage.dart';
import '../../../../core/providers.dart';
import '../../../../shared/models/permissions_model.dart';
import '../../../../shared/models/user_model.dart';
import '../../data/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final tokenStorage = ref.watch(tokenStorageProvider);
  return AuthRepository(
    tokenStorage: tokenStorage,
    apiClientFactory: (baseUrl, tokenGetter) => ApiClient(
      baseUrl: baseUrl,
      tokenGetter: tokenGetter,
    ),
  );
});

// ──────────────────────────── Auth State ────────────────────────────

enum AuthStatus { initial, authenticated, unauthenticated }

class AuthState {
  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.errorMessage,
  });

  final AuthStatus status;
  final UserModel? user;
  final String? errorMessage;

  bool get isAuthenticated => status == AuthStatus.authenticated;
  bool get isLoading => status == AuthStatus.initial;

  AuthState copyWith({
    AuthStatus? status,
    UserModel? user,
    String? errorMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      errorMessage: errorMessage,
    );
  }
}

class AuthNotifier extends AsyncNotifier<AuthState> {
  @override
  Future<AuthState> build() async {
    final repo = ref.watch(authRepositoryProvider);
    final isAuth = await repo.getAuthStatus();
    if (isAuth) {
      try {
        final user = await repo.getUserInfo();
        return AuthState(status: AuthStatus.authenticated, user: user);
      } catch (_) {
        return const AuthState(status: AuthStatus.unauthenticated);
      }
    }
    return const AuthState(status: AuthStatus.unauthenticated);
  }

  Future<void> login({
    required String username,
    required String password,
    required String serverUrl,
  }) async {
    state = const AsyncValue.loading();
    final repo = ref.read(authRepositoryProvider);
    state = await AsyncValue.guard(() async {
      final user = await repo.login(
        username: username,
        password: password,
        serverUrl: serverUrl,
      );
      return AuthState(status: AuthStatus.authenticated, user: user);
    });
  }

  Future<void> logout() async {
    final repo = ref.read(authRepositoryProvider);
    await repo.logout();
    state = const AsyncValue.data(AuthState(status: AuthStatus.unauthenticated));
  }
}

final authStateProvider = AsyncNotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);

// ──────────────────────────── Permissions ────────────────────────────

final userPermissionsProvider = FutureProvider<PermissionsModel?>((ref) async {
  final repo = ref.watch(authRepositoryProvider);
  return repo.getCachedPermissions();
});

// ──────────────────────────── Current User ────────────────────────────

final currentUserProvider = Provider<UserModel?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.valueOrNull?.user;
});
