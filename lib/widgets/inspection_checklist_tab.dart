import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';
import 'package:inspecao/config/app_config.dart';
import 'package:inspecao/models/checklist_secao.dart';
import 'package:inspecao/models/inspection.dart';
import 'package:inspecao/services/api_service.dart';
import 'package:inspecao/services/auth_service.dart';
import 'package:inspecao/services/connectivity_service.dart';
import 'package:inspecao/services/database_service.dart';
import 'package:inspecao/services/gps_service.dart';
import 'package:inspecao/services/data_service.dart';
import 'package:inspecao/services/inspecao_service.dart';
import 'package:inspecao/utils/app_logger.dart';
import 'package:inspecao/utils/checklist_evidence_storage.dart';
import 'package:inspecao/widgets/checklist_item_field.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ─── Paleta ───────────────────────────────────────────────────────────────────
const _kPrimary       = Color(0xFF18778A);
const _kPrimaryLight  = Color(0xFFE8F4F7);
const _kBorder        = Color(0xFFE2ECF0);
const _kSurface       = Color(0xFFF7FAFB);
const _kTextPrimary   = Color(0xFF0F2A31);
const _kTextSecondary = Color(0xFF5A7A83);
const _kSuccess       = Color(0xFF1DAF6E);
const _kSuccessLight  = Color(0xFFEAF8F2);
const _kError         = Color(0xFFEF4444);
const _kWarning       = Color(0xFFF59E0B);

// ─── Widget principal ─────────────────────────────────────────────────────────

class InspectionChecklistTab extends StatefulWidget {
  final Inspection inspection;
  final bool canEdit;

  /// Incrementado no ecrã pai sempre que o utilizador abre o separador Checklist
  /// (força repovoar observações/evidências do plano a partir do servidor).
  final int checklistTabVisitToken;

  /// Quando falso, o separador Checklist não está visível — pára GPS/rastreamento API.
  final bool isChecklistTabActive;

  /// Callback chamado após finalizar com sucesso (para o pai actualizar)
  final VoidCallback? onFinalizado;

  /// Callback chamado sempre que o progresso muda (total, respondidos)
  final void Function(int total, int respondidos)? onProgressoAtualizado;

  /// Após gravar resposta em modo offline (fila local).
  final VoidCallback? onInspectionDirtyLocal;

  const InspectionChecklistTab({
    super.key,
    required this.inspection,
    required this.canEdit,
    this.checklistTabVisitToken = 0,
    this.isChecklistTabActive = true,
    this.onFinalizado,
    this.onProgressoAtualizado,
    this.onInspectionDirtyLocal,
  });

  @override
  State<InspectionChecklistTab> createState() => _InspectionChecklistTabState();
}

class _InspectionChecklistTabState extends State<InspectionChecklistTab> {
  final _inspecaoService = InspecaoService();
  final _gpsService      = GpsService();
  final _dbService       = DatabaseService();

  // ── Dados ────────────────────────────────────────────────────────────────
  List<SecaoChecklistCompleta>          _secoes       = [];
  Map<String, RespostaInspecaoCompleta> _respostasMap = {};
  bool    _loadingItens     = false;
  String? _erroCarregamento;

  // ── Colapso ──────────────────────────────────────────────────────────────
  final Map<String, bool> _expandedMap = {};

  // ── Sync background ──────────────────────────────────────────────────────
  Timer?    _syncTimer;
  bool      _syncing  = false;
  DateTime? _lastSync;

  // ── GPS / Rastreamento ───────────────────────────────────────────────────
  StreamSubscription<Position>? _gpsSub;
  Timer?    _trackingTimer;
  bool      _gpsActivo = false;
  _LocationState _locationState   = _LocationState.desconhecido;
  double?   _distanciaEstabelecimento;

  /// Sessão `/api/v1/rastreamento/iniciar` já chamada nesta visita ao separador.
  bool _rastreamentoApiIniciadoNestaVisita = false;

  /// Erro ao iniciar rastreamento (ex.: inspetor em falta).
  String? _rastreamentoErro;

  // ── Concluir ─────────────────────────────────────────────────────────────
  bool _finalizando = false;

  // ── Plano de ação em curso ───────────────────────────────────────────────
  /// Itens com plano de ação a guardar (itemChecklistId → a processar)
  final Set<String> _salvandoPlanoAcao = {};

  // ─── Contadores ──────────────────────────────────────────────────────────

  List<ItemChecklistCompleto> get _todosItens {
    final list = <ItemChecklistCompleto>[];
    for (final s in _secoes) {
      list.addAll(s.itens);
      for (final sub in s.subsecoes) {
        list.addAll(sub.itens);
        for (final sub2 in sub.subsecoes) list.addAll(sub2.itens);
      }
    }
    return list;
  }

  int get _totalItens  => _todosItens.length;
  int get _respondidos => _respostasMap.length.clamp(0, _totalItens);

