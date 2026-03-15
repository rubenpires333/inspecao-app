import 'package:dio/dio.dart';
import 'package:inspecao/config/app_config.dart';
import 'package:inspecao/models/checklist_secao.dart';
import 'package:inspecao/services/api_service.dart';
import 'package:inspecao/services/auth_service.dart';
import 'package:inspecao/utils/app_logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Serviço dedicado para operações de Inspeção:
///  - Seções do checklist  → GET /api/v1/secoes-checklist/checklist/{id}
///  - Itens por seção      → GET /api/v1/itens-checklist/secao/{id}
///  - Respostas            → GET /api/v1/inspecoes/{id}/respostas
///  - Salvar resposta      → POST /api/v1/inspecoes/{id}/respostas
///
/// NOTA: NÃO faz cache do Dio – o token é obtido de fresco em cada chamada
/// para evitar 401 após expiração silenciosa.
class InspecaoService {
  // ── Construtor de Dio sem cache ───────────────────────────────────────────

  Future<Dio> _buildDio() async {
    final dio = Dio(BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    try {
      final apiService = ApiService();
      if (apiService.baseUrl == null) {
        apiService.initialize(baseUrl: AppConfig.apiBaseUrl);
      }
      final prefs = await SharedPreferences.getInstance();
      final authService = AuthService(apiService, prefs);
      final token = await authService.getAccessToken();
      if (token != null && token.isNotEmpty) {
        dio.options.headers['Authorization'] = 'Bearer $token';
        AppLogger.log('🔑 [InspecaoService] token OK (${token.length} chars)');
      } else {
        AppLogger.log('⚠️ [InspecaoService] token NULO – requests podem falhar com 401');
      }
    } catch (e, st) {
      AppLogger.error('[InspecaoService] Erro ao obter token', e, st);
    }

    return dio;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Checklist
  // ─────────────────────────────────────────────────────────────────────────

  /// GET /api/v1/checklists/{checklistId}
  Future<Map<String, dynamic>> getChecklist(String checklistId) async {
    AppLogger.log('🌐 [InspecaoService.getChecklist] → GET /api/v1/checklists/$checklistId');
    final dio = await _buildDio();
    try {
      final response = await dio.get('/api/v1/checklists/$checklistId');
      AppLogger.log('✅ [InspecaoService.getChecklist] status=${response.statusCode}');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleError('getChecklist', e);
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Seções
  // ─────────────────────────────────────────────────────────────────────────

  /// GET /api/v1/secoes-checklist/checklist/{checklistId}
  Future<List<SecaoChecklistCompleta>> getSecoesByChecklist(String checklistId) async {
    AppLogger.log('🌐 [InspecaoService.getSecoesByChecklist] → GET /api/v1/secoes-checklist/checklist/$checklistId');
    final dio = await _buildDio();
    try {
      final response = await dio.get('/api/v1/secoes-checklist/checklist/$checklistId');
      AppLogger.log('✅ [InspecaoService.getSecoesByChecklist] status=${response.statusCode} '
          'tipoResposta=${response.data.runtimeType}');

      final raw = _extractList(response.data, 'getSecoesByChecklist');
      AppLogger.log('📦 [InspecaoService.getSecoesByChecklist] raw.length=${raw.length}');

      final secoes = raw
          .map((s) => SecaoChecklistCompleta.fromJson(s as Map<String, dynamic>))
          .where((s) => s.ativo)
          .toList()
        ..sort((a, b) => a.ordem.compareTo(b.ordem));

      AppLogger.log('📋 [InspecaoService.getSecoesByChecklist] secoes_ativas=${secoes.length}');
      for (final s in secoes) {
        AppLogger.log('   ▶ secao id=${s.id} titulo="${s.titulo}" ordem=${s.ordem}');
      }
      return secoes;
    } on DioException catch (e) {
      throw _handleError('getSecoesByChecklist', e);
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Itens
  // ─────────────────────────────────────────────────────────────────────────

  /// GET /api/v1/itens-checklist/secao/{secaoId}
  Future<List<ItemChecklistCompleto>> getItensBySecao(String secaoId) async {
    AppLogger.log('🌐 [InspecaoService.getItensBySecao] → GET /api/v1/itens-checklist/secao/$secaoId');
    final dio = await _buildDio();
    try {
      final response = await dio.get('/api/v1/itens-checklist/secao/$secaoId');
      AppLogger.log('✅ [InspecaoService.getItensBySecao] secao=$secaoId status=${response.statusCode}');

      final raw = _extractList(response.data, 'getItensBySecao');
      AppLogger.log('📦 [InspecaoService.getItensBySecao] secao=$secaoId raw.length=${raw.length}');

      final itens = raw
          .map((i) => ItemChecklistCompleto.fromJson(i as Map<String, dynamic>))
          .where((i) => i.ativo)
          .toList()
        ..sort((a, b) => a.ordem.compareTo(b.ordem));

      AppLogger.log('📋 [InspecaoService.getItensBySecao] secao=$secaoId itens_ativos=${itens.length}');
      for (final item in itens) {
        AppLogger.log('      • item id=${item.id} rotulo="${item.rotulo}" '
            'tipo=${item.tipo.name} opcoes=${item.opcoes.length} obrigatorio=${item.obrigatorio}');
      }
      return itens;
    } on DioException catch (e) {
      throw _handleError('getItensBySecao', e);
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Carregamento completo (seções + subseções + itens)
  // ─────────────────────────────────────────────────────────────────────────

  /// Carrega seções e, para cada uma, os seus itens directos E os itens de cada
  /// subseção — exactamente o mesmo que a web faz em [carregarItensDasSecoes].
  ///
  /// Estrutura esperada (igual à web):
  ///   Secao principal  (pode ter itens directos ou apenas subseções)
  ///     └─ Subseção A  (tem os itens reais)
  ///     └─ Subseção B  (tem os itens reais)
  Future<List<SecaoChecklistCompleta>> getChecklistCompleto(String checklistId) async {
    AppLogger.log('🚀 [InspecaoService.getChecklistCompleto] START checklistId=$checklistId');

    final secoes = await getSecoesByChecklist(checklistId);
    AppLogger.log('📂 [InspecaoService.getChecklistCompleto] secoes=${secoes.length} – a carregar itens...');

    // Para cada seção: carregar itens directos E itens de cada subseção em paralelo
    await Future.wait(secoes.map((secao) async {
      // Itens directos da seção
      secao.itens = await getItensBySecao(secao.id);
      AppLogger.log('   ✓ secao "${secao.titulo}" → ${secao.itens.length} itens directos');

      // Itens das subseções (padrão idêntico ao da web: carregarItensDasSecoes)
      if (secao.subsecoes.isNotEmpty) {
        AppLogger.log('   🔽 "${secao.titulo}" tem ${secao.subsecoes.length} subseções – a carregar itens...');
        await Future.wait(secao.subsecoes.map((sub) async {
          sub.itens = await getItensBySecao(sub.id);
          AppLogger.log('      ↳ subsecao "${sub.titulo}" → ${sub.itens.length} itens');

          // Subseções de 2.º nível (caso existam)
          if (sub.subsecoes.isNotEmpty) {
            await Future.wait(sub.subsecoes.map((sub2) async {
              sub2.itens = await getItensBySecao(sub2.id);
              AppLogger.log('         ↳↳ sub2 "${sub2.titulo}" → ${sub2.itens.length} itens');
            }));
          }
        }));
      }
    }));

    final totalItens = secoes.fold<int>(0, (acc, s) {
      var t = s.itens.length;
      for (final sub in s.subsecoes) {
        t += sub.itens.length;
        for (final sub2 in sub.subsecoes) t += sub2.itens.length;
      }
      return acc + t;
    });

    AppLogger.log('✅ [InspecaoService.getChecklistCompleto] DONE '
        'checklistId=$checklistId secoes=${secoes.length} totalItens=$totalItens');
    return secoes;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Respostas
  // ─────────────────────────────────────────────────────────────────────────

  /// GET /api/v1/inspecoes/{inspecaoId}/respostas
  Future<List<RespostaInspecaoCompleta>> getRespostas(String inspecaoId) async {
    AppLogger.log('🌐 [InspecaoService.getRespostas] → GET /api/v1/inspecoes/$inspecaoId/respostas');
    final dio = await _buildDio();
    try {
      final response = await dio.get('/api/v1/inspecoes/$inspecaoId/respostas');
      AppLogger.log('✅ [InspecaoService.getRespostas] status=${response.statusCode}');

      final raw = _extractList(response.data, 'getRespostas');
      final respostas = raw
          .map((r) => RespostaInspecaoCompleta.fromJson(r as Map<String, dynamic>))
          .toList();

      AppLogger.log('📋 [InspecaoService.getRespostas] inspecao=$inspecaoId respostas=${respostas.length}');
      for (final r in respostas) {
        AppLogger.log('   ↳ resposta itemId=${r.itemChecklistId} '
            'opcaoId=${r.opcaoId} valorTexto=${r.valorTexto} '
            'valorNumero=${r.valorNumero} valorRating=${r.valorRating}');
      }
      return respostas;
    } on DioException catch (e) {
      throw _handleError('getRespostas', e);
    }
  }

  /// POST /api/v1/inspecoes/{inspecaoId}/respostas
  Future<RespostaInspecaoCompleta> salvarResposta(
      String inspecaoId, Map<String, dynamic> payload) async {
    final preview = Map<String, dynamic>.from(payload)
      ..remove('arquivo'); // não logar blobs
    AppLogger.log('📝 [InspecaoService.salvarResposta] → POST /api/v1/inspecoes/$inspecaoId/respostas '
        'payload=$preview');
    final dio = await _buildDio();
    try {
      final response = await dio.post(
        '/api/v1/inspecoes/$inspecaoId/respostas',
        data: payload,
      );
      AppLogger.log('✅ [InspecaoService.salvarResposta] status=${response.statusCode}');
      return RespostaInspecaoCompleta.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleError('salvarResposta', e);
    }
  }


  // ─────────────────────────────────────────────────────────────────────────
  // Validação e Finalização
  // ─────────────────────────────────────────────────────────────────────────

  /// GET /api/v1/inspecoes/{id}/validar
  Future<Map<String, dynamic>> validar(String inspecaoId) async {
    AppLogger.log('🔍 [InspecaoService.validar] → GET /api/v1/inspecoes/$inspecaoId/validar');
    final dio = await _buildDio();
    try {
      final response = await dio.get('/api/v1/inspecoes/$inspecaoId/validar');
      AppLogger.log('✅ [InspecaoService.validar] status=${response.statusCode}');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleError('validar', e);
    }
  }

  /// POST /api/v1/inspecoes/{id}/finalizar
  /// payload: { latitude?, longitude?, precisaoGps? }
  Future<Map<String, dynamic>> finalizar(
      String inspecaoId, Map<String, dynamic> payload) async {
    AppLogger.log('🏁 [InspecaoService.finalizar] → POST /api/v1/inspecoes/$inspecaoId/finalizar payload=$payload');
    final dio = await _buildDio();
    try {
      final response = await dio.post(
        '/api/v1/inspecoes/$inspecaoId/finalizar',
        data: payload,
      );
      AppLogger.log('✅ [InspecaoService.finalizar] status=${response.statusCode}');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleError('finalizar', e);
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // GPS — Rastreamento em tempo real
  // ─────────────────────────────────────────────────────────────────────────

  /// POST /api/v1/inspecoes/{id}/rastreamento
  /// Regista um ponto de localização GPS durante a inspeção
  Future<void> registarPontoRastreamento(
      String inspecaoId, double lat, double lng, double accuracy) async {
    final dio = await _buildDio();
    try {
      await dio.post('/api/v1/inspecoes/$inspecaoId/rastreamento', data: {
        'latitude': lat,
        'longitude': lng,
        'precisao': accuracy,
        'timestamp': DateTime.now().toUtc().toIso8601String(),
      });
      AppLogger.log('📍 [InspecaoService.registarPontoRastreamento] lat=$lat lng=$lng acc=${accuracy.toStringAsFixed(1)}m');
    } on DioException catch (e) {
      // Rastreamento é best-effort — não lançar erro para não perturbar o fluxo
      AppLogger.log('⚠️ [InspecaoService.registarPontoRastreamento] falhou: ${e.response?.statusCode}');
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // GPS — Validação de localização
  // ─────────────────────────────────────────────────────────────────────────

  /// POST /api/v1/inspecoes/{id}/validar-localizacao
  /// Valida se o inspetor está dentro do raio do estabelecimento
  Future<Map<String, dynamic>> validarLocalizacao(
      String inspecaoId, double lat, double lng, double accuracy) async {
    AppLogger.log('📍 [InspecaoService.validarLocalizacao] → POST lat=$lat lng=$lng');
    final dio = await _buildDio();
    try {
      final response = await dio.post(
        '/api/v1/inspecoes/$inspecaoId/validar-localizacao',
        data: {
          'latitude': lat,
          'longitude': lng,
          'precisao': accuracy,
        },
      );
      AppLogger.log('✅ [InspecaoService.validarLocalizacao] status=${response.statusCode}');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleError('validarLocalizacao', e);
    }
  }
  // ─────────────────────────────────────────────────────────────────────────
  // Helpers
  // ─────────────────────────────────────────────────────────────────────────

  List<dynamic> _extractList(dynamic data, String context) {
    if (data is List) return data;
    if (data is Map) {
      if (data.containsKey('content')) return data['content'] as List<dynamic>;
      if (data.containsKey('data'))    return data['data']    as List<dynamic>;
    }
    AppLogger.log('⚠️ [$context] Resposta não é lista nem tem "content"/"data": ${data.runtimeType}');
    return [];
  }

  Exception _handleError(String method, DioException e) {
    final status = e.response?.statusCode;
    final body   = e.response?.data?.toString() ?? '';
    final msg    = e.message ?? 'Erro desconhecido';
    AppLogger.log('❌ [InspecaoService.$method] status=$status msg=$msg body=${body.length > 200 ? body.substring(0, 200) : body}');
    if (status == 401) return Exception('Sessão expirada. Faça login novamente.');
    if (status == 403) return Exception('Sem permissão para esta operação.');
    if (status == 404) return Exception('Recurso não encontrado ($method).');
    return Exception('Erro em $method [HTTP $status]: $msg');
  }
}