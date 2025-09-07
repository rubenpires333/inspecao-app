import 'package:flutter/material.dart';
import 'package:inspecao/models/inspection.dart';
import 'package:inspecao/models/user.dart';
import 'package:inspecao/models/establishment.dart';
import 'package:inspecao/services/data_service.dart';
import 'package:inspecao/services/role_service.dart';
import 'package:inspecao/screens/login_screen.dart';
import 'package:inspecao/screens/inspections_screen.dart';
import 'package:inspecao/screens/inspection_detail_screen.dart';
import 'package:inspecao/screens/create_inspection_screen.dart';
import 'package:inspecao/screens/calendar_screen.dart';
import 'package:inspecao/screens/map_screen.dart';
import 'package:inspecao/screens/reports_screen.dart';
import 'package:inspecao/screens/inspectors_screen.dart';
import 'package:inspecao/screens/profile_screen.dart';
import 'package:inspecao/widgets/notification_center.dart';
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

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _navigateToCreateInspection() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CreateInspectionScreen(),
      ),
    );
    // Recarregar dados após criar inspeção
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
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Olá, ${_currentUser?.nome ?? 'Usuário'}'),
            if (_currentUser != null)
              Text(
                RoleService.getRoleDisplayName(_currentUser!.role),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.8),
                ),
              ),
          ],
        ),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications),
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
          PopupMenuButton(
            icon: const Icon(Icons.account_circle),
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
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const SizedBox(height: 24),
              if (RoleService.canCreateInspection(_currentUser?.role ?? UserRole.inspetor))
                _buildQuickActions(),
              if (RoleService.canCreateInspection(_currentUser?.role ?? UserRole.inspetor))
                const SizedBox(height: 24),
              _buildStatsSection(agendadas, emAndamento, concluidas, canceladas),
              const SizedBox(height: 24),
              _buildRecentInspections(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '⚡ Ações Rápidas',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            if (RoleService.canCreateInspection(_currentUser?.role ?? UserRole.inspetor))
              Expanded(
                child: _buildActionCard(
                  '📋 Nova Inspeção',
                  'Criar nova inspeção',
                  Icons.add_circle_outline,
                  Theme.of(context).colorScheme.primary,
                  () => _navigateToCreateInspection(),
                ),
              ),
            if (RoleService.canCreateInspection(_currentUser?.role ?? UserRole.inspetor))
              const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                '📅 Calendário',
                'Ver agendamentos',
                Icons.calendar_today,
                Theme.of(context).colorScheme.tertiary,
                () => setState(() => _selectedIndex = 2),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard(String title, String subtitle, IconData icon, Color color, VoidCallback onTap) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsSection(int agendadas, int emAndamento, int concluidas, int canceladas) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '📈 Estatísticas',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.3,
          children: [
            _buildModernStatusCard(
              'Agendadas',
              agendadas.toString(),
              Theme.of(context).colorScheme.primary,
              Icons.schedule,
              '⏰',
            ),
            _buildModernStatusCard(
              'Em Andamento',
              emAndamento.toString(),
              Colors.orange,
              Icons.play_circle_filled,
              '🔄',
            ),
            _buildModernStatusCard(
              'Concluídas',
              concluidas.toString(),
              Colors.green,
              Icons.check_circle,
              '✅',
            ),
            _buildModernStatusCard(
              'Canceladas',
              canceladas.toString(),
              Colors.red.shade400,
              Icons.cancel,
              '❌',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRecentInspections() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '🕐 Inspeções Recentes',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () => setState(() => _selectedIndex = 1),
              child: const Text('Ver todas'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_inspections.isEmpty)
          Card(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(
                    Icons.assignment_outlined,
                    size: 48,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Nenhuma inspeção encontrada',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Crie sua primeira inspeção para começar',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _inspections.take(3).length,
            itemBuilder: (context, index) {
              final inspection = _inspections[index];
              return _buildModernInspectionCard(inspection);
            },
          ),
      ],
    );
  }

  Widget _buildModernInspectionCard(Inspection inspection) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => InspectionDetailScreen(inspection: inspection),
            ),
          );
          _loadData(); // Recarregar dados após voltar
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _getStatusColor(inspection.status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getStatusIcon(inspection.status),
                  color: _getStatusColor(inspection.status),
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getInspectionDisplayTitle(inspection),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 14,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            inspection.endereco,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor(inspection.status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  inspection.statusText,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: _getStatusColor(inspection.status),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernStatusCard(String title, String value, Color color, IconData icon, String emoji) {
    return Card(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withOpacity(0.1),
              color.withOpacity(0.05),
            ],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              emoji,
              style: const TextStyle(fontSize: 24),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
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

  IconData _getStatusIcon(InspectionStatus status) {
    switch (status) {
      case InspectionStatus.agendada:
        return Icons.schedule;
      case InspectionStatus.emAndamento:
        return Icons.play_circle;
      case InspectionStatus.concluida:
        return Icons.check_circle;
      case InspectionStatus.cancelada:
        return Icons.cancel;
    }
  }

  String _getInspectionDisplayTitle(Inspection inspection) {
    if (inspection.establishmentId == null) {
      return inspection.titulo;
    }
    
    final establishment = _establishmentsCache[inspection.establishmentId];
    if (establishment != null) {
      return '${inspection.titulo} - ${establishment.nome}';
    }
    
    return inspection.titulo;
  }

  List<BottomNavigationBarItem> _buildBottomNavItems() {
    final userRole = _currentUser?.role ?? UserRole.inspetor;
    final items = <BottomNavigationBarItem>[
      const BottomNavigationBarItem(
        icon: Icon(Icons.dashboard_outlined),
        activeIcon: Icon(Icons.dashboard),
        label: 'Dashboard',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.assignment_outlined),
        activeIcon: Icon(Icons.assignment),
        label: 'Inspeções',
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
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: NotificationCenter(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
          selectedItemColor: Theme.of(context).colorScheme.primary,
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