  // ─── Lifecycle ────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    AppLogger.log('🚀 [ChecklistTab] init inspecaoId=${widget.inspection.id}');
    _loadChecklistItens();
    if (widget.canEdit) {
      _iniciarSync();
    }
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _ajustarRastreamentoAoSeparador());
  }

  @override
  void didUpdateWidget(covariant InspectionChecklistTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isChecklistTabActive != widget.isChecklistTabActive ||
        oldWidget.canEdit != widget.canEdit ||
        oldWidget.inspection.id != widget.inspection.id) {
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _ajustarRastreamentoAoSeparador());
    }
  }

  @override
  void dispose() {
    _syncTimer?.cancel();
    _trackingTimer?.cancel();
    _gpsSub?.cancel();
    _pararFluxoRastreamentoChecklist();
    super.dispose();
  }

  // ─── Carregamento inicial ─────────────────────────────────────────────────

  Future<void> _loadChecklistItens() async {
    if (widget.inspection.checklistId == null) return;
    if (mounted) {
      setState(() {
        _loadingItens = true;
        _erroCarregamento = null;
      });
    }

    try {
      final cid = widget.inspection.checklistId!;
      final apiInspecaoId = widget.inspection.apiInspecaoId;

      late List<SecaoChecklistCompleta> secoes;
      List<RespostaInspecaoCompleta>? apiRespostasParaAnexos;

      final online = ConnectivityService().isConnected;

      if (online) {
        try {
          final results = await Future.wait([
            _inspecaoService.getChecklistCompleto(cid),
            _inspecaoService.getRespostas(apiInspecaoId),
          ]);
          secoes = results[0] as List<SecaoChecklistCompleta>;
          apiRespostasParaAnexos =
              results[1] as List<RespostaInspecaoCompleta>;
          await _dbService.initialize();
          if (apiRespostasParaAnexos.isNotEmpty) {
            await _dbService.mergeChecklistRespostasFromServer(
              widget.inspection.id,
              apiRespostasParaAnexos,
            );
          }
        } catch (_) {
          await _dbService.initialize();
          secoes = await _dbService.loadChecklistCompletoFromCache(cid);
          apiRespostasParaAnexos = null;
          if (secoes.isEmpty) rethrow;
        }
      } else {
        await _dbService.initialize();
        secoes = await _dbService.loadChecklistCompletoFromCache(cid);
        apiRespostasParaAnexos = null;
        if (secoes.isEmpty) {
          throw Exception(
            'Sem dados locais do checklist. Abra esta inspeção com internet pelo menos uma vez para descarregar o modelo.',
          );
        }
      }

      var respostasParaMap = await _dbService
          .listRespostasChecklistCompleta(widget.inspection.id);

      if (apiRespostasParaAnexos != null &&
          apiRespostasParaAnexos.isNotEmpty) {
        final apiPorItem = {
          for (final r in apiRespostasParaAnexos) r.itemChecklistId: r,
        };
        respostasParaMap = respostasParaMap.map((local) {
          final api = apiPorItem[local.itemChecklistId];
          if (api == null) return local;
          return local.overlayServerAnexosFrom(api);
        }).toList();
      }

      final expanded = <String, bool>{};
      for (final s in secoes) {
        expanded[s.id] = true;
        for (final sub in s.subsecoes) expanded[sub.id] = true;
      }
      final map = <String, RespostaInspecaoCompleta>{};
      for (final r in respostasParaMap) {
        map[r.itemChecklistId] = r;
      }

      if (mounted) {
        setState(() {
          _secoes = secoes;
          _respostasMap = map;
          _expandedMap.addAll(expanded);
          _loadingItens = false;
          _lastSync = DateTime.now();
        });
        widget.onProgressoAtualizado?.call(_todosItens.length, map.length);
      }
    } catch (e, st) {
      AppLogger.error('[ChecklistTab] erro carregamento', e, st);
      if (mounted) {
        setState(() {
          _loadingItens = false;
          _erroCarregamento = e.toString();
        });
      }
    }
  }

  // ─── Sync background ─────────────────────────────────────────────────────

  void _iniciarSync() {
    _syncTimer = Timer.periodic(const Duration(seconds: 30), (_) => _syncRespostas());
  }

  Future<void> _syncRespostas() async {
    if (_syncing || !mounted) return;
    setState(() => _syncing = true);
    try {
      final respostasApi =
          await _inspecaoService.getRespostas(widget.inspection.apiInspecaoId);
      await _dbService.initialize();
      await _dbService.mergeChecklistRespostasFromServer(
          widget.inspection.id, respostasApi);
      if (!mounted) return;
      var locais = await _dbService
          .listRespostasChecklistCompleta(widget.inspection.id);
      if (respostasApi.isNotEmpty) {
        final apiPorItem = {
          for (final r in respostasApi) r.itemChecklistId: r,
        };
        locais = locais.map((local) {
          final api = apiPorItem[local.itemChecklistId];
          if (api == null) return local;
          return local.overlayServerAnexosFrom(api);
        }).toList();
      }
      final map = <String, RespostaInspecaoCompleta>{};
      for (final r in locais) {
        map[r.itemChecklistId] = r;
      }
      setState(() {
        _respostasMap = map;
        _syncing = false;
        _lastSync = DateTime.now();
      });
      widget.onProgressoAtualizado?.call(_todosItens.length, map.length);
    } catch (_) {
      if (mounted) setState(() => _syncing = false);
    }
  }

  // ─── GPS / Rastreamento API (como backoffice: iniciar → registos periódicos → finalizar) ───

  void _ajustarRastreamentoAoSeparador() {
    if (!mounted) return;
    if (!widget.canEdit || !widget.isChecklistTabActive) {
      _pararFluxoRastreamentoChecklist();
      return;
    }
    unawaited(_iniciarFluxoRastreamentoChecklist());
  }

  Future<String?> _resolverInspetorUuid() async {
    try {
      final daApi =
          await _inspecaoService.obterInspetorIdDaInspecao(widget.inspection.apiInspecaoId);
      if (daApi != null && daApi.isNotEmpty) {
        return daApi;
      }
    } catch (_) {}
    final fromInspection = widget.inspection.inspectorId;
    if (fromInspection != null && fromInspection.isNotEmpty) {
      return fromInspection;
    }
    final prefs = await SharedPreferences.getInstance();
    final api = ApiService();
    if (api.baseUrl == null) {
      api.initialize(baseUrl: AppConfig.apiBaseUrl);
    }
    final auth = AuthService(api, prefs);
    final u = await auth.getCurrentUser();
    return u?.id;
  }

  Future<void> _garantirIniciarRastreamentoApi() async {
    if (_rastreamentoApiIniciadoNestaVisita) return;
    final inspetor = await _resolverInspetorUuid();
    if (inspetor == null) {
      if (mounted) {
        setState(() => _rastreamentoErro =
            'Rastreamento em tempo real indisponível: inspetor não identificado.');
      }
      return;
    }
    try {
      await _inspecaoService.iniciarRastreamentoSessao(
        inspecaoId: widget.inspection.apiInspecaoId,
        inspetorId: inspetor,
      );
      if (mounted) {
        setState(() {
          _rastreamentoApiIniciadoNestaVisita = true;
          _rastreamentoErro = null;
        });
      }
    } catch (e) {
      AppLogger.log('⚠️ [ChecklistTab] iniciar rastreamento API: $e');
      if (mounted) {
        setState(() => _rastreamentoErro =
            'Não foi possível iniciar o rastreamento no servidor.');
      }
    }
  }

  Future<void> _iniciarFluxoRastreamentoChecklist() async {
    if (!widget.canEdit || !widget.isChecklistTabActive || !mounted) return;

    final ok = await _gpsService.ensurePermissions();
    if (!ok) {
      if (mounted) {
        setState(() => _rastreamentoErro =
            'Permissão de localização necessária para o rastreamento.');
      }
      return;
    }

    _gpsService.startTracking();
    await _verificarLocalizacao();
    await _garantirIniciarRastreamentoApi();
    if (!_rastreamentoApiIniciadoNestaVisita) {
      return;
    }

    _trackingTimer?.cancel();
    _trackingTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) unawaited(_enviarPontoRastreamento());
    });
    await _enviarPontoRastreamento();
  }

  void _pararFluxoRastreamentoChecklist() {
    _trackingTimer?.cancel();
    _trackingTimer = null;
    unawaited(_inspecaoService.finalizarRastreamentoSessao(widget.inspection.apiInspecaoId));
    _gpsService.stopTracking();
    _rastreamentoApiIniciadoNestaVisita = false;
  }

  Future<void> _verificarLocalizacao() async {
    final estLat = widget.inspection.latitude;
    final estLng = widget.inspection.longitude;
    if (estLat == 0.0 && estLng == 0.0) return;
    try {
      final r = await _gpsService.validarLocalizacao(
          estLat: estLat, estLng: estLng, raioMetros: 10);
      if (!mounted) return;
      setState(() {
        _distanciaEstabelecimento = r.distanciaMetros;
        _locationState = r.temLocalizacao
            ? (r.dentroDoRaio ? _LocationState.dentro : _LocationState.fora)
            : _LocationState.desconhecido;
      });
    } catch (_) {}
  }

  Future<void> _enviarPontoRastreamento() async {
    final pos = _gpsService.lastPosition;
    if (pos == null) return;
    await _inspecaoService.registrarLocalizacaoRastreamento(
      inspecaoId: widget.inspection.apiInspecaoId,
      latitude: pos.latitude,
      longitude: pos.longitude,
      precisaoMetros: pos.accuracy,
      velocidade: pos.speed,
      direcao: pos.heading.isFinite ? pos.heading : null,
      altitude: pos.altitude.isFinite ? pos.altitude : null,
    );
  }

  // ─── Guardar resposta ─────────────────────────────────────────────────────

  /// Recebe o payload do [ChecklistItemField].
  ///
  /// Se o payload contiver `salvarPlanoAcao: true`, executa o fluxo completo:
  ///   1. Guarda a resposta normal (se ainda não guardada)
  ///   2. Aguarda o backend criar o item do plano de ação
  ///   3. Actualiza as observações do item do plano de ação
  ///   4. Faz upload das evidências (imagens)
  ///
  /// Caso contrário, apenas guarda a resposta.
  bool _podeEnfileirarRespostaOffline() {
    final sid = widget.inspection.serverId?.trim();
    return sid != null && sid.isNotEmpty;
  }

  bool _deveTratarComoErroDeRede(Object e) {
    if (!ConnectivityService().isConnected) return true;
    if (e is DioException) {
      return e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.receiveTimeout;
    }
    return false;
  }

  Future<void> _guardarRespostaOffline(
    Map<String, dynamic> payloadCompleto,
    Map<String, dynamic> payloadResposta,
    bool salvarPlanoAcao,
    String itemChecklistId,
  ) async {
    if (!_podeEnfileirarRespostaOffline()) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text(
          'Sem rede: sincronize a inspeção primeiro para obter o ID no servidor.',
        ),
        backgroundColor: _kError,
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }

    final uuid = const Uuid().v4();
    await _dbService.initialize();
    await _dbService.upsertRespostaFromChecklistPayload(
      inspecaoLocalId: widget.inspection.id,
      payload: payloadResposta,
      respostaRowId: uuid,
    );

    final filaPayload = Map<String, dynamic>.from(payloadResposta)
      ..['evidenciasItemPaths'] =
          (payloadCompleto['evidenciasItemPaths'] as List?) ?? []
      ..['anexosItemServidorRemovidosIds'] =
          (payloadCompleto['anexosItemServidorRemovidosIds'] as List?) ??
              [];

    await _dbService.enqueuePendingRespostaOp(
      inspecaoLocalId: widget.inspection.id,
      payloadResposta: filaPayload,
      salvarPlanoAcao: salvarPlanoAcao,
      planoExtras: salvarPlanoAcao
          ? {
              'observacoesPlanoAcao': payloadCompleto['observacoesPlanoAcao'],
              'evidenciasPlanoAcao': payloadCompleto['evidenciasPlanoAcao'],
              'anexosPlanoServidorRemovidosIds':
                  payloadCompleto['anexosPlanoServidorRemovidosIds'],
            }
          : null,
    );

    final optimistic = RespostaInspecaoCompleta(
      id: uuid,
      inspecaoId: widget.inspection.id,
      itemChecklistId: itemChecklistId,
      opcaoId: payloadResposta['opcaoId']?.toString(),
      valorTexto: payloadResposta['valorTexto']?.toString(),
      valorNumero: (payloadResposta['valorNumero'] as num?)?.toDouble(),
      valorData: payloadResposta['valorData']?.toString(),
      valorDataHora: payloadResposta['valorDataHora']?.toString(),
      valorRating: (payloadResposta['valorRating'] as num?)?.toInt(),
      latitude: (payloadResposta['latitude'] as num?)?.toDouble(),
      longitude: (payloadResposta['longitude'] as num?)?.toDouble(),
      observacoes: payloadResposta['observacoes']?.toString(),
      anexos: const [],
      evidenciasLocaisPendentesPaths:
          ((filaPayload['evidenciasItemPaths'] as List?) ?? [])
              .map((e) => e.toString())
              .where((p) => p.trim().isNotEmpty)
              .toList(),
      anexosServidorRemovidosPendentesIds:
          ((filaPayload['anexosItemServidorRemovidosIds'] as List?) ?? [])
              .map((e) => e.toString())
              .where((id) => id.trim().isNotEmpty)
              .toList(),
    );

    await DataService().updateInspection(
      widget.inspection.copyWith(updatedAt: DateTime.now()),
      markDirty: true,
    );

    if (mounted) {
      setState(() {
        _respostasMap[optimistic.itemChecklistId] = optimistic;
      });
      widget.onProgressoAtualizado?.call(_todosItens.length, _respostasMap.length);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
          salvarPlanoAcao
              ? 'Guardado offline (resposta e plano na fila). Sincronize com rede.'
              : 'Guardado offline. Sincronize com rede.',
        ),
        backgroundColor: _kPrimary,
        behavior: SnackBarBehavior.floating,
      ));
    }
    widget.onInspectionDirtyLocal?.call();
  }

  Future<void> _salvarResposta(Map<String, dynamic> payload) async {
    final salvarPlanoAcao = payload['salvarPlanoAcao'] == true;
    final itemChecklistId = payload['itemChecklistId']?.toString() ?? '';

    final evidenciasItemPaths = (payload['evidenciasItemPaths'] as List?)
            ?.map((e) => e.toString())
            .where((p) => p.trim().isNotEmpty)
            .toList() ??
        [];
    final removidosAnexosItem = (payload['anexosItemServidorRemovidosIds']
                as List?)
            ?.map((e) => e.toString())
            .where((id) => id.trim().isNotEmpty)
            .toList() ??
        [];

    // Remover campos específicos do plano e da UI mobile antes de enviar ao backend de resposta
    final payloadResposta = Map<String, dynamic>.from(payload)
      ..remove('salvarPlanoAcao')
      ..remove('observacoesPlanoAcao')
      ..remove('evidenciasPlanoAcao')
      ..remove('anexosPlanoServidorRemovidosIds')
      ..remove('evidenciasItemPaths')
      ..remove('anexosItemServidorRemovidosIds');

    var loadingShown = false;
    final online = ConnectivityService().isConnected;
    if (salvarPlanoAcao && mounted && online) {
      loadingShown = true;
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => PopScope(
          canPop: false,
          child: AlertDialog(
            content: Row(
              children: [
                const SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    'A guardar resposta e plano de ação…',
                    style: const TextStyle(
                        fontSize: 14, color: _kTextPrimary),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    try {
      if (!online) {
        await _guardarRespostaOffline(
            payload, payloadResposta, salvarPlanoAcao, itemChecklistId);
        return;
      }

      try {
        var respostaUi = await _inspecaoService.salvarResposta(
            widget.inspection.apiInspecaoId, payloadResposta);

        for (final anexoId in removidosAnexosItem) {
          if (anexoId.isEmpty) continue;
          try {
            await _inspecaoService.removerAnexoRespostaInspecao(anexoId);
          } catch (e) {
            AppLogger.log(
                '⚠️ [ChecklistTab] remover anexo da resposta $anexoId: $e');
          }
        }

        for (final path in evidenciasItemPaths) {
          try {
            final file = File(path);
            if (await file.exists() && respostaUi.id.isNotEmpty) {
              await _inspecaoService.uploadAnexoRespostaInspecao(
                inspecaoId: widget.inspection.apiInspecaoId,
                respostaId: respostaUi.id,
                arquivo: file,
                tipoAnexo: tipoAnexoInspecaoParaCaminhoLocal(path),
              );
            }
          } catch (e) {
            AppLogger.log(
                '⚠️ [ChecklistTab] upload evidência do item $path: $e');
          }
        }

        if (evidenciasItemPaths.isNotEmpty ||
            removidosAnexosItem.isNotEmpty) {
          try {
            final todas = await _inspecaoService
                .getRespostas(widget.inspection.apiInspecaoId);
            for (final x in todas) {
              if (x.itemChecklistId == respostaUi.itemChecklistId) {
                respostaUi = x;
                break;
              }
            }
          } catch (e) {
            AppLogger.log(
                '⚠️ [ChecklistTab] atualizar resposta após anexos: $e');
          }
        }

        await _dbService.initialize();
        await _dbService.mergeChecklistRespostasFromServer(
            widget.inspection.id, [respostaUi]);
        if (mounted) {
          setState(() {
            _respostasMap[respostaUi.itemChecklistId] = respostaUi;
          });
          widget.onProgressoAtualizado
              ?.call(_todosItens.length, _respostasMap.length);
        }

        if (salvarPlanoAcao && respostaUi.id.isNotEmpty) {
          await _processarPlanoAcao(
            respostaId: respostaUi.id,
            itemChecklistId: itemChecklistId,
            observacoes: payload['observacoesPlanoAcao']?.toString() ?? '',
            evidenciasPaths: (payload['evidenciasPlanoAcao'] as List?)
                    ?.cast<String>() ??
                [],
            anexosServidorRemovidosIds:
                (payload['anexosPlanoServidorRemovidosIds'] as List?)
                        ?.cast<String>() ??
                    [],
          );
        }
      } catch (e) {
        if (_deveTratarComoErroDeRede(e)) {
          await _guardarRespostaOffline(
              payload, payloadResposta, salvarPlanoAcao, itemChecklistId);
          return;
        }
        rethrow;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Erro ao guardar: $e'),
          backgroundColor: _kError,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ));
      }
    } finally {
      if (loadingShown && mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }
    }
  }

  // ─── Processamento do Plano de Ação ──────────────────────────────────────

  /// Após guardar a resposta, busca o plano de ação criado pelo backend
  /// (o backend cria automaticamente via ChecklistAcaoProcessadorService),
  /// atualiza as observações e faz upload das evidências.
  /// Aguarda o backend criar o plano e o item associados à resposta (processamento pode demorar).
  Future<Map<String, dynamic>?> _pollPlanoAteTerItem(String respostaId) async {
    const maxAttempts = 36;
    const step = Duration(milliseconds: 500);
    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      if (attempt > 0) await Future.delayed(step);
      final plano =
          await _inspecaoService.buscarPlanoAcaoPorResposta(respostaId);
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

  Future<void> _processarPlanoAcao({
    required String respostaId,
    required String itemChecklistId,
    required String observacoes,
    required List<String> evidenciasPaths,
    required List<String> anexosServidorRemovidosIds,
  }) async {
    if (_salvandoPlanoAcao.contains(itemChecklistId)) return;
    _salvandoPlanoAcao.add(itemChecklistId);

    try {
      final plano = await _pollPlanoAteTerItem(respostaId);

      if (plano == null) {
        AppLogger.log(
            '⚠️ [ChecklistTab] plano de ação não disponível após espera (resposta $respostaId)');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: const Text(
              'A resposta foi guardada, mas o plano de ação ainda não apareceu no servidor. '
              'Aguarde alguns segundos e abra o item novamente, ou sincronize.',
            ),
            backgroundColor: _kWarning,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 5),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ));
        }
        return;
      }

      final itens =
          (plano['itens'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      final itemPlanoAcao = itens.firstWhere(
        (i) => i['respostaInspecaoId']?.toString() == respostaId,
        orElse: () => itens.isNotEmpty ? itens.first : <String, dynamic>{},
      );

      final itemPlanoAcaoId = itemPlanoAcao['id']?.toString() ?? '';
      if (itemPlanoAcaoId.isEmpty) {
        AppLogger.log('⚠️ [ChecklistTab] itemPlanoAcaoId não encontrado no plano');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: const Text(
                'Plano encontrado, mas sem item associado a esta resposta.'),
            backgroundColor: _kWarning,
            behavior: SnackBarBehavior.floating,
          ));
        }
        return;
      }

      await _inspecaoService.atualizarItemPlanoAcao(itemPlanoAcaoId, observacoes);

      for (final anexoId in anexosServidorRemovidosIds) {
        if (anexoId.isEmpty) continue;
        try {
          await _inspecaoService.removerAnexoItemPlanoAcao(anexoId);
        } catch (e) {
          AppLogger.log('⚠️ [ChecklistTab] remover anexo plano $anexoId: $e');
        }
      }

      var uploadsOk = 0;
      var uploadsFail = 0;
      for (final path in evidenciasPaths) {
        try {
          final file = File(path);
          if (await file.exists()) {
            await _inspecaoService.adicionarAnexoItemPlanoAcao(
              itemPlanoAcaoId,
              file,
              descricao: 'Evidência capturada no mobile',
            );
            uploadsOk++;
          } else {
            uploadsFail++;
            AppLogger.log('⚠️ [ChecklistTab] ficheiro inexistente: $path');
          }
        } catch (e) {
          uploadsFail++;
          AppLogger.log('⚠️ [ChecklistTab] erro ao enviar evidência $path: $e');
        }
      }

      if (mounted) {
        if (evidenciasPaths.isNotEmpty && uploadsFail > 0) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
              uploadsOk > 0
                  ? 'Plano guardado. $uploadsOk anexo(s) enviado(s); $uploadsFail falharam.'
                  : 'Observações guardadas, mas $uploadsFail anexo(s) falharam (rede ou permissões).',
            ),
            backgroundColor: uploadsOk > 0 ? _kWarning : _kError,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 5),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ));
        } else {
          _mostrarSucessoPlanoAcao(
            totalEvidencias: uploadsOk,
          );
        }
      }
    } catch (e) {
      AppLogger.log('⚠️ [ChecklistTab] erro ao processar plano de ação: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Plano de ação: $e'),
          backgroundColor: _kError,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 5),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ));
      }
    } finally {
      _salvandoPlanoAcao.remove(itemChecklistId);
    }
  }

  void _mostrarSucessoPlanoAcao({
    int totalEvidencias = 0,
    bool somenteFeedback = false,
  }) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        const Icon(Icons.check_circle_rounded,
            color: Colors.white, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            somenteFeedback
                ? 'Plano de ação registado com sucesso.'
                : totalEvidencias > 0
                    ? 'Plano de ação guardado com $totalEvidencias evidência(s).'
                    : 'Plano de ação guardado com sucesso.',
            style: const TextStyle(fontSize: 13),
          ),
        ),
      ]),
      backgroundColor: _kSuccess,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  // ─── Concluir ─────────────────────────────────────────────────────────────

  Future<void> _concluir() async {
    if (_finalizando) return;

    // 1. Verificar se há itens por responder
    final obrigPendentes = _todosItens
        .where((i) => i.obrigatorio && !_respostasMap.containsKey(i.id))
        .length;
    final totalPendentes = _todosItens
        .where((i) => !_respostasMap.containsKey(i.id))
        .length;

    // Itens obrigatórios: bloquear completamente
    if (obrigPendentes > 0) {
      _dlg(icon: Icons.warning_amber_rounded, cor: _kWarning,
          titulo: 'Itens obrigatórios por responder',
          msg: '$obrigPendentes item(ns) obrigatório(s) ainda sem resposta.\nPreencha-os antes de concluir.',
          label: 'Entendido');
      return;
    }

    // Itens não obrigatórios pendentes: avisar mas permitir continuar
    if (totalPendentes > 0) {
      final continuar = await _dlgPendentesOpcional(totalPendentes);
      if (!continuar) return;
    }

    setState(() => _finalizando = true);

    // 2. Validar no servidor (best-effort)
    try {
      final v = await _inspecaoService.validar(widget.inspection.apiInspecaoId);
      final valida = v['valida'] as bool? ?? true;
      final erros  = (v['erros'] as List?)?.cast<String>() ?? [];
      if (!valida && erros.isNotEmpty) {
        if (mounted) setState(() => _finalizando = false);
        _dlg(icon: Icons.error_outline_rounded, cor: _kError,
            titulo: 'Não é possível concluir',
            msg: erros.join('\n'), label: 'Entendido');
        return;
      }
    } catch (_) { /* endpoint pode não existir */ }

    // 3. Validação de localização GPS (raio 10m)
    final estLat = widget.inspection.latitude;
    final estLng = widget.inspection.longitude;
    bool semGps  = false;

    if (estLat != 0.0 && estLng != 0.0) {
      try {
        final r = await _gpsService.validarLocalizacao(
            estLat: estLat, estLng: estLng, raioMetros: 10);
        if (mounted) setState(() {
          _distanciaEstabelecimento = r.distanciaMetros;
          _locationState = r.temLocalizacao
              ? (r.dentroDoRaio ? _LocationState.dentro : _LocationState.fora)
              : _LocationState.desconhecido;
        });
        if (!r.dentroDoRaio && r.temLocalizacao) {
          if (mounted) setState(() => _finalizando = false);
          final continuar = await _resolverForaDoRaio(r.distanciaMetros!);
          if (!continuar) return;
          if (mounted) setState(() => _finalizando = true);
        }
      } catch (_) { semGps = true; }
    }

    // 4. Confirmação final
    if (mounted) setState(() => _finalizando = false);
    final confirmar = await _dlgConfirmar();
    if (!confirmar) return;
    setState(() => _finalizando = true);

    // 5. Antes de finalizar, parar rastreamento periódico para evitar corrida
    // com POST /rastreamento/registrar durante a conclusão.
    var retomarRastreamentoSeFalhar = false;
    if (_trackingTimer != null ||
        _rastreamentoApiIniciadoNestaVisita ||
        _gpsService.isTracking) {
      retomarRastreamentoSeFalhar = widget.canEdit && widget.isChecklistTabActive;
      _trackingTimer?.cancel();
      _trackingTimer = null;
      _gpsService.stopTracking();
      try {
        await _inspecaoService.finalizarRastreamentoSessao(widget.inspection.apiInspecaoId);
      } catch (_) {
        // Best-effort: não bloquear a conclusão da inspeção por falha no rastreamento.
      }
      _rastreamentoApiIniciadoNestaVisita = false;
    }

    // 6. Finalizar
    try {
      final pos     = _gpsService.lastPosition;
      final payload = <String, dynamic>{};
      if (pos != null) {
        payload['latitude']    = pos.latitude;
        payload['longitude']   = pos.longitude;
        payload['precisaoGps'] = pos.accuracy;
      }
      await _inspecaoService.finalizar(widget.inspection.apiInspecaoId, payload);

      if (mounted) {
        setState(() => _finalizando = false);
        _dlg(
          icon: Icons.check_circle_rounded,
          cor: _kSuccess,
          titulo: 'Inspeção Concluída!',
          msg: semGps
              ? 'Concluída com sucesso, mas não foi possível validar a localização GPS.'
              : 'A inspeção foi concluída com sucesso.',
          label: 'Ver Detalhes',
          onConfirm: widget.onFinalizado,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _finalizando = false);
        if (retomarRastreamentoSeFalhar) {
          unawaited(_iniciarFluxoRastreamentoChecklist());
        }
        _dlg(icon: Icons.error_outline_rounded, cor: _kError,
            titulo: 'Erro ao concluir',
            msg: e.toString().replaceAll('Exception: ', ''),
            label: 'OK');
      }
    }
  }

  // ─── Helpers de diálogo ───────────────────────────────────────────────────

  void _dlg({
    required IconData icon, required Color cor,
    required String titulo, required String msg,
    required String label, VoidCallback? onConfirm,
  }) {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _AlertDlg(
        icon: icon, iconColor: cor,
        titulo: titulo, mensagem: msg, confirmLabel: label,
        onConfirm: onConfirm,
      ),
    );
  }

  Future<bool> _dlgPendentesOpcional(int pendentes) async =>
      await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (_) => _PendentesOpcionaisDialog(pendentes: pendentes),
      ) ??
      false;

  /// Fora do raio: alinha com a web — validar localização no servidor, justificativa
  /// (mín. 10 caracteres) e só depois permitir continuar para a confirmação final.
  Future<bool> _resolverForaDoRaio(double distanciaMetros) async {
    if (!mounted) return false;
    final pos = _gpsService.lastPosition;
    if (pos == null) {
      _dlg(
        icon: Icons.location_off_rounded,
        cor: _kError,
        titulo: 'Localização indisponível',
        msg: 'Não foi possível obter coordenadas GPS para registar o desvio no servidor.',
        label: 'Entendido',
      );
      return false;
    }

    try {
      await _inspecaoService.validarLocalizacao(
        widget.inspection.apiInspecaoId,
        latitude: pos.latitude,
        longitude: pos.longitude,
        precisaoGps: pos.accuracy,
      );
    } catch (e) {
      if (mounted) {
        _dlg(
          icon: Icons.cloud_off_rounded,
          cor: _kError,
          titulo: 'Erro ao validar localização',
          msg: e.toString().replaceAll('Exception: ', ''),
          label: 'OK',
        );
      }
      return false;
    }

    if (!mounted) return false;

    final existente = widget.inspection.justificativaDesvio?.trim() ?? '';
    if (existente.length >= 10) {
      final confirmar = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (_) => _JustificativaExistenteDlg(
          distanciaMetros: distanciaMetros,
          justificativa: existente,
        ),
      );
      return confirmar == true;
    }

    if (!mounted) return false;

    final texto = await showDialog<String?>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _JustificativaDesvioFormDlg(
        distanciaMetros: distanciaMetros,
      ),
    );

    if (texto == null || texto.trim().length < 10) {
      return false;
    }

    try {
      await _inspecaoService.registrarJustificativaDesvio(
        widget.inspection.apiInspecaoId,
        texto.trim(),
      );
    } catch (e) {
      if (mounted) {
        _dlg(
          icon: Icons.error_outline_rounded,
          cor: _kError,
          titulo: 'Erro ao registar justificativa',
          msg: e.toString().replaceAll('Exception: ', ''),
          label: 'OK',
        );
      }
      return false;
    }

    return true;
  }

  Future<bool> _dlgConfirmar() async =>
      await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (_) => const _ConfirmDlg(),
      ) ?? false;

  // ─── Toggle ───────────────────────────────────────────────────────────────

  void _toggle(String id) =>
      setState(() => _expandedMap[id] = !(_expandedMap[id] ?? true));
  bool _isExpanded(String id) => _expandedMap[id] ?? true;

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_loadingItens) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: _kPrimary, strokeWidth: 2.5),
            SizedBox(height: 16),
            Text('A carregar checklist...',
                style: TextStyle(color: _kTextSecondary, fontSize: 14)),
          ],
        ),
      );
    }

    if (widget.inspection.checklistId == null) {
      return _emptyState(Icons.assignment_late_outlined,
          'Sem checklist associado', 'Esta inspeção não tem checklist configurado.');
    }

    if (_erroCarregamento != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.wifi_off_rounded, size: 48, color: _kError),
            const SizedBox(height: 12),
            Text(_erroCarregamento!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: _kTextSecondary, fontSize: 13)),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _loadChecklistItens,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Tentar novamente'),
              style: FilledButton.styleFrom(
                  backgroundColor: _kPrimary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10))),
            ),
          ]),
        ),
      );
    }

    final isRascunho = widget.inspection.status == InspectionStatus.rascunho;

    return Stack(
      children: [
        ListView(
          padding: EdgeInsets.fromLTRB(12, 12, 12, widget.canEdit ? 120 : 24),
          children: [
            _ProgressBar(total: _totalItens, respondidos: _respondidos),
            const SizedBox(height: 8),

            if (isRascunho) ...[
              _RascunhoBanner(),
              const SizedBox(height: 8),
            ],

            if (widget.canEdit) ...[
              _GpsStatusBar(
                locationState: _locationState,
                distancia:     _distanciaEstabelecimento,
                syncing:       _syncing,
                lastSync:      _lastSync,
                temEstabelecimento:
                    (widget.inspection.latitude != 0.0 && widget.inspection.longitude != 0.0),
                onRefresh: _verificarLocalizacao,
              ),
              const SizedBox(height: 8),
              if (widget.isChecklistTabActive)
                _RastreamentoTempoRealBanner(
                  ativo: _rastreamentoApiIniciadoNestaVisita && _rastreamentoErro == null,
                  mensagemErro: _rastreamentoErro,
                ),
              if (widget.isChecklistTabActive) const SizedBox(height: 8),
            ],

            for (final secao in _secoes) ...[
              _buildSecao(secao),
              const SizedBox(height: 8),
            ],
          ],
        ),

        if (widget.canEdit)
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: _ConcluirBar(
              respondidos:    _respondidos,
              total:          _totalItens,
              finalizando:    _finalizando,
              todosRespondidos: _totalItens == 0 || _respondidos >= _totalItens,
              onConcluir:     _concluir,
            ),
          ),
      ],
    );
  }

  Widget _buildSecao(SecaoChecklistCompleta secao) {
    final tem = secao.itens.isNotEmpty ||
        secao.subsecoes.any((s) =>
            s.itens.isNotEmpty || s.subsecoes.any((s2) => s2.itens.isNotEmpty));
    if (!tem) return const SizedBox.shrink();

    final exp = _isExpanded(secao.id);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SecaoHeader(titulo: secao.titulo, isExpanded: exp,
            onTap: () => _toggle(secao.id)),
        if (exp) ...[
          const SizedBox(height: 6),
          for (final item in secao.itens) _itemField(item),
          for (final sub in secao.subsecoes) _buildSubsecao(sub),
        ],
      ],
    );
  }

  Widget _buildSubsecao(SecaoChecklistCompleta sub, {int level = 1}) {
    final tem = sub.itens.isNotEmpty ||
        sub.subsecoes.any((s2) => s2.itens.isNotEmpty);
    if (!tem) return const SizedBox.shrink();

    final exp = _isExpanded(sub.id);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 4),
        _SubsecaoHeader(titulo: sub.titulo, isExpanded: exp,
            onTap: () => _toggle(sub.id)),
        if (exp) ...[
          const SizedBox(height: 6),
          for (final item in sub.itens) _itemField(item),
          for (final sub2 in sub.subsecoes) _buildSubsecao(sub2, level: level + 1),
        ],
      ],
    );
  }

  Widget _itemField(ItemChecklistCompleto item) {
    final hydrateKey = '${widget.checklistTabVisitToken}';
    return ChecklistItemField(
      key: ValueKey('item-${item.id}'),
      item: item,
      inspecaoLocalId: widget.inspection.id,
      resposta: _respostasMap[item.id],
      enabled: widget.canEdit,
      onSave: widget.canEdit ? _salvarResposta : null,
      planoHydrateKey: hydrateKey,
    );
  }

  Widget _emptyState(IconData icon, String t, String s) => Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(color: _kPrimaryLight, shape: BoxShape.circle),
          child: Icon(icon, size: 40, color: _kPrimary)),
      const SizedBox(height: 16),
      Text(t, style: const TextStyle(color: _kTextPrimary, fontSize: 15, fontWeight: FontWeight.w600)),
      const SizedBox(height: 6),
      Text(s, style: const TextStyle(color: _kTextSecondary, fontSize: 13), textAlign: TextAlign.center),
    ]),
  );
}

