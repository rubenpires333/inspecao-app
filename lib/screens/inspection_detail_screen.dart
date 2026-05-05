import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:inspecao/config/app_config.dart';
import 'package:inspecao/models/inspection.dart';
import 'package:inspecao/models/inspection_item.dart';
import 'package:inspecao/models/establishment.dart';
import 'package:inspecao/services/api_service.dart';
import 'package:inspecao/services/auth_service.dart';
import 'package:inspecao/services/data_service.dart';
import 'package:inspecao/widgets/item_evidence_widget.dart';
import 'package:inspecao/widgets/action_plan_widget.dart';
import 'package:inspecao/widgets/non_conformity_action_dialog.dart';
import 'package:inspecao/services/database_service.dart';
import 'package:inspecao/utils/app_logger.dart';
import 'package:inspecao/widgets/inspection_checklist_tab.dart';

// ─── Paleta ──────────────────────────────────────────────────────────────────
const _kPrimary      = Color(0xFF18778A);
const _kPrimaryMid   = Color(0xFF1A8FA5);
const _kPrimaryLight = Color(0xFFE8F4F7);
const _kSurface      = Color(0xFFF7FAFB);
const _kBorder       = Color(0xFFE2ECF0);
const _kTextPrimary  = Color(0xFF0F2A31);
const _kTextSecondary= Color(0xFF5A7A83);
const _kSuccess      = Color(0xFF1DAF6E);
const _kWarning      = Color(0xFFF59E0B);
const _kError        = Color(0xFFEF4444);
const _kNaoAplica    = Color(0xFF6B7FD7);

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
  final _dbService = DatabaseService();
  String? _checklistNome;
  late TabController _tabController;

  // Progresso do checklist — actualizado pelo InspectionChecklistTab via callback
  int _checklistTotal       = 0;
  int _checklistRespondidos = 0;

  // Equipa da inspeção
  Map<String, dynamic>? _equipe;
  List<Map<String, dynamic>> _membros = [];
  bool _loadingEquipe = false;
  int get _pendentes => (_checklistTotal - _checklistRespondidos).clamp(0, _checklistTotal);

  /// Chamado pelo ChecklistTab sempre que o progresso muda
  void _onProgressoAtualizado(int total, int respondidos) {
    if (!mounted) return;
    setState(() {
      _checklistTotal       = total;
      _checklistRespondidos = respondidos;
    });
  }

  /// Chamado pelo ChecklistTab quando a inspeção é concluída com sucesso
  void _onInspecaoFinalizada() {
    if (!mounted) return;
    setState(() {
      _inspection = _inspection.copyWith(
        status: InspectionStatus.concluida,
        dataConclusao: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    });
    _showSnack('Inspeção concluída com sucesso!', _kPrimary, Icons.check_circle_rounded);
  }

  @override
  void initState() {
    super.initState();
    _inspection = widget.inspection;
    _tabController = TabController(length: 3, vsync: this);
    _commentsController.text = _inspection.observacoes ?? '';
    AppLogger.log('🔎 [InspectionDetail] init inspectionId=${_inspection.id} '
        'status=${_inspection.status} checklistId=${_inspection.checklistId}');
    _loadEstablishment();
    _loadChecklistNome();
    _loadChecklistItens();
    _loadEquipe();
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

  /// Nome do checklist na BD local; se não existir, tenta API (nome oficial do modelo de inspeção).
  Future<void> _loadChecklistNome() async {
    final id = _inspection.checklistId;
    if (id == null || id.isEmpty) return;

    String? nome = await _dbService.getChecklistNomeById(id);

    if ((nome == null || nome.isEmpty) && mounted) {
      try {
        final apiService = ApiService();
        if (apiService.baseUrl == null) {
          apiService.initialize(baseUrl: AppConfig.apiBaseUrl);
        }
        final prefs = await SharedPreferences.getInstance();
        final authService = AuthService(apiService, prefs);
        final token = await authService.getAccessToken();
        if (token != null) apiService.setAuthToken(token);

        final data = await apiService.getChecklistCompleto(id);
        nome = data['nome']?.toString();
      } catch (_) {
        /* offline ou erro — mantém null */
      }
    }

    if (mounted) setState(() => _checklistNome = nome ?? '');
  }

  /// `dataInspecao` da API é só data → meia-noite local; não confundir com hora agendada real.
  String _formatAgendaTimeLabel(DateTime d) {
    if (d.hour == 0 && d.minute == 0 && d.second == 0) {
      return 'Sem horário';
    }
    return DateFormat('HH:mm').format(d);
  }

  Future<void> _loadEquipe() async {
    final equipeId = _inspection.equipeId;
    AppLogger.log('👥 [InspectionDetail._loadEquipe] equipeId=$equipeId ');
    if (equipeId == null || equipeId.isEmpty) {
      AppLogger.log('⚠️ [InspectionDetail._loadEquipe] equipeId nulo/vazio — a usar inspection.equipe (${_inspection.equipe.length} membros)');
      return;
    }

    if (mounted) setState(() => _loadingEquipe = true);
    try {
      final apiService = ApiService();
      if (apiService.baseUrl == null) {
        apiService.initialize(baseUrl: AppConfig.apiBaseUrl);
      }
      final prefs = await SharedPreferences.getInstance();
      final authService = AuthService(apiService, prefs);
      final token = await authService.getAccessToken();
      if (token != null) apiService.setAuthToken(token);

      final data = await apiService.getEquipeCompleta(equipeId);
      final membros = (data['membros'] as List<dynamic>?)
              ?.cast<Map<String, dynamic>>() ??
          [];
      if (mounted) {
        setState(() {
          _equipe  = data;
          _membros = membros;
          _loadingEquipe = false;
        });
      }
    } catch (e) {
      AppLogger.log('⚠️ [InspectionDetail] equipe não carregada: $e');
      if (mounted) setState(() => _loadingEquipe = false);
    }
  }

  /// Carrega os itens do checklist associado à inspeção.
  Future<void> _loadChecklistItens() async {
    // Mantido apenas para compatibilidade antiga; o carregamento real
    // do checklist agora é feito em `InspectionChecklistTab` via API.
    if (_inspection.checklistId == null) return;
    AppLogger.log('ℹ️ [InspectionDetail] _loadChecklistItens delegado para InspectionChecklistTab '
        'checklistId=${_inspection.checklistId}');
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
    }

    AppLogger.log('📝 [InspectionDetail] atualizar status inspectionId=${_inspection.id} '
        'de=${_inspection.status} para=$newStatus pendentes=$_pendentes');

    setState(() => _isLoading = true);
    HapticFeedback.mediumImpact();

    DateTime? dataInicio    = _inspection.dataInicio;
    DateTime? dataConclusao = _inspection.dataConclusao;

    if (newStatus == InspectionStatus.emAndamento) dataInicio    = DateTime.now();
    if (newStatus == InspectionStatus.concluida)   dataConclusao = DateTime.now();

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
        AppLogger.log('✅ [InspectionDetail] status atualizado inspectionId=${_inspection.id} '
            'novoStatus=${updated.status} dataInicio=${updated.dataInicio} dataConclusao=${updated.dataConclusao}');
        HapticFeedback.heavyImpact();
        _showSnack(
          newStatus == InspectionStatus.emAndamento ? 'Inspeção iniciada!' : 'Inspeção concluída!',
          newStatus == InspectionStatus.emAndamento ? _kSuccess : _kPrimary,
          newStatus == InspectionStatus.emAndamento
              ? Icons.play_circle_fill_rounded
              : Icons.check_circle_rounded,
        );
      }
    } catch (e) {
      if (mounted) _showSnack('Erro ao atualizar status.', _kError, Icons.error_rounded);
      AppLogger.log('❌ [InspectionDetail] erro ao atualizar status inspectionId=${_inspection.id}: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveComments() async {
    setState(() => _isLoading = true);
    AppLogger.log('📝 [InspectionDetail] guardar observacoes inspectionId=${_inspection.id}');
    try {
      final updated = _inspection.copyWith(
        observacoes: _commentsController.text.trim(),
        updatedAt: DateTime.now(),
      );
      await _dataService.updateInspection(updated);
      if (mounted) {
        setState(() => _inspection = updated);
        _showSnack('Observações guardadas!', _kSuccess, Icons.check_rounded);
        AppLogger.log('✅ [InspectionDetail] observacoes guardadas inspectionId=${_inspection.id}');
      }
    } catch (e) {
      if (mounted) _showSnack('Erro ao guardar.', _kError, Icons.error_rounded);
      AppLogger.log('❌ [InspectionDetail] erro ao guardar observacoes inspectionId=${_inspection.id}: $e');
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
    AppLogger.log('📝 [InspectionDetail] item status alterado inspectionId=${_inspection.id} '
        'itemId=${item.id} novoStatus=$newStatus');
  }

  Future<void> _showNonConformityDialog(InspectionItem item) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => NonConformityActionDialog(item: item, inspection: _inspection),
    );
    if (result != null) {
      final responsibles = result['responsibles'] as List<String>;
      final dueDate      = result['dueDate'] as DateTime;
      await _dataService.createActionPlanForNonConformity(
        inspectionId:    _inspection.id,
        inspectionItemId: item.id,
        itemDescription: item.descricao,
        responsibles:    responsibles,
        dueDate:         dueDate,
      );
      _applyItemStatus(item, ItemStatus.naoConforme);
      if (mounted) _showSnack('Não conformidade registada!', _kWarning, Icons.warning_rounded);
      AppLogger.log('✅ [InspectionDetail] nao conformidade registada inspectionId=${_inspection.id} '
          'itemId=${item.id} responsaveis=${responsibles.join(',')} dueDate=$dueDate');
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
              Expanded(
                  child: Text(title,
                      style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: _kTextPrimary))),
            ]),
            content:
                Text(message, style: const TextStyle(color: _kTextSecondary, height: 1.5)),
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
                child: Text(confirmLabel,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ) ??
        false;
  }

  bool get _canEdit => _inspection.status == InspectionStatus.emAndamento;

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final canEdit = _canEdit;
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
      expandedHeight: 160,
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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _inspection.serverId != null
                          ? 'Nº ${_inspection.serverId}'
                          : _inspection.id.substring(0, 8).toUpperCase(),
                      style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Título
                  Text(
                    _inspection.titulo,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        height: 1.3),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  // Local
                  if (_establishment != null || _inspection.endereco.isNotEmpty)
                    Row(children: [
                      const Icon(Icons.location_on_rounded,
                          color: Colors.white60, size: 14),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          _establishment?.endereco ?? _inspection.endereco,
                          style: const TextStyle(color: Colors.white70, fontSize: 13),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ]),
                 
                ],
              ),
            ),
          ),
        ),
      ),
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
        labelStyle:
            const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        unselectedLabelStyle:
            const TextStyle(fontSize: 13, fontWeight: FontWeight.w400),
        tabs: [
          const Tab(text: 'Detalhes'),
          Tab(
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Text('Checklist'),
              if (_pendentes > 0) ...[
                const SizedBox(width: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: _kWarning,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text('$_pendentes',
                      style: const TextStyle(
                          fontSize: 10,
                          color: Colors.white,
                          fontWeight: FontWeight.w700)),
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
          _buildInfoCard(),
          const SizedBox(height: 16),
          _buildDatesCard(),
          const SizedBox(height: 16),
          _buildEquipeCard(),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  // _buildStatsRow removido — estatísticas agora no ChecklistTab

  Widget _buildInfoCard() {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardTitle('Informações', Icons.info_outline_rounded),
          const SizedBox(height: 12),
          if (_establishment != null) ...[
            _infoRow(Icons.business_rounded, 'Estabelecimento', _establishment!.nome),
            _infoRow(Icons.store_mall_directory_rounded, 'Categoria do estabelecimento',
                _establishment!.categoriaOuTipoText),
            if (_establishment!.endereco.isNotEmpty)
              _infoRow(Icons.location_on_rounded, 'Endereço', _establishment!.endereco),
            const _Divider(),
          ],
          if (_inspection.checklistId != null && _inspection.checklistId!.isNotEmpty)
            _infoRow(
              Icons.assignment_outlined,
              'Checklist',
              _checklistNome == null
                  ? 'A carregar…'
                  : (_checklistNome!.trim().isEmpty ? '—' : _checklistNome!.trim()),
            ),
          _infoRow(Icons.calendar_today_rounded, 'Data Agendada',
              DateFormat('dd/MM/yyyy').format(_inspection.dataAgendada)),
          _infoRow(Icons.access_time_rounded, 'Horário',
              _formatAgendaTimeLabel(_inspection.dataAgendada)),
          _infoRow(Icons.sync_rounded, 'Sincronização',
              _inspection.isSynced ? 'Sincronizado ✓' : 'Pendente'),
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
              final diff =
                  _inspection.dataConclusao!.difference(_inspection.dataInicio!);
              final h = diff.inHours;
              final m = diff.inMinutes.remainder(60);
              return h > 0 ? '${h}h ${m}min' : '${m} min';
            }()),
          ],
        ],
      ),
    );
  }

  Widget _buildEquipeCard() {
    final temEquipeId = _inspection.equipeId != null && _inspection.equipeId!.isNotEmpty;

    // Se não tem equipeId e não tem membros na inspeção, não mostra o card
    if (!temEquipeId && _inspection.equipe.isEmpty && !_loadingEquipe) {
      return const SizedBox.shrink();
    }

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            _cardTitle('Equipa', Icons.group_rounded),
            const Spacer(),
            if (_loadingEquipe)
              const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                      strokeWidth: 1.5, color: _kPrimary)),
          ]),
          const SizedBox(height: 12),

          // Nome da equipa
          if (_equipe != null) ...[
            _infoRow(
              Icons.groups_rounded,
              'Nome',
              _equipe!['nome']?.toString() ?? '—',
            ),
            if ((_equipe!['codigo'] ?? '').toString().isNotEmpty)
              _infoRow(
                Icons.tag_rounded,
                'Código',
                _equipe!['codigo'].toString(),
              ),
          ] else if (!_loadingEquipe) ...[
            _infoRow(Icons.tag_rounded, 'ID', _inspection.equipeId!),
          ],

          // Membros
          if (_membros.isNotEmpty) ...[
            const _Divider(),
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(children: [
                const Icon(Icons.person_outline_rounded,
                    size: 14, color: _kPrimary),
                const SizedBox(width: 6),
                Text(
                  'Membros (${_membros.length})',
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: _kTextPrimary),
                ),
              ]),
            ),
            ..._membros.map((m) => _MembroCard(membro: m)),
          ] else if (!_loadingEquipe) ...[
            // Fallback: membros vindos do modelo local (inspection.equipe)
            if (_inspection.equipe.isNotEmpty) ...[
              const _Divider(),
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(children: [
                  const Icon(Icons.person_outline_rounded,
                      size: 14, color: _kPrimary),
                  const SizedBox(width: 6),
                  Text(
                    'Membros (${_inspection.equipe.length})',
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _kTextPrimary),
                  ),
                ]),
              ),
              ..._inspection.equipe.map((inspector) {
                  // Usar toJson() para acesso seguro a todos os campos
                  final m = inspector.toJson();
                  return _MembroCard(membro: m);
                }),
            ] else if (_equipe != null) ...[
              const _Divider(),
              const Text(
                'Sem membros registados.',
                style: TextStyle(fontSize: 12, color: _kTextSecondary),
              ),
            ],
          ],
        ],
      ),
    );
  }

  // ─── Tab: Checklist ───────────────────────────────────────────────────────

  Widget _buildTabChecklist(bool canEdit) {
    return InspectionChecklistTab(
      inspection: _inspection,
      canEdit: canEdit,
      onFinalizado: _onInspecaoFinalizada,
      onProgressoAtualizado: _onProgressoAtualizado,
    );
  }

  // _buildChecklistSummary e _verticalDivider removidos

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
                hintStyle:
                    const TextStyle(color: _kTextSecondary, fontSize: 14),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(16),
              ),
              style: const TextStyle(
                  fontSize: 14, color: _kTextPrimary, height: 1.5),
            ),
          ),
          if (canEdit) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _isLoading ? null : _saveComments,
                icon: _isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.save_rounded, size: 18),
                label: Text(_isLoading ? 'A guardar...' : 'Guardar Observações'),
                style: FilledButton.styleFrom(
                  backgroundColor: _kPrimary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
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

  /// Bottom bar: só aparece quando status == rascunho (botão Iniciar).
  /// O botão Concluir está no InspectionChecklistTab para ter validação GPS
  /// e sincronização com o servidor.
  Widget? _buildBottomBar() {
    if (_inspection.status != InspectionStatus.rascunho) return null;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: _kBorder)),
        boxShadow: [
          BoxShadow(
              color: _kPrimary.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, -4)),
        ],
      ),
      child: SafeArea(
        child: _ActionButton(
          label: 'Iniciar Inspeção',
          icon: Icons.play_circle_fill_rounded,
          color: _kPrimary,
          loading: _isLoading,
          onPressed: () =>
              _updateInspectionStatus(InspectionStatus.emAndamento),
        ),
      ),
    );
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  Widget _cardTitle(String title, IconData icon) {
    return Row(children: [
      Icon(icon, size: 16, color: _kPrimary),
      const SizedBox(width: 8),
      Text(title,
          style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: _kTextPrimary)),
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
            child: Text(label,
                style: const TextStyle(fontSize: 13, color: _kTextSecondary)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _kTextPrimary)),
          ),
        ],
      ),
    );
  }
}

