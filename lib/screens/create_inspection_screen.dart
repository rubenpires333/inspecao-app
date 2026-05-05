import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:inspecao/models/inspection.dart';
import 'package:inspecao/models/inspector.dart';
import 'package:inspecao/models/inspection_item.dart';
import 'package:inspecao/models/establishment.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:inspecao/config/app_config.dart';
import 'package:inspecao/services/data_service.dart';
import 'package:inspecao/services/api_service.dart';
import 'package:inspecao/services/auth_service.dart';
import 'package:inspecao/screens/establishment_selection_screen.dart';
import 'package:inspecao/screens/team_selection_screen.dart';

// ─── Modelos locais ──────────────────────────────────────────────────────────

class _EquipeItem {
  final String id;
  final String codigo;
  final String nome;
  final String? supervisorNome;
  final int totalMembros;

  const _EquipeItem({
    required this.id,
    required this.codigo,
    required this.nome,
    this.supervisorNome,
    this.totalMembros = 0,
  });

  factory _EquipeItem.fromJson(Map<String, dynamic> json) {
    final membros = json['membros'] as List<dynamic>? ?? [];
    return _EquipeItem(
      id: json['id']?.toString() ?? '',
      codigo: json['codigo']?.toString() ?? '',
      nome: json['nome']?.toString() ?? '',
      supervisorNome: json['supervisorNome']?.toString(),
      totalMembros: membros.length,
    );
  }
}

class _ChecklistItem {
  final String id;
  final String nome;
  final String? descricao;
  final String? categoria;

  const _ChecklistItem({
    required this.id,
    required this.nome,
    this.descricao,
    this.categoria,
  });

  factory _ChecklistItem.fromJson(Map<String, dynamic> json) {
    return _ChecklistItem(
      id: json['id']?.toString() ?? '',
      nome: json['nome']?.toString() ?? '',
      descricao: json['descricao']?.toString(),
      categoria: json['categoriaEstabelecimentoNome']?.toString() ??
          json['categoria']?.toString() ??
          json['categoriaEstabelecimento']?.toString(),
    );
  }
}

// ─── Cores ───────────────────────────────────────────────────────────────────

const _kPrimary = Color(0xFF18778A);
const _kPrimaryLight = Color(0xFFE8F5F8);
const _kPrimaryMid = Color(0xFF1A8FA5);
const _kSurface = Color(0xFFF7FAFB);
const _kBorder = Color(0xFFDDE8EB);
const _kTextPrimary = Color(0xFF1A2E35);
const _kTextSecondary = Color(0xFF5A7A85);
const _kError = Color(0xFFE53E3E);
const _kSuccess = Color(0xFF2E7D52);
const _kWarning = Color(0xFFD97706);

// ─── Tela principal ──────────────────────────────────────────────────────────

class CreateInspectionScreen extends StatefulWidget {
  const CreateInspectionScreen({super.key});

  @override
  State<CreateInspectionScreen> createState() => _CreateInspectionScreenState();
}

