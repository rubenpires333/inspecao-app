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

class InspectionsScreen extends StatefulWidget {
  const InspectionsScreen({super.key});

  @override
  State<InspectionsScreen> createState() => _InspectionsScreenState();
}

class _InspectionsScreenState extends State<InspectionsScreen> {
  final _dataService = DataService();
  List<Inspection> _inspections = [];
  List<Inspection> _filteredInspections = [];
  InspectionStatus? _statusFilter;
  final _searchController = TextEditingController();
  User? _currentUser;
  Map<String, Establishment> _establishmentsCache = {};
  bool _isSearchVisible = false;
  bool _isLoading = false;
  
  // Filtros adicionais
  double _minScore = -100.0;
  double _maxScore = 100.0;
  DateTime? _startDate;
  DateTime? _endDate;
  String? _selectedCompany;
  String? _selectedLocation;
  String? _selectedChecklist;

  @override
  void initState() {
    super.initState();
    _loadData();
    _searchController.addListener(_filterInspections);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      setState(() => _isLoading = true);
      
      final user = await _dataService.getCurrentUser();
      List<Inspection> inspections = [];
      Map<String, Establishment> establishmentsMap = {};
      
      if (user != null) {
        // Carregar inspeções da API
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
          // Navegar para login usando Navigator.pop até chegar na tela de login
          Navigator.of(context).popUntil((route) => route.isFirst);
          // Mostrar mensagem ao usuário
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Sessão expirada. Faça login novamente.'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
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
      
      // Filtro de checklist (baseado no tipo de inspeção)
      final matchesChecklist = _selectedChecklist == null ||
          inspection.tipoText.toLowerCase().contains(_selectedChecklist!.toLowerCase());
      
      return matchesSearch && matchesStatus && matchesScore && matchesDate && 
             matchesCompany && matchesLocation && matchesChecklist;
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
              onRefresh: _loadData,
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
                    color: const Color(0xFF1976D2).withOpacity(0.3),
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
                  _loadData();
                },
                backgroundColor: const Color(0xFF1976D2),
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
            Color(0xFF1976D2), // lightPrimary sempre
            Color(0xFF1565C0), // lightPrimary com opacidade
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
                                color: Color(0xFF1976D2),
                                size: 20,
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Audits',
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
                      GestureDetector(
                        onTap: () async {
                          // Mostrar indicador de loading
                          setState(() {
                            _isLoading = true;
                          });
                          
                          try {
                            // Aguardar um pouco para mostrar o loading
                            await Future.delayed(const Duration(milliseconds: 500));
                            
                            // Recarregar a tela completamente
                            if (mounted) {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const InspectionsScreen(),
                                ),
                              );
                            }
                          } catch (e) {
                            // Em caso de erro, apenas recarregar dados
                            await _loadData();
                            if (mounted) {
                              setState(() {
                                _isLoading = false;
                              });
                            }
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          child: _isLoading 
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Icon(Icons.refresh, color: Colors.white, size: 24),
                        ),
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
                      GestureDetector(
                        onTap: () {},
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          child: const Icon(Icons.description_outlined, color: Colors.white, size: 24),
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
                      hintText: 'Search audits...',
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
                'Recent Audits',
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
                _buildStatusFilter('All', _getAllCount(), null),
                const SizedBox(width: 12),
                _buildStatusFilter('In Progress', _getInProgressCount(), InspectionStatus.emAndamento),
                const SizedBox(width: 12),
                _buildStatusFilter('Submitted', _getSubmittedCount(), InspectionStatus.concluida),
                const SizedBox(width: 12),
                _buildStatusFilter('Completed', _getCompletedCount(), InspectionStatus.concluida),
                const SizedBox(width: 12),
                _buildStatusFilter('Inválidas', _getRejectedCount(), InspectionStatus.invalida),
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
          color: isSelected ? const Color(0xFF1976D2) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF1976D2) : Colors.grey[300]!,
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
    // Calcular score baseado nos itens da inspeção
    final totalItems = inspection.itens.length;
    final conformItems = inspection.itens.where((item) => item.status == ItemStatus.conforme).length;
    final score = totalItems > 0 ? (conformItems / totalItems * 100).round() : 0;
    
    return InkWell(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => InspectionDetailScreen(inspection: inspection),
          ),
        );
        _loadData();
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1976D2), // lightPrimary sempre
              Color(0xFF1565C0), // lightPrimary com opacidade
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1976D2).withOpacity(0.3), // lightPrimary sempre
              spreadRadius: 2,
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Título
            Text(
              inspection.titulo,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            
            // Localização
            Text(
              inspection.endereco.isNotEmpty ? inspection.endereco : 'Endereço não informado',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            
            // Autor e Data
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _currentUser?.nome ?? 'Inspetor',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
                Text(
                  _formatDate(inspection.dataAgendada),
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
              // Status e Percentage
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Status
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getStatusColor(inspection.status),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white,
                        width: 1,
                      ),
                    ),
                    child: Text(
                      inspection.statusText,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  
                  // Percentage em círculo
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '$score%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }


  void _showFilterMenu() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
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
                    'Filter by',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2E2E2E),
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Score Range
                  _buildFilterSection(
                    'Score Range',
                    _buildScoreRangeSlider(),
                  ),
                  const SizedBox(height: 24),
                  
                  // Date Range
                  _buildFilterSection(
                    'Date Range',
                    Column(
                      children: [
                        // Quick date buttons
                        Row(
                          children: [
                            _buildQuickDateButton('Today', () => _setQuickDate('today')),
                            const SizedBox(width: 8),
                            _buildQuickDateButton('Yesterday', () => _setQuickDate('yesterday')),
                            const SizedBox(width: 8),
                            _buildQuickDateButton('This Week', () => _setQuickDate('week')),
                            const SizedBox(width: 8),
                            _buildQuickDateButton('This month', () => _setQuickDate('month')),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Date input
                        GestureDetector(
                          onTap: () => _selectDateRange(),
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
                                      : 'Select date range',
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
                  
                  // Company
                  _buildFilterSection(
                    'Company',
                    GestureDetector(
                      onTap: () => _showCompanyPicker(),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Text(
                              _selectedCompany ?? 'Select Company',
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
                  
                  // Location
                  _buildFilterSection(
                    'Location',
                    GestureDetector(
                      onTap: () => _showLocationPicker(),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Text(
                              _selectedLocation ?? 'Select Location',
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
                  const SizedBox(height: 24),
                  
                  // Checklist
                  _buildFilterSection(
                    'Checklist',
                    GestureDetector(
                      onTap: () => _showChecklistPicker(),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Text(
                              _selectedChecklist ?? 'Select Checklist',
                              style: TextStyle(
                                fontSize: 14, 
                                color: _selectedChecklist != null ? const Color(0xFF2E2E2E) : Colors.grey,
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
                        side: const BorderSide(color: Color(0xFF1976D2)),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Reset filter',
                        style: TextStyle(
                          color: Color(0xFF1976D2),
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
                        backgroundColor: const Color(0xFF1976D2),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Apply',
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

  Widget _buildScoreRangeSlider() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('${_minScore.round()}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
            Text('${_maxScore.round()}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        const SizedBox(height: 8),
        RangeSlider(
          values: RangeValues(_minScore, _maxScore),
          min: -100.0,
          max: 100.0,
          divisions: 20,
          activeColor: const Color(0xFF1976D2),
          inactiveColor: Colors.grey[200],
          onChanged: (RangeValues values) {
            setState(() {
              _minScore = values.start;
              _maxScore = values.end;
              // Aplicar filtro dentro do setState
              _applyFilters();
            });
          },
        ),
      ],
    );
  }

  Widget _buildQuickDateButton(String text, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF2E2E2E),
          ),
        ),
      ),
    );
  }

  int _getAllCount() {
    return _inspections.length;
  }

  int _getInProgressCount() {
    return _inspections.where((i) => i.status == InspectionStatus.emAndamento).length;
  }

  int _getSubmittedCount() {
    return _inspections.where((i) => 
        i.status == InspectionStatus.concluida && 
        i.observacoes != null && 
        i.observacoes!.isNotEmpty
    ).length;
  }

  int _getCompletedCount() {
    return _inspections.where((i) => i.status == InspectionStatus.concluida).length;
  }

  int _getRejectedCount() {
    return _inspections.where((i) => i.status == InspectionStatus.invalida).length;
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
        _startDate = picked.start;
        _endDate = picked.end;
        _applyFilters();
      });
    }
  }

  void _showCompanyPicker() {
    final companies = _establishmentsCache.values.map((e) => e.nome).toSet().toList();
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Select Company', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ...companies.map((company) => ListTile(
              title: Text(company),
              onTap: () {
                setState(() {
                  _selectedCompany = company;
                  _applyFilters();
                });
                Navigator.pop(context);
              },
            )),
            ListTile(
              title: const Text('Clear Selection'),
              onTap: () {
                setState(() {
                  _selectedCompany = null;
                  _applyFilters();
                });
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showLocationPicker() {
    final locations = _inspections.map((i) => i.endereco).toSet().toList();
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Select Location', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ...locations.map((location) => ListTile(
              title: Text(location),
              onTap: () {
                setState(() {
                  _selectedLocation = location;
                  _applyFilters();
                });
                Navigator.pop(context);
              },
            )),
            ListTile(
              title: const Text('Clear Selection'),
              onTap: () {
                setState(() {
                  _selectedLocation = null;
                  _applyFilters();
                });
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showChecklistPicker() {
    final checklists = _inspections.map((i) => i.tipoText).toSet().toList();
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Select Checklist', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ...checklists.map((checklist) => ListTile(
              title: Text(checklist),
              onTap: () {
                setState(() {
                  _selectedChecklist = checklist;
                  _applyFilters();
                });
                Navigator.pop(context);
              },
            )),
            ListTile(
              title: const Text('Clear Selection'),
              onTap: () {
                setState(() {
                  _selectedChecklist = null;
                  _applyFilters();
                });
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _resetAllFilters() {
    setState(() {
      _statusFilter = null;
      _minScore = -100.0;
      _maxScore = 100.0;
      _startDate = null;
      _endDate = null;
      _selectedCompany = null;
      _selectedLocation = null;
      _selectedChecklist = null;
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
              'No audits found',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              _searchController.text.isNotEmpty || _statusFilter != null
                  ? 'Try adjusting the search filters'
                  : _currentUser != null && RoleService.canCreateInspection(_currentUser!)
                      ? 'Create your first inspection to start'
                      : 'You do not have any inspections assigned to your team',
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
                  _loadData();
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