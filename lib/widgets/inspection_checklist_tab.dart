import 'package:flutter/material.dart';
import 'package:inspecao/models/checklist_secao.dart';
import 'package:inspecao/models/inspection.dart';
import 'package:inspecao/services/inspecao_service.dart';
import 'package:inspecao/utils/app_logger.dart';
import 'package:inspecao/widgets/checklist_item_field.dart';

// ─── Paleta ───────────────────────────────────────────────────────────────────
const _kPrimary        = Color(0xFF18778A);
const _kPrimaryLight   = Color(0xFFE8F4F7);
const _kBorder         = Color(0xFFE2ECF0);
const _kSurface        = Color(0xFFF7FAFB);
const _kTextPrimary    = Color(0xFF0F2A31);
const _kTextSecondary  = Color(0xFF5A7A83);
const _kSuccess        = Color(0xFF1DAF6E);
const _kError          = Color(0xFFEF4444);
const _kNaoAplica      = Color(0xFF6B7FD7);

// ─── Widget principal ─────────────────────────────────────────────────────────

class InspectionChecklistTab extends StatefulWidget {
  final Inspection inspection;
  final bool canEdit;

  const InspectionChecklistTab({
    super.key,
    required this.inspection,
    required this.canEdit,
  });

  @override
  State<InspectionChecklistTab> createState() => _InspectionChecklistTabState();
}

class _InspectionChecklistTabState extends State<InspectionChecklistTab> {
  final _inspecaoService = InspecaoService();

  List<SecaoChecklistCompleta>          _secoes       = [];
  Map<String, RespostaInspecaoCompleta> _respostasMap = {};
  bool   _loadingItens = false;
  String? _erroCarregamento;

  /// Controlo de colapso: true = expandido (default)
  final Map<String, bool> _expandedMap = {};

  // ── Contadores ──────────────────────────────────────────────────────────────

  /// Todos os itens em todos os níveis
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

  int get _totalItens => _todosItens.length;