class _RastreamentoTempoRealBanner extends StatelessWidget {
  final bool ativo;
  final String? mensagemErro;

  const _RastreamentoTempoRealBanner({
    required this.ativo,
    this.mensagemErro,
  });

  @override
  Widget build(BuildContext context) {
    final erro = mensagemErro != null && mensagemErro!.isNotEmpty;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: erro ? _kError.withValues(alpha: 0.08) : _kSuccessLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: erro ? _kError.withValues(alpha: 0.35) : _kSuccess.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            erro ? Icons.warning_amber_rounded : Icons.podcasts_rounded,
            size: 20,
            color: erro ? _kError : _kSuccess,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              erro
                  ? mensagemErro!
                  : ativo
                      ? 'Rastreamento em tempo real activo. A sua posição é enviada ao servidor '
                          '(como no backoffice) enquanto este separador está aberto.'
                      : 'A iniciar rastreamento em tempo real…',
              style: TextStyle(
                fontSize: 12,
                height: 1.35,
                color: erro ? _kError : _kTextPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Estado GPS ───────────────────────────────────────────────────────────────
enum _LocationState { desconhecido, dentro, fora }

// ─── _GpsStatusBar ────────────────────────────────────────────────────────────
class _GpsStatusBar extends StatelessWidget {
  final _LocationState locationState;
  final double? distancia;
  final bool syncing;
  final DateTime? lastSync;
  final bool temEstabelecimento;
  final VoidCallback onRefresh;

  const _GpsStatusBar({
    required this.locationState,
    required this.distancia,
    required this.syncing,
    required this.lastSync,
    required this.temEstabelecimento,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final gpsColor = locationState == _LocationState.dentro
        ? _kSuccess
        : locationState == _LocationState.fora
            ? _kError
            : _kTextSecondary;

    final gpsIcon = locationState == _LocationState.dentro
        ? Icons.location_on_rounded
        : locationState == _LocationState.fora
            ? Icons.location_off_rounded
            : Icons.location_searching_rounded;

    final gpsText = locationState == _LocationState.dentro
        ? 'Dentro do raio'
        : locationState == _LocationState.fora
            ? 'Fora do raio${distancia != null ? ' (${distancia!.round()}m)' : ''}'
            : temEstabelecimento
                ? 'A verificar localização...'
                : 'Sem coordenadas';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _kBorder)),
      child: Row(
        children: [
          Icon(gpsIcon, size: 16, color: gpsColor),
          const SizedBox(width: 6),
          Expanded(
              child: Text(gpsText,
                  style: TextStyle(
                      fontSize: 11, color: gpsColor, fontWeight: FontWeight.w500))),
          if (syncing)
            const SizedBox(
                width: 14, height: 14,
                child: CircularProgressIndicator(color: _kPrimary, strokeWidth: 1.5))
          else if (lastSync != null)
            Text(
              'sync ${_hhmm(lastSync!)}',
              style: const TextStyle(fontSize: 10, color: _kTextSecondary),
            ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: onRefresh,
            child: const Icon(Icons.refresh_rounded, size: 16, color: _kTextSecondary),
          ),
        ],
      ),
    );
  }

  static String _hhmm(DateTime dt) {
    final l = dt.toLocal();
    return '${l.hour.toString().padLeft(2, '0')}:${l.minute.toString().padLeft(2, '0')}';
  }
}

// ─── _ConcluirBar ─────────────────────────────────────────────────────────────
class _ConcluirBar extends StatelessWidget {
  final int respondidos, total;
  final bool finalizando, todosRespondidos;
  final VoidCallback onConcluir;

