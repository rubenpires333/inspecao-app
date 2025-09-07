import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:inspecao/models/action_plan.dart';
import 'package:inspecao/models/inspection_item.dart';
import 'package:inspecao/services/data_service.dart';
import 'package:inspecao/screens/action_plan_screen.dart';

class ActionPlanWidget extends StatefulWidget {
  final String inspectionId;
  final bool enabled;
  final List<String> availableResponsibles;
  final List<InspectionItem> inspectionItems; // Nova propriedade para verificar não conformidades

  const ActionPlanWidget({
    super.key,
    required this.inspectionId,
    this.enabled = true,
    this.availableResponsibles = const [],
    required this.inspectionItems, // Nova propriedade obrigatória
  });

  @override
  State<ActionPlanWidget> createState() => _ActionPlanWidgetState();
}

class _ActionPlanWidgetState extends State<ActionPlanWidget> {
  final _dataService = DataService();
  List<ActionPlan> _actionPlans = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadActionPlans();
  }

  Future<void> _loadActionPlans() async {
    setState(() => _isLoading = true);
    try {
      final actionPlans = await _dataService.getActionPlansByInspection(widget.inspectionId);
      if (mounted) {
        setState(() => _actionPlans = actionPlans);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  bool get _hasNonConformityItems {
    return widget.inspectionItems.any((item) => item.status == ItemStatus.naoConforme);
  }

  bool get _canAddNewAction {
    return widget.enabled && _hasNonConformityItems;
  }

  Future<void> _addNewAction() async {
    if (!_canAddNewAction) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Para criar uma ação, é necessário ter pelo menos um item marcado como "não conforme"'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 4),
        ),
      );
      return;
    }

    final result = await Navigator.push<ActionPlan>(
      context,
      MaterialPageRoute(
        builder: (context) => ActionPlanScreen(
          inspectionId: widget.inspectionId,
          availableResponsibles: widget.availableResponsibles,
        ),
      ),
    );

    if (result != null) {
      await _loadActionPlans();
    }
  }

  Future<void> _editAction(ActionPlan actionPlan) async {
    final result = await Navigator.push<ActionPlan>(
      context,
      MaterialPageRoute(
        builder: (context) => ActionPlanScreen(
          inspectionId: widget.inspectionId,
          actionPlan: actionPlan,
          availableResponsibles: widget.availableResponsibles,
        ),
      ),
    );

    if (result != null) {
      await _loadActionPlans();
    }
  }

  Future<void> _deleteAction(ActionPlan actionPlan) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Exclusão'),
        content: Text('Deseja realmente excluir a ação "${actionPlan.description}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _dataService.deleteActionPlan(actionPlan.id);
      await _loadActionPlans();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Plano de Ação',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                if (widget.enabled)
                  IconButton(
                    onPressed: _canAddNewAction ? _addNewAction : null,
                    icon: Icon(
                      _canAddNewAction ? Icons.add : Icons.add_circle_outline,
                      color: _canAddNewAction ? null : Colors.grey,
                    ),
                    tooltip: _canAddNewAction 
                        ? 'Adicionar Ação' 
                        : 'Necessário ter item "não conforme" para criar ação',
                  ),
              ],
            ),
            const SizedBox(height: 8),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_actionPlans.isEmpty)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    if (!_hasNonConformityItems) ...[
                      Icon(
                        Icons.info_outline,
                        color: Colors.blue.shade300,
                        size: 48,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Nenhuma ação cadastrada',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Para criar ações, marque pelo menos um item como "não conforme"',
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ] else
                      const Text(
                        'Nenhuma ação cadastrada',
                        style: TextStyle(color: Colors.grey),
                      ),
                  ],
                ),
              )
            else
              ..._actionPlans.map((action) => _buildActionTile(action)),
          ],
        ),
      ),
    );
  }

  Widget _buildActionTile(ActionPlan action) {
    final isOverdue = action.isOverdue;
    final statusColor = _getStatusColor(action.status);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: statusColor,
          child: Icon(
            _getStatusIcon(action.status),
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Text(
          action.description,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: isOverdue ? Colors.red : null,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Responsáveis: ${action.responsiblesList}'),
            Text('Prazo: ${DateFormat('dd/MM/yyyy').format(action.dueDate)}'),
            if (isOverdue)
              const Text(
                '⚠️ Prazo vencido',
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.w500),
              ),
          ],
        ),
        trailing: widget.enabled
            ? PopupMenuButton<String>(
                onSelected: (value) {
                  switch (value) {
                    case 'edit':
                      _editAction(action);
                      break;
                    case 'delete':
                      _deleteAction(action);
                      break;
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit),
                        SizedBox(width: 8),
                        Text('Editar'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete),
                        SizedBox(width: 8),
                        Text('Excluir'),
                      ],
                    ),
                  ),
                ],
              )
            : null,
        onTap: widget.enabled ? () => _editAction(action) : null,
      ),
    );
  }

  Color _getStatusColor(ActionStatus status) {
    switch (status) {
      case ActionStatus.pendente:
        return Colors.orange;
      case ActionStatus.emAndamento:
        return Colors.blue;
      case ActionStatus.concluida:
        return Colors.green;
      case ActionStatus.cancelada:
        return Colors.red;
    }
  }

  IconData _getStatusIcon(ActionStatus status) {
    switch (status) {
      case ActionStatus.pendente:
        return Icons.schedule;
      case ActionStatus.emAndamento:
        return Icons.play_circle;
      case ActionStatus.concluida:
        return Icons.check_circle;
      case ActionStatus.cancelada:
        return Icons.cancel;
    }
  }
}