  // ── Lifecycle ────────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    AppLogger.log('🚀 [InspectionChecklistTab.initState] '
        'inspectionId=${widget.inspection.id} '
        'checklistId=${widget.inspection.checklistId} '
        'status=${widget.inspection.status} '
        'canEdit=${widget.canEdit}');
    _loadChecklistItens();
  }

  // ── Carregamento ─────────────────────────────────────────────────────────────

  Future<void> _loadChecklistItens() async {
    if (widget.inspection.checklistId == null) {
      AppLogger.log('⚠️ [InspectionChecklistTab] checklistId é NULL – nada a carregar');
      return;
    }

    AppLogger.log('⏳ [InspectionChecklistTab._loadChecklistItens] START '
        'checklistId=${widget.inspection.checklistId} '
        'inspecaoId=${widget.inspection.id}');

    if (mounted) setState(() { _loadingItens = true; _erroCarregamento = null; });

    try {
      final results = await Future.wait([
        _inspecaoService.getChecklistCompleto(widget.inspection.checklistId!),
        _inspecaoService.getRespostas(widget.inspection.id),
      ]);

      final secoes    = results[0] as List<SecaoChecklistCompleta>;
      final respostas = results[1] as List<RespostaInspecaoCompleta>;

      AppLogger.log('📊 [InspectionChecklistTab] RESULTADO: '
          'secoes=${secoes.length} respostas=${respostas.length}');

      // Por defeito todas as seções e subseções expandidas
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
        });
        AppLogger.log('✅ [InspectionChecklistTab] setState OK – '
            'totalItens=$_totalItens respondidos=${_respostasMap.length}');
      }
    } catch (e, st) {
      AppLogger.error('[InspectionChecklistTab._loadChecklistItens] ERRO', e, st);
      if (mounted) {
        setState(() {
          _loadingItens     = false;
          _erroCarregamento = e.toString();
        });
      }
    }
  }

  // ── Guardar resposta ──────────────────────────────────────────────────────────

  Future<void> _salvarResposta(Map<String, dynamic> payload) async {
    AppLogger.log('💾 [InspectionChecklistTab._salvarResposta] payload=$payload');
    try {
      final resposta = await _inspecaoService.salvarResposta(
        widget.inspection.id,
        payload,
      );
      AppLogger.log('✅ [InspectionChecklistTab._salvarResposta] '
          'itemId=${resposta.itemChecklistId} display="${resposta.displayValue}"');
      if (mounted) {
        setState(() => _respostasMap[resposta.itemChecklistId] = resposta);
      }
    } catch (e, st) {
      AppLogger.error('[InspectionChecklistTab._salvarResposta]', e, st);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Erro ao guardar resposta: $e'),
          backgroundColor: _kError,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ));
      }
    }
  }

  // ── Toggle colapso ────────────────────────────────────────────────────────────

  void _toggle(String id) {
    setState(() => _expandedMap[id] = !(_expandedMap[id] ?? true));
  }

  bool _isExpanded(String id) => _expandedMap[id] ?? true;

  // ── Build ─────────────────────────────────────────────────────────────────────

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
          'Sem checklist associado',
          'Esta inspeção não tem checklist configurado.');
    }

    if (_erroCarregamento != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration:
                    BoxDecoration(color: _kError.withOpacity(0.1), shape: BoxShape.circle),
                child: const Icon(Icons.wifi_off_rounded, size: 40, color: _kError),
              ),
              const SizedBox(height: 16),
              const Text('Erro ao carregar',
                  style: TextStyle(
                      color: _kTextPrimary, fontSize: 15, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              Text(_erroCarregamento!,
                  style: const TextStyle(color: _kTextSecondary, fontSize: 12),
                  textAlign: TextAlign.center),
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
            ],
          ),
        ),
      );
    }

    if (_totalItens == 0 && _secoes.isNotEmpty) {
      return _emptyState(Icons.cloud_download_outlined,
          'Sem itens no checklist', 'Não foram encontrados itens neste checklist.');
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 100),
      children: [
        // ── Barra de progresso ─────────────────────────────────────────────────
        _ProgressBar(
          total:       _totalItens,
          respondidos: _respostasMap.length,
        ),
        const SizedBox(height: 12),

        // ── Seções ─────────────────────────────────────────────────────────────
        for (final secao in _secoes) ...[
          _buildSecao(secao),
          const SizedBox(height: 8),
        ],
      ],
    );
  }

  // ── Seção principal ───────────────────────────────────────────────────────────

  Widget _buildSecao(SecaoChecklistCompleta secao) {
    final temConteudo = secao.itens.isNotEmpty ||
        secao.subsecoes.any((s) =>
            s.itens.isNotEmpty ||
            s.subsecoes.any((s2) => s2.itens.isNotEmpty));

    if (!temConteudo) return const SizedBox.shrink();

    final expanded = _isExpanded(secao.id);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Cabeçalho da seção (colapsável)
        _SecaoHeader(
          titulo: secao.titulo,
          isExpanded: expanded,
          onTap: () => _toggle(secao.id),
        ),
        // Conteúdo
        if (expanded) ...[
          const SizedBox(height: 6),
          // Itens directos
          for (final item in secao.itens)
            ChecklistItemField(
              key: ValueKey('item-${item.id}'),
              item: item,
              resposta: _respostasMap[item.id],
              enabled: widget.canEdit,
              onSave: widget.canEdit ? _salvarResposta : null,
            ),
          // Subseções
          for (final sub in secao.subsecoes)
            _buildSubsecao(sub, level: 1),
        ],
      ],
    );
  }

  // ── Subseção ──────────────────────────────────────────────────────────────────

  Widget _buildSubsecao(SecaoChecklistCompleta sub, {int level = 1}) {
    final temItens = sub.itens.isNotEmpty ||
        sub.subsecoes.any((s2) => s2.itens.isNotEmpty);
    if (!temItens) return const SizedBox.shrink();

    final expanded = _isExpanded(sub.id);

    return Padding(
      padding: EdgeInsets.only(left: level * 0.0), // sem indent, igual à imagem
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          _SubsecaoHeader(
            titulo: sub.titulo,
            isExpanded: expanded,
            onTap: () => _toggle(sub.id),
          ),
          if (expanded) ...[
            const SizedBox(height: 6),
            for (final item in sub.itens)
              ChecklistItemField(
                key: ValueKey('item-${item.id}'),
                item: item,
                resposta: _respostasMap[item.id],
                enabled: widget.canEdit,
                onSave: widget.canEdit ? _salvarResposta : null,
              ),
            for (final sub2 in sub.subsecoes)
              _buildSubsecao(sub2, level: level + 1),
          ],
        ],
      ),
    );
  }

  // ── Helper vazio ──────────────────────────────────────────────────────────────

  Widget _emptyState(IconData icon, String title, String sub) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration:
                BoxDecoration(color: _kPrimaryLight, shape: BoxShape.circle),
            child: Icon(icon, size: 40, color: _kPrimary),
          ),
          const SizedBox(height: 16),
          Text(title,
              style: const TextStyle(
                  color: _kTextPrimary, fontSize: 15, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text(sub,
              style: const TextStyle(color: _kTextSecondary, fontSize: 13),
              textAlign: TextAlign.center),
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
        ],
      ),
    );
  }
}