  const _ConcluirBar({
    required this.respondidos, required this.total,
    required this.finalizando, required this.todosRespondidos,
    required this.onConcluir,
  });

  @override
  Widget build(BuildContext context) {
    final pendentes  = (total - respondidos).clamp(0, total);
    final bloqueado  = finalizando;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: _kBorder))),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!todosRespondidos && pendentes > 0) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.info_outline_rounded,
                      size: 13, color: _kWarning),
                  const SizedBox(width: 4),
                  Text(
                    '$pendentes ${pendentes == 1 ? "item" : "itens"} por responder',
                    style: const TextStyle(
                        fontSize: 11,
                        color: _kWarning,
                        fontWeight: FontWeight.w500),
                  ),
                ],
              ),
              const SizedBox(height: 6),
            ],
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton.icon(
                onPressed: bloqueado ? null : onConcluir,
                icon: finalizando
                    ? const SizedBox(
                        width: 18, height: 18,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : Icon(
                        todosRespondidos
                            ? Icons.check_circle_rounded
                            : Icons.check_circle_outline_rounded,
                        size: 20),
                label: Text(
                  finalizando ? 'A concluir...' : 'Concluir',
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w700),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor:
                      todosRespondidos ? _kPrimary : _kPrimary.withOpacity(0.65),
                  disabledBackgroundColor: _kPrimary.withOpacity(0.4),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── _RascunhoBanner ─────────────────────────────────────────────────────────
class _RascunhoBanner extends StatelessWidget {
  const _RascunhoBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.5)),
      ),
      child: Row(
        children: [
          const Icon(Icons.lock_outline_rounded,
              size: 20, color: Color(0xFFF59E0B)),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Inspeção não iniciada',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF92400E)),
                ),
                SizedBox(height: 2),
                Text(
                  'Inicie a inspeção para poder preencher as respostas.',
                  style: TextStyle(fontSize: 12, color: Color(0xFFB45309)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── _ProgressBar ─────────────────────────────────────────────────────────────
class _ProgressBar extends StatelessWidget {
  final int total, respondidos;
  const _ProgressBar({required this.total, required this.respondidos});

  @override
  Widget build(BuildContext context) {
    final pct = total > 0 ? (respondidos / total).clamp(0.0, 1.0) : 0.0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _kBorder)),
      child: Column(children: [
        Row(children: [
          Expanded(
            child: Text('$respondidos de $total respondidos',
                style: const TextStyle(
                    color: _kTextPrimary, fontSize: 13,
                    fontWeight: FontWeight.w600)),
          ),
          Text('${(pct * 100).round()}%',
              style: const TextStyle(
                  color: _kPrimary, fontSize: 13,
                  fontWeight: FontWeight.w700)),
        ]),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: pct, minHeight: 6,
            backgroundColor: _kBorder, color: _kPrimary,
          ),
        ),
      ]),
    );
  }
}

