import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:inspecao/models/inspection.dart';
import 'package:inspecao/models/inspection_item.dart';
import 'package:inspecao/models/user.dart';
import 'package:inspecao/models/establishment.dart';
import 'package:inspecao/services/data_service.dart';
import 'package:inspecao/services/role_service.dart';
import 'package:inspecao/screens/create_inspection_screen.dart';
import 'package:inspecao/screens/inspection_detail_screen.dart';

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
    final user = await _dataService.getCurrentUser();
    List<Inspection> inspections = [];
    
    if (user != null) {
      inspections = await _dataService.getInspectionsForUser(user);
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
        _filteredInspections = inspections;
        _establishmentsCache = establishmentsMap;
      });
    }
  }

  void _filterInspections() {
    final searchTerm = _searchController.text.toLowerCase();
    setState(() {
      _filteredInspections = _inspections.where((inspection) {
        final matchesSearch = searchTerm.isEmpty ||
            inspection.titulo.toLowerCase().contains(searchTerm) ||
            inspection.endereco.toLowerCase().contains(searchTerm);
        final matchesStatus = _statusFilter == null || inspection.status == _statusFilter;
        return matchesSearch && matchesStatus;
      }).toList();
    });
  }

  void _setStatusFilter(InspectionStatus? status) {
    setState(() {
      _statusFilter = status;
      _filterInspections();
    });
  }

  String _getEstablishmentName(Inspection inspection) {
    if (inspection.establishmentId == null) {
      return inspection.endereco; // Fallback para endereço se não tiver estabelecimento
    }
    
    final establishment = _establishmentsCache[inspection.establishmentId];
    if (establishment != null) {
      return establishment.nome;
    }
    
    return inspection.endereco; // Fallback para endereço se não encontrar estabelecimento
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inspeções'),
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            color: Theme.of(context).colorScheme.surface,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              labelText: 'Buscar inspeções...',
                              hintText: 'Digite o título ou endereço',
                              prefixIcon: Icon(
                                Icons.search,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(
                                  color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(
                                  color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(
                                  color: Theme.of(context).colorScheme.primary,
                                  width: 2,
                                ),
                              ),
                              filled: true,
                              fillColor: Theme.of(context).colorScheme.surface,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: Theme.of(context).colorScheme.surface,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: PopupMenuButton<InspectionStatus?>(
                          onSelected: _setStatusFilter,
                          icon: Icon(
                            Icons.filter_list,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: null,
                              child: Row(
                                children: [
                                  Icon(Icons.clear_all, size: 16),
                                  SizedBox(width: 8),
                                  Text('Todas'),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: InspectionStatus.agendada,
                              child: Row(
                                children: [
                                  Icon(Icons.schedule, color: Colors.blue, size: 16),
                                  const SizedBox(width: 8),
                                  const Text('Agendadas'),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: InspectionStatus.emAndamento,
                              child: Row(
                                children: [
                                  Icon(Icons.play_circle, color: Colors.orange, size: 16),
                                  const SizedBox(width: 8),
                                  const Text('Em Andamento'),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: InspectionStatus.concluida,
                              child: Row(
                                children: [
                                  Icon(Icons.check_circle, color: Colors.green, size: 16),
                                  const SizedBox(width: 8),
                                  const Text('Concluídas'),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (_statusFilter != null) ...[
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Chip(
                          avatar: Icon(
                            _getStatusIcon(_statusFilter!),
                            size: 16,
                            color: _getStatusColor(_statusFilter!),
                          ),
                          label: Text('Filtro: ${_statusFilter!.name}'),
                          onDeleted: () => _setStatusFilter(null),
                          backgroundColor: _getStatusColor(_statusFilter!).withOpacity(0.1),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: _filteredInspections.isEmpty
                ? SliverFillRemaining(
                    child: RefreshIndicator(
                      onRefresh: _loadData,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: _buildEmptyState(),
                      ),
                    ),
                  )
                : SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final inspection = _filteredInspections[index];
                        return _buildModernInspectionCard(inspection);
                      },
                      childCount: _filteredInspections.length,
                    ),
                  ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
      floatingActionButton: RoleService.canCreateInspection(_currentUser?.role ?? UserRole.inspetor)
          ? Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: FloatingActionButton.extended(
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const CreateInspectionScreen()),
                  );
                  _loadData();
                },
                icon: const Icon(Icons.add),
                label: const Text('Nova Inspeção'),
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
              ),
            )
          : null,
    );
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
              '📋 Nenhuma inspeção encontrada',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              _searchController.text.isNotEmpty || _statusFilter != null
                  ? 'Tente ajustar os filtros de busca'
                  : RoleService.canCreateInspection(_currentUser?.role ?? UserRole.inspetor)
                      ? 'Crie sua primeira inspeção para começar'
                      : 'Você não possui inspeções atribuídas à sua equipe',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
              textAlign: TextAlign.center,
            ),
            if (_searchController.text.isEmpty && _statusFilter == null && RoleService.canCreateInspection(_currentUser?.role ?? UserRole.inspetor)) ...[
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
                label: const Text('Criar Inspeção'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildModernInspectionCard(Inspection inspection) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
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
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          inspection.tipoText,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getStatusColor(inspection.status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      inspection.statusText,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: _getStatusColor(inspection.status),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.schedule,
                          size: 16,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          DateFormat('dd/MM/yyyy • HH:mm').format(inspection.dataAgendada),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Spacer(),
                        Icon(
                          Icons.people,
                          size: 16,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${inspection.equipe.length} inspector(es)',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 16,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _getEstablishmentName(inspection),
                            style: Theme.of(context).textTheme.bodySmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${inspection.itens.where((i) => i.status != ItemStatus.pendente).length}/${inspection.itens.length} itens',
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
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

  IconData _getStatusIcon(InspectionStatus status) {
    switch (status) {
      case InspectionStatus.agendada:
        return Icons.schedule;
      case InspectionStatus.emAndamento:
        return Icons.play_circle_filled;
      case InspectionStatus.concluida:
        return Icons.check_circle;
      case InspectionStatus.cancelada:
        return Icons.cancel;
    }
  }
}