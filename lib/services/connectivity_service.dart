import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';

class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  final Connectivity _connectivity = Connectivity();
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;
  
  bool _isConnected = false;
  bool get isConnected => _isConnected;

  Stream<bool> get onConnectivityChanged => _connectivityStreamController.stream;
  final StreamController<bool> _connectivityStreamController = StreamController<bool>.broadcast();

  Future<void> initialize() async {
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      _updateConnectionStatus,
    );
    _updateConnectionStatus(await _connectivity.checkConnectivity());
  }

  void _updateConnectionStatus(ConnectivityResult result) {
    final wasConnected = _isConnected;
    _isConnected = result == ConnectivityResult.mobile || 
      result == ConnectivityResult.wifi ||
      result == ConnectivityResult.ethernet;
    
    // Notificar apenas se o status mudou
    if (wasConnected != _isConnected) {
      _connectivityStreamController.add(_isConnected);
    }
  }

  Future<bool> checkConnectivity() async {
    final result = await _connectivity.checkConnectivity();
    return result == ConnectivityResult.mobile || 
      result == ConnectivityResult.wifi ||
      result == ConnectivityResult.ethernet;
  }

  void dispose() {
    _connectivitySubscription?.cancel();
    _connectivityStreamController.close();
  }
}
