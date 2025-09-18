import 'package:flutter/material.dart';
import 'package:inspecao/models/inspection.dart';
import 'package:inspecao/models/user.dart';
import 'package:inspecao/models/establishment.dart';
import 'package:inspecao/models/inspection_item.dart';
import 'package:inspecao/services/data_service.dart';
import 'package:inspecao/services/role_service.dart';
import 'package:inspecao/screens/login_screen.dart';
import 'package:inspecao/screens/inspections_screen.dart';
import 'package:inspecao/screens/calendar_screen.dart';
import 'package:inspecao/screens/map_screen.dart';
import 'package:inspecao/screens/reports_screen.dart';
import 'package:inspecao/screens/inspectors_screen.dart';
import 'package:inspecao/screens/profile_screen.dart';
import 'package:inspecao/screens/notifications_screen.dart';
import 'package:inspecao/screens/audit_templates_screen.dart';
import 'package:inspecao/models/notification.dart';

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
  Map<String, Establishment> _establishmentsCache = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }


  Future<void> _loadData() async {
    final user = await _dataService.getCurrentUser();
    List<Inspection> inspections = [];
    List<AppNotification> notifications = [];
    
    if (user != null) {
      inspections = await _dataService.getInspectionsForUser(user);
      notifications = await _dataService.getNotifications();
    }
    
    // Carregar estabelecimentos para cache
    final establishments = await _dataService.getAllEstablishments();
    final establishmentsMap = <String, Establishment>{};
    for (final establishment in establishments) {
      establishmentsMap[establishment.id] = establishment;
    }
    
    if (mounted) {
      setState(() {
        _currentUser = user;
        _inspections = inspections;
        _notifications = notifications;
        _establishmentsCache = establishmentsMap;
      });
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
    final userRole = _currentUser?.role ?? UserRole.inspetor;
    
    switch (_selectedIndex) {
      case 0:
        return _buildDashboard();
      case 1:
        return const InspectionsScreen();
      case 2:
        return const CalendarScreen();
      case 3:
        return const MapScreen();
      case 4:
        if (RoleService.canViewReports(userRole)) {
          return const ReportsScreen();
        }
        return _buildDashboard();
      default:
        return _buildDashboard();
    }
  }

  Widget _buildDashboard() {
    final agendadas = _inspections.where((i) => i.status == InspectionStatus.agendada).length;
    final emAndamento = _inspections.where((i) => i.status == InspectionStatus.emAndamento).length;
    final concluidas = _inspections.where((i) => i.status == InspectionStatus.concluida).length;
    final canceladas = _inspections.where((i) => i.status == InspectionStatus.cancelada).length;

    return Scaffold(
      backgroundColor: const Color(0xFFE3F0E9), // Background específico sempre
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
                    // Seção My Actions
                    _buildMyActionsSection(agendadas, emAndamento, concluidas, canceladas),
                    // Seção My Audits
                    _buildMyAuditsSection(agendadas, emAndamento, concluidas, canceladas),
                    // Seção Recent Audits
                    _buildRecentAuditsSection(),
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
                                color: Color(0xFF1976D2), // lightPrimary sempre
                                size: 20,
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Inspeção Pro',
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
                          if (RoleService.canManageInspectors(_currentUser?.role ?? UserRole.inspetor))
                            PopupMenuItem(
                              child: ListTile(
                                leading: Icon(Icons.people, color: Theme.of(context).colorScheme.primary),
                                title: const Text('Inspetores'),
                                onTap: () {
                                  Navigator.pop(context);
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => const InspectorsScreen()),
                                  );
                                },
                              ),
                            ),
                          PopupMenuItem(
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
                          ),
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
              const SizedBox(height: 16),
              // New Inspection Button
              if (RoleService.canCreateInspection(_currentUser?.role ?? UserRole.inspetor))
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AuditTemplatesScreen(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF1976D2), // lightPrimary sempre
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    child: const Text(
                      'Start Audit',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMyActionsSection(int agendadas, int emAndamento, int concluidas, int canceladas) {
    return Container(
      margin: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'My Actions',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).brightness == Brightness.dark 
                      ? Colors.white 
                      : const Color(0xFF2E2E2E),
                ),
              ),
              TextButton(
                onPressed: () => setState(() => _selectedIndex = 1),
                child: Text(
                  'View All',
                  style: const TextStyle(
                    color: Color(0xFF1976D2), // lightPrimary sempre
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildActionStatusCard(
                  'Open',
                  agendadas.toString(),
                  const Color(0xFFE3F2FD),
                  const Color(0xFF1976D2),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionStatusCard(
                  'In Progress',
                  emAndamento.toString(),
                  const Color(0xFFFFF3E0),
                  const Color(0xFFFF9800),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionStatusCard(
                  'Overdue',
                  '0', // Implementar lógica de overdue
                  const Color(0xFFFFEBEE),
                  const Color(0xFFE53935),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionStatusCard(
                  'Rejected',
                  canceladas.toString(),
                  const Color(0xFFFFEBEE),
                  const Color(0xFFE53935),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionStatusCard(String title, String count, Color backgroundColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            count,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: textColor,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMyAuditsSection(int agendadas, int emAndamento, int concluidas, int canceladas) {
    // Calcular inspeções submetidas (concluídas mas não rejeitadas)
    final submitted = _inspections.where((i) => 
        i.status == InspectionStatus.concluida && 
        i.observacoes != null && 
        i.observacoes!.isNotEmpty
    ).length;
    
    // Calcular período dinâmico baseado nas inspeções
    final now = DateTime.now();
    final startDate = now.subtract(const Duration(days: 6));
    final endDate = now;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'My Audits',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).brightness == Brightness.dark 
                      ? Colors.white 
                      : const Color(0xFF2E2E2E),
                ),
              ),
              Text(
                '${_formatDateShort(startDate)} - ${_formatDateShort(endDate)}',
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).brightness == Brightness.dark 
                      ? Colors.grey[300] 
                      : Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.6,
            children: [
              _buildAuditStatusCard(
                'In Progress',
                emAndamento.toString(),
                Icons.access_time,
                const Color(0xFFFF9800),
              ),
              _buildAuditStatusCard(
                'Rejected',
                canceladas.toString(),
                Icons.refresh,
                const Color(0xFFE53935),
              ),
              _buildAuditStatusCard(
                'Submitted',
                submitted.toString(),
                Icons.upload,
                const Color(0xFF1976D2),
              ),
              _buildAuditStatusCard(
                'Completed',
                concluidas.toString(),
                Icons.check_circle,
                const Color(0xFF4CAF50),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAuditStatusCard(String title, String count, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: color,
            size: 24,
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Color(0xFF2E2E2E),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            count,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentAuditsSection() {
    return Container(
      margin: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent audits',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).brightness == Brightness.dark 
                      ? Colors.white 
                      : const Color(0xFF2E2E2E),
                ),
              ),
              TextButton(
                onPressed: () => setState(() => _selectedIndex = 1),
                child: Text(
                  'View All',
                  style: const TextStyle(
                    color: Color(0xFF1976D2), // lightPrimary sempre
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_inspections.isNotEmpty)
            _buildRecentAuditCard(_inspections.first)
          else
            _buildEmptyRecentAudits(),
        ],
      ),
    );
  }

  Widget _buildRecentAuditCard(Inspection inspection) {
    final establishment = _establishmentsCache[inspection.establishmentId];
    final establishmentName = establishment?.nome ?? 'Organização não identificada';
    
    // Calcular score baseado nos itens da inspeção
    final totalItems = inspection.itens.length;
    final conformItems = inspection.itens.where((item) => item.status == ItemStatus.conforme).length;
    final score = totalItems > 0 ? (conformItems / totalItems * 100).round() : 0;
    
    return Container(
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
          
          // ID | Organização | Localização
          Text(
            '${inspection.id} | $establishmentName | ${inspection.endereco}',
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
                  color: _getStatusColor(inspection.status).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _getStatusColor(inspection.status),
                    width: 1,
                  ),
                ),
                child: Text(
                  inspection.statusText,
                  style: TextStyle(
                    color: _getStatusColor(inspection.status),
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
          const SizedBox(height: 8),
          
          // Score
          Text(
            'Score: $score.0%',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyRecentAudits() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          Icon(
            Icons.assignment_outlined,
            size: 48,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No recent audits',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first inspection to get started',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _formatDateShort(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${date.day} ${months[date.month - 1]} \'${date.year.toString().substring(2)}';
  }



  Color _getStatusColor(InspectionStatus status) {
    switch (status) {
      case InspectionStatus.agendada:
        return Colors.blue;
      case InspectionStatus.emAndamento:
        return Colors.orange;
      case InspectionStatus.concluida:
        return Colors.green;
      case InspectionStatus.cancelada:
        return Colors.red;
    }
  }


  List<BottomNavigationBarItem> _buildBottomNavItems() {
    final userRole = _currentUser?.role ?? UserRole.inspetor;
    final items = <BottomNavigationBarItem>[
      const BottomNavigationBarItem(
        icon: Icon(Icons.home_outlined),
        activeIcon: Icon(Icons.home),
        label: 'Home',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.assignment_outlined),
        activeIcon: Icon(Icons.assignment),
        label: 'Audits',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.calendar_month_outlined),
        activeIcon: Icon(Icons.calendar_month),
        label: 'Calendário',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.map_outlined),
        activeIcon: Icon(Icons.map),
        label: 'Mapa',
      ),
    ];

    if (RoleService.canViewReports(userRole)) {
      items.add(
        const BottomNavigationBarItem(
          icon: Icon(Icons.analytics_outlined),
          activeIcon: Icon(Icons.analytics),
          label: 'Relatórios',
        ),
      );
    }

    return items;
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
          selectedItemColor: const Color(0xFF1976D2), // lightPrimary sempre
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