// ─── _SecaoHeader ─────────────────────────────────────────────────────────────
class _SecaoHeader extends StatelessWidget {
  final String titulo;
  final bool isExpanded;
  final VoidCallback onTap;
  const _SecaoHeader({required this.titulo, required this.isExpanded, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
          color: _kSurface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _kBorder)),
      child: Row(children: [
        Container(
          width: 3, height: 18,
          margin: const EdgeInsets.only(right: 10),
          decoration: BoxDecoration(
              color: _kPrimary, borderRadius: BorderRadius.circular(2)),
        ),
        Expanded(
          child: Text(titulo.toUpperCase(),
              style: const TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w700,
                  color: _kTextPrimary, letterSpacing: 0.3)),
        ),
        Icon(
          isExpanded
              ? Icons.keyboard_arrow_up_rounded
              : Icons.keyboard_arrow_down_rounded,
          size: 18, color: _kTextSecondary,
        ),
      ]),
    ),
  );
}

// ─── _SubsecaoHeader ──────────────────────────────────────────────────────────
class _SubsecaoHeader extends StatelessWidget {
  final String titulo;
  final bool isExpanded;
  final VoidCallback onTap;
  const _SubsecaoHeader({required this.titulo, required this.isExpanded, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
          color: _kPrimaryLight,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _kPrimary.withOpacity(0.2))),
      child: Row(children: [
        Container(
          width: 2, height: 14,
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
              color: _kPrimary.withOpacity(0.5),
              borderRadius: BorderRadius.circular(2)),
        ),
        Expanded(
          child: Text(titulo,
              style: const TextStyle(
                  fontSize: 11.5, fontWeight: FontWeight.w600,
                  color: _kPrimary)),
        ),
        Icon(
          isExpanded
              ? Icons.keyboard_arrow_up_rounded
              : Icons.keyboard_arrow_down_rounded,
          size: 16, color: _kPrimary,
        ),
      ]),
    ),
  );
}

// ─── _AlertDlg ────────────────────────────────────────────────────────────────
class _AlertDlg extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String titulo, mensagem, confirmLabel;
  final VoidCallback? onConfirm;

  const _AlertDlg({
    required this.icon, required this.iconColor,
    required this.titulo, required this.mensagem,
    required this.confirmLabel, this.onConfirm,
  });

  @override
  Widget build(BuildContext context) => AlertDialog(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
    content: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1), shape: BoxShape.circle),
        child: Icon(icon, size: 36, color: iconColor),
      ),
      const SizedBox(height: 16),
      Text(titulo,
          textAlign: TextAlign.center,
          style: const TextStyle(
              fontSize: 16, fontWeight: FontWeight.w700, color: _kTextPrimary)),
      const SizedBox(height: 8),
      Text(mensagem,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 13, color: _kTextSecondary)),
      const SizedBox(height: 20),
    ]),
    actions: [
      SizedBox(
        width: double.infinity,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: FilledButton(
            onPressed: () {
              Navigator.pop(context);
              onConfirm?.call();
            },
            style: FilledButton.styleFrom(
                backgroundColor: iconColor,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10))),
            child: Text(confirmLabel,
                style: const TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 14)),
          ),
        ),
      ),
    ],
  );
}

// ─── Itens opcionais por responder (concluir na mesma) ───────────────────────

