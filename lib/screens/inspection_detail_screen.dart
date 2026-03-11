import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:inspecao/models/inspection.dart';
import 'package:inspecao/models/inspection_item.dart';
import 'package:inspecao/models/establishment.dart';
import 'package:inspecao/services/data_service.dart';
import 'package:inspecao/widgets/item_evidence_widget.dart';
import 'package:inspecao/widgets/action_plan_widget.dart';
import 'package:inspecao/widgets/non_conformity_action_dialog.dart';
import 'package:inspecao/services/database_service.dart';

// ─── Paleta ──────────────────────────────────────────────────────────────────
const _kPrimary     = Color(0xFF18778A);
const _kPrimaryMid  = Color(0xFF1A8FA5);
const _kPrimaryLight= Color(0xFFE8F4F7);
const _kSurface     = Color(0xFFF7FAFB);
const _kBorder      = Color(0xFFE2ECF0);
const _kTextPrimary = Color(0xFF0F2A31);
const _kTextSecondary = Color(0xFF5A7A83);
const _kSuccess     = Color(0xFF1DAF6E);
const _kWarning     = Color(0xFFF59E0B);
const _kError       = Color(0xFFEF4444);
const _kNaoAplica   = Color(0xFF6B7FD7);

// ─── Main Screen ─────────────────────────────────────────────────────────────

class InspectionDetailScreen extends StatefulWidget {
  final Inspection inspection;
  const InspectionDetailScreen({super.key, required this.inspection});

  @override
  State<InspectionDetailScreen> createState() => _InspectionDetailScreenState();
}

