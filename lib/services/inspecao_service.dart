import 'dart:io';

import 'package:dio/dio.dart';
import 'package:inspecao/config/app_config.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
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
///  - Plano de ação        → GET planos-acao/resposta/{id}, PUT itens-plano-acao/{id}, POST …/anexos
///
/// NOTA: NÃO faz cache do Dio – o token é obtido de fresco em cada chamada
/// para evitar 401 após expiração silenciosa.
class InspecaoService {
  // ── Construtor de Dio sem cache ───────────────────────────────────────────

  Future<Dio> _buildDio() async {
    final dio = Dio(BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      connectTimeout: const Duration(seconds: 45),
      sendTimeout: const Duration(seconds: 120),
      receiveTimeout: const Duration(seconds: 120),
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

  /// POST /api/v1/inspecoes/{inspecaoId}/respostas/{respostaId}/anexos (multipart)
  Future<void> uploadAnexoRespostaInspecao({
    required String inspecaoId,
    required String respostaId,
    required File arquivo,
    String? tipoAnexo,
  }) async {
    final baseName = arquivo.path.replaceAll(r'\', '/').split('/').last;
    AppLogger.log('📎 [InspecaoService.uploadAnexoRespostaInspecao] inspecao=$inspecaoId '
        'resposta=$respostaId arquivo=$baseName tipo=$tipoAnexo');
    final dio = await _buildDio();
    dio.options.headers.remove('Content-Type');

    final map = <String, dynamic>{
      'arquivo': await MultipartFile.fromFile(
        arquivo.path,
        filename: baseName,
      ),
    };
    if (tipoAnexo != null && tipoAnexo.trim().isNotEmpty) {
      map['tipoAnexo'] = tipoAnexo.trim();
    }

    try {
      await dio.post(
        '/api/v1/inspecoes/$inspecaoId/respostas/$respostaId/anexos',
        data: FormData.fromMap(map),
      );
      AppLogger.log('✅ [InspecaoService.uploadAnexoRespostaInspecao] OK');
    } on DioException catch (e) {
      throw _handleError('uploadAnexoRespostaInspecao', e);
    }
  }

  /// DELETE /api/v1/inspecoes/anexos/{anexoId}
  Future<void> removerAnexoRespostaInspecao(String anexoId) async {
    final dio = await _buildDio();
    AppLogger.log('🗑️ [InspecaoService.removerAnexoRespostaInspecao] anexo=$anexoId');
    try {
      await dio.delete('/api/v1/inspecoes/anexos/$anexoId');
      AppLogger.log('✅ [InspecaoService.removerAnexoRespostaInspecao] OK');
    } on DioException catch (e) {
      throw _handleError('removerAnexoRespostaInspecao', e);
    }
  }

  /// GET /api/v1/inspecoes/anexos/{anexoId}/download
  ///
  /// Bytes do anexo da inspeção/resposta (Alfresco via backend), com JWT.
  Future<File> downloadAnexoRespostaInspecao(
    String anexoId, {
    String filename = 'anexo',
  }) async {
    final dio = await _buildDio();
    AppLogger.log('⬇️ [InspecaoService.downloadAnexoRespostaInspecao] anexoId=$anexoId');
    try {
      final response = await dio.get<List<int>>(
        '/api/v1/inspecoes/anexos/$anexoId/download',
        options: Options(
          responseType: ResponseType.bytes,
          receiveTimeout: const Duration(seconds: 120),
        ),
      );
      final bytes = response.data;
      if (bytes == null || bytes.isEmpty) {
        throw Exception('Ficheiro vazio no servidor');
      }
      final dir = await getTemporaryDirectory();
      final safe = filename.replaceAll(RegExp(r'[^\w.\-]'), '_');
      final path = p.join(dir.path, 'inspecao_resposta_anexo_${anexoId}_$safe');
      final file = File(path);
      await file.writeAsBytes(bytes);
      return file;
    } on DioException catch (e) {
      throw _handleError('downloadAnexoRespostaInspecao', e);
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Validação e Finalização
  // ─────────────────────────────────────────────────────────────────────────

  /// POST /api/v1/inspecoes/{id}/validar
  ///
  /// Igual ao backoffice Angular ([InspecaoService.validar]): POST com corpo vazio.
  /// O servidor só expõe este método (não há GET).
  Future<Map<String, dynamic>> validar(String inspecaoId) async {
    AppLogger.log('🔍 [InspecaoService.validar] → POST /api/v1/inspecoes/$inspecaoId/validar');
    final dio = await _buildDio();
    try {
      final response = await dio.post(
        '/api/v1/inspecoes/$inspecaoId/validar',
        data: const <String, dynamic>{},
      );
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
  // GPS — Rastreamento em tempo real (mesmo contrato que o backoffice Angular)
  // POST /api/v1/rastreamento/iniciar | /registrar | /{id}/finalizar
  // ─────────────────────────────────────────────────────────────────────────

  /// Converte URL relativa da API ou absoluta (Alfresco, etc.) para visualização.
  Future<String> absolutizarUrlArmazenamento(String url) async {
    final trimmed = url.trim();
    final parsed = Uri.tryParse(trimmed);
    if (parsed != null &&
        parsed.hasScheme &&
        (parsed.scheme == 'http' || parsed.scheme == 'https')) {
      return trimmed;
    }
    final dio = await _buildDio();
    final base = dio.options.baseUrl;
    final path = trimmed.startsWith('/') ? trimmed : '/$trimmed';
    return Uri.parse(base).resolve(path).toString();
  }

  /// Inicia a sessão de rastreamento (cria o 1.º ponto no servidor).
  Future<void> iniciarRastreamentoSessao({
    required String inspecaoId,
    required String inspetorId,
  }) async {
    final dio = await _buildDio();
    AppLogger.log(
        '📍 [InspecaoService.iniciarRastreamentoSessao] inspecao=$inspecaoId inspetor=$inspetorId');
    try {
      await dio.post(
        '/api/v1/rastreamento/iniciar',
        data: {
          'inspecaoId': inspecaoId,
          'inspetorId': inspetorId,
        },
      );
      AppLogger.log('✅ [InspecaoService.iniciarRastreamentoSessao] OK');
    } on DioException catch (e) {
      AppLogger.log(
          '⚠️ [InspecaoService.iniciarRastreamentoSessao] ${e.response?.statusCode} ${e.response?.data}');
      rethrow;
    }
  }

  /// Regista um ponto periódico (equivalente ao [RastreamentoService.registrarLocalizacao] na web).
  Future<void> registrarLocalizacaoRastreamento({
    required String inspecaoId,
    required double latitude,
    required double longitude,
    required double precisaoMetros,
    double? velocidade,
    double? direcao,
    double? altitude,
  }) async {
    final dio = await _buildDio();
    try {
      await dio.post(
        '/api/v1/rastreamento/registrar',
        data: {
          'inspecaoId': inspecaoId,
          'latitude': latitude,
          'longitude': longitude,
          'precisao': precisaoMetros,
          if (velocidade != null) 'velocidade': velocidade,
          if (direcao != null) 'direcao': direcao,
          if (altitude != null) 'altitude': altitude,
          'tipoCaptura': 'PERIODICA',
        },
      );
      AppLogger.log(
          '📍 [InspecaoService.registrarLocalizacaoRastreamento] lat=$latitude lng=$longitude');
    } on DioException catch (e) {
      AppLogger.log(
          '⚠️ [InspecaoService.registrarLocalizacaoRastreamento] falhou: ${e.response?.statusCode}');
    }
  }

  /// GET inspeção — devolve o UUID do inspetor na BD (`inspetor.id`), não o Keycloak «sub» por omissão.
  Future<String?> obterInspetorIdDaInspecao(String inspecaoId) async {
    final dio = await _buildDio();
    try {
      final response = await dio.get('/api/v1/inspecoes/$inspecaoId');
      final data = response.data;
      if (data is! Map<String, dynamic>) return null;
      final insp = data['inspetor'];
      if (insp is Map<String, dynamic> && insp['id'] != null) {
        return insp['id'].toString();
      }
      return null;
    } on DioException catch (e) {
      AppLogger.log(
          '⚠️ [InspecaoService.obterInspetorIdDaInspecao] ${e.response?.statusCode}');
      return null;
    }
  }

  /// Finaliza o rastreamento da inspeção (marca pontos inactivos).
  Future<void> finalizarRastreamentoSessao(String inspecaoId) async {
    final dio = await _buildDio();
    try {
      await dio.post('/api/v1/rastreamento/$inspecaoId/finalizar');
      AppLogger.log('✅ [InspecaoService.finalizarRastreamentoSessao] inspecao=$inspecaoId');
    } on DioException catch (e) {
      AppLogger.log(
          '⚠️ [InspecaoService.finalizarRastreamentoSessao] falhou: ${e.response?.statusCode}');
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // GPS — Validação de localização
  // ─────────────────────────────────────────────────────────────────────────

  /// POST /api/v1/inspecoes/{id}/validar-localizacao
  ///
  /// Persiste GPS na inspeção e define [desvioRegistrado] quando fora do raio
  /// (pré-requisito para [registrarJustificativaDesvio] no backend).
  Future<Map<String, dynamic>> validarLocalizacao(
    String inspecaoId, {
    required double latitude,
    required double longitude,
    double? precisaoGps,
  }) async {
    AppLogger.log('📍 [InspecaoService.validarLocalizacao] → POST lat=$latitude lng=$longitude');
    final dio = await _buildDio();
    try {
      final response = await dio.post(
        '/api/v1/inspecoes/$inspecaoId/validar-localizacao',
        data: {
          'latitude': latitude,
          'longitude': longitude,
          if (precisaoGps != null) 'precisaoGps': precisaoGps,
        },
      );
      AppLogger.log('✅ [InspecaoService.validarLocalizacao] status=${response.statusCode}');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleError('validarLocalizacao', e);
    }
  }

  /// POST /api/v1/inspecoes/{id}/registrar-justificativa-desvio
  ///
  /// Exige desvio registado no servidor (via [validarLocalizacao] fora do raio).
  /// Texto mínimo 10 caracteres (igual à API).
  Future<void> registrarJustificativaDesvio(
      String inspecaoId, String justificativa) async {
    AppLogger.log('📝 [InspecaoService.registrarJustificativaDesvio] inspecao=$inspecaoId');
    final dio = await _buildDio();
    try {
      await dio.post(
        '/api/v1/inspecoes/$inspecaoId/registrar-justificativa-desvio',
        data: {'justificativa': justificativa},
      );
      AppLogger.log('✅ [InspecaoService.registrarJustificativaDesvio] OK');
    } on DioException catch (e) {
      throw _handleError('registrarJustificativaDesvio', e);
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Plano de Ação
  // ─────────────────────────────────────────────────────────────────────────

  /// GET /api/v1/planos-acao/resposta/{respostaId}
  ///
  /// Busca o plano de ação associado a uma resposta de inspeção.
  /// Retorna null se não existir plano para a resposta (404 tratado como null).
  Future<Map<String, dynamic>?> buscarPlanoAcaoPorResposta(String respostaId) async {
    AppLogger.log('🌐 [InspecaoService.buscarPlanoAcaoPorResposta] → GET respostaId=$respostaId');
    final dio = await _buildDio();
    try {
      final response = await dio.get('/api/v1/planos-acao/resposta/$respostaId');
      AppLogger.log('✅ [InspecaoService.buscarPlanoAcaoPorResposta] status=${response.statusCode}');
      return response.data as Map<String, dynamic>?;
    } on DioException catch (e) {
      // 404 = plano ainda não existe — não é erro
      if (e.response?.statusCode == 404) return null;
      // Outros erros: logar mas não propagar (best-effort)
      AppLogger.log('⚠️ [InspecaoService.buscarPlanoAcaoPorResposta] falhou: ${e.response?.statusCode}');
      return null;
    }
  }

  /// GET /api/v1/itens-plano-acao/{itemId}
  Future<Map<String, dynamic>> buscarItemPlanoAcao(String itemPlanoAcaoId) async {
    AppLogger.log('🌐 [InspecaoService.buscarItemPlanoAcao] → GET itemId=$itemPlanoAcaoId');
    final dio = await _buildDio();
    try {
      final response = await dio.get('/api/v1/itens-plano-acao/$itemPlanoAcaoId');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleError('buscarItemPlanoAcao', e);
    }
  }

  /// GET /api/v1/itens-plano-acao/anexos/{anexoId}/download
  ///
  /// Mesmo endpoint que o backoffice; devolve os bytes com JWT (Alfresco via backend).
  Future<File> downloadAnexoPlanoAcao(
    String anexoId, {
    String filename = 'evidencia',
  }) async {
    final dio = await _buildDio();
    AppLogger.log('⬇️ [InspecaoService.downloadAnexoPlanoAcao] anexoId=$anexoId');
    try {
      final response = await dio.get<List<int>>(
        '/api/v1/itens-plano-acao/anexos/$anexoId/download',
        options: Options(
          responseType: ResponseType.bytes,
          receiveTimeout: const Duration(seconds: 120),
        ),
      );
      final bytes = response.data;
      if (bytes == null || bytes.isEmpty) {
        throw Exception('Ficheiro vazio no servidor');
      }
      final dir = await getTemporaryDirectory();
      final safe = filename.replaceAll(RegExp(r'[^\w.\-]'), '_');
      final path = p.join(
        dir.path,
        'plano_anexo_${anexoId}_$safe',
      );
      final file = File(path);
      await file.writeAsBytes(bytes);
      return file;
    } on DioException catch (e) {
      throw _handleError('downloadAnexoPlanoAcao', e);
    }
  }

  /// DELETE /api/v1/itens-plano-acao/anexos/{anexoId}?isFrontoffice=true
  Future<void> removerAnexoItemPlanoAcao(String anexoId) async {
    final dio = await _buildDio();
    AppLogger.log('🗑️ [InspecaoService.removerAnexoItemPlanoAcao] anexo=$anexoId');
    await dio.delete(
      '/api/v1/itens-plano-acao/anexos/$anexoId',
      queryParameters: {'isFrontoffice': 'true'},
    );
  }

  /// Remove todos os anexos do item no servidor para reflectir apenas o conjunto
  /// seleccionado na app após «Salvar» (substituição, não acumulação).
  ///
  /// DELETE /api/v1/itens-plano-acao/anexos/{anexoId}?isFrontoffice=true
  Future<void> removerTodosAnexosDoItemPlanoAcao(String itemPlanoAcaoId) async {
    AppLogger.log('🗑️ [InspecaoService.removerTodosAnexosDoItemPlanoAcao] item=$itemPlanoAcaoId');
    final dio = await _buildDio();
    final item = await buscarItemPlanoAcao(itemPlanoAcaoId);
    final raw = item['anexos'];
    if (raw is! List || raw.isEmpty) {
      AppLogger.log('   (nenhum anexo no servidor)');
      return;
    }
    for (final a in raw) {
      if (a is! Map<String, dynamic>) continue;
      final id = a['id']?.toString();
      if (id == null || id.isEmpty) continue;
      AppLogger.log('   → DELETE anexo $id');
      try {
        await dio.delete(
          '/api/v1/itens-plano-acao/anexos/$id',
          queryParameters: {'isFrontoffice': 'true'},
        );
      } on DioException catch (e) {
        AppLogger.log('⚠️ [InspecaoService] falha ao remover anexo $id: ${e.response?.statusCode}');
        rethrow;
      }
    }
    AppLogger.log('✅ [InspecaoService.removerTodosAnexosDoItemPlanoAcao] concluído');
  }

  /// Descarrega um ficheiro (URL absoluta ou relativa à API) com o mesmo token JWT.
  /// Usado para repovoar evidências do plano ao reabrir o checklist.
  Future<File> descarregarUrlParaFicheiroTemporario(
    String url, {
    String filename = 'evidencia.bin',
  }) async {
    final dio = await _buildDio();
    final trimmed = url.trim();
    final Uri uri;
    final parsed = Uri.tryParse(trimmed);
    if (parsed != null &&
        parsed.hasScheme &&
        (parsed.scheme == 'http' || parsed.scheme == 'https')) {
      uri = parsed;
    } else {
      final base = dio.options.baseUrl;
      final path = trimmed.startsWith('/') ? trimmed : '/$trimmed';
      uri = Uri.parse(base).resolve(path);
    }

    AppLogger.log('⬇️ [InspecaoService.descarregarUrlParaFicheiroTemporario] $uri');
    final resp = await dio.getUri<List<int>>(
      uri,
      options: Options(
        responseType: ResponseType.bytes,
        receiveTimeout: const Duration(seconds: 120),
      ),
    );
    final bytes = resp.data;
    if (bytes == null || bytes.isEmpty) {
      throw Exception('Ficheiro vazio ao descarregar evidência');
    }
    final dir = await getTemporaryDirectory();
    final safe = filename.replaceAll(RegExp(r'[^\w.\-]'), '_');
    final path = p.join(
      dir.path,
      'plano_${DateTime.now().millisecondsSinceEpoch}_$safe',
    );
    final file = File(path);
    await file.writeAsBytes(bytes);
    return file;
  }

  /// PUT /api/v1/itens-plano-acao/{itemId}
  ///
  /// Atualiza as observações de um item do plano de ação (contrato igual ao backoffice).
  Future<void> atualizarItemPlanoAcao(
      String itemPlanoAcaoId, String observacoes) async {
    AppLogger.log('📝 [InspecaoService.atualizarItemPlanoAcao] → PUT itemId=$itemPlanoAcaoId');
    final dio = await _buildDio();
    try {
      await dio.put(
        '/api/v1/itens-plano-acao/$itemPlanoAcaoId',
        data: {'observacoes': observacoes},
      );
      AppLogger.log('✅ [InspecaoService.atualizarItemPlanoAcao] OK');
    } on DioException catch (e) {
      AppLogger.log('⚠️ [InspecaoService.atualizarItemPlanoAcao] falhou: ${e.response?.statusCode}');
      rethrow;
    }
  }

  /// POST /api/v1/itens-plano-acao/{itemId}/anexos  (multipart)
  ///
  /// Faz upload de uma imagem de evidência para um item do plano de ação.
  Future<void> adicionarAnexoItemPlanoAcao(
      String itemPlanoAcaoId, File arquivo, {String descricao = 'Evidência mobile'}) async {
    final baseName = arquivo.path.replaceAll(r'\', '/').split('/').last;
    AppLogger.log('📎 [InspecaoService.adicionarAnexoItemPlanoAcao] → POST itemId=$itemPlanoAcaoId '
        'arquivo=$baseName');
    final dio = await _buildDio();
    dio.options.headers.remove('Content-Type'); // boundary definido pelo multipart

    try {
      final formData = FormData.fromMap({
        'arquivo': await MultipartFile.fromFile(
          arquivo.path,
          filename: baseName,
        ),
        'descricao': descricao,
        'criadoPorFrontoffice': 'true',
      });
      await dio.post(
        '/api/v1/itens-plano-acao/$itemPlanoAcaoId/anexos',
        data: formData,
        options: Options(
          sendTimeout: const Duration(seconds: 180),
          receiveTimeout: const Duration(seconds: 180),
        ),
      );
      AppLogger.log('✅ [InspecaoService.adicionarAnexoItemPlanoAcao] upload OK');
    } on DioException catch (e) {
      AppLogger.log('⚠️ [InspecaoService.adicionarAnexoItemPlanoAcao] falhou: ${e.response?.statusCode}');
      rethrow;
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

  /// Aguarda o plano de ação ficar disponível no servidor (sem UI).
  Future<Map<String, dynamic>?> pollPlanoAteTerItem(String respostaId) async {
    const maxAttempts = 36;
    const step = Duration(milliseconds: 500);
    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      if (attempt > 0) await Future.delayed(step);
      final plano = await buscarPlanoAcaoPorResposta(respostaId);
      if (plano == null) continue;
      final itens =
          (plano['itens'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      Map<String, dynamic>? itemPlano;
      for (final i in itens) {
        if (i['respostaInspecaoId']?.toString() == respostaId) {
          itemPlano = i;
          break;
        }
      }
      itemPlano ??= itens.isNotEmpty ? itens.first : null;
      final itemId = itemPlano?['id']?.toString() ?? '';
      if (itemId.isNotEmpty) return plano;
    }
    return null;
  }

  /// Completa observações e anexos do plano após criar a resposta (sincronização offline).
  Future<void> completarPlanoAcaoParaRespostaSync({
    required String respostaId,
    required String observacoes,
    required List<String> evidenciasPaths,
    required List<String> anexosServidorRemovidosIds,
  }) async {
    final plano = await pollPlanoAteTerItem(respostaId);
    if (plano == null) {
      AppLogger.log(
          '⚠️ [InspecaoService.completarPlanoAcaoParaRespostaSync] sem plano para resposta $respostaId');
      return;
    }
    final itens =
        (plano['itens'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    Map<String, dynamic> itemPlanoAcao = {};
    for (final i in itens) {
      if (i['respostaInspecaoId']?.toString() == respostaId) {
        itemPlanoAcao = i;
        break;
      }
    }
    if (itemPlanoAcao.isEmpty && itens.isNotEmpty) {
      itemPlanoAcao = itens.first;
    }

    final itemPlanoAcaoId = itemPlanoAcao['id']?.toString() ?? '';
    if (itemPlanoAcaoId.isEmpty) return;

    await atualizarItemPlanoAcao(itemPlanoAcaoId, observacoes);

    for (final anexoId in anexosServidorRemovidosIds) {
      if (anexoId.isEmpty) continue;
      try {
        await removerAnexoItemPlanoAcao(anexoId);
      } catch (e) {
        AppLogger.log('⚠️ [InspecaoService] remover anexo plano $anexoId: $e');
      }
    }

    for (final path in evidenciasPaths) {
      try {
        final file = File(path);
        if (await file.exists()) {
          await adicionarAnexoItemPlanoAcao(
            itemPlanoAcaoId,
            file,
            descricao: 'Evidência capturada no mobile',
          );
        }
      } catch (e) {
        AppLogger.log('⚠️ [InspecaoService] upload evidência $path: $e');
      }
    }
  }

  
}