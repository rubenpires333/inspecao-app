import 'dart:io';
import 'package:flutter/foundation.dart';

/// Configurações da aplicação
class AppConfig {
  // URL base da API backend
  // Para Android Emulador: use http://10.0.2.2:8081
  // Para dispositivo físico: use http://SEU_IP_LOCAL:8081
  // Para produção: use https://api.inspev.com
  static String get apiBaseUrl {
    // Verificar se foi definido via variável de ambiente (PRIORIDADE)
    const envUrl = String.fromEnvironment('API_BASE_URL');
    if (envUrl.isNotEmpty) {
      return envUrl;
    }
    
    // Se não foi definido, detectar automaticamente
    if (kIsWeb) {
      // Web usa localhost normalmente
      return 'https://api.inspecao.rubenpires.dev';
    } else if (Platform.isAndroid) {
      // Android: 
      // - Emulador: usar 10.0.2.2 (mapeia para localhost do host)
      // - Dispositivo físico: precisa do IP da máquina host
      // Por padrão, tentar 10.0.2.2 (funciona no emulador)
      // Para dispositivo físico, defina: flutter run --dart-define=API_BASE_URL=http://SEU_IP:8081
      return 'https://api.inspecao.rubenpires.dev';
    } else if (Platform.isIOS) {
      // iOS: usar localhost normalmente
      return 'https://api.inspecao.rubenpires.dev';
    } else {
      // Desktop: usar localhost normalmente
      return 'https://api.inspecao.rubenpires.dev';
    }
  }
  
  /// Instruções para configurar URL em dispositivo físico Android
  /// Execute: flutter run --dart-define=API_BASE_URL=http://SEU_IP:8081
  /// Onde SEU_IP é o IP da sua máquina na rede local (ex: 192.168.1.100)

  // Timeout para requisições HTTP (em segundos)
  static const int httpTimeout = 30;

  // Tempo de expiração do token (em segundos) - margem de segurança
  static const int tokenRefreshMargin = 300; // 5 minutos antes de expirar
}
