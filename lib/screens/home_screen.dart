import 'package:flutter/material.dart';
import 'package:inspecao/models/inspection.dart';
import 'package:inspecao/models/user.dart';
import 'package:inspecao/models/inspection_item.dart';
import 'package:inspecao/services/data_service.dart';
import 'package:inspecao/services/role_service.dart';
import 'package:inspecao/exceptions/forced_logout_exception.dart';
import 'package:inspecao/screens/login_screen.dart';
import 'package:inspecao/screens/inspection_detail_screen.dart';
import 'package:inspecao/screens/calendar_screen.dart';
import 'package:inspecao/screens/map_screen.dart';
import 'package:inspecao/screens/profile_screen.dart';
import 'package:inspecao/screens/notifications_screen.dart';
import 'package:inspecao/screens/create_inspection_screen.dart';
import 'package:inspecao/screens/database_viewer_screen.dart';
import 'package:inspecao/screens/inspections_screen.dart';
import 'package:inspecao/models/notification.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeScreen extends StatefulWidget {
  final Function(ThemeMode) changeThemeMode;
  
  const HomeScreen({super.key, required this.changeThemeMode});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _dataService = DataService();
  User? _currentUser;
  int _selectedIndex = 0;
  List<Inspection> _inspections = [];
  List<AppNotification> _notifications = [];
  bool _isLoading = false;
  
  // Filtros para Inspeções Recentes
  InspectionStatus? _statusFilter;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filterRecentInspections);
    _loadData().then((_) {
      // Sempre começar na tela de início (dashboard) - índice 0
      setState(() {
        _selectedIndex = 0; // Primeira tela será o dashboard/início
      });
    });
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
  
  void _filterRecentInspections() {
    setState(() {
      // O filtro será aplicado automaticamente quando o estado mudar
    });
  }
  
  void _setStatusFilter(InspectionStatus? status) {
    setState(() {
      _statusFilter = status;
    });
  }
  
  List<Inspection> _applyFiltersToRecentInspections(List<Inspection> inspections) {
    final searchTerm = _searchController.text.toLowerCase();
    
    return inspections.where((inspection) {
      // Filtro de busca
      final matchesSearch = searchTerm.isEmpty ||
          inspection.titulo.toLowerCase().contains(searchTerm) ||
          inspection.endereco.toLowerCase().contains(searchTerm);
      
      // Filtro de status
      final matchesStatus = _statusFilter == null || inspection.status == _statusFilter;
      
      return matchesSearch && matchesStatus;
    }).toList();
  }
  
  Widget _buildStatusFilter(String title, int count, InspectionStatus? status) {
    final isSelected = _statusFilter == status;
    
    return GestureDetector(
      onTap: () => _setStatusFilter(status),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF027A8A) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF027A8A) : Colors.grey[300]!,
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
  
  int _getAllCount(List<Inspection> inspections) {
    return inspections.length;
  }
  
  int _getStatusCount(List<Inspection> inspections, InspectionStatus status) {
    return inspections.where((i) => i.status == status).length;
  }


  Future<void> _loadData() async {
    try {
      setState(() => _isLoading = true);
      
      final user = await _dataService.getCurrentUser();
      List<Inspection> inspections = [];
      List<AppNotification> notifications = [];
      
      if (user != null) {
        // Se for a primeira carga após login, garantir sincronização inicial
        // (já deve ter sido feita no login, mas garantir aqui também)
        final prefs = await SharedPreferences.getInstance();
        final lastSync = prefs.getInt('last_initial_sync') ?? 0;
        final now = DateTime.now().millisecondsSinceEpoch;
        final oneHour = 60 * 60 * 1000; // 1 hora em milissegundos
        
        // Se passou mais de 1 hora desde a última sincronização inicial, sincronizar novamente
        if (now - lastSync > oneHour) {
          print('🔄 Fazendo sincronização periódica de dados...');
          _dataService.syncInitialData().then((_) {
            prefs.setInt('last_initial_sync', now);
          }).catchError((e) {
            print('⚠️ Erro na sincronização periódica: $e');
          });
        }
        
        // Carregar inspeções (já sincroniza automaticamente)
        inspections = await _dataService.getInspectionsForUser(user);
        
        // Carregar notificações da API
        try {
          notifications = await _dataService.getNotifications();
        } catch (e) {
          // Se não houver notificações, continuar com lista vazia
          notifications = [];
        }
      }
      
      if (mounted) {
        setState(() {
          _currentUser = user;
          _inspections = inspections;
          _notifications = notifications;
          _isLoading = false;
        });
      }
    } on ForcedLogoutException catch (e) {
      // Forçar logout e redirecionar para tela de login
      if (mounted) {
        await _dataService.logout();
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => LoginScreen(changeThemeMode: widget.changeThemeMode)),
        );
        // Mostrar mensagem ao usuário
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      // Tratar erro de forma adequada
      if (mounted) {
        setState(() {
          _inspections = [];
          _notifications = [];
        });
      }
      // Log do erro para debug
      print('Erro ao carregar dados: $e');
    }
  }

  Future<void> _logout() async {
    await _dataService.logout();
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => LoginScreen(changeThemeMode: widget.changeThemeMode)),
      );
    }
  }

  Widget _getSelectedScreen() {
    if (_currentUser == null) {
      // Enquanto os dados do utilizador ainda não foram carregados,
      // mostramos um pequeno indicador de carregamento em vez de
      // forçar a navegação direta para a tela de inspeções.
      return const Center(
        child: CircularProgressIndicator(),
      );
    }
    final menuItems = _getMenuItemsForUser(_currentUser!);
    
    // Garantir que o índice selecionado existe no menu do usuário
    if (_selectedIndex >= menuItems.length) {
      _selectedIndex = 0;
    }
    
    final selectedMenuItem = menuItems[_selectedIndex];
    
    switch (selectedMenuItem['screen']) {
      case 'dashboard':
        return _buildDashboard();
      case 'inspections':
        return const InspectionsScreen(); // Usar tela dedicada de inspeções
      case 'calendar':
        return const CalendarScreen();
      case 'map':
        return const MapScreen();
      case 'database':
        return const DatabaseViewerScreen(); // Tela temporária de debug
      default:
        return const InspectionsScreen(); // Default para inspetores
    }
  }
  /// Retorna os itens de menu disponíveis baseado no usuário (permissões da API ou role)
  List<Map<String, dynamic>> _getMenuItemsForUser(User user) {
    final items = <Map<String, dynamic>>[];
    
    // Para inspetores: Início (Dashboard), Inspeção, Calendário, Mapa
    if (user.role == UserRole.inspetor) {
      items.add({
        'screen': 'dashboard',
        'icon': Icons.dashboard_outlined,
        'label': 'Início',
      });
      items.add({
        'screen': 'inspections',
        'icon': Icons.assignment_outlined,
        'label': 'Inspeções',
      });
      items.add({
        'screen': 'calendar',
        'icon': Icons.calendar_today_outlined,
        'label': 'Calendário',
      });
      items.add({
        'screen': 'map',
        'icon': Icons.map_outlined,
        'label': 'Mapa',
      });
      // Tela temporária de debug - será removida
      items.add({
        'screen': 'database',
        'icon': Icons.storage_outlined,
        'label': 'DB Local',
      });
      return items;
    }
    
    // Para outros roles: Dashboard primeiro
    items.add({
      'screen': 'dashboard',
      'icon': Icons.dashboard_outlined,
      'label': 'Início',
    });
    
    // Inspeções - Foco principal (execução de inspeções)
    if (RoleService.canExecuteInspections(user) || RoleService.canViewAllInspections(user)) {
      items.add({
        'screen': 'inspections',
        'icon': Icons.assignment_outlined,
        'label': 'Inspeções',
      });
    }
    
    // Calendário - Todos podem ver
    items.add({
      'screen': 'calendar',
      'icon': Icons.calendar_today_outlined,
      'label': 'Calendário',
    });
    
    // Mapa - Todos podem ver
    items.add({
      'screen': 'map',
      'icon': Icons.map_outlined,
      'label': 'Mapa',
    });
    
    // Tela temporária de debug - será removida
    items.add({
      'screen': 'database',
      'icon': Icons.storage_outlined,
      'label': 'DB Local',
    });
    
    return items;
  }

  Widget _buildDashboard() {
    // Filtrar inspeções do inspetor se necessário e excluir Finalizadas e Concluídas
    final filteredInspections = (_currentUser?.role == UserRole.inspetor
        ? _inspections.where((i) => i.inspectorId == _currentUser!.id).toList()
        : _inspections)
        .where((i) => 
            i.status != InspectionStatus.finalizada && 
            i.status != InspectionStatus.concluida
        ).toList();
    
    // Calcular contadores usando os novos status do backend

    return Scaffold(
      backgroundColor: const Color(0xFFE3F0E9), // Background específico sempre
      body: Column(
        children: [
          // Header fixo
          _buildGoAuditsHeader(),
          // Conteúdo com scroll
          Expanded(
            child: _isLoading
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF18778A)),
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Carregando inspeções...',
                          style: TextStyle(
                            color: Color(0xFF666666),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadData,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.only(bottom: 100),
                      child: Column(
                        children: [
                          // Seção Inspeções Recentes
                          _buildRecentAuditsSection(filteredInspections),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
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
                                color: Color(0xFF18778A), // lightPrimary sempre
                                size: 20,
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'INSPEV',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  // Ícones de ação
                  Row(
                    children: [
                      Stack(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.notifications_outlined, color: Colors.white),
                            onPressed: () => _showNotificationCenter(),
                          ),
                          if (_notifications.where((n) => !n.isRead).isNotEmpty)
                            Positioned(
                              top: 8,
                              right: 8,
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                constraints: const BoxConstraints(
                                  minWidth: 16,
                                  minHeight: 16,
                                ),
                                child: Text(
                                  '${_notifications.where((n) => !n.isRead).length}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                        ],
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
                            // Aguardar um pouco para mostrar o loading
                            await Future.delayed(const Duration(milliseconds: 500));
                            
                            // Recarregar a tela completamente
                            if (mounted) {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => HomeScreen(changeThemeMode: widget.changeThemeMode),
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
                      ),
                      PopupMenuButton(
                        icon: const Icon(Icons.more_vert, color: Colors.white),
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            child: ListTile(
                              leading: Icon(Icons.person, color: Theme.of(context).colorScheme.primary),
                              title: const Text('Meu Perfil'),
                              onTap: () {
                                Navigator.pop(context);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const ProfileScreen()),
                                );
                              },
                            ),
                          ),
                         /* PopupMenuItem(
                            child: ListTile(
                              leading: Icon(
                                Theme.of(context).brightness == Brightness.dark 
                                    ? Icons.light_mode 
                                    : Icons.dark_mode,
                                color: Theme.of(context).colorScheme.secondary,
                              ),
                              title: Text(
                                Theme.of(context).brightness == Brightness.dark 
                                    ? 'Modo Claro' 
                                    : 'Modo Escuro',
                              ),
                              onTap: () {
                                Navigator.pop(context);
                                widget.changeThemeMode(
                                  Theme.of(context).brightness == Brightness.dark 
                                      ? ThemeMode.light 
                                      : ThemeMode.dark,
                                );
                              },
                            ),
                          ),*/
                          PopupMenuItem(
                            child: ListTile(
                              leading: Icon(Icons.logout, color: Theme.of(context).colorScheme.error),
                              title: const Text('Sair'),
                              onTap: () {
                                Navigator.pop(context);
                                _logout();
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 0),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentAuditsSection(List<Inspection> inspections) {
    // Aplicar filtros
    final filteredInspections = _applyFiltersToRecentInspections(inspections);
    
    // Ordenar por data mais recente
    final sortedInspections = List<Inspection>.from(filteredInspections);
    sortedInspections.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    
    return Container(
      margin: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /*Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Inspeções Recentes',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).brightness == Brightness.dark 
                      ? Colors.white 
                      : const Color(0xFF2E2E2E),
                ),
              ),
              if (_currentUser != null)
              TextButton(
                  onPressed: () {
                    // Navegar para tela de inspeções
                    final menuItems = _getMenuItemsForUser(_currentUser!);
                    final inspectionsIndex = menuItems.indexWhere((item) => item['screen'] == 'inspections');
                    if (inspectionsIndex >= 0) {
                      setState(() => _selectedIndex = inspectionsIndex);
                    }
                  },
                  child: const Text(
                    'Ver Todas',
                    style: TextStyle(
                    color: Color(0xFF18778A), // lightPrimary sempre
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),*/
          const SizedBox(height: 4),
          
          // Campo de busca
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: _searchController,
            builder: (context, value, child) {
              return TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Buscar inspeções recentes...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: value.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF18778A), width: 2),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          
          // Filtro de status
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildStatusFilter('Todas', _getAllCount(inspections), null),
                const SizedBox(width: 12),
                _buildStatusFilter('Rascunho', _getStatusCount(inspections, InspectionStatus.rascunho), InspectionStatus.rascunho),
                const SizedBox(width: 12),
                _buildStatusFilter('Em Andamento', _getStatusCount(inspections, InspectionStatus.emAndamento), InspectionStatus.emAndamento),
                const SizedBox(width: 20),
              ],
            ),
          ),
          const SizedBox(height: 16),
          
          // Lista de inspeções filtradas
          if (sortedInspections.isNotEmpty)
            ...sortedInspections.map((inspection) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _buildRecentAuditCard(inspection),
            )).toList()
          else
            _buildEmptyRecentAudits(),
        ],
      ),
    );
  }

  Widget _buildRecentAuditCard(Inspection inspection) {
    // Calcular score baseado nos itens da inspeção
    final totalItems = inspection.itens.length;
    final conformItems = inspection.itens.where((item) => item.status == ItemStatus.conforme).length;
    final score = totalItems > 0 ? (conformItems / totalItems * 100).round() : 0;
    
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => InspectionDetailScreen(inspection: inspection),
          ),
        );
      },
      child: Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF18778A), // lightPrimary sempre
            Color(0xFF027A8A), // lightPrimary com opacidade
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF18778A).withOpacity(0.3), // lightPrimary sempre
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

  Widget _buildEmptyRecentAudits() {
    return Center(
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 400),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.assignment_outlined,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Nenhuma inspeção recente',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Suas inspeções recentes aparecerão aqui',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun',
      'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
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


  List<BottomNavigationBarItem> _buildBottomNavItems() {
    if (_currentUser == null) {
      // Retornar pelo menos 2 itens para evitar erro do BottomNavigationBar
      return [
        const BottomNavigationBarItem(
          icon: Icon(Icons.assignment_outlined),
          activeIcon: Icon(Icons.assignment),
          label: 'Inspeções',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.calendar_today_outlined),
          activeIcon: Icon(Icons.calendar_today),
          label: 'Calendário',
        ),
      ];
    }
    final menuItems = _getMenuItemsForUser(_currentUser!);
    
    // Garantir pelo menos 2 itens
    if (menuItems.length < 2) {
      // Adicionar itens padrão se necessário
      if (!menuItems.any((item) => item['screen'] == 'inspections')) {
        menuItems.insert(0, {
          'screen': 'inspections',
          'icon': Icons.assignment_outlined,
          'label': 'Inspeções',
        });
      }
      if (!menuItems.any((item) => item['screen'] == 'calendar')) {
        menuItems.add({
          'screen': 'calendar',
          'icon': Icons.calendar_today_outlined,
          'label': 'Calendário',
        });
      }
    }
    
    return menuItems.map((item) {
      return BottomNavigationBarItem(
        icon: Icon(item['icon'] as IconData),
        activeIcon: Icon(item['icon'] as IconData),
        label: item['label'] as String,
      );
    }).toList();
  }

  void _showNotificationCenter() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const NotificationsScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE3F0E9), // Background específico sempre
      body: _getSelectedScreen(),
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
                  _loadData();
                },
                backgroundColor: const Color(0xFF18778A),
                foregroundColor: Colors.white,
                child: const Icon(Icons.add),
              ),
            )
          : null,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.shadow.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          currentIndex: _selectedIndex,
          onTap: (index) => setState(() => _selectedIndex = index),
          selectedItemColor: const Color(0xFF18778A), // lightPrimary sempre
          unselectedItemColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          backgroundColor: Theme.of(context).colorScheme.surface,
          elevation: 0,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
          unselectedLabelStyle: const TextStyle(fontSize: 11),
          items: _buildBottomNavItems(),
        ),
      ),
    );
  }
}