// ─── _ProgressBar ─────────────────────────────────────────────────────────────
/// Barra simples com contagem X/Y respondidos
class _ProgressBar extends StatelessWidget {
  final int total;
  final int respondidos;

  const _ProgressBar({required this.total, required this.respondidos});

  @override
  Widget build(BuildContext context) {
    final pct = total > 0 ? (respondidos / total).clamp(0.0, 1.0) : 0.0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kBorder),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '$respondidos de $total respondidos',
                  style: const TextStyle(
                      color: _kTextPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600),
                ),
              ),
              Text(
                '${(pct * 100).round()}%',
                style: const TextStyle(
                    color: _kPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 6,
              backgroundColor: _kBorder,
              color: _kPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── _SecaoHeader ─────────────────────────────────────────────────────────────
/// Cabeçalho da seção principal — barra com linha vertical colorida + chevron
class _SecaoHeader extends StatelessWidget {
  final String titulo;
  final bool isExpanded;
  final VoidCallback onTap;

  const _SecaoHeader({
    required this.titulo,
    required this.isExpanded,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: _kSurface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _kBorder),
        ),
        child: Row(
          children: [
            // Linha vertical azul (igual à imagem)
            Container(
              width: 3,
              height: 18,
              margin: const EdgeInsets.only(right: 10),
              decoration: BoxDecoration(
                color: _kPrimary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child: Text(
                titulo.toUpperCase(),
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _kTextPrimary,
                    letterSpacing: 0.3),
              ),
            ),
            Icon(
              isExpanded
                  ? Icons.keyboard_arrow_up_rounded
                  : Icons.keyboard_arrow_down_rounded,
              size: 20,
              color: _kTextSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── _SubsecaoHeader ──────────────────────────────────────────────────────────
/// Cabeçalho de subseção — fundo ligeiramente diferente, texto normal
class _SubsecaoHeader extends StatelessWidget {
  final String titulo;
  final bool isExpanded;
  final VoidCallback onTap;

  const _SubsecaoHeader({
    required this.titulo,
    required this.isExpanded,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: _kPrimaryLight.withOpacity(0.55),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _kPrimary.withOpacity(0.25)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                titulo,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _kTextPrimary),
              ),
            ),
            Icon(
              isExpanded
                  ? Icons.keyboard_arrow_up_rounded
                  : Icons.keyboard_arrow_down_rounded,
              size: 18,
              color: _kPrimary,
            ),
          ],
        ),
      ),
    );
  }
}