// ─── Widgets auxiliares ──────────────────────────────────────────────────────

Widget _Card({required Widget child}) {
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: _kBorder),
      boxShadow: [
        BoxShadow(
            color: _kPrimary.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2))
      ],
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
  const _StatCard(
      {required this.value,
      required this.label,
      required this.color,
      required this.icon});

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
            Text(value,
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: color)),
            Text(label,
                style: const TextStyle(
                    fontSize: 10, color: _kTextSecondary),
                textAlign: TextAlign.center),
          ],
        ),
      );
}

class _MiniStat extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  const _MiniStat(
      {required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Column(children: [
        Text(value,
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.w800, color: color)),
        Text(label,
            style: const TextStyle(fontSize: 11, color: _kTextSecondary)),
      ]);
}

class _CategoryHeader extends StatelessWidget {
  final String label;
  const _CategoryHeader({required this.label});

  @override
  Widget build(BuildContext context) => Row(children: [
        Container(
            width: 3,
            height: 16,
            decoration: BoxDecoration(
                color: _kPrimary,
                borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 8),
        // CORRIGIDO: Expanded para evitar overflow em títulos longos
        Expanded(
          child: Text(
            label.toUpperCase(),
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: _kPrimary,
                letterSpacing: 0.8),
            softWrap: true,
          ),
        ),
      ]);
}