class _InspectionDetailScreenState extends State<InspectionDetailScreen>
    with SingleTickerProviderStateMixin {
  final _dataService = DataService();
  late Inspection _inspection;
  bool _isLoading = false;
  bool _loadingItens = false;
  final _commentsController = TextEditingController();
  Establishment? _establishment;
  late TabController _tabController;

  // Estatísticas
  int get _totalItens => _inspection.itens.length;
  int get _conformes => _inspection.itens.where((i) => i.status == ItemStatus.conforme).length;
  int get _naoConformes => _inspection.itens.where((i) => i.status == ItemStatus.naoConforme).length;
  int get _naoAplica => _inspection.itens.where((i) => i.status == ItemStatus.naoAplica).length;
  int get _pendentes => _inspection.itens.where((i) => i.status == ItemStatus.pendente).length;
  double get _progresso => _totalItens > 0 ? (_totalItens - _pendentes) / _totalItens : 0;

  @override
  void initState() {
    super.initState();
    _inspection = widget.inspection;
    _tabController = TabController(length: 3, vsync: this);
    _commentsController.text = _inspection.observacoes ?? '';
    _loadEstablishment();
    _loadChecklistItens();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _commentsController.dispose();
    super.dispose();
  }

  Future<void> _loadEstablishment() async {
    if (_inspection.establishmentId != null) {
      final est = await _dataService.getEstablishmentById(_inspection.establishmentId!);
      if (mounted) setState(() => _establishment = est);
    }
  }

  /// Carrega os itens do checklist associado à inspeção.
  /// Se a inspeção já tem itens (respostas guardadas), usa-os.
  /// Caso contrário, carrega os ItensChecklist da base local pelo checklistId
  /// e cria InspectionItems com status pendente.
  Future<void> _loadChecklistItens() async {
    // Se já tem itens carregados, não fazer nada
    if (_inspection.itens.isNotEmpty) return;

    // Sem checklistId não há como carregar
    if (_inspection.checklistId == null) return;

    if (mounted) setState(() => _loadingItens = true);

    try {
      // Usar o DatabaseService singleton (mesma instância do DataService)
      final dbService = DatabaseService();
      await dbService.initialize();

      // Buscar seções do checklist via DatabaseService
      final secoes = await dbService.getSecoesByChecklist(_inspection.checklistId!);

      final itens = <InspectionItem>[];
      for (final secao in secoes) {
        final itensSecao = await dbService.getItensAtivosBySecao(secao.id);
        for (final item in itensSecao) {
          itens.add(InspectionItem(
            id: item.id,
            descricao: item.rotulo,
            categoria: secao.titulo,
            status: ItemStatus.pendente,
            obrigatorio: item.obrigatorio,
            ordem: item.ordem,
          ));
        }
      }

      // Ordenar por secção (ordem da secção) e depois por item
      itens.sort((a, b) => a.ordem.compareTo(b.ordem));

      if (mounted && itens.isNotEmpty) {
        final updated = _inspection.copyWith(itens: itens);
        setState(() => _inspection = updated);
        // Persistir os itens na base local para próximas aberturas
        await _dataService.updateInspection(updated);
      }
    } catch (e) {
      print('Erro ao carregar itens do checklist: $e');
    } finally {
      if (mounted) setState(() => _loadingItens = false);
    }
  }

  Future<void> _updateInspectionStatus(InspectionStatus newStatus) async {
    if (newStatus == InspectionStatus.emAndamento) {
      final ok = await _showConfirmDialog(
        title: 'Iniciar Inspeção',
        message: 'Ao iniciar, poderá avaliar os itens do checklist e adicionar evidências.',
        confirmLabel: 'Iniciar',
        confirmColor: _kSuccess,
        icon: Icons.play_circle_fill_rounded,
      );
      if (!ok) return;
    } else if (newStatus == InspectionStatus.concluida) {
      if (_pendentes > 0) {
        final ok = await _showConfirmDialog(
          title: 'Finalizar com itens pendentes?',
          message: '$_pendentes ${_pendentes == 1 ? 'item ainda não foi avaliado' : 'itens ainda não foram avaliados'}. Deseja finalizar mesmo assim?',
          confirmLabel: 'Finalizar',
          confirmColor: _kWarning,
          icon: Icons.warning_amber_rounded,
          isDanger: true,
        );
        if (!ok) return;
      } else {
        final ok = await _showConfirmDialog(
          title: 'Concluir Inspeção',
          message: 'Todos os itens foram avaliados. Confirma a conclusão?',
          confirmLabel: 'Concluir',
          confirmColor: _kPrimary,
          icon: Icons.check_circle_rounded,
        );
        if (!ok) return;
      }
    }

    setState(() => _isLoading = true);
    HapticFeedback.mediumImpact();

    DateTime? dataInicio = _inspection.dataInicio;
    DateTime? dataConclusao = _inspection.dataConclusao;

    if (newStatus == InspectionStatus.emAndamento) dataInicio = DateTime.now();
    if (newStatus == InspectionStatus.concluida) dataConclusao = DateTime.now();

    final updated = _inspection.copyWith(
      status: newStatus,
      dataInicio: dataInicio,
      dataConclusao: dataConclusao,
      updatedAt: DateTime.now(),
    );

    try {
      await _dataService.updateInspection(updated);
      if (mounted) {
        setState(() => _inspection = updated);
        HapticFeedback.heavyImpact();
        _showSnack(
          newStatus == InspectionStatus.emAndamento
              ? 'Inspeção iniciada!'
              : 'Inspeção concluída!',
          newStatus == InspectionStatus.emAndamento ? _kSuccess : _kPrimary,
          newStatus == InspectionStatus.emAndamento
              ? Icons.play_circle_fill_rounded
              : Icons.check_circle_rounded,
        );
      }
    } catch (e) {
      if (mounted) _showSnack('Erro ao atualizar status.', _kError, Icons.error_rounded);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveComments() async {
    setState(() => _isLoading = true);
    try {
      final updated = _inspection.copyWith(
        observacoes: _commentsController.text.trim(),
        updatedAt: DateTime.now(),
      );
      await _dataService.updateInspection(updated);
      if (mounted) {
        setState(() => _inspection = updated);
        _showSnack('Observações guardadas!', _kSuccess, Icons.check_rounded);
      }
    } catch (e) {
      if (mounted) _showSnack('Erro ao guardar.', _kError, Icons.error_rounded);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _updateItemStatus(InspectionItem item, ItemStatus newStatus) {
    if (newStatus == ItemStatus.naoConforme) {
      _showNonConformityDialog(item);
    } else {
      _applyItemStatus(item, newStatus);
    }
  }

  void _applyItemStatus(InspectionItem item, ItemStatus newStatus) {
    final updated = _inspection.copyWith(
      itens: _inspection.itens
          .map((i) => i.id == item.id ? i.copyWith(status: newStatus) : i)
          .toList(),
      updatedAt: DateTime.now(),
    );
    setState(() => _inspection = updated);
    _dataService.updateInspection(updated);
    HapticFeedback.selectionClick();
  }

  Future<void> _showNonConformityDialog(InspectionItem item) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => NonConformityActionDialog(item: item, inspection: _inspection),
    );
    if (result != null) {
      final responsibles = result['responsibles'] as List<String>;
      final dueDate = result['dueDate'] as DateTime;
      await _dataService.createActionPlanForNonConformity(
        inspectionId: _inspection.id,
        inspectionItemId: item.id,
        itemDescription: item.descricao,
        responsibles: responsibles,
        dueDate: dueDate,
      );
      _applyItemStatus(item, ItemStatus.naoConforme);
      if (mounted) _showSnack('Não conformidade registada!', _kError, Icons.warning_rounded);
    }
  }

  void _showSnack(String msg, Color color, IconData icon) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        Icon(icon, color: Colors.white, size: 18),
        const SizedBox(width: 10),
        Text(msg, style: const TextStyle(fontWeight: FontWeight.w600)),
      ]),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 2),
    ));
  }

  Future<bool> _showConfirmDialog({
    required String title,
    required String message,
    required String confirmLabel,
    required Color confirmColor,
    required IconData icon,
    bool isDanger = false,
  }) async {
    return await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
        title: Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: confirmColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: confirmColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: _kTextPrimary))),
        ]),
        content: Text(message, style: const TextStyle(color: _kTextSecondary, height: 1.5)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar', style: TextStyle(color: _kTextSecondary)),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: confirmColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            child: Text(confirmLabel, style: const TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    ) ?? false;
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final canEdit = _inspection.status == InspectionStatus.emAndamento;
    return Scaffold(
      backgroundColor: _kSurface,
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [_buildSliverHeader()],
        body: Column(
          children: [
            _buildTabBar(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildTabDetalhes(),
                  _buildTabChecklist(canEdit),
                  _buildTabComentarios(canEdit),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  // ─── Sliver Header ────────────────────────────────────────────────────────

  Widget _buildSliverHeader() {
    return SliverAppBar(
      expandedHeight: 220,
      pinned: true,
      backgroundColor: _kPrimary,
      foregroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_rounded, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        _StatusBadge(status: _inspection.status),
        const SizedBox(width: 12),
      ],
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.pin,
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [_kPrimary, _kPrimaryMid],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 60, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Número / ID
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _inspection.serverId != null
                          ? 'Nº ${_inspection.serverId!.substring(0, 8).toUpperCase()}'
                          : 'LOCAL · ${_inspection.id.substring(0, 8)}',
                      style: const TextStyle(color: Colors.white70, fontSize: 11, letterSpacing: 0.5),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _inspection.titulo,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(children: [
                    const Icon(Icons.location_on_rounded, size: 14, color: Colors.white60),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        _establishment?.nome ?? _inspection.endereco,
                        style: const TextStyle(color: Colors.white70, fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ]),
                  const SizedBox(height: 16),
                  // Barra de progresso
                  _buildProgressBar(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProgressBar() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${((_totalItens - _pendentes))} / $_totalItens itens avaliados',
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
            Text(
              '${(_progresso * 100).toInt()}%',
              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: _progresso,
            minHeight: 5,
            backgroundColor: Colors.white.withOpacity(0.2),
            valueColor: AlwaysStoppedAnimation<Color>(
              _progresso == 1.0 ? _kSuccess : Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  // ─── TabBar ───────────────────────────────────────────────────────────────

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        labelColor: _kPrimary,
        unselectedLabelColor: _kTextSecondary,
        indicatorColor: _kPrimary,
        indicatorWeight: 2.5,
        labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w400),
        tabs: [
          const Tab(text: 'Detalhes'),
          Tab(
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Text('Checklist'),
              if (_pendentes > 0) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: _kWarning,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text('$_pendentes', style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w700)),
                ),
              ],
            ]),
          ),
          const Tab(text: 'Notas'),
        ],
      ),
    );
  }

  // ─── Tab: Detalhes ────────────────────────────────────────────────────────

  Widget _buildTabDetalhes() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cards de estatísticas
          _buildStatsRow(),
          const SizedBox(height: 16),
          // Info card
          _buildInfoCard(),
          const SizedBox(height: 16),
          // Datas
          _buildDatesCard(),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        Expanded(child: _StatCard(value: '$_conformes', label: 'Conforme', color: _kSuccess, icon: Icons.check_circle_rounded)),
        const SizedBox(width: 10),
        Expanded(child: _StatCard(value: '$_naoConformes', label: 'N. Conforme', color: _kError, icon: Icons.cancel_rounded)),
        const SizedBox(width: 10),
        Expanded(child: _StatCard(value: '$_naoAplica', label: 'N/A', color: _kNaoAplica, icon: Icons.remove_circle_rounded)),
        const SizedBox(width: 10),
        Expanded(child: _StatCard(value: '$_pendentes', label: 'Pendente', color: _kTextSecondary, icon: Icons.schedule_rounded)),
      ],
    );
  }

  Widget _buildInfoCard() {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardTitle('Informações', Icons.info_outline_rounded),
          const SizedBox(height: 12),
          if (_establishment != null) ...[
            _infoRow(Icons.business_rounded, 'Estabelecimento', _establishment!.nome),
            _infoRow(Icons.category_rounded, 'Tipo', _establishment!.tipoText),
            _infoRow(Icons.location_on_rounded, 'Endereço', _establishment!.endereco),
            const _Divider(),
          ],
          _infoRow(Icons.calendar_today_rounded, 'Data Agendada', DateFormat('dd/MM/yyyy').format(_inspection.dataAgendada)),
          _infoRow(Icons.access_time_rounded, 'Horário', DateFormat('HH:mm').format(_inspection.dataAgendada)),
          _infoRow(Icons.sync_rounded, 'Sincronização', _inspection.isSynced ? 'Sincronizado ✓' : 'Pendente'),
        ],
      ),
    );
  }

  Widget _buildDatesCard() {
    if (_inspection.dataInicio == null && _inspection.dataConclusao == null) {
      return const SizedBox.shrink();
    }
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardTitle('Execução', Icons.timeline_rounded),
          const SizedBox(height: 12),
          if (_inspection.dataInicio != null)
            _infoRow(Icons.play_circle_outline_rounded, 'Iniciada em',
                DateFormat('dd/MM/yyyy HH:mm').format(_inspection.dataInicio!)),
          if (_inspection.dataConclusao != null)
            _infoRow(Icons.stop_circle_outlined, 'Concluída em',
                DateFormat('dd/MM/yyyy HH:mm').format(_inspection.dataConclusao!)),
          if (_inspection.dataInicio != null && _inspection.dataConclusao != null) ...[
            const _Divider(),
            _infoRow(Icons.timer_outlined, 'Duração', () {
              final diff = _inspection.dataConclusao!.difference(_inspection.dataInicio!);
              final h = diff.inHours;
              final m = diff.inMinutes.remainder(60);
              return h > 0 ? '${h}h ${m}min' : '${m} min';
            }()),
          ],
        ],
      ),
    );
  }

  // ─── Tab: Checklist ───────────────────────────────────────────────────────

  Widget _buildTabChecklist(bool canEdit) {
    // A carregar itens do checklist
    if (_loadingItens) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: _kPrimary, strokeWidth: 2.5),
            SizedBox(height: 16),
            Text('A carregar checklist...', style: TextStyle(color: _kTextSecondary, fontSize: 14)),
          ],
        ),
      );
    }

    // Sem checklistId associado
    if (_inspection.checklistId == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: _kBorder.withOpacity(0.4), shape: BoxShape.circle),
              child: const Icon(Icons.assignment_late_outlined, size: 40, color: _kTextSecondary),
            ),
            const SizedBox(height: 16),
            const Text('Sem checklist associado', style: TextStyle(color: _kTextPrimary, fontSize: 15, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            const Text('Esta inspeção não tem checklist configurado.', style: TextStyle(color: _kTextSecondary, fontSize: 13)),
          ],
        ),
      );
    }

    // Itens ainda a carregar (checklistId existe mas itens ainda vazios)
    if (_inspection.itens.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: _kPrimaryLight, shape: BoxShape.circle),
              child: const Icon(Icons.cloud_download_outlined, size: 40, color: _kPrimary),
            ),
            const SizedBox(height: 16),
            const Text('Checklist sem itens locais', style: TextStyle(color: _kTextPrimary, fontSize: 15, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            const Text('Os itens do checklist não foram sincronizados para este dispositivo.', style: TextStyle(color: _kTextSecondary, fontSize: 13), textAlign: TextAlign.center),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _loadChecklistItens,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Tentar novamente'),
              style: FilledButton.styleFrom(backgroundColor: _kPrimary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            ),
          ],
        ),
      );
    }

    // Agrupar por categoria
    final Map<String, List<InspectionItem>> grouped = {};
    for (final item in _inspection.itens) {
      grouped.putIfAbsent(item.categoria, () => []).add(item);
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      children: [
        // Resumo visual inline
        _buildChecklistSummary(),
        const SizedBox(height: 16),
        // Grupos
        for (final entry in grouped.entries) ...[
          _CategoryHeader(label: entry.key),
          const SizedBox(height: 6),
          ...entry.value.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _InspectionItemCard(
              item: item,
              enabled: canEdit,
              inspectionId: _inspection.id,
              inspectionStatus: _inspection.status,
              onStatusChanged: (s) => _updateItemStatus(item, s),
            ),
          )),
          const SizedBox(height: 8),
        ],
        // Plano de ação
        if (_inspection.status == InspectionStatus.emAndamento ||
            _inspection.status == InspectionStatus.concluida) ...[
          const SizedBox(height: 8),
          _cardTitle('Plano de Ação', Icons.assignment_late_rounded),
          const SizedBox(height: 8),
          ActionPlanWidget(
            inspectionId: _inspection.id,
            availableResponsibles: const ['Inspetor', 'Supervisor', 'Gestor'],
            inspectionItems: _inspection.itens,
          ),
        ],
      ],
    );
  }

  Widget _buildChecklistSummary() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kBorder),
      ),
      child: Row(
        children: [
          Expanded(child: _MiniStat(value: '$_conformes', label: 'Conf.', color: _kSuccess)),
          _verticalDivider(),
          Expanded(child: _MiniStat(value: '$_naoConformes', label: 'N.Conf.', color: _kError)),
          _verticalDivider(),
          Expanded(child: _MiniStat(value: '$_naoAplica', label: 'N/A', color: _kNaoAplica)),
          _verticalDivider(),
          Expanded(child: _MiniStat(value: '$_pendentes', label: 'Pend.', color: _kTextSecondary)),
        ],
      ),
    );
  }

  Widget _verticalDivider() => Container(width: 1, height: 32, color: _kBorder);

  // ─── Tab: Comentários ─────────────────────────────────────────────────────

  Widget _buildTabComentarios(bool canEdit) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardTitle('Observações Gerais', Icons.comment_rounded),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _kBorder),
            ),
            child: TextField(
              controller: _commentsController,
              enabled: canEdit,
              maxLines: 8,
              decoration: InputDecoration(
                hintText: canEdit
                    ? 'Adicione observações gerais sobre a inspeção...'
                    : 'Sem observações registadas.',
                hintStyle: const TextStyle(color: _kTextSecondary, fontSize: 14),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(16),
              ),
              style: const TextStyle(fontSize: 14, color: _kTextPrimary, height: 1.5),
            ),
          ),
          if (canEdit) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _isLoading ? null : _saveComments,
                icon: _isLoading
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.save_rounded, size: 18),
                label: Text(_isLoading ? 'A guardar...' : 'Guardar Observações'),
                style: FilledButton.styleFrom(
                  backgroundColor: _kPrimary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  // ─── Bottom Bar ───────────────────────────────────────────────────────────

  Widget? _buildBottomBar() {
    final status = _inspection.status;
    if (status != InspectionStatus.rascunho && status != InspectionStatus.emAndamento) {
      return null;
    }
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: _kBorder)),
        boxShadow: [
          BoxShadow(color: _kPrimary.withOpacity(0.08), blurRadius: 12, offset: const Offset(0, -4)),
        ],
      ),
      child: SafeArea(
        child: status == InspectionStatus.rascunho
            ? _ActionButton(
                label: 'Iniciar Inspeção',
                icon: Icons.play_circle_fill_rounded,
                color: _kSuccess,
                loading: _isLoading,
                onPressed: () => _updateInspectionStatus(InspectionStatus.emAndamento),
              )
            : Row(
                children: [
                  Expanded(
                    child: _ActionButton(
                      label: 'Concluir',
                      icon: Icons.check_circle_rounded,
                      color: _pendentes == 0 ? _kPrimary : _kPrimary,
                      loading: _isLoading,
                      onPressed: () => _updateInspectionStatus(InspectionStatus.concluida),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  Widget _cardTitle(String title, IconData icon) {
    return Row(children: [
      Icon(icon, size: 16, color: _kPrimary),
      const SizedBox(width: 8),
      Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _kTextPrimary)),
    ]);
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 15, color: _kTextSecondary),
          const SizedBox(width: 10),
          SizedBox(
            width: 110,
            child: Text(label, style: const TextStyle(fontSize: 13, color: _kTextSecondary)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _kTextPrimary)),
          ),
        ],
      ),
    );
  }
}

// ─── Widgets auxiliares ──────────────────────────────────────────────────────

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: _kBorder),
      boxShadow: [BoxShadow(color: _kPrimary.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
    ),
    child: child,
  );
}

class _Divider extends StatelessWidget {
  const _Divider();
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Divider(height: 1, color: _kBorder),
  );
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  final IconData icon;
  const _StatCard({required this.value, required this.label, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
    decoration: BoxDecoration(
      color: color.withOpacity(0.08),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: color)),
        Text(label, style: const TextStyle(fontSize: 10, color: _kTextSecondary), textAlign: TextAlign.center),
      ],
    ),
  );
}

class _MiniStat extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  const _MiniStat({required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Column(children: [
    Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: color)),
    Text(label, style: const TextStyle(fontSize: 11, color: _kTextSecondary)),
  ]);
}

class _CategoryHeader extends StatelessWidget {
  final String label;
  const _CategoryHeader({required this.label});
  @override
  Widget build(BuildContext context) => Row(children: [
    Container(width: 3, height: 16, decoration: BoxDecoration(color: _kPrimary, borderRadius: BorderRadius.circular(2))),
    const SizedBox(width: 8),
    Text(label.toUpperCase(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _kPrimary, letterSpacing: 0.8)),
  ]);
}

class _StatusBadge extends StatelessWidget {
  final InspectionStatus status;
  const _StatusBadge({required this.status});

