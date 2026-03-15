import 'dart:async';
import 'dart:math' as math;
import 'package:geolocator/geolocator.dart';
import 'package:inspecao/utils/app_logger.dart';

/// Resultado da validação de localização
class LocationValidationResult {
  final bool dentroDoRaio;
  final double? distanciaMetros;
  final double? latitude;
  final double? longitude;
  final double? accuracy;
  final String? erro;

  const LocationValidationResult({
    required this.dentroDoRaio,
    this.distanciaMetros,
    this.latitude,
    this.longitude,
    this.accuracy,
    this.erro,
  });

  bool get temLocalizacao => latitude != null && longitude != null;
}

/// Serviço de GPS para rastreamento e validação de localização.
///
/// Responsabilidades:
///  - Pedir permissões de localização
///  - Obter posição actual (alta precisão)
///  - Calcular distância entre dois pontos (Haversine)
///  - Validar se o utilizador está dentro de um raio (default 10m)
///  - Emitir stream de posição para rastreamento em background
class GpsService {
  static final GpsService _instance = GpsService._internal();
  factory GpsService() => _instance;
  GpsService._internal();

  StreamSubscription<Position>? _trackingSubscription;
  final _positionController = StreamController<Position>.broadcast();

  /// Stream de posições para rastreamento externo
  Stream<Position> get positionStream => _positionController.stream;

  bool _isTracking = false;
  bool get isTracking => _isTracking;

  Position? _lastPosition;
  Position? get lastPosition => _lastPosition;

  // ── Permissões ─────────────────────────────────────────────────────────────

  /// Verifica e solicita permissões. Retorna true se OK.
  Future<bool> ensurePermissions() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      AppLogger.log('⚠️ [GpsService] serviço de localização desactivado');
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        AppLogger.log('⚠️ [GpsService] permissão negada');
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      AppLogger.log('⚠️ [GpsService] permissão negada permanentemente');
      return false;
    }

    return true;
  }

  // ── Obter posição actual ───────────────────────────────────────────────────

  /// Obtém a posição actual com alta precisão.
  /// Timeout de 15s; em caso de falha retorna null.
  Future<Position?> getCurrentPosition() async {
    try {
      final ok = await ensurePermissions();
      if (!ok) return null;

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15),
      );
      _lastPosition = pos;
      AppLogger.log('📍 [GpsService.getCurrentPosition] '
          'lat=${pos.latitude.toStringAsFixed(6)} '
          'lng=${pos.longitude.toStringAsFixed(6)} '
          'acc=${pos.accuracy.toStringAsFixed(1)}m');
      return pos;
    } catch (e) {
      AppLogger.log('❌ [GpsService.getCurrentPosition] erro: $e');
      return null;
    }
  }

  // ── Validação de localização ───────────────────────────────────────────────

  /// Valida se o utilizador está dentro de [raioMetros] do ponto
  /// [estLat]/[estLng] do estabelecimento.
  /// Default raio = 10m (igual à web).
  Future<LocationValidationResult> validarLocalizacao({
    required double estLat,
    required double estLng,
    double raioMetros = 10.0,
  }) async {
    final ok = await ensurePermissions();
    if (!ok) {
      return const LocationValidationResult(
        dentroDoRaio: false,
        erro: 'Permissão de localização não concedida.',
      );
    }

    final pos = await getCurrentPosition();
    if (pos == null) {
      return const LocationValidationResult(
        dentroDoRaio: false,
        erro: 'Não foi possível obter a localização actual.',
      );
    }

    final dist = _haversineMetros(
        pos.latitude, pos.longitude, estLat, estLng);

    AppLogger.log('📏 [GpsService.validarLocalizacao] '
        'distancia=${dist.toStringAsFixed(1)}m raio=${raioMetros}m '
        'dentro=${dist <= raioMetros}');

    return LocationValidationResult(
      dentroDoRaio: dist <= raioMetros,
      distanciaMetros: dist,
      latitude: pos.latitude,
      longitude: pos.longitude,
      accuracy: pos.accuracy,
    );
  }

  // ── Rastreamento background ────────────────────────────────────────────────

  /// Inicia o rastreamento contínuo (intervalo ~30s, distancia mínima 5m).
  /// Cada posição é emitida em [positionStream].
  Future<void> startTracking() async {
    if (_isTracking) return;

    final ok = await ensurePermissions();
    if (!ok) {
      AppLogger.log('⚠️ [GpsService.startTracking] sem permissão');
      return;
    }

    const settings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 5, // só emite se mover mais de 5m
    );

    _trackingSubscription = Geolocator.getPositionStream(
      locationSettings: settings,
    ).listen(
      (pos) {
        _lastPosition = pos;
        _positionController.add(pos);
        AppLogger.log('🛰️ [GpsService.tracking] '
            'lat=${pos.latitude.toStringAsFixed(5)} '
            'lng=${pos.longitude.toStringAsFixed(5)} '
            'acc=${pos.accuracy.toStringAsFixed(1)}m');
      },
      onError: (e) {
        AppLogger.log('❌ [GpsService.tracking] erro: $e');
      },
    );

    _isTracking = true;
    AppLogger.log('▶️ [GpsService] rastreamento INICIADO');
  }

  /// Para o rastreamento e liberta recursos.
  Future<void> stopTracking() async {
    await _trackingSubscription?.cancel();
    _trackingSubscription = null;
    _isTracking = false;
    AppLogger.log('⏹️ [GpsService] rastreamento PARADO');
  }

  void dispose() {
    stopTracking();
    _positionController.close();
  }

  // ── Haversine ─────────────────────────────────────────────────────────────

  /// Distância em metros entre dois pontos geográficos (fórmula de Haversine).
  double _haversineMetros(double lat1, double lng1, double lat2, double lng2) {
    const r = 6371000.0; // raio da Terra em metros
    final dLat = _toRad(lat2 - lat1);
    final dLng = _toRad(lng2 - lng1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRad(lat1)) *
            math.cos(_toRad(lat2)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return r * c;
  }

  double _toRad(double deg) => deg * math.pi / 180;
}