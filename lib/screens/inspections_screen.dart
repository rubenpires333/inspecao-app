import 'package:flutter/material.dart';
import 'package:inspecao/models/inspection.dart';
import 'package:inspecao/models/inspection_item.dart';
import 'package:inspecao/models/user.dart';
import 'package:inspecao/models/establishment.dart';
import 'package:inspecao/services/data_service.dart';
import 'package:inspecao/services/role_service.dart';
import 'package:inspecao/screens/create_inspection_screen.dart';
import 'package:inspecao/screens/inspection_detail_screen.dart';
import 'package:inspecao/screens/notifications_screen.dart';
import 'package:inspecao/services/database_service.dart';
import 'package:inspecao/screens/login_screen.dart';

class InspectionsScreen extends StatefulWidget {
  final Function(ThemeMode) changeThemeMode;

  const InspectionsScreen({super.key, required this.changeThemeMode});

  @override
  State<InspectionsScreen> createState() => _InspectionsScreenState();
}

class _InspectionsScreenState extends State<InspectionsScreen> {
  final _dataService = DataService();
  final _dbService = DatabaseService();
  List<Inspection> _inspections = [];
  List<Inspection> _filteredInspections = [];
  InspectionStatus? _statusFilter;
  final _searchController = TextEditingController();
  User? _currentUser;
  Map<String, Establishment> _establishmentsCache = {};
  bool _isSearchVisible = false;
  bool _isLoading = false;
  
  // Filtros adicionais
  double _minScore = 0.0;
  double _maxScore = 100.0;
  DateTime? _startDate;
  DateTime? _endDate;
  String? _selectedCompany;
  String? _selectedLocation;
  String? _selectedQuickDate; // Para rastrear qual botão de data rápida está selecionado