class _CreateInspectionScreenState extends State<CreateInspectionScreen>
    with TickerProviderStateMixin {
  final _dataService = DataService();
  final _apiService = ApiService();

  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _selectedTime = TimeOfDay.now();

  Establishment? _selectedEstablishment;
  _EquipeItem? _selectedEquipe;
  _ChecklistItem? _selectedChecklist;

  List<_EquipeItem> _equipes = [];
  List<_ChecklistItem> _checklists = [];

  bool _isLoading = false;
  bool _isLoadingEquipes = false;
  bool _isLoadingChecklists = false;
  String? _errorMessage;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _fadeController.forward();
    _loadInitialData();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    await _loadEquipes();
  }

  Future<void> _ensureApiReady() async {
    if (_apiService.baseUrl == null) {
      _apiService.initialize(baseUrl: AppConfig.apiBaseUrl);
    }
    final prefs = await SharedPreferences.getInstance();
    final authService = AuthService(_apiService, prefs);
    final token = await authService.getAccessToken();
    if (token != null) _apiService.setAuthToken(token);
  }

  Future<void> _loadEquipes() async {
    setState(() => _isLoadingEquipes = true);
    try {
      await _ensureApiReady();
      final raw = await _apiService.getEquipesAtivas();
      if (mounted) {
        setState(() {
          _equipes = raw
              .map((e) => _EquipeItem.fromJson(e as Map<String, dynamic>))
              .where((e) => e.id.isNotEmpty)
              .toList();
        });
      }
    } catch (e) {
      debugPrint('Erro ao carregar equipes: $e');
    } finally {
      if (mounted) setState(() => _isLoadingEquipes = false);
    }
  }

  /// Alinhado ao backoffice: checklists filtrados por `categoriaEstabelecimentoId` (ou nome da categoria).
  Future<void> _loadChecklistsByCategoria(Establishment establishment) async {
    setState(() => _isLoadingChecklists = true);
    try {
      await _ensureApiReady();
      List<Map<String, dynamic>> raw = [];
      final catId = establishment.categoriaEstabelecimentoId;
      if (catId != null && catId.trim().isNotEmpty) {
        raw = await _apiService.getChecklistsPorCategoriaEstabelecimentoId(catId.trim());
      } else {
        final nome = establishment.categoriaEstabelecimentoNome;
        if (nome != null && nome.trim().isNotEmpty) {
          raw = await _apiService.getChecklistsPorCategoriaEstabelecimento(nome.trim());
        }
      }
      if (!mounted) return;
      setState(() {
        _checklists = raw
            .map((e) => _ChecklistItem.fromJson(e as Map<String, dynamic>))
            .where((e) => e.id.isNotEmpty)
            .toList();
        if (_checklists.length == 1) {
          _selectedChecklist = _checklists.first;
        } else if (_selectedChecklist != null &&
            !_checklists.any((c) => c.id == _selectedChecklist!.id)) {
          _selectedChecklist = null;
        }
      });
    } catch (e) {
      debugPrint('Erro ao carregar checklists por categoria: $e');
      if (mounted) {
        setState(() {
          _checklists = [];
          _selectedChecklist = null;
        });
      }
    } finally {
      if (mounted) setState(() => _isLoadingChecklists = false);
    }
  }

  bool get _isFormValid =>
      _selectedEstablishment != null &&
      _selectedEquipe != null &&
      _selectedChecklist != null;

  int get _completedSteps {
    int c = 0;
    if (_selectedEstablishment != null) c++;
    if (_selectedChecklist != null) c++;
    if (_selectedEquipe != null) c++;
    return c;
  }

  Future<void> _selectEstablishment() async {
    await Navigator.push<Establishment>(
      context,
      MaterialPageRoute(
        builder: (context) => EstablishmentSelectionScreen(
          selectedEstablishment: _selectedEstablishment,
          onEstablishmentSelected: (establishment) {
            setState(() => _selectedEstablishment = establishment);
            _loadChecklistsByCategoria(establishment);
          },
        ),
      ),
    );
  }

  void _showEquipeBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _EquipeBottomSheet(
        equipes: _equipes,
        selectedEquipe: _selectedEquipe,
        isLoading: _isLoadingEquipes,
        onSelect: (equipe) {
          setState(() => _selectedEquipe = equipe);
          Navigator.pop(ctx);
        },
        onRefresh: _loadEquipes,
      ),
    );
  }

  void _showChecklistBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ChecklistBottomSheet(
        checklists: _checklists,
        selectedChecklist: _selectedChecklist,
        isLoading: _isLoadingChecklists,
        onSelect: (checklist) {
          setState(() => _selectedChecklist = checklist);
          Navigator.pop(ctx);
        },
        onRefresh: () async {
          if (_selectedEstablishment != null) {
            await _loadChecklistsByCategoria(_selectedEstablishment!);
          }
        },
      ),
    );
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: _kPrimary,
            onPrimary: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (date != null) setState(() => _selectedDate = date);
  }

  Future<void> _selectTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: _kPrimary,
            onPrimary: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (time != null) setState(() => _selectedTime = time);
  }

  Future<void> _createInspection() async {
    if (!_isFormValid) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    HapticFeedback.mediumImpact();

    final dataAgendada = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    final localId = DateTime.now().millisecondsSinceEpoch.toString();

    final inspection = Inspection(
      id: localId,
      titulo: _selectedEstablishment!.nome,
      descricao: 'Inspeção - ${_selectedChecklist!.nome}',
      tipo: InspectionType.estrutural,
      status: InspectionStatus.rascunho,
      dataAgendada: dataAgendada,
      endereco: _selectedEstablishment!.endereco,
      latitude: _selectedEstablishment!.latitude,
      longitude: _selectedEstablishment!.longitude,
      equipe: const [],
      itens: const [],
      establishmentId: _selectedEstablishment!.id,
      equipeId: _selectedEquipe!.id,
      checklistId: _selectedChecklist!.id,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    try {
      // ── Tentar criar directamente no servidor (API) ──────────────────────
      final dataInspecao =
          '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';
      final horaInicio =
          '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}';

      // Mesmos campos que o backoffice web (inspecao-nova): o backend preenche localização a partir do estabelecimento.
      final requestData = <String, dynamic>{
        'checklistId': _selectedChecklist!.id,
        'estabelecimentoId': _selectedEstablishment!.id,
        'equipeId': _selectedEquipe!.id,
        'dataInspecao': dataInspecao,
        'horaInicio': horaInicio,
      };

      final response = await _apiService.createInspectionMobile(requestData);
      final serverId = response['id']?.toString();

      // Usar o ID do servidor como chave local evita duplicar a inspeção quando a lista é
      // atualizada a partir da API (antes ficava uma linha com id temporário e outra com UUID).
      final syncedInspection = inspection.copyWith(
        id: serverId ?? inspection.id,
        serverId: serverId,
        isSynced: true,
      );
      await _dataService.addInspection(syncedInspection);

      if (mounted) {
        HapticFeedback.heavyImpact();
        _showSuccessSnackBar(online: true);
        Navigator.pop(context);
      }
    } catch (_) {
      // ── Fallback: guardar localmente se offline ou erro de rede ─────────
      try {
        await _dataService.addInspection(inspection);
        if (mounted) {
          HapticFeedback.heavyImpact();
          _showSuccessSnackBar(online: false);
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          setState(() =>
              _errorMessage = 'Erro ao criar inspeção. Tente novamente.');
          HapticFeedback.vibrate();
        }
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSuccessSnackBar({required bool online}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              online ? Icons.cloud_done_rounded : Icons.save_rounded,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    online ? 'Inspeção criada no servidor!' : 'Guardada localmente',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  Text(
                    online
                        ? _selectedEstablishment!.nome
                        : 'Será sincronizada quando houver ligação',
                    style: const TextStyle(fontSize: 12, color: Colors.white70),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: online ? _kSuccess : _kWarning,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kSurface,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 24),
                    _buildProgressCard(),
                    const SizedBox(height: 28),
                    _buildSectionLabel('Estabelecimento', Icons.business_rounded, required: true),
                    const SizedBox(height: 10),
                    _buildEstablishmentCard(),
                    const SizedBox(height: 20),
                    _buildSectionLabel('Data e Hora', Icons.event_rounded, required: true),
                    const SizedBox(height: 10),
                    _buildDateTimeRow(),
                    const SizedBox(height: 20),
                    _buildSectionLabel('Checklist', Icons.checklist_rounded, required: true),
                    const SizedBox(height: 10),
                    _buildChecklistCard(),
                    const SizedBox(height: 20),
                    _buildSectionLabel('Equipe de Inspeção', Icons.groups_rounded, required: true),
                    const SizedBox(height: 10),
                    _buildEquipeCard(),
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 20),
                      _buildErrorBanner(),
                    ],
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: _buildActionButton(),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_kPrimary, _kPrimaryMid],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 16, 20),
          child: Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white, size: 20),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Nova Inspeção',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                      ),
                    ),
                    Text(
                      'Preencha os dados para iniciar',
                      style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressCard() {
    final steps = [
      ('Estabelecimento', _selectedEstablishment != null),
      ('Checklist', _selectedChecklist != null),
      ('Equipe', _selectedEquipe != null),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kBorder),
        boxShadow: [
          BoxShadow(color: _kPrimary.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$_completedSteps de 3 etapas',
                style: const TextStyle(color: _kTextSecondary, fontSize: 13, fontWeight: FontWeight.w500),
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Text(
                  _completedSteps == 3 ? 'Pronto para criar!' : 'Em progresso',
                  key: ValueKey(_completedSteps),
                  style: TextStyle(
                    color: _completedSteps == 3 ? _kSuccess : _kWarning,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: _completedSteps / 3),
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOut,
              builder: (_, value, __) => LinearProgressIndicator(
                value: value,
                minHeight: 6,
                backgroundColor: _kBorder,
                valueColor: AlwaysStoppedAnimation<Color>(
                  _completedSteps == 3 ? _kSuccess : _kPrimary,
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: () {
              final widgets = <Widget>[];
              for (int i = 0; i < steps.length; i++) {
                final (label, done) = steps[i];
                // Step: ícone + texto sem Expanded para não ser comprimido
                widgets.add(
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: done ? _kSuccess : _kBorder,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          done ? Icons.check_rounded : Icons.remove_rounded,
                          color: done ? Colors.white : _kTextSecondary,
                          size: 13,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: done ? FontWeight.w600 : FontWeight.w400,
                          color: done ? _kSuccess : _kTextSecondary,
                        ),
                      ),
                    ],
                  ),
                );
                // Separador entre steps, fora do step
                if (i < steps.length - 1) {
                  widgets.add(
                    Expanded(
                      child: Container(
                        height: 1,
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        color: _kBorder,
                      ),
                    ),
                  );
                }
              }
              return widgets;
            }(),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String label, IconData icon, {bool required = false}) {
    return Row(
      children: [
        Icon(icon, size: 16, color: _kPrimary),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            color: _kTextPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.1,
          ),
        ),
        if (required)
          const Text(' *', style: TextStyle(color: _kError, fontSize: 14, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildEstablishmentCard() {
    final s = _selectedEstablishment;
    return _SelectionCard(
      onTap: _selectEstablishment,
      isSelected: s != null,
      child: s != null
          ? Row(
              children: [
                _IconBox(icon: Icons.business_rounded, selected: true),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s.nome,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 15, color: _kTextPrimary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 3),
                      Text(s.endereco,
                          style: const TextStyle(color: _kTextSecondary, fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      if (s.descricao.isNotEmpty) ...[
                        const SizedBox(height: 5),
                        _Chip(label: s.descricao, color: _kPrimary),
                      ],
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: _kTextSecondary),
              ],
            )
          : _EmptyHint(
              icon: Icons.add_business_rounded,
              label: 'Toque para selecionar o estabelecimento',
            ),
    );
  }

  Widget _buildDateTimeRow() {
    final dateLabel = DateFormat('dd/MM/yyyy').format(_selectedDate);
    String dayName = '';
    try {
      dayName = DateFormat('EEEE', 'pt_BR').format(_selectedDate);
    } catch (_) {
      dayName = DateFormat('EEEE').format(_selectedDate);
    }
    final timeLabel = _selectedTime.format(context);

    return Row(
      children: [
        Expanded(
          flex: 3,
          child: _SelectionCard(
            onTap: _selectDate,
            isSelected: true,
            child: Row(
              children: [
                _IconBox(icon: Icons.calendar_today_rounded, selected: true, size: 40),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(dateLabel,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 15, color: _kTextPrimary)),
                      Text(dayName,
                          style: const TextStyle(color: _kTextSecondary, fontSize: 11)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: _SelectionCard(
            onTap: _selectTime,
            isSelected: true,
            child: Row(
              children: [
                _IconBox(icon: Icons.schedule_rounded, selected: true, size: 40),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(timeLabel,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 15, color: _kTextPrimary)),
                      const Text('Início',
                          style: TextStyle(color: _kTextSecondary, fontSize: 11)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChecklistCard() {
    final s = _selectedChecklist;
    final est = _selectedEstablishment;
    final canTap = est != null && !_isLoadingChecklists;

    String emptyLabel() {
      final semCat = est!.categoriaEstabelecimentoId == null &&
          (est.categoriaEstabelecimentoNome == null ||
              est.categoriaEstabelecimentoNome!.trim().isEmpty);
      if (semCat) {
        return 'Estabelecimento sem categoria — atualize a sincronização ou escolha outro';
      }
      return 'Nenhum checklist público para esta categoria';
    }

    return _SelectionCard(
      onTap: canTap ? _showChecklistBottomSheet : null,
      isSelected: s != null,
      child: est == null
          ? const _EmptyHint(
              icon: Icons.store_mall_directory_outlined,
              label:
                  'Selecione o estabelecimento para mostrar apenas checklists da sua categoria',
            )
          : _isLoadingChecklists
              ? const _LoadingHint(label: 'A carregar checklists...')
              : _checklists.isEmpty
                  ? _EmptyDataHint(label: emptyLabel())
                  : s != null
                      ? Row(
                          children: [
                            _IconBox(icon: Icons.checklist_rounded, selected: true),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(s.nome,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 15,
                                          color: _kTextPrimary),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis),
                                  if (s.descricao != null && s.descricao!.isNotEmpty) ...[
                                    const SizedBox(height: 3),
                                    Text(s.descricao!,
                                        style: const TextStyle(
                                            color: _kTextSecondary, fontSize: 12),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis),
                                  ],
                                  if (s.categoria != null) ...[
                                    const SizedBox(height: 5),
                                    _Chip(label: s.categoria!, color: _kPrimary),
                                  ],
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right_rounded, color: _kTextSecondary),
                          ],
                        )
                      : _EmptyHint(
                          icon: Icons.playlist_add_check_circle_rounded,
                          label:
                              'Toque para selecionar o checklist (${_checklists.length} disponíveis)',
                        ),
    );
  }

  Widget _buildEquipeCard() {
    final s = _selectedEquipe;
    return _SelectionCard(
      onTap: !_isLoadingEquipes ? _showEquipeBottomSheet : null,
      isSelected: s != null,
      child: _isLoadingEquipes
          ? const _LoadingHint(label: 'A carregar equipes...')
          : _equipes.isEmpty
              ? const _EmptyDataHint(label: 'Nenhuma equipe disponível')
              : s != null
                  ? Row(
                      children: [
                        _IconBox(icon: Icons.groups_rounded, selected: true),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(s.nome,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15,
                                      color: _kTextPrimary),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis),
                              if (s.supervisorNome != null) ...[
                                const SizedBox(height: 3),
                                Text('Supervisor: ${s.supervisorNome}',
                                    style:
                                        const TextStyle(color: _kTextSecondary, fontSize: 12),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis),
                              ],
                              const SizedBox(height: 5),
                              Row(
                                children: [
                                  _Chip(label: s.codigo, color: _kPrimary),
                                  if (s.totalMembros > 0) ...[
                                    const SizedBox(width: 6),
                                    _Chip(
                                      label:
                                          '${s.totalMembros} membro${s.totalMembros != 1 ? 's' : ''}',
                                      color: _kTextSecondary,
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right_rounded, color: _kTextSecondary),
                      ],
                    )
                  : _EmptyHint(
                      icon: Icons.group_add_rounded,
                      label: 'Toque para selecionar a equipe (${_equipes.length} disponíveis)',
                    ),
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _kError.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kError.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: _kError, size: 20),
          const SizedBox(width: 12),
          Expanded(
              child: Text(_errorMessage!, style: const TextStyle(color: _kError, fontSize: 13))),
          GestureDetector(
            onTap: () => setState(() => _errorMessage = null),
            child: const Icon(Icons.close_rounded, color: _kError, size: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton() {
    final canCreate = _isFormValid && !_isLoading;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: canCreate
              ? const LinearGradient(
                  colors: [_kPrimary, _kPrimaryMid],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight)
              : null,
          color: canCreate ? null : const Color(0xFFCDD9DC),
          boxShadow: canCreate
              ? [BoxShadow(color: _kPrimary.withOpacity(0.35), blurRadius: 16, offset: const Offset(0, 6))]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: canCreate ? _createInspection : null,
            borderRadius: BorderRadius.circular(16),
            child: Center(
              child: _isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.5, valueColor: AlwaysStoppedAnimation(Colors.white)))
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.assignment_add,
                          color: canCreate ? Colors.white : const Color(0xFF8FAAB0),
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          _completedSteps < 3 ? 'Preencha todos os campos' : 'Criar Inspeção',
                          style: TextStyle(
                            color: canCreate ? Colors.white : const Color(0xFF8FAAB0),
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Widgets reutilizáveis ────────────────────────────────────────────────────

class _IconBox extends StatelessWidget {
  final IconData icon;
  final bool selected;
  final double size;

  const _IconBox({required this.icon, this.selected = false, this.size = 44});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: selected ? _kPrimaryLight : _kBorder.withOpacity(0.4),
        borderRadius: BorderRadius.circular(size * 0.27),
      ),
      child: Icon(icon, color: selected ? _kPrimary : _kTextSecondary, size: size * 0.5),
    );
  }
}

class _SelectionCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final bool isSelected;

  const _SelectionCard({required this.child, required this.onTap, this.isSelected = false});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? _kPrimary.withOpacity(0.4) : _kBorder,
          width: isSelected ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isSelected ? _kPrimary.withOpacity(0.07) : Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(padding: const EdgeInsets.all(16), child: child),
        ),
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  final IconData icon;
  final String label;

  const _EmptyHint({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: _kTextSecondary, size: 24),
        const SizedBox(width: 14),
        Expanded(child: Text(label, style: const TextStyle(color: _kTextSecondary, fontSize: 14))),
        const Icon(Icons.chevron_right_rounded, color: _kTextSecondary),
      ],
    );
  }
}

class _LoadingHint extends StatelessWidget {
  final String label;
  const _LoadingHint({required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary),
        ),
        const SizedBox(width: 14),
        Text(label, style: const TextStyle(color: _kTextSecondary, fontSize: 14)),
      ],
    );
  }
}

class _EmptyDataHint extends StatelessWidget {
  final String label;
  const _EmptyDataHint({required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.info_outline_rounded, color: _kWarning, size: 20),
        const SizedBox(width: 12),
        Text(label, style: const TextStyle(color: _kWarning, fontSize: 14)),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color color;

  const _Chip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label,
          style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }
}

// ─── Bottom Sheet: Equipe ─────────────────────────────────────────────────────

class _EquipeBottomSheet extends StatefulWidget {
  final List<_EquipeItem> equipes;
  final _EquipeItem? selectedEquipe;
  final bool isLoading;
  final Function(_EquipeItem) onSelect;
  final VoidCallback onRefresh;

  const _EquipeBottomSheet({
    required this.equipes,
    required this.selectedEquipe,
    required this.isLoading,
    required this.onSelect,
    required this.onRefresh,
  });

  @override
  State<_EquipeBottomSheet> createState() => _EquipeBottomSheetState();
}

class _EquipeBottomSheetState extends State<_EquipeBottomSheet> {
  String _search = '';

  List<_EquipeItem> get _filtered => widget.equipes
      .where((e) =>
          e.nome.toLowerCase().contains(_search.toLowerCase()) ||
          e.codigo.toLowerCase().contains(_search.toLowerCase()) ||
          (e.supervisorNome?.toLowerCase().contains(_search.toLowerCase()) ?? false))
      .toList();

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (ctx, scrollController) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            _buildHandle(),
            _buildSheetHeader('Selecionar Equipe', Icons.groups_rounded, widget.onRefresh),
            _buildSearchField('Pesquisar equipe...'),
            Expanded(
              child: widget.isLoading
                  ? const Center(child: CircularProgressIndicator(color: _kPrimary))
                  : _filtered.isEmpty
                      ? _buildEmpty('Nenhuma equipe encontrada', Icons.group_off_rounded)
                      : ListView.separated(
                          controller: scrollController,
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                          itemCount: _filtered.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (_, i) {
                            final eq = _filtered[i];
                            final isSelected = widget.selectedEquipe?.id == eq.id;
                            return _ItemTile(
                              icon: Icons.groups_rounded,
                              title: eq.nome,
                              subtitle: eq.supervisorNome != null
                                  ? 'Supervisor: ${eq.supervisorNome}'
                                  : null,
                              chips: [
                                eq.codigo,
                                if (eq.totalMembros > 0)
                                  '${eq.totalMembros} membro${eq.totalMembros != 1 ? 's' : ''}',
                              ],
                              isSelected: isSelected,
                              onTap: () => widget.onSelect(eq),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchField(String hint) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: TextField(
        onChanged: (v) => setState(() => _search = v),
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: const Icon(Icons.search_rounded, color: _kTextSecondary, size: 20),
          filled: true,
          fillColor: _kSurface,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        ),
      ),
    );
  }
}

// ─── Bottom Sheet: Checklist ──────────────────────────────────────────────────

class _ChecklistBottomSheet extends StatefulWidget {
  final List<_ChecklistItem> checklists;
  final _ChecklistItem? selectedChecklist;
  final bool isLoading;
  final Function(_ChecklistItem) onSelect;
  final VoidCallback onRefresh;

  const _ChecklistBottomSheet({
    required this.checklists,
    required this.selectedChecklist,
    required this.isLoading,
    required this.onSelect,
    required this.onRefresh,
  });

  @override
  State<_ChecklistBottomSheet> createState() => _ChecklistBottomSheetState();
}

class _ChecklistBottomSheetState extends State<_ChecklistBottomSheet> {
  String _search = '';

  List<_ChecklistItem> get _filtered => widget.checklists
      .where((c) =>
          c.nome.toLowerCase().contains(_search.toLowerCase()) ||
          (c.descricao?.toLowerCase().contains(_search.toLowerCase()) ?? false) ||
          (c.categoria?.toLowerCase().contains(_search.toLowerCase()) ?? false))
      .toList();

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (ctx, scrollController) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            _buildHandle(),
            _buildSheetHeader('Selecionar Checklist', Icons.checklist_rounded, widget.onRefresh),
            _buildSearchField('Pesquisar checklist...'),
            Expanded(
              child: widget.isLoading
                  ? const Center(child: CircularProgressIndicator(color: _kPrimary))
                  : _filtered.isEmpty
                      ? _buildEmpty('Nenhum checklist encontrado', Icons.assignment_late_outlined)
                      : ListView.separated(
                          controller: scrollController,
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                          itemCount: _filtered.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (_, i) {
                            final cl = _filtered[i];
                            final isSelected = widget.selectedChecklist?.id == cl.id;
                            return _ItemTile(
                              icon: Icons.assignment_rounded,
                              title: cl.nome,
                              subtitle: cl.descricao,
                              chips: [if (cl.categoria != null) cl.categoria!],
                              isSelected: isSelected,
                              onTap: () => widget.onSelect(cl),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchField(String hint) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: TextField(
        onChanged: (v) => setState(() => _search = v),
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: const Icon(Icons.search_rounded, color: _kTextSecondary, size: 20),
          filled: true,
          fillColor: _kSurface,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        ),
      ),
    );
  }
}

// ─── Widgets partilhados entre bottom sheets ─────────────────────────────────

Widget _buildHandle() {
  return Center(
    child: Container(
      margin: const EdgeInsets.only(top: 12, bottom: 8),
      width: 40,
      height: 4,
      decoration: BoxDecoration(color: _kBorder, borderRadius: BorderRadius.circular(2)),
    ),
  );
}

Widget _buildSheetHeader(String title, IconData icon, VoidCallback onRefresh) {
  return Padding(
    padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
    child: Row(
      children: [
        Icon(icon, color: _kPrimary, size: 22),
        const SizedBox(width: 10),
        Expanded(
          child: Text(title,
              style: const TextStyle(
                  fontWeight: FontWeight.w700, fontSize: 18, color: _kTextPrimary)),
        ),
        IconButton(
          onPressed: onRefresh,
          icon: const Icon(Icons.refresh_rounded, color: _kPrimary, size: 20),
          padding: EdgeInsets.zero,
        ),
      ],
    ),
  );
}

Widget _buildEmpty(String label, IconData icon) {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 48, color: Colors.grey[300]),
        const SizedBox(height: 12),
        Text(label, style: const TextStyle(color: _kTextSecondary)),
      ],
    ),
  );
}

class _ItemTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final List<String> chips;
  final bool isSelected;
  final VoidCallback onTap;

  const _ItemTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.chips = const [],
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: isSelected ? _kPrimaryLight : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isSelected ? _kPrimary : _kBorder, width: isSelected ? 1.5 : 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: isSelected ? _kPrimary : _kBorder.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon,
                      color: isSelected ? Colors.white : _kTextSecondary, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: isSelected ? _kPrimary : _kTextPrimary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis),
                      if (subtitle != null && subtitle!.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(subtitle!,
                            style: const TextStyle(color: _kTextSecondary, fontSize: 12),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ],
                      if (chips.isNotEmpty) ...[
                        const SizedBox(height: 5),
                        Wrap(
                          spacing: 6,
                          children: chips
                              .map((c) => _Chip(
                                  label: c,
                                  color: isSelected ? _kPrimary : _kTextSecondary))
                              .toList(),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  isSelected
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked_rounded,
                  color: isSelected ? _kPrimary : _kBorder,
                  size: 22,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Step item para a barra de progresso ─────────────────────────────────────

class _StepItem extends StatelessWidget {
  final String label;
  final bool done;

  const _StepItem({required this.label, required this.done});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: done ? _kSuccess : _kBorder,
            shape: BoxShape.circle,
          ),
          child: Icon(
            done ? Icons.check_rounded : Icons.remove_rounded,
            color: done ? Colors.white : _kTextSecondary,
            size: 13,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: done ? FontWeight.w600 : FontWeight.w400,
            color: done ? _kSuccess : _kTextSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}