  Color get _color {
    switch (status) {
      case InspectionStatus.rascunho: return Colors.grey;
      case InspectionStatus.emAndamento: return _kWarning;
      case InspectionStatus.concluida: return Colors.blue;
      case InspectionStatus.sincronizada: return Colors.cyan;
      case InspectionStatus.porVerificar: return Colors.amber;
      case InspectionStatus.verificada: return Colors.lightBlue;
      case InspectionStatus.invalida: return _kError;
      case InspectionStatus.relatorioGerado: return Colors.purple;
      case InspectionStatus.parecerDdrsDdrf: return Colors.indigo;
      case InspectionStatus.assinaturaCa: return Colors.teal;
      case InspectionStatus.finalizada: return _kSuccess;
      case InspectionStatus.disponibilizada: return Colors.lightGreen;
    }
  }

  String get _label {
    switch (status) {
      case InspectionStatus.rascunho: return 'Rascunho';
      case InspectionStatus.emAndamento: return 'Em Andamento';
      case InspectionStatus.concluida: return 'Concluída';
      case InspectionStatus.sincronizada: return 'Sincronizada';
      case InspectionStatus.porVerificar: return 'Por Verificar';
      case InspectionStatus.verificada: return 'Verificada';
      case InspectionStatus.invalida: return 'Inválida';
      case InspectionStatus.relatorioGerado: return 'Relatório';
      case InspectionStatus.parecerDdrsDdrf: return 'Parecer';
      case InspectionStatus.assinaturaCa: return 'Assinatura CA';
      case InspectionStatus.finalizada: return 'Finalizada';
      case InspectionStatus.disponibilizada: return 'Disponível';
    }
  }

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: _color.withOpacity(0.2),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: _color.withOpacity(0.5)),
    ),
    child: Text(_label, style: TextStyle(color: _color, fontSize: 11, fontWeight: FontWeight.w700)),
  );
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool loading;
  final VoidCallback onPressed;
  const _ActionButton({required this.label, required this.icon, required this.color, required this.loading, required this.onPressed});

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    child: FilledButton.icon(
      onPressed: loading ? null : onPressed,
      icon: loading
          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
          : Icon(icon, size: 20),
      label: Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
      style: FilledButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(vertical: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
  );
}