  @override
  void initState() {
    super.initState();
    // Garantir que os valores de score estejam no range correto
    _minScore = _minScore.clamp(0.0, 100.0);
    _maxScore = _maxScore.clamp(0.0, 100.0);
    _loadData(sync: false); // Carregar apenas do banco local, sem sincronizar
    _searchController.addListener(_filterInspections);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData({bool sync = false}) async {
    try {
      setState(() => _isLoading = true);
      
      final user = await _dataService.getCurrentUser();
      List<Inspection> inspections = [];
      Map<String, Establishment> establishmentsMap = {};
      
      if (user != null) {
        if (sync) {
          // Sincronizar com API apenas quando solicitado explicitamente
          inspections = await _dataService.getInspectionsForUser(user);
          
          // Carregar estabelecimentos da API
          try {
            final establishments = await _dataService.getAllEstablishments();
            for (final establishment in establishments) {
              establishmentsMap[establishment.id] = establishment;
            }
          } catch (e) {
            // Se não houver estabelecimentos, continuar com mapa vazio
            establishmentsMap = {};
          }
        } else {
          // Carregar apenas do banco local (sem sincronizar)
          await _dbService.initialize();
          inspections = await _dbService.getInspections();
          
          // Carregar estabelecimentos do banco local
          try {
            final establishments = await _dbService.getEstablishments();
            for (final establishment in establishments) {
              establishmentsMap[establishment.id] = establishment;
            }
          } catch (e) {
            // Se não houver estabelecimentos, continuar com mapa vazio
            establishmentsMap = {};
          }
        }
      }
      
      if (mounted) {
        setState(() {
          _currentUser = user;
          _inspections = inspections;
          _establishmentsCache = establishmentsMap;
          _isLoading = false;
          // Reaplicar filtros após carregar dados
          _applyFilters();
        });
      }
    } catch (e) {
      // Verificar se é erro de autenticação (403/401)
      final errorString = e.toString();
      if (errorString.contains('403') || errorString.contains('401') || errorString.contains('ForcedLogoutException')) {
        // Forçar logout e redirecionar para tela de login
        if (mounted) {
          await _dataService.logout();
          
          // Mostrar mensagem ao usuário antes ou durante a navegação
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Sessão expirada. Faça login novamente.'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
          
          // Navegar para login removendo todas as telas anteriores da pilha
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => LoginScreen(changeThemeMode: widget.changeThemeMode)),
            (route) => false,
          );
        }
        return;
      }
      
      // Tratar outros erros de forma adequada
      if (mounted) {
        setState(() {
          _inspections = [];
          _filteredInspections = [];
          _establishmentsCache = {};
          _isLoading = false;
        });
      }
      // Log do erro para debug
      print('Erro ao carregar inspeções: $e');
    }
  }

  void _filterInspections() {
    setState(() {
      _applyFilters();
    });
  }

  void _applyFilters() {
    // Garantir que os valores de score estejam no range correto
    _minScore = _minScore.clamp(0.0, 100.0);
    _maxScore = _maxScore.clamp(0.0, 100.0);
    
    final searchTerm = _searchController.text.toLowerCase();
    _filteredInspections = _inspections.where((inspection) {
      // Filtro de busca
      final matchesSearch = searchTerm.isEmpty ||
          inspection.titulo.toLowerCase().contains(searchTerm) ||
          inspection.endereco.toLowerCase().contains(searchTerm);
      
      // Filtro de status
      final matchesStatus = _statusFilter == null || inspection.status == _statusFilter;
      
      // Filtro de score
      final totalItems = inspection.itens.length;
      final conformItems = inspection.itens.where((item) => item.status == ItemStatus.conforme).length;
      final score = totalItems > 0 ? (conformItems / totalItems * 100) : 0.0;
      final matchesScore = score >= _minScore && score <= _maxScore;
      
      // Filtro de data
      final matchesDate = _startDate == null || _endDate == null ||
          (inspection.dataAgendada.isAfter(_startDate!.subtract(const Duration(days: 1))) && 
           inspection.dataAgendada.isBefore(_endDate!.add(const Duration(days: 1))));
      
      // Filtro de empresa
      final establishment = _establishmentsCache[inspection.establishmentId];
      final matchesCompany = _selectedCompany == null || 
          (establishment != null && establishment.nome.toLowerCase().contains(_selectedCompany!.toLowerCase()));
      
      // Filtro de localização
      final matchesLocation = _selectedLocation == null ||
          inspection.endereco.toLowerCase().contains(_selectedLocation!.toLowerCase());
      
      return matchesSearch && matchesStatus && matchesScore && matchesDate && 
             matchesCompany && matchesLocation;
    }).toList();
  }

  void _setStatusFilter(InspectionStatus? status) {
    setState(() {
      _statusFilter = status;
      _applyFilters();
    });
  }


  Color _getStatusColor(InspectionStatus status) {
    switch (status) {
      case InspectionStatus.rascunho:
        return Colors.grey;
      case InspectionStatus.emAndamento:
        return Colors.orange;
      case InspectionStatus.concluida:
        return Colors.blue;
      case InspectionStatus.sincronizada:
        return Colors.cyan;
      case InspectionStatus.porVerificar:
        return Colors.amber;
      case InspectionStatus.verificada:
        return Colors.lightBlue;
      case InspectionStatus.invalida:
        return Colors.red;
      case InspectionStatus.relatorioGerado:
        return Colors.purple;
      case InspectionStatus.parecerDdrsDdrf:
        return Colors.indigo;
      case InspectionStatus.assinaturaCa:
        return Colors.teal;
      case InspectionStatus.finalizada:
        return Colors.green;
      case InspectionStatus.disponibilizada:
        return Colors.lightGreen;
    }
  }

  IconData _getStatusIcon(InspectionStatus status) {
    switch (status) {
      case InspectionStatus.rascunho:
        return Icons.edit;
      case InspectionStatus.emAndamento:
        return Icons.access_time;
      case InspectionStatus.concluida:
        return Icons.check_circle;
      case InspectionStatus.sincronizada:
        return Icons.sync;
      case InspectionStatus.porVerificar:
        return Icons.visibility;
      case InspectionStatus.verificada:
        return Icons.verified;
      case InspectionStatus.invalida:
        return Icons.cancel;
      case InspectionStatus.relatorioGerado:
        return Icons.description;
      case InspectionStatus.parecerDdrsDdrf:
        return Icons.gavel;
      case InspectionStatus.assinaturaCa:
        return Icons.verified_user;
      case InspectionStatus.finalizada:
        return Icons.check_circle_outline;
      case InspectionStatus.disponibilizada:
        return Icons.public;
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final startDate = now.subtract(const Duration(days: 6));
    final endDate = now;
    
    return Scaffold(
      backgroundColor: const Color(0xFFE3F0E9), // Background específico
      body: Column(
        children: [
          // Header fixo
          _buildGoAuditsHeader(),
          // Conteúdo com scroll
          Expanded(
              child: RefreshIndicator(
                onRefresh: () => _loadData(sync: true), // Sincronizar ao fazer pull-to-refresh
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 100),
                child: Column(
                  children: [
                    // Seção Recent com filtros
                    _buildRecentSection(startDate, endDate),
                    // Lista de inspeções
                    _buildInspectionsList(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: _currentUser != null && RoleService.canCreateInspection(_currentUser!)
          ? Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF18778A).withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: FloatingActionButton(
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const CreateInspectionScreen()),
                  );
                  _loadData(sync: false);
                },
                backgroundColor: const Color(0xFF18778A),
                foregroundColor: Colors.white,
                child: const Icon(Icons.add),
              ),
            )
          : null,
    );
  }

  Widget _buildGoAuditsHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF18778A), // lightPrimary sempre
            Color(0xFF18778A), // lightPrimary com opacidade
          ],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // App Bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Logo e nome
                  Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.asset(
                            'web/icons/icon-192.png',
                            width: 32,
                            height: 32,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(
                                Icons.check_circle,
                                color: Color(0xFF18778A),
                                size: 20,
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Inspeções',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  // Ícones de ação compactos
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const NotificationsScreen(),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          child: const Icon(Icons.notifications_outlined, color: Colors.white, size: 24),
                        ),
                      ),
                      IconButton(
                        icon: _isLoading 
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Icon(Icons.refresh, color: Colors.white),
                        onPressed: _isLoading ? null : () async {
                          setState(() {
                            _isLoading = true;
                          });
                          
                          try {
                            // Sincronizar dados ao clicar no botão refresh
                            await _loadData(sync: true);
                            if (mounted) {
                              setState(() {
                                _isLoading = false;
                              });
                            }
                          } catch (e) {
                            // Em caso de erro, apenas recarregar dados locais
                            await _loadData(sync: false);
                            if (mounted) {
                              setState(() {
                                _isLoading = false;
                              });
                            }
                          }
                        },
                      ),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _isSearchVisible = !_isSearchVisible;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          child: const Icon(Icons.search, color: Colors.white, size: 24),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => _showFilterMenu(),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          child: const Icon(Icons.tune, color: Colors.white, size: 24),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              // Campo de busca (se visível)
              if (_isSearchVisible) ...[
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: 'Buscar inspeções...',
                      prefixIcon: Icon(Icons.search, color: Colors.grey),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    onChanged: (value) => _filterInspections(),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentSection(DateTime startDate, DateTime endDate) {
    return Container(
      margin: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Inspeções Recentes',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2E2E2E), // Sempre escuro
                ),
              ),
              Text(
                '${_formatDateShort(startDate)} - ${_formatDateShort(endDate)}',
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF666666),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildStatusFilter('Todas', _getAllCount(), null),
                const SizedBox(width: 12),
                _buildStatusFilter('Rascunho', _getStatusCount(InspectionStatus.rascunho), InspectionStatus.rascunho),
                const SizedBox(width: 12),
                _buildStatusFilter('Em Andamento', _getStatusCount(InspectionStatus.emAndamento), InspectionStatus.emAndamento),
                const SizedBox(width: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusFilter(String title, int count, InspectionStatus? status) {
    final isSelected = _statusFilter == status;
    
    return GestureDetector(
      onTap: () => _setStatusFilter(status),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF18778A) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF18778A) : Colors.grey[300]!,
          ),
        ),
        child: Text(
          '$title ($count)',
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF666666),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildInspectionsList() {
    if (_filteredInspections.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      children: _filteredInspections.map((inspection) => 
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: _buildAuditCard(inspection),
        ),
      ).toList(),
    );
  }

  Widget _buildAuditCard(Inspection inspection) {
    final est = _establishmentsCache[inspection.establishmentId];
    final endereco = (est != null && est.endereco.trim().isNotEmpty)
        ? est.endereco.trim()
        : inspection.endereco.trim();

    return InkWell(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => InspectionDetailScreen(inspection: inspection),
          ),
        );
        _loadData(sync: false); // Recarregar dados locais após editar inspeção
      },
      child: Card(
        margin: EdgeInsets.zero,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Título
              Text(
                inspection.titulo,
                style: const TextStyle(
                  color: Color(0xFF2E2E2E),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Icon(
                      Icons.location_on_outlined,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      endereco.isNotEmpty ? endereco : 'Endereço não informado',
                      style: TextStyle(
                        color: endereco.isNotEmpty
                            ? Colors.grey[700]
                            : Colors.grey[500],
                        fontSize: 13,
                        height: 1.25,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // Data e Status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Data com ícone
                  Row(
                    children: [
                      Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        _formatDate(inspection.dataAgendada),
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  
                  // Status badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getStatusColor(inspection.status),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getStatusIcon(inspection.status),
                          size: 14,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          inspection.statusText,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }


  void _showFilterMenu() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const Text(
                      'Filtrar por',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2E2E2E),
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // Faixa de Pontuação
                    _buildFilterSection(
                      'Faixa de Pontuação',
                      _buildScoreRangeSlider(setModalState),
                    ),
                    const SizedBox(height: 24),
                    
                    // Período
                    _buildFilterSection(
                      'Período',
                      Column(
                        children: [
                          // Botões de data rápida
                          Row(
                            children: [
                              _buildQuickDateButton('Hoje', 'today', () {
                                _setQuickDate('today');
                                setModalState(() {}); // Atualizar o modal
                              }),
                              const SizedBox(width: 8),
                              _buildQuickDateButton('Ontem', 'yesterday', () {
                                _setQuickDate('yesterday');
                                setModalState(() {}); // Atualizar o modal
                              }),
                              const SizedBox(width: 8),
                              _buildQuickDateButton('Esta Semana', 'week', () {
                                _setQuickDate('week');
                                setModalState(() {}); // Atualizar o modal
                              }),
                              const SizedBox(width: 8),
                              _buildQuickDateButton('Este Mês', 'month', () {
                                _setQuickDate('month');
                                setModalState(() {}); // Atualizar o modal
                              }),
                            ],
                          ),
                        const SizedBox(height: 12),
                        // Date input
                        GestureDetector(
                          onTap: () async {
                            await _selectDateRange();
                            setModalState(() {}); // Atualizar o modal após selecionar data
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey[300]!),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Text(
                                  _startDate != null && _endDate != null
                                      ? '${_formatDateShort(_startDate!)} - ${_formatDateShort(_endDate!)}'
                                      : 'Selecionar período',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: _startDate != null && _endDate != null 
                                        ? const Color(0xFF2E2E2E) 
                                        : Colors.grey,
                                  ),
                                ),
                                const Spacer(),
                                Icon(Icons.calendar_today, color: Colors.grey[600], size: 20),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Estabelecimento
                  _buildFilterSection(
                    'Estabelecimento',
                    GestureDetector(
                      onTap: () => _showCompanyPicker(setModalState),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Text(
                              _selectedCompany ?? 'Selecionar Estabelecimento',
                              style: TextStyle(
                                fontSize: 14, 
                                color: _selectedCompany != null ? const Color(0xFF2E2E2E) : Colors.grey,
                              ),
                            ),
                            const Spacer(),
                            Icon(Icons.keyboard_arrow_down, color: Colors.grey[600], size: 20),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Localização
                  _buildFilterSection(
                    'Localização',
                    GestureDetector(
                      onTap: () => _showLocationPicker(setModalState),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Text(
                              _selectedLocation ?? 'Selecionar Localização',
                              style: TextStyle(
                                fontSize: 14, 
                                color: _selectedLocation != null ? const Color(0xFF2E2E2E) : Colors.grey,
                              ),
                            ),
                            const Spacer(),
                            Icon(Icons.keyboard_arrow_down, color: Colors.grey[600], size: 20),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const Spacer(),
            
            // Action buttons
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        _resetAllFilters();
                        Navigator.pop(context);
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF18778A)),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Limpar Filtros',
                        style: TextStyle(
                          color: Color(0xFF18778A),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        _filterInspections();
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFC4E1E8),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Aplicar',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
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

  Widget _buildFilterSection(String title, Widget content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2E2E2E),
          ),
        ),
        const SizedBox(height: 8),
        content,
      ],
    );
  }

  Widget _buildScoreRangeSlider([StateSetter? modalStateSetter]) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${_minScore.clamp(0.0, 100.0).round()}',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF18778A)),
            ),
            Text(
              '${_maxScore.clamp(0.0, 100.0).round()}',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF18778A)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        RangeSlider(
          values: RangeValues(
            _minScore.clamp(0.0, 100.0),
            _maxScore.clamp(0.0, 100.0),
          ),
          min: 0.0,
          max: 100.0,
          divisions: 20,
          activeColor: const Color(0xFF18778A),
          inactiveColor: Colors.grey[200],
          onChanged: (RangeValues values) {
            setState(() {
              _minScore = values.start.clamp(0.0, 100.0);
              _maxScore = values.end.clamp(0.0, 100.0);
              // Aplicar filtro dentro do setState
              _applyFilters();
            });
            // Atualizar o modal se estiver aberto
            if (modalStateSetter != null) {
              modalStateSetter(() {});
            }
          },
        ),
      ],
    );
  }

  Widget _buildQuickDateButton(String text, String type, VoidCallback onTap) {
    final isSelected = _selectedQuickDate == type;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF18778A) : Colors.white,
          border: Border.all(
            color: isSelected ? const Color(0xFF18778A) : Colors.grey[300]!,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 12,
            color: isSelected ? Colors.white : const Color(0xFF2E2E2E),
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  int _getAllCount() {
    return _inspections.length;
  }

  int _getStatusCount(InspectionStatus status) {
    return _inspections.where((i) => i.status == status).length;
  }

  String _formatDateShort(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${date.day} ${months[date.month - 1]} \'${date.year.toString().substring(2)}';
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  void _setQuickDate(String type) {
    final now = DateTime.now();
    setState(() {
      _selectedQuickDate = type; // Marcar o botão selecionado
      switch (type) {
        case 'today':
          _startDate = DateTime(now.year, now.month, now.day);
          _endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
          break;
        case 'yesterday':
          final yesterday = now.subtract(const Duration(days: 1));
          _startDate = DateTime(yesterday.year, yesterday.month, yesterday.day);
          _endDate = DateTime(yesterday.year, yesterday.month, yesterday.day, 23, 59, 59);
          break;
        case 'week':
          _startDate = now.subtract(const Duration(days: 7));
          _endDate = now;
          break;
        case 'month':
          _startDate = now.subtract(const Duration(days: 30));
          _endDate = now;
          break;
      }
      _applyFilters();
    });
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
    );
    if (picked != null) {
      setState(() {
        _selectedQuickDate = null; // Limpar seleção de botão rápido quando usar seletor de data
        _startDate = picked.start;
        _endDate = picked.end;
        _applyFilters();
      });
    }
  }

  void _showCompanyPicker([StateSetter? parentModalState]) {
    final companies = _establishmentsCache.values.map((e) => e.nome).toSet().toList()..sort();
    final searchController = TextEditingController();
    final filteredCompanies = ValueNotifier<List<String>>(companies);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.7,
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const Text(
                  'Selecionar Estabelecimento',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                // Campo de busca
                TextField(
                  controller: searchController,
                  decoration: InputDecoration(
                    hintText: 'Buscar estabelecimento...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  onChanged: (value) {
                    setModalState(() {
                      if (value.isEmpty) {
                        filteredCompanies.value = companies;
                      } else {
                        filteredCompanies.value = companies
                            .where((c) => c.toLowerCase().contains(value.toLowerCase()))
                            .toList();
                      }
                    });
                  },
                ),
                const SizedBox(height: 16),
                // Lista scrollável
                Expanded(
                  child: ValueListenableBuilder<List<String>>(
                    valueListenable: filteredCompanies,
                    builder: (context, filteredList, _) {
                      if (filteredList.isEmpty) {
                        return const Center(
                          child: Text('Nenhum estabelecimento encontrado'),
                        );
                      }
                      return ListView.builder(
                        itemCount: filteredList.length,
                        itemBuilder: (context, index) {
                          final company = filteredList[index];
                          final isSelected = _selectedCompany == company;
                          return ListTile(
                            title: Text(company),
                            selected: isSelected,
                            selectedTileColor: const Color(0xFF18778A).withOpacity(0.1),
                            trailing: isSelected
                                ? const Icon(Icons.check, color: Color(0xFF18778A))
                                : null,
                            onTap: () {
                              setState(() {
                                _selectedCompany = company;
                                _applyFilters();
                              });
                              // Atualizar o modal pai se existir
                              if (parentModalState != null) {
                                parentModalState(() {});
                              }
                              Navigator.pop(context);
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                // Botão limpar seleção
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      setState(() {
                        _selectedCompany = null;
                        _applyFilters();
                      });
                      // Atualizar o modal pai se existir
                      if (parentModalState != null) {
                        parentModalState(() {});
                      }
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.clear),
                    label: const Text('Limpar Seleção'),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF18778A)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showLocationPicker([StateSetter? parentModalState]) {
    final locations = _inspections.map((i) => i.endereco).toSet().toList()..sort();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text(
              'Selecionar Localização',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            // Lista scrollável
            Expanded(
              child: locations.isEmpty
                  ? const Center(child: Text('Nenhuma localização disponível'))
                  : ListView.builder(
                      itemCount: locations.length,
                      itemBuilder: (context, index) {
                        final location = locations[index];
                        final isSelected = _selectedLocation == location;
                        return ListTile(
                          title: Text(location),
                          selected: isSelected,
                          selectedTileColor: const Color(0xFF18778A).withOpacity(0.1),
                          trailing: isSelected
                              ? const Icon(Icons.check, color: Color(0xFF18778A))
                              : null,
                          onTap: () {
                            setState(() {
                              _selectedLocation = location;
                              _applyFilters();
                            });
                            // Atualizar o modal pai se existir
                            if (parentModalState != null) {
                              parentModalState(() {});
                            }
                            Navigator.pop(context);
                          },
                        );
                      },
                    ),
            ),
            const SizedBox(height: 16),
            // Botão limpar seleção
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    _selectedLocation = null;
                    _applyFilters();
                  });
                  // Atualizar o modal pai se existir
                  if (parentModalState != null) {
                    parentModalState(() {});
                  }
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.clear),
                label: const Text('Limpar Seleção'),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF18778A)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _resetAllFilters() {
    setState(() {
      _statusFilter = null;
      _minScore = 0.0;
      _maxScore = 100.0;
      _startDate = null;
      _endDate = null;
      _selectedCompany = null;
      _selectedLocation = null;
      _selectedQuickDate = null; // Limpar seleção de botão rápido
      _applyFilters();
    });
  }

  Widget _buildEmptyState() {
    return Card(
      margin: const EdgeInsets.all(20),
      child: Container(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.assignment_outlined,
                size: 48,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Nenhuma inspeção encontrada',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              _searchController.text.isNotEmpty || _statusFilter != null
                  ? 'Tente ajustar os filtros de busca'
                  : _currentUser != null && RoleService.canCreateInspection(_currentUser!)
                      ? 'Crie sua primeira inspeção para começar'
                      : 'Você não tem inspeções atribuídas à sua equipe',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
              textAlign: TextAlign.center,
            ),
            if (_searchController.text.isEmpty && _statusFilter == null && _currentUser != null && RoleService.canCreateInspection(_currentUser!)) ...[
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const CreateInspectionScreen()),
                  );
                  _loadData(sync: false);
                },
                icon: const Icon(Icons.add),
                label: const Text('Create Inspection'),
              ),
            ],
          ],
        ),
      ),
    );
  }


}