import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Service that exposes a stream of connectivity status.
class ConnectivityService {
  ConnectivityService() : _connectivity = Connectivity() {
    _controller = StreamController<bool>.broadcast();
    _subscription = _connectivity.onConnectivityChanged.listen((results) {
      final connected = results.any((r) => r != ConnectivityResult.none);
      _controller.add(connected);
    });
    // Emit initial connectivity state immediately.
    _connectivity.checkConnectivity().then((results) {
      if (!_controller.isClosed) {
        _controller.add(results.any((r) => r != ConnectivityResult.none));
      }
    });
  }

  final Connectivity _connectivity;
  late final StreamController<bool> _controller;
  late final StreamSubscription<List<ConnectivityResult>> _subscription;

  Stream<bool> get isConnectedStream => _controller.stream;

  Future<bool> checkConnectivity() async {
    final results = await _connectivity.checkConnectivity();
    return results.any((r) => r != ConnectivityResult.none);
  }

  void dispose() {
    _subscription.cancel();
    _controller.close();
  }
}

final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  final service = ConnectivityService();
  ref.onDispose(service.dispose);
  return service;
});