// ─── InspectionItemCard ───────────────────────────────────────────────────────

class _InspectionItemCard extends StatefulWidget {
  final InspectionItem item;
  final bool enabled;
  final String inspectionId;
  final InspectionStatus inspectionStatus;
  final ValueChanged<ItemStatus> onStatusChanged;

  const _InspectionItemCard({
    required this.item,
    required this.enabled,
    required this.inspectionId,
    required this.inspectionStatus,
    required this.onStatusChanged,
  });

  @override
  State<_InspectionItemCard> createState() => _InspectionItemCardState();
}

class _InspectionItemCardState extends State<_InspectionItemCard> {
  bool _expanded = false;

  Color get _statusColor {
    switch (widget.item.status) {
      case ItemStatus.pendente: return _kTextSecondary;
      case ItemStatus.conforme: return _kSuccess;
      case ItemStatus.naoConforme: return _kError;
      case ItemStatus.naoAplica: return _kNaoAplica;
    }
  }

  IconData get _statusIcon {
    switch (widget.item.status) {
      case ItemStatus.pendente: return Icons.schedule_rounded;
      case ItemStatus.conforme: return Icons.check_circle_rounded;
      case ItemStatus.naoConforme: return Icons.cancel_rounded;
      case ItemStatus.naoAplica: return Icons.remove_circle_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPendente = widget.item.status == ItemStatus.pendente;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isPendente ? _kBorder : _statusColor.withOpacity(0.35),
          width: isPendente ? 1 : 1.5,
        ),
        boxShadow: [
          BoxShadow(color: _statusColor.withOpacity(0.06), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  // Status icon
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: _statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(_statusIcon, color: _statusColor, size: 18),
                  ),
                  const SizedBox(width: 12),
                  // Descrição
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.item.descricao,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isPendente ? _kTextSecondary : _kTextPrimary,
                          ),
                        ),
                        if (widget.item.obrigatorio)
                          const Padding(
                            padding: EdgeInsets.only(top: 2),
                            child: Text('Obrigatório', style: TextStyle(fontSize: 10, color: _kError)),
                          ),
                      ],
                    ),
                  ),
                  // Acções rápidas (se enabled)
                  if (widget.enabled)
                    _QuickActions(item: widget.item, onStatusChanged: widget.onStatusChanged)
                  else
                    Icon(_expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                        color: _kTextSecondary, size: 20),
                ],
              ),
            ),
          ),
          // Expandido: observação + evidências
          if (_expanded) ...[
            Divider(height: 1, color: _kBorder),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.item.observacao != null && widget.item.observacao!.isNotEmpty) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _kSurface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: _kBorder),
                      ),
                      child: Text(widget.item.observacao!,
                          style: const TextStyle(fontSize: 13, color: _kTextSecondary, height: 1.4)),
                    ),
                    const SizedBox(height: 10),
                  ],
                  ItemEvidenceWidget(
                    inspectionId: widget.inspectionId,
                    itemId: widget.item.id,
                    itemTitle: widget.item.descricao,
                    onEvidencesChanged: (_) {},
                    enabled: widget.enabled,
                    allowDeletion: widget.enabled,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  final InspectionItem item;
  final ValueChanged<ItemStatus> onStatusChanged;
  const _QuickActions({required this.item, required this.onStatusChanged});

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      _QBtn(
        icon: Icons.check_rounded,
        color: _kSuccess,
        selected: item.status == ItemStatus.conforme,
        onTap: () => onStatusChanged(ItemStatus.conforme),
      ),
      const SizedBox(width: 6),
      _QBtn(
        icon: Icons.close_rounded,
        color: _kError,
        selected: item.status == ItemStatus.naoConforme,
        onTap: () => onStatusChanged(ItemStatus.naoConforme),
      ),
      const SizedBox(width: 6),
      _QBtn(
        icon: Icons.remove_rounded,
        color: _kNaoAplica,
        selected: item.status == ItemStatus.naoAplica,
        onTap: () => onStatusChanged(ItemStatus.naoAplica),
      ),
    ],
  );
}

class _QBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;
  const _QBtn({required this.icon, required this.color, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: selected ? color : color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: selected ? color : color.withOpacity(0.25)),
      ),
      child: Icon(icon, color: selected ? Colors.white : color, size: 16),
    ),
  );
}