class _PendentesOpcionaisDialog extends StatelessWidget {
  final int pendentes;

  const _PendentesOpcionaisDialog({required this.pendentes});

  @override
  Widget build(BuildContext context) {
    final resumo = pendentes == 1
        ? '1 item do checklist ainda não tem resposta indicada.'
        : '$pendentes itens do checklist ainda não têm resposta indicada.';

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFF4E5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.assignment_late_outlined,
                  size: 36,
                  color: _kWarning,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Respostas em falta',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                  color: _kTextPrimary,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                resumo,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.45,
                  color: _kTextSecondary,
                ),
              ),
              const SizedBox(height: 18),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                decoration: BoxDecoration(
                  color: _kSurface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _kBorder),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      size: 22,
                      color: _kPrimary,
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Se concluir agora, a inspeção fica registada com o preenchimento actual. '
                        'Itens em branco podem afectar o score e a completude do relatório.',
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.4,
                          color: _kTextPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context, false),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: _kBorder, width: 1.2),
                    foregroundColor: _kTextPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Voltar ao checklist',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: _kPrimary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Concluir na mesma',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Justificativa fora do raio (mesmo fluxo que o backoffice) ───────────────

class _JustificativaExistenteDlg extends StatelessWidget {
  final double distanciaMetros;
  final String justificativa;

