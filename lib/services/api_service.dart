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


  /// Alias de [getInspecoesAtivas] (`GET .../minhas` — mesmo critério no servidor).
  Future<List<Map<String, dynamic>>> getMinhasInspecoesAtivas() async {
    final response = await _dio.get('/api/v1/mobile/inspecoes/minhas');
    if (response.data is List) {
      return List<Map<String, dynamic>>.from(response.data);
    }
    return [];
  }

  /// Inspeções em curso visíveis para o utilizador (equipa / supervisor / inspetor designado).
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

  /// Detalhe da inspeção no servidor (inclui `inspetor` com nome, checklist, equipa, etc.)
  /// Usa primeiro o endpoint mobile (mesma visibilidade que a lista; não exige INSPECAO_VISUALIZAR).
  Future<Map<String, dynamic>> getInspecaoById(String id) async {
    try {
      final response = await _dio.get('/api/v1/mobile/inspecoes/$id');
      return response.data as Map<String, dynamic>;
    } catch (e) {
      final response = await _dio.get('/api/v1/inspecoes/$id');
      return response.data as Map<String, dynamic>;
    }
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

  /// Busca checklists por **nome** da categoria de estabelecimento (API compara por nome).
  /// Preferir [getChecklistsPorCategoriaEstabelecimentoId] quando tiver o UUID.
  Future<List<Map<String, dynamic>>> getChecklistsPorCategoriaEstabelecimento(String categoriaNome) async {
    final encoded = Uri.encodeComponent(categoriaNome.trim());
    try {
      final response = await _dio.get(
        '/api/v1/mobile/checklists/por-categoria-estabelecimento/$encoded',
      );
      if (response.data is List) {
        return List<Map<String, dynamic>>.from(response.data);
      }
    } catch (e) {
      print('⚠️ Endpoint mobile não disponível, usando endpoint web: $e');
      final response = await _dio.get(
        '/api/v1/checklists/por-categoria-estabelecimento/$encoded',
      );
      if (response.data is List) {
        return List<Map<String, dynamic>>.from(response.data);
      }
    }
    return [];
  }

  /// Lista checklists públicos ativos pela categoria de estabelecimento (UUID) — alinhado ao backoffice web.
  Future<List<Map<String, dynamic>>> getChecklistsPorCategoriaEstabelecimentoId(
      String categoriaEstabelecimentoId) async {
    try {
      final response = await _dio.get(
        '/api/v1/mobile/checklists/por-categoria-estabelecimento-id/$categoriaEstabelecimentoId',
      );
      if (response.data is List) {
        return List<Map<String, dynamic>>.from(response.data);
      }
    } catch (e) {
      print('⚠️ GET por-categoria-estabelecimento-id mobile falhou: $e');
      final response = await _dio.get(
        '/api/v1/checklists/por-categoria-estabelecimento-id/$categoriaEstabelecimentoId',
      );
      if (response.data is List) {
        return List<Map<String, dynamic>>.from(response.data);
      }
    }
    return [];
  }

  /// Busca checklist completo com itens (endpoint mobile)
  Future<Map<String, dynamic>> getChecklistCompleto(String id) async {
    try {
      final response = await _dio.get('/api/v1/mobile/checklists/$id/completo');
      return response.data as Map<String, dynamic>;
    } catch (e) {
      // Fallback para endpoint web
      print('⚠️ Endpoint mobile não disponível, usando endpoint web: $e');
      final response = await _dio.get('/api/v1/checklists/$id');
      return response.data as Map<String, dynamic>;
    }
  }

  /// Busca todas as equipes ativas (endpoint mobile)
  Future<List<Map<String, dynamic>>> getEquipesAtivas() async {
    try {
      // Tentar endpoint mobile primeiro
      final response = await _dio.get('/api/v1/mobile/equipes/ativas');
      if (response.data is List) {
        return List<Map<String, dynamic>>.from(response.data);
      }
    } catch (e) {
      // Fallback para endpoint web
      print('⚠️ Endpoint mobile não disponível, usando endpoint web: $e');
      final response = await _dio.get('/api/v1/equipes');
      if (response.data is List) {
        return List<Map<String, dynamic>>.from(response.data);
      }
    }
    return [];
  }

  /// Busca equipe completa com membros (endpoint mobile)
  Future<Map<String, dynamic>> getEquipeCompleta(String id) async {
    try {
      final response = await _dio.get('/api/v1/mobile/equipes/$id/completa');
      return response.data as Map<String, dynamic>;
    } catch (e) {
      // Fallback para endpoint web
      print('⚠️ Endpoint mobile não disponível, usando endpoint web: $e');
      final equipeResponse = await _dio.get('/api/v1/equipes/$id');
      final membrosResponse = await _dio.get('/api/v1/equipes/$id/membros');
      
      final equipe = equipeResponse.data as Map<String, dynamic>;
      final membros = membrosResponse.data as List<dynamic>;
      equipe['membros'] = membros;
      
      return equipe;
    }
  }

  // Métodos de configuração
  void setAuthToken(String token) {
    if (_baseUrl == null) return;
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  void clearAuthToken() {
    if (_baseUrl == null) return;
    _dio.options.headers.remove('Authorization');
  }

  String? get baseUrl => _baseUrl;
}
