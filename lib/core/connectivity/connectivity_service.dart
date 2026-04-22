import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Service that exposes a stream of connectivity status.
class ConnectivityService {
  ConnectivityService() : _connectivity = Connectivity() {
    _controller = StreamController<bool>.broadcast();
    _connectivity.onConnectivityChanged.listen((results) {
      final connected = results.any((r) => r != ConnectivityResult.none);
      _controller.add(connected);
    });
  }

  final Connectivity _connectivity;
  late final StreamController<bool> _controller;

  Stream<bool> get isConnectedStream => _controller.stream;

  Future<bool> checkConnectivity() async {
    final results = await _connectivity.checkConnectivity();
    return results.any((r) => r != ConnectivityResult.none);
  }

  void dispose() {
    _controller.close();
  }
}

final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  final service = ConnectivityService();
  ref.onDispose(service.dispose);
  return service;
});