  const _JustificativaExistenteDlg({
    required this.distanciaMetros,
    required this.justificativa,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text(
        'Finalizar com justificativa?',
        style: TextStyle(
            fontSize: 17, fontWeight: FontWeight.w700, color: _kTextPrimary),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Está a ${distanciaMetros.round()} m do estabelecimento (raio: 10 m). '
              'Já existe uma justificativa registada:',
              style: const TextStyle(fontSize: 13, color: _kTextSecondary),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _kPrimaryLight,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _kBorder),
              ),
              child: Text(
                justificativa,
                style: const TextStyle(fontSize: 13, color: _kTextPrimary),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Deseja continuar para concluir a inspeção?',
              style: TextStyle(fontSize: 13, color: _kTextSecondary),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          style: FilledButton.styleFrom(backgroundColor: _kPrimary),
          child: const Text('Continuar'),
        ),
      ],
    );
  }
}

class _JustificativaDesvioFormDlg extends StatefulWidget {
  final double distanciaMetros;

  const _JustificativaDesvioFormDlg({required this.distanciaMetros});

  @override
  State<_JustificativaDesvioFormDlg> createState() =>
      _JustificativaDesvioFormDlgState();
}

class _JustificativaDesvioFormDlgState extends State<_JustificativaDesvioFormDlg> {
  final _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text(
        'Justificativa do desvio',
        style: TextStyle(
            fontSize: 17, fontWeight: FontWeight.w700, color: _kTextPrimary),
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Está a ${widget.distanciaMetros.round()} m do estabelecimento (raio permitido: 10 m). '
                'Indique o motivo (mínimo 10 caracteres), como na versão web.',
                style: const TextStyle(fontSize: 13, color: _kTextSecondary),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _controller,
                minLines: 3,
                maxLines: 6,
                decoration: InputDecoration(
                  hintText: 'Explique o motivo do desvio de localização…',
                  filled: true,
                  fillColor: _kSurface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: _kBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: _kBorder),
                  ),
                ),
                validator: (v) {
                  final t = v?.trim() ?? '';
                  if (t.isEmpty) return 'Justificativa obrigatória.';
                  if (t.length < 10) return 'Mínimo de 10 caracteres.';
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () {
            if (_formKey.currentState?.validate() ?? false) {
              Navigator.pop(context, _controller.text.trim());
            }
          },
          style: FilledButton.styleFrom(backgroundColor: _kPrimary),
          child: const Text('Registar e continuar'),
        ),
      ],
    );
  }
}

// ─── _ConfirmDlg ──────────────────────────────────────────────────────────────
class _ConfirmDlg extends StatelessWidget {
  const _ConfirmDlg();

  @override
  Widget build(BuildContext context) => AlertDialog(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
    content: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: _kPrimary.withOpacity(0.1), shape: BoxShape.circle),
        child: const Icon(Icons.help_outline_rounded, size: 36, color: _kPrimary),
      ),
      const SizedBox(height: 16),
      const Text('Concluir inspeção?',
          textAlign: TextAlign.center,
          style: TextStyle(
              fontSize: 16, fontWeight: FontWeight.w700, color: _kTextPrimary)),
      const SizedBox(height: 8),
      const Text(
        'Após concluir não poderá alterar as respostas. Tem a certeza?',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 13, color: _kTextSecondary),
      ),
      const SizedBox(height: 20),
    ]),
    actions: [
      Row(children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(left: 16, bottom: 16),
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(right: 16, bottom: 16),
            child: FilledButton(
              onPressed: () => Navigator.pop(context, true),
              style: FilledButton.styleFrom(backgroundColor: _kPrimary),
              child: const Text('Concluir'),
            ),
          ),
        ),
      ]),
    ],
  );
}