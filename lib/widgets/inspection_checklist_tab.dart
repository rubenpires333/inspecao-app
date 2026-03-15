import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:inspecao/models/checklist_secao.dart';
import 'package:inspecao/models/inspection.dart';
import 'package:inspecao/services/gps_service.dart';
import 'package:inspecao/services/inspecao_service.dart';
import 'package:inspecao/utils/app_logger.dart';
import 'package:inspecao/widgets/checklist_item_field.dart';

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

  /// Callback chamado após finalizar com sucesso (para o pai actualizar)
  final VoidCallback? onFinalizado;

  /// Callback chamado sempre que o progresso muda (total, respondidos)
  /// Permite ao pai (InspectionDetailScreen) actualizar o badge da tab
  final void Function(int total, int respondidos)? onProgressoAtualizado;

  const InspectionChecklistTab({
    super.key,
    required this.inspection,
    required this.canEdit,
    this.onFinalizado,
    this.onProgressoAtualizado,
  });

  @override
  State<InspectionChecklistTab> createState() => _InspectionChecklistTabState();
}

class _InspectionChecklistTabState extends State<InspectionChecklistTab> {
  final _inspecaoService = InspecaoService();
  final _gpsService      = GpsService();

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

  // ── Concluir ─────────────────────────────────────────────────────────────
  bool _finalizando = false;

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
      _iniciarGps();
    }
  }

  @override
  void dispose() {
    _syncTimer?.cancel();
    _trackingTimer?.cancel();
    _gpsSub?.cancel();
    _gpsService.stopTracking();
    super.dispose();
  }

  // ─── Carregamento inicial ─────────────────────────────────────────────────

  Future<void> _loadChecklistItens() async {
    if (widget.inspection.checklistId == null) return;
    if (mounted) setState(() { _loadingItens = true; _erroCarregamento = null; });

    try {
      final results = await Future.wait([
        _inspecaoService.getChecklistCompleto(widget.inspection.checklistId!),
        _inspecaoService.getRespostas(widget.inspection.id),
      ]);

      final secoes    = results[0] as List<SecaoChecklistCompleta>;
      final respostas = results[1] as List<RespostaInspecaoCompleta>;

      final expanded = <String, bool>{};
      for (final s in secoes) {
        expanded[s.id] = true;
        for (final sub in s.subsecoes) expanded[sub.id] = true;
      }
      final map = <String, RespostaInspecaoCompleta>{};
      for (final r in respostas) map[r.itemChecklistId] = r;

      if (mounted) {
        setState(() {
          _secoes       = secoes;
          _respostasMap = map;
          _expandedMap.addAll(expanded);
          _loadingItens = false;
          _lastSync     = DateTime.now();
        });
        widget.onProgressoAtualizado?.call(_todosItens.length, map.length);
      }
    } catch (e, st) {
      AppLogger.error('[ChecklistTab] erro carregamento', e, st);
      if (mounted) setState(() { _loadingItens = false; _erroCarregamento = e.toString(); });
    }
  }

  // ─── Sync background ─────────────────────────────────────────────────────
  //
  // Corre a cada 30s. Faz merge silencioso das respostas:
  //  · se o servidor tem uma versão mais recente (atualizadoEm posterior),
  //    actualiza o mapa local — cobre o caso web + app simultâneos.
  //  · não apaga respostas locais que ainda não chegaram ao servidor.
  //  · nunca bloqueia a UI (sem setState durante operação, só no final).

  void _iniciarSync() {
    _syncTimer = Timer.periodic(const Duration(seconds: 30), (_) => _syncRespostas());
  }

  Future<void> _syncRespostas() async {
    if (_syncing || !mounted) return;
    _syncing = true;
    if (mounted) setState(() {});   // mostra indicador de sync

    try {
      final respostas = await _inspecaoService.getRespostas(widget.inspection.id);
      if (!mounted) return;

      bool mudou = false;
      final novo = Map<String, RespostaInspecaoCompleta>.from(_respostasMap);

      for (final r in respostas) {
        // Adiciona se ainda não existe localmente (adicionado via web por outro utilizador)
        if (!novo.containsKey(r.itemChecklistId)) {
          novo[r.itemChecklistId] = r;
          mudou = true;
        }
        // Se já existe, mantém a versão local (pode estar mais recente — acabou de ser guardada)
      }

      if (mounted) {
      setState(() {
        if (mudou) _respostasMap = novo;
        _lastSync = DateTime.now();
        _syncing  = false;
      });
      if (mudou) {
        widget.onProgressoAtualizado?.call(_todosItens.length, _respostasMap.length);
      }
    }
    } catch (_) {
      if (mounted) setState(() => _syncing = false);
    }
  }

  // ─── GPS / Rastreamento ───────────────────────────────────────────────────

  Future<void> _iniciarGps() async {
    final ok = await _gpsService.ensurePermissions();
    if (!ok || !mounted) return;
    if (mounted) setState(() => _gpsActivo = true);

    await _gpsService.startTracking();

    // Enviar ponto de rastreamento ao servidor a cada 30s
    _trackingTimer = Timer.periodic(const Duration(seconds: 30), (_) async {
      final pos = _gpsService.lastPosition;
      if (pos == null) return;
      await _inspecaoService.registarPontoRastreamento(
        widget.inspection.id,
        pos.latitude, pos.longitude, pos.accuracy,
      );
    });

    // Ouvir posições localmente para UI
    _gpsSub = _gpsService.positionStream.listen((_) {
      if (!mounted) return;
      setState(() {});
    });

    // Validação inicial
    await _verificarLocalizacao();
  }

  Future<void> _verificarLocalizacao() async {
    final lat = widget.inspection.latitude;
    final lng = widget.inspection.longitude;
    // latitude/longitude são double não-nullable; 0.0 significa não definido
    if (lat == 0.0 || lng == 0.0) return;

    try {
      final result = await _gpsService.validarLocalizacao(
          estLat: lat, estLng: lng, raioMetros: 10);
      if (!mounted) return;
      setState(() {
        _distanciaEstabelecimento = result.distanciaMetros;
        _locationState = result.temLocalizacao
            ? (result.dentroDoRaio ? _LocationState.dentro : _LocationState.fora)
            : _LocationState.desconhecido;
      });
    } catch (_) {}
  }

  // ─── Guardar resposta ─────────────────────────────────────────────────────

  Future<void> _salvarResposta(Map<String, dynamic> payload) async {
    try {
      final r = await _inspecaoService.salvarResposta(
          widget.inspection.id, payload);
      if (mounted) {
        setState(() => _respostasMap[r.itemChecklistId] = r);
        widget.onProgressoAtualizado?.call(_todosItens.length, _respostasMap.length);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Erro ao guardar: $e'),
          backgroundColor: _kError,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ));
      }
    }
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
      final v = await _inspecaoService.validar(widget.inspection.id);
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
          final continuar = await _dlgFora(r.distanciaMetros!);
          if (!continuar) return;
          setState(() => _finalizando = true);
        }
      } catch (_) { semGps = true; }
    }

    // 4. Confirmação final
    if (mounted) setState(() => _finalizando = false);
    final confirmar = await _dlgConfirmar();
    if (!confirmar) return;
    setState(() => _finalizando = true);

    // 5. Finalizar
    try {
      final pos     = _gpsService.lastPosition;
      final payload = <String, dynamic>{};
      if (pos != null) {
        payload['latitude']    = pos.latitude;
        payload['longitude']   = pos.longitude;
        payload['precisaoGps'] = pos.accuracy;
      }
      await _inspecaoService.finalizar(widget.inspection.id, payload);

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
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.help_outline_rounded, size: 48, color: _kWarning),
            const SizedBox(height: 12),
            const Text('Itens por responder',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _kTextPrimary)),
            const SizedBox(height: 8),
            Text(
              '$pendentes ${pendentes == 1 ? "item ainda não foi respondido" : "itens ainda não foram respondidos"}.Deseja concluir mesmo assim?',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: _kTextSecondary),
            ),
            const SizedBox(height: 20),
          ]),
          actions: [
            Row(children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancelar',
                      style: TextStyle(color: _kTextSecondary)),
                ),
              ),
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Concluir mesmo assim',
                      style: TextStyle(color: _kWarning, fontWeight: FontWeight.w700)),
                ),
              ),
            ]),
          ],
        ),
      ) ?? false;

  Future<bool> _dlgFora(double dist) async =>
      await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (_) => _LocationWarningDlg(distancia: dist),
      ) ?? false;

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

    // Rascunho: mostrar checklist em preview + banner a pedir para iniciar
    final isRascunho = widget.inspection.status == InspectionStatus.rascunho;

    return Stack(
      children: [
        ListView(
          padding: EdgeInsets.fromLTRB(12, 12, 12, widget.canEdit ? 120 : 24),
          children: [
            _ProgressBar(total: _totalItens, respondidos: _respondidos),
            const SizedBox(height: 8),

            // Banner "Inicie a inspeção" quando em rascunho
            if (isRascunho) ...[
              _RascunhoBanner(),
              const SizedBox(height: 8),
            ],

            // Barra GPS + sync (só quando pode editar)
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
            ],

            // Seções (sempre visíveis, mas disabled em rascunho/concluída)
            for (final secao in _secoes) ...[
              _buildSecao(secao),
              const SizedBox(height: 8),
            ],
          ],
        ),

        // Botão Concluir fixo em baixo (só quando emAndamento E todos respondidos)
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

  Widget _itemField(ItemChecklistCompleto item) => ChecklistItemField(
    key: ValueKey('item-${item.id}'),
    item: item,
    resposta: _respostasMap[item.id],
    enabled: widget.canEdit,
    onSave: widget.canEdit ? _salvarResposta : null,
  );

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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _kBorder),
      ),
      child: Row(
        children: [
          _icon(),
          const SizedBox(width: 8),
          Expanded(child: _label()),
          // Indicador de sync
          if (syncing)
            const SizedBox(
              width: 13, height: 13,
              child: CircularProgressIndicator(strokeWidth: 1.5, color: _kPrimary),
            )
          else if (lastSync != null) ...[
            Icon(Icons.sync_rounded, size: 12,
                color: _kTextSecondary.withOpacity(0.6)),
            const SizedBox(width: 2),
            Text(_ago(lastSync!),
                style: TextStyle(fontSize: 10,
                    color: _kTextSecondary.withOpacity(0.6))),
          ],
          // Botão refresh localização
          if (temEstabelecimento) ...[
            const SizedBox(width: 6),
            GestureDetector(
              onTap: onRefresh,
              child: Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                    color: _kPrimaryLight,
                    borderRadius: BorderRadius.circular(6)),
                child: const Icon(Icons.my_location_rounded,
                    size: 14, color: _kPrimary),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _icon() {
    switch (locationState) {
      case _LocationState.dentro:
        return const Icon(Icons.location_on_rounded, size: 15, color: _kSuccess);
      case _LocationState.fora:
        return const Icon(Icons.location_off_rounded, size: 15, color: _kWarning);
      case _LocationState.desconhecido:
        return const Icon(Icons.location_searching_rounded,
            size: 15, color: _kTextSecondary);
    }
  }

  Widget _label() {
    switch (locationState) {
      case _LocationState.dentro:
        return Text('No local (${distancia?.toStringAsFixed(0) ?? '~'}m)',
            style: const TextStyle(
                fontSize: 11, color: _kSuccess, fontWeight: FontWeight.w600));
      case _LocationState.fora:
        return Text(
            'Fora do raio — ${distancia?.toStringAsFixed(0) ?? '?'}m (máx 10m)',
            style: const TextStyle(
                fontSize: 11, color: _kWarning, fontWeight: FontWeight.w600));
      case _LocationState.desconhecido:
        return const Text('A verificar localização...',
            style: TextStyle(fontSize: 11, color: _kTextSecondary));
    }
  }

  String _ago(DateTime dt) {
    final d = DateTime.now().difference(dt);
    if (d.inSeconds < 60) return 'agora';
    if (d.inMinutes < 60) return '${d.inMinutes}m';
    return '${d.inHours}h';
  }
}

// ─── _ConcluirBar ─────────────────────────────────────────────────────────────
class _ConcluirBar extends StatelessWidget {
  final int respondidos, total;
  final bool finalizando;
  final bool todosRespondidos;
  final VoidCallback onConcluir;

  const _ConcluirBar({
    required this.respondidos,
    required this.total,
    required this.finalizando,
    required this.todosRespondidos,
    required this.onConcluir,
  });

  @override
  Widget build(BuildContext context) {
    final pendentes  = (total - respondidos).clamp(0, total);
    final bloqueado  = finalizando;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: _kBorder)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.06),
              blurRadius: 8, offset: const Offset(0, -3)),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Aviso visual quando há pendentes (não bloqueia, apenas informa)
            if (!todosRespondidos && !finalizando && total > 0) ...[
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
/// Banner informativo que aparece na tab Checklist quando a inspeção está em rascunho
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
          isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
          size: 20, color: _kTextSecondary,
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
          color: _kPrimaryLight.withOpacity(0.55),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _kPrimary.withOpacity(0.25))),
      child: Row(children: [
        Expanded(
          child: Text(titulo,
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600,
                  color: _kTextPrimary)),
        ),
        Icon(
          isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
          size: 18, color: _kPrimary,
        ),
      ]),
    ),
  );
}

// ─── Diálogos ─────────────────────────────────────────────────────────────────

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
    contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
    content: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 48, color: iconColor),
      const SizedBox(height: 12),
      Text(titulo, textAlign: TextAlign.center,
          style: const TextStyle(
              fontSize: 16, fontWeight: FontWeight.w700, color: _kTextPrimary)),
      const SizedBox(height: 8),
      Text(mensagem, textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 13, color: _kTextSecondary)),
      const SizedBox(height: 20),
    ]),
    actions: [
      SizedBox(
        width: double.infinity,
        child: TextButton(
          onPressed: () { Navigator.pop(context); onConfirm?.call(); },
          style: TextButton.styleFrom(
              foregroundColor: _kPrimary,
              padding: const EdgeInsets.symmetric(vertical: 12)),
          child: Text(confirmLabel,
              style: const TextStyle(fontWeight: FontWeight.w600)),
        ),
      ),
    ],
  );
}

class _LocationWarningDlg extends StatelessWidget {
  final double distancia;
  const _LocationWarningDlg({required this.distancia});

  @override
  Widget build(BuildContext context) => AlertDialog(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
    content: Column(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.location_off_rounded, size: 48, color: _kWarning),
      const SizedBox(height: 12),
      const Text('Fora do raio do estabelecimento',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _kTextPrimary)),
      const SizedBox(height: 8),
      Text(
        'Está a ${distancia.toStringAsFixed(0)}m do estabelecimento '
        '(raio permitido: 10m).\n\nDeseja continuar mesmo assim?',
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 13, color: _kTextSecondary),
      ),
      const SizedBox(height: 20),
    ]),
    actions: [
      Row(children: [
        Expanded(
          child: TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar',
                style: TextStyle(color: _kTextSecondary)),
          ),
        ),
        Expanded(
          child: TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Continuar',
                style: TextStyle(color: _kWarning, fontWeight: FontWeight.w700)),
          ),
        ),
      ]),
    ],
  );
}

class _ConfirmDlg extends StatelessWidget {
  const _ConfirmDlg();

  @override
  Widget build(BuildContext context) => AlertDialog(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
    content: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(
        padding: const EdgeInsets.all(14),
        decoration: const BoxDecoration(color: _kSuccessLight, shape: BoxShape.circle),
        child: const Icon(Icons.check_circle_outline_rounded,
            size: 36, color: _kSuccess),
      ),
      const SizedBox(height: 12),
      const Text('Concluir Inspeção?',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _kTextPrimary)),
      const SizedBox(height: 8),
      const Text('Após concluir não será possível editar as respostas.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: _kTextSecondary)),
      const SizedBox(height: 20),
    ]),
    actions: [
      Row(children: [
        Expanded(
          child: TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar',
                style: TextStyle(color: _kTextSecondary)),
          ),
        ),
        Expanded(
          child: TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: _kSuccess),
            child: const Text('Sim, concluir',
                style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ),
      ]),
    ],
  );
}