import 'package:dio/dio.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  late Dio _dio;
  String? _baseUrl;
  
  void initialize({required String baseUrl}) {
    _baseUrl = baseUrl;
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    // Interceptor para logs (apenas em debug)
    _dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      logPrint: (obj) => print(obj),
    ));
  }

  // Métodos de autenticação
  Future<Map<String, dynamic>> login(String username, String password) async {
    final response = await _dio.post('/api/v1/auth/login', data: {
      'username': username,
      'password': password,
    });
    return response.data;
  }

  Future<void> logout() async {
    await _dio.post('/api/v1/auth/logout');
  }

  Future<Map<String, dynamic>> refreshToken(String refreshToken) async {
    final response = await _dio.post('/api/v1/auth/refresh-token', data: {
      'refreshToken': refreshToken,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> getProfile() async {
    final response = await _dio.get('/api/v1/auth/profile');
    return response.data;
  }

  /// Busca permissões do usuário pelo keycloakId
  Future<Set<String>> getUserPermissions(String keycloakId) async {
    try {
      final response = await _dio.get('/api/v1/usuarios/$keycloakId/permissoes');
      final permissoes = response.data['permissoes'] as List<dynamic>?;
      return permissoes != null 
          ? Set<String>.from(permissoes.map((p) => p.toString()))
          : <String>{};
    } catch (e) {
      // Se não conseguir buscar permissões, retorna conjunto vazio
      // O RoleService usará fallback baseado no role
      return <String>{};
    }
  }


  /// Busca minhas inspeções ativas (do inspetor logado) - para home screen
  /// Retorna apenas inspeções com status RASCUNHO, EM_ANDAMENTO ou POR_VERIFICAR
  Future<List<Map<String, dynamic>>> getMinhasInspecoesAtivas() async {
    final response = await _dio.get('/api/v1/mobile/inspecoes/minhas');
    if (response.data is List) {
      return List<Map<String, dynamic>>.from(response.data);
    }
    return [];
  }

  /// Busca todas as inspeções ativas - para tela "Ver Todas Inspeções"
  /// Retorna todas as inspeções com status RASCUNHO, EM_ANDAMENTO ou POR_VERIFICAR
  Future<List<Map<String, dynamic>>> getInspecoesAtivas() async {
    final response = await _dio.get('/api/v1/mobile/inspecoes/ativas');
    if (response.data is List) {
      return List<Map<String, dynamic>>.from(response.data);
    }
    return [];
  }

  /// Busca inspeções não sincronizadas - para modo offline
  Future<List<Map<String, dynamic>>> getInspecoesNaoSincronizadas() async {
    final response = await _dio.get('/api/v1/mobile/inspecoes/nao-sincronizadas');
    if (response.data is List) {
      return List<Map<String, dynamic>>.from(response.data);
    }
    return [];
  }

  /// Cria inspeção via endpoint mobile
  Future<Map<String, dynamic>> createInspectionMobile(Map<String, dynamic> inspectionData) async {
    final response = await _dio.post('/api/v1/mobile/inspecoes', data: inspectionData);
    return response.data;
  }

  /// Cria inspeção (endpoint web - mantido para compatibilidade)
  Future<Map<String, dynamic>> createInspectionOnServer(Map<String, dynamic> inspection) async {
    final response = await _dio.post('/api/v1/inspecoes', data: inspection);
    return response.data;
  }

  /// Atualiza inspeção via endpoint mobile
  Future<Map<String, dynamic>> updateInspectionMobile(String id, Map<String, dynamic> inspectionData) async {
    final response = await _dio.put('/api/v1/mobile/inspecoes/$id', data: inspectionData);
    return response.data;
  }

  /// Atualiza inspeção (endpoint web - mantido para compatibilidade)
  Future<Map<String, dynamic>> updateInspectionOnServer(String id, Map<String, dynamic> inspection) async {
    final response = await _dio.put('/api/v1/inspecoes/$id', data: inspection);
    return response.data;
  }

  /// Busca todos os checklists
  Future<List<Map<String, dynamic>>> getChecklists() async {
    final response = await _dio.get('/api/v1/checklists');
    if (response.data is List) {
      return List<Map<String, dynamic>>.from(response.data);
    }
    return [];
  }

  /// Busca checklists públicos e ativos (endpoint mobile)
  Future<List<Map<String, dynamic>>> getChecklistsPublicos() async {
    try {
      // Tentar endpoint mobile primeiro
      final response = await _dio.get('/api/v1/mobile/checklists/publicos');
      if (response.data is List) {
        return List<Map<String, dynamic>>.from(response.data);
      }
    } catch (e) {
      // Fallback para endpoint web se mobile não estiver disponível
      print('⚠️ Endpoint mobile não disponível, usando endpoint web: $e');
      final response = await _dio.get('/api/v1/checklists/publicos');
      if (response.data is List) {
        return List<Map<String, dynamic>>.from(response.data);
      }
    }
    return [];
  }

  /// Busca checklists por categoria de estabelecimento (endpoint mobile)
  Future<List<Map<String, dynamic>>> getChecklistsPorCategoriaEstabelecimento(String categoria) async {
    try {
      // Tentar endpoint mobile primeiro
      final response = await _dio.get('/api/v1/mobile/checklists/por-categoria-estabelecimento/$categoria');
      if (response.data is List) {
        return List<Map<String, dynamic>>.from(response.data);
      }
    } catch (e) {
      // Fallback para endpoint web se mobile não estiver disponível
      print('⚠️ Endpoint mobile não disponível, usando endpoint web: $e');
      final response = await _dio.get('/api/v1/checklists/por-categoria-estabelecimento/$categoria');
      if (response.data is List) {
        return List<Map<String, dynamic>>.from(response.data);
      }
    }
    return [];
  }

  // Métodos de configuração
  void setAuthToken(String token) {
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  void clearAuthToken() {
    _dio.options.headers.remove('Authorization');
  }

  String? get baseUrl => _baseUrl;
}
