import 'dart:io';

import 'package:flutter/foundation.dart';

/// Configurações da aplicação
class AppConfig {
  // ── API: prioridade ─────────────────────────────────────────────────────
  // 1) API_BASE_URL — URL completa (ignora local/remoto)
  // 2) API_TARGET=local | remote — escolhe base local ou a URL remota abaixo
  //
  // Exemplos:
  //   flutter run --dart-define=API_TARGET=local
  //   flutter run --dart-define=API_TARGET=remote
  //   flutter run --dart-define=API_BASE_URL=http://192.168.1.50:8081
  //   flutter run --dart-define=API_TARGET=local --dart-define=API_LOCAL_HOST=192.168.1.50
  //   flutter run --dart-define=API_TARGET=local --dart-define=API_LOCAL_PORT=8081
  // ─────────────────────────────────────────────────────────────────────────

  static const String _apiBaseUrlOverride = String.fromEnvironment('API_BASE_URL');

  /// `local` → backend na máquina de desenvolvimento; qualquer outro valor → remoto.
  static const String _apiTarget = String.fromEnvironment('API_TARGET', defaultValue: 'remote');

  /// IP ou hostname do PC quando corre local em Android físico / iOS dispositivo.
  static const String _apiLocalHost = String.fromEnvironment('API_LOCAL_HOST');

  static const int _apiLocalPort = int.fromEnvironment('API_LOCAL_PORT', defaultValue: 8081);

  /// API alinhada ao frontend web / ambiente partilhado (produção ou staging).
  static const String _remoteApiBaseUrl = String.fromEnvironment(
    'API_REMOTE_URL',
    defaultValue: 'https://api.inspecao.rubenpires.dev',
  );

  /// URL base da API backend (sem barra final).
  static String get apiBaseUrl {
    final override = _apiBaseUrlOverride.trim();
    if (override.isNotEmpty) {
      return _stripTrailingSlash(override);
    }

    final useLocal = _apiTarget.toLowerCase() == 'local';
    if (!useLocal) {
      return _stripTrailingSlash(_remoteApiBaseUrl.trim());
    }

    return _stripTrailingSlash(_localBaseUrl());
  }

  static String _localBaseUrl() {
    final port = _apiLocalPort;
    final customHost = _apiLocalHost.trim();

    if (kIsWeb) {
      final host = customHost.isNotEmpty ? customHost : 'localhost';
      return 'http://$host:$port';
    }

    if (Platform.isAndroid) {
      // Emulador: 10.0.2.2 mapeia para o host. Dispositivo físico: defina API_LOCAL_HOST.
      final host = customHost.isNotEmpty ? customHost : '10.0.2.2';
      return 'http://$host:$port';
    }

    if (Platform.isIOS) {
      // Simulador: localhost. Dispositivo físico: defina API_LOCAL_HOST (mesma rede Wi‑Fi).
      final host = customHost.isNotEmpty ? customHost : 'localhost';
      return 'http://$host:$port';
    }

    // Windows, macOS, Linux
    final host = customHost.isNotEmpty ? customHost : 'localhost';
    return 'http://$host:$port';
  }

  static String _stripTrailingSlash(String url) {
    if (url.length > 1 && url.endsWith('/')) {
      return url.substring(0, url.length - 1);
    }
    return url;
  }

  /// Indica se a configuração actual aponta para backend local (útil para logs / debug).
  static bool get isLocalApi {
    final override = _apiBaseUrlOverride.trim();
    if (override.isNotEmpty) {
      final o = override.toLowerCase();
      return o.contains('localhost') ||
          o.contains('127.0.0.1') ||
          o.contains('10.0.2.2') ||
          o.startsWith('http://192.168.') ||
          o.startsWith('http://10.');
    }
    return _apiTarget.toLowerCase() == 'local';
  }

  // Timeout para requisições HTTP (em segundos)
  static const int httpTimeout = 30;

  // Tempo de expiração do token (em segundos) - margem de segurança
  static const int tokenRefreshMargin = 300; // 5 minutos antes de expirar
}
