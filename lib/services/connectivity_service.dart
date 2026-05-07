import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';
import 'package:flutter/foundation.dart';

/// Estado de rede para modo offline-first.
/// Suporta `ConnectivityResult` ou `List<ConnectivityResult>` conforme versão da plataforma / pacote.
class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  final Connectivity _connectivity = Connectivity();
  StreamSubscription<dynamic>? _connectivitySubscription;

  bool _isConnected = false;
  bool get isConnected => _isConnected;

  /// Notificação para widgets (`ValueListenableBuilder`).
  /// Inicia pessimista; [initialize] (ex.: em `main`) atualiza após o primeiro check.
  final ValueNotifier<bool> onlineNotifier = ValueNotifier<bool>(false);

  Stream<bool> get onConnectivityChanged => _connectivityStreamController.stream;
  final StreamController<bool> _connectivityStreamController =
      StreamController<bool>.broadcast();

  List<ConnectivityResult> _asResultList(dynamic raw) {
    if (raw is List<ConnectivityResult>) return raw;
    if (raw is ConnectivityResult) return [raw];
    return const [];
  }

  void _applyRaw(dynamic raw) {
    final list = _asResultList(raw);
    final connected =
        list.isEmpty ? false : list.any((r) => r != ConnectivityResult.none);

    final wasConnected = _isConnected;
    _isConnected = connected;
    onlineNotifier.value = _isConnected;

    if (wasConnected != _isConnected) {
      _connectivityStreamController.add(_isConnected);
    }
  }

  Future<void> initialize() async {
    await _connectivitySubscription?.cancel();
    _connectivitySubscription =
        _connectivity.onConnectivityChanged.listen(_applyRaw);
    _applyRaw(await _connectivity.checkConnectivity());
  }

  Future<bool> checkConnectivity() async {
    final raw = await _connectivity.checkConnectivity();
    final list = _asResultList(raw);
    return list.isNotEmpty &&
        list.any((r) => r != ConnectivityResult.none);
  }

  void dispose() {
    _connectivitySubscription?.cancel();
    _connectivityStreamController.close();
  }
}