class _StatusBadge extends StatelessWidget {
  final InspectionStatus status;
  const _StatusBadge({required this.status});

  Color get _color {
    switch (status) {
      case InspectionStatus.rascunho:        return Colors.grey;
      case InspectionStatus.emAndamento:     return _kWarning;
      case InspectionStatus.concluida:       return Colors.blue;
      case InspectionStatus.sincronizada:    return Colors.cyan;
      case InspectionStatus.porVerificar:    return Colors.amber;
      case InspectionStatus.verificada:      return Colors.lightBlue;
      case InspectionStatus.invalida:        return _kError;
      case InspectionStatus.relatorioGerado: return Colors.purple;
      case InspectionStatus.parecerDdrsDdrf: return Colors.indigo;
      case InspectionStatus.assinaturaCa:    return Colors.teal;
      case InspectionStatus.finalizada:      return _kSuccess;
      case InspectionStatus.disponibilizada: return Colors.lightGreen;
    }
  }

  String get _label {
    switch (status) {
      case InspectionStatus.rascunho:        return 'Rascunho';
      case InspectionStatus.emAndamento:     return 'Em Andamento';
      case InspectionStatus.concluida:       return 'Concluída';
      case InspectionStatus.sincronizada:    return 'Sincronizada';
      case InspectionStatus.porVerificar:    return 'Por Verificar';
      case InspectionStatus.verificada:      return 'Verificada';
      case InspectionStatus.invalida:        return 'Inválida';
      case InspectionStatus.relatorioGerado: return 'Relatório';
      case InspectionStatus.parecerDdrsDdrf: return 'Parecer';
      case InspectionStatus.assinaturaCa:    return 'Assinatura CA';
      case InspectionStatus.finalizada:      return 'Finalizada';
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
        child: Text(_label,
            style: TextStyle(
                color: _color,
                fontSize: 11,
                fontWeight: FontWeight.w700)),
      );
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool loading;
  final VoidCallback onPressed;
  const _ActionButton(
      {required this.label,
      required this.icon,
      required this.color,
      required this.loading,
      required this.onPressed});

  @override
  Widget build(BuildContext context) => SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: loading ? null : onPressed,
          icon: loading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : Icon(icon, size: 20),
          label: Text(label,
              style: const TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w700)),
          style: FilledButton.styleFrom(
            backgroundColor: color,
            padding: const EdgeInsets.symmetric(vertical: 15),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
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
      case ItemStatus.pendente:    return _kTextSecondary;
      case ItemStatus.conforme:    return _kSuccess;
      case ItemStatus.naoConforme: return _kError;
      case ItemStatus.naoAplica:   return _kNaoAplica;
    }
  }

  IconData get _statusIcon {
    switch (widget.item.status) {
      case ItemStatus.pendente:    return Icons.schedule_rounded;
      case ItemStatus.conforme:    return Icons.check_circle_rounded;
      case ItemStatus.naoConforme: return Icons.cancel_rounded;
      case ItemStatus.naoAplica:   return Icons.remove_circle_rounded;
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
          BoxShadow(
              color: _statusColor.withOpacity(0.06),
              blurRadius: 6,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Cabeçalho: ícone de status + descrição (sem os botões aqui!) ──
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Ícone de status
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
                // Descrição — ocupa toda a largura restante e quebra linha
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 2),
                      Text(
                        widget.item.descricao,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isPendente ? _kTextSecondary : _kTextPrimary,
                          height: 1.4,
                        ),
                        softWrap: true,  // ← garante quebra de linha
                      ),
                      if (widget.item.obrigatorio)
                        const Padding(
                          padding: EdgeInsets.only(top: 2),
                          child: Text('Obrigatório',
                              style: TextStyle(fontSize: 10, color: _kError)),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Botões de resposta ABAIXO da descrição, com texto das opções ──
          if (widget.enabled) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
              child: _QuickActions(
                item: widget.item,
                onStatusChanged: widget.onStatusChanged,
              ),
            ),
          ],

          // ── Rodapé clicável para expandir evidências ──────────────────────
          InkWell(
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(14),
              bottomRight: Radius.circular(14),
            ),
            onTap: () => setState(() => _expanded = !_expanded),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: _kSurface,
                border: Border(top: BorderSide(color: _kBorder)),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(14),
                  bottomRight: Radius.circular(14),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.photo_library_outlined,
                      size: 13, color: _kTextSecondary),
                  const SizedBox(width: 5),
                  Text(
                    'Evidências e observações',
                    style: const TextStyle(
                        fontSize: 11, color: _kTextSecondary),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    _expanded
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                    color: _kTextSecondary,
                    size: 16,
                  ),
                ],
              ),
            ),
          ),

          // ── Painel expansível: observação + evidências ────────────────────
          if (_expanded) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 4, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.item.observacao != null &&
                      widget.item.observacao!.isNotEmpty) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _kSurface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: _kBorder),
                      ),
                      child: Text(
                        widget.item.observacao!,
                        style: const TextStyle(
                            fontSize: 13,
                            color: _kTextSecondary,
                            height: 1.4),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                  // Widget de evidências (fotos/anexos)
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

// ─── _QuickActions — botões de resposta em largura total com TEXTO das opções ─

class _QuickActions extends StatelessWidget {
  final InspectionItem item;
  final ValueChanged<ItemStatus> onStatusChanged;
  const _QuickActions(
      {required this.item, required this.onStatusChanged});

  @override
  Widget build(BuildContext context) => Row(
        children: [
          // ✓ Conforme
          Expanded(
            child: _QBtn(
              icon: Icons.check_rounded,
              label: 'Conforme',
              color: _kSuccess,
              selected: item.status == ItemStatus.conforme,
              onTap: () => onStatusChanged(ItemStatus.conforme),
            ),
          ),
          const SizedBox(width: 6),
          // ✗ Não Conforme
          Expanded(
            child: _QBtn(
              icon: Icons.close_rounded,
              label: 'N. Conforme',
              color: _kError,
              selected: item.status == ItemStatus.naoConforme,
              onTap: () => onStatusChanged(ItemStatus.naoConforme),
            ),
          ),
          const SizedBox(width: 6),
          // — N/A
          Expanded(
            child: _QBtn(
              icon: Icons.remove_rounded,
              label: 'N/A',
              color: _kNaoAplica,
              selected: item.status == ItemStatus.naoAplica,
              onTap: () => onStatusChanged(ItemStatus.naoAplica),
            ),
          ),
        ],
      );
}

// ─── _MembroCard — card de membro da equipa ──────────────────────────────────

class _MembroCard extends StatelessWidget {
  final Map<String, dynamic> membro;
  const _MembroCard({required this.membro});

  String _val(String key) => membro[key]?.toString() ?? '';

  @override
  Widget build(BuildContext context) {
    final nome     = _val('nome').isNotEmpty ? _val('nome') : _val('nomeCompleto');
    final email    = _val('email');
    final telefone = _val('telefone').isNotEmpty ? _val('telefone') : _val('telemovel');
    final cargo    = _val('cargo').isNotEmpty ? _val('cargo') : _val('funcao');
    final role     = _val('role').isNotEmpty ? _val('role') : _val('perfil');

    // Iniciais para avatar
    final partes = nome.trim().split(' ');
    final iniciais = partes.length >= 2
        ? '${partes.first[0]}${partes.last[0]}'.toUpperCase()
        : nome.isNotEmpty ? nome[0].toUpperCase() : '?';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar com iniciais
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: _kPrimaryLight,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              iniciais,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: _kPrimary),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Nome
                Text(
                  nome.isNotEmpty ? nome : 'Sem nome',
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _kTextPrimary),
                ),
                // Cargo / Role
                if (cargo.isNotEmpty || role.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    cargo.isNotEmpty ? cargo : role,
                    style: const TextStyle(
                        fontSize: 11,
                        color: _kPrimary,
                        fontWeight: FontWeight.w500),
                  ),
                ],
                // Email
                if (email.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(children: [
                    const Icon(Icons.email_outlined,
                        size: 12, color: _kTextSecondary),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        email,
                        style: const TextStyle(
                            fontSize: 12, color: _kTextSecondary),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ]),
                ],
                // Telefone
                if (telefone.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Row(children: [
                    const Icon(Icons.phone_outlined,
                        size: 12, color: _kTextSecondary),
                    const SizedBox(width: 4),
                    Text(
                      telefone,
                      style: const TextStyle(
                          fontSize: 12, color: _kTextSecondary),
                    ),
                  ]),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── _QBtn — botão individual com ícone + texto ───────────────────────────────

class _QBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _QBtn({
    required this.icon,
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
          decoration: BoxDecoration(
            color: selected ? color : color.withOpacity(0.07),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
                color: selected ? color : color.withOpacity(0.3),
                width: selected ? 1.5 : 1),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: selected ? Colors.white : color,
                size: 18,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: selected ? Colors.white : color,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      );
}