import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:inspecao/models/action_plan.dart';
import 'package:inspecao/services/data_service.dart';

class ActionPlanScreen extends StatefulWidget {
  final String inspectionId;
  final ActionPlan? actionPlan; // null para criar novo, não null para editar
  final List<String> availableResponsibles; // Lista de responsáveis disponíveis

  const ActionPlanScreen({
    super.key,
    required this.inspectionId,
    this.actionPlan,
    required this.availableResponsibles,
  });

  @override
  State<ActionPlanScreen> createState() => _ActionPlanScreenState();
}

class _ActionPlanScreenState extends State<ActionPlanScreen> {
  final _formKey = GlobalKey<FormState>();
  final _dataService = DataService();
  final _descriptionController = TextEditingController();
  final _commentsController = TextEditingController();
  late List<String> _selectedResponsibles;
  late ActionStatus _status;
  late DateTime _dueDate;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    
    if (widget.actionPlan != null) {
      // Modo edição
      _descriptionController.text = widget.actionPlan!.description;
      _commentsController.text = widget.actionPlan!.comments ?? '';
      _selectedResponsibles = List.from(widget.actionPlan!.responsibles);
      _status = widget.actionPlan!.status;
      _dueDate = widget.actionPlan!.dueDate;
    } else {
      // Modo criação
      _selectedResponsibles = List.from(widget.availableResponsibles);
      _status = ActionStatus.pendente;
      _dueDate = DateTime.now().add(const Duration(days: 30));
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _commentsController.dispose();
    super.dispose();
  }

  // Getter para verificar se todos os campos obrigatórios estão preenchidos
  bool get _isFormValid {
    return _descriptionController.text.trim().isNotEmpty &&
           _selectedResponsibles.isNotEmpty;
  }

  Future<void> _selectDueDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null) {
      setState(() => _dueDate = date);
    }
  }

  void _toggleResponsible(String responsible) {
    setState(() {
      if (_selectedResponsibles.contains(responsible)) {
        _selectedResponsibles.remove(responsible);
      } else {
        _selectedResponsibles.add(responsible);
      }
    });
  }

  Future<void> _saveAction() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedResponsibles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecione pelo menos um responsável'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final actionPlan = widget.actionPlan != null
          ? widget.actionPlan!.copyWith(
              description: _descriptionController.text.trim(),
              status: _status,
              responsibles: _selectedResponsibles,
              dueDate: _dueDate,
              comments: _commentsController.text.trim().isEmpty ? null : _commentsController.text.trim(),
              updatedAt: DateTime.now(),
            )
          : ActionPlan(
              id: 'action_${widget.inspectionId}_${DateTime.now().millisecondsSinceEpoch}',
              inspectionId: widget.inspectionId,
              inspectionItemId: '', // Ação geral, não vinculada a item específico
              description: _descriptionController.text.trim(),
              status: _status,
              responsibles: _selectedResponsibles,
              dueDate: _dueDate,
              comments: _commentsController.text.trim().isEmpty ? null : _commentsController.text.trim(),
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            );

      if (widget.actionPlan != null) {
        await _dataService.updateActionPlan(actionPlan);
      } else {
        await _dataService.addActionPlan(actionPlan);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.actionPlan != null ? 'Ação atualizada com sucesso!' : 'Ação criada com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(actionPlan);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar ação: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _getStatusText(ActionStatus status) {
    switch (status) {
      case ActionStatus.pendente:
        return 'Pendente';
      case ActionStatus.emAndamento:
        return 'Em Andamento';
      case ActionStatus.concluida:
        return 'Concluída';
      case ActionStatus.cancelada:
        return 'Cancelada';
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.actionPlan != null ? 'Editar Ação Corretiva' : 'Nova Ação Corretiva'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Descrição da Ação
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Descrição da Ação *',
                  hintText: 'Descreva a ação corretiva a ser implementada',
                  prefixIcon: const Icon(Icons.description),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2),
                  ),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surface,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Descrição é obrigatória';
                  }
                  return null;
                },
                maxLines: 3,
                onChanged: (_) => setState(() {}), // Para atualizar o estado do botão
              ),
              const SizedBox(height: 24),
              
              // Seleção de Responsáveis
              Text(
                'Responsáveis *',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(12),
                  color: Theme.of(context).colorScheme.surface,
                ),
                child: Column(
                  children: widget.availableResponsibles.map((responsible) {
                    final isSelected = _selectedResponsibles.contains(responsible);
                    return ListTile(
                      leading: Checkbox(
                        value: isSelected,
                        onChanged: (value) => _toggleResponsible(responsible),
                        activeColor: Theme.of(context).colorScheme.primary,
                      ),
                      title: Text(
                        responsible,
                        style: TextStyle(
                          fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                          color: isSelected 
                              ? Theme.of(context).colorScheme.primary 
                              : Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      onTap: () => _toggleResponsible(responsible),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 24),
              
              // Status
              DropdownButtonFormField<ActionStatus>(
                value: _status,
                decoration: InputDecoration(
                  labelText: 'Status *',
                  prefixIcon: const Icon(Icons.flag),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2),
                  ),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surface,
                ),
                items: ActionStatus.values.map((status) {
                  return DropdownMenuItem(
                    value: status,
                    child: Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: _getStatusColor(status),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(_getStatusText(status)),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _status = value);
                  }
                },
              ),
              const SizedBox(height: 24),
              
              // Prazo
              InkWell(
                onTap: _selectDueDate,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(12),
                    color: Theme.of(context).colorScheme.surface,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        color: Theme.of(context).colorScheme.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Prazo *',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              DateFormat('dd/MM/yyyy').format(_dueDate),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.arrow_drop_down,
                        color: Colors.grey[600],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // Comentários
              TextFormField(
                controller: _commentsController,
                decoration: InputDecoration(
                  labelText: 'Comentários',
                  hintText: 'Observações adicionais (opcional)',
                  prefixIcon: const Icon(Icons.comment),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2),
                  ),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surface,
                ),
                maxLines: 3,
                onChanged: (_) => setState(() {}), // Para atualizar o estado do botão
              ),
              
              const SizedBox(height: 32),
              
              // Botões de Ação
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: BorderSide(
                          color: Theme.of(context).colorScheme.outline,
                          width: 1.5,
                        ),
                        foregroundColor: Theme.of(context).colorScheme.onSurface,
                      ),
                      icon: const Icon(
                        Icons.close,
                        size: 24,
                      ),
                      label: const Text(
                        'Cancelar',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isLoading || !_isFormValid ? null : _saveAction,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        backgroundColor: _isFormValid 
                            ? Theme.of(context).colorScheme.primary 
                            : Colors.grey[400],
                        foregroundColor: Colors.white,
                        elevation: _isFormValid ? 4 : 0,
                        shadowColor: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                      ),
                      icon: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Icon(
                              _isFormValid ? Icons.save : Icons.block,
                              size: 24,
                            ),
                      label: Text(
                        _isLoading 
                            ? 'Salvando...' 
                            : _isFormValid 
                                ? (widget.actionPlan != null ? 'Salvar' : 'Criar') 
                                : 'Preencha os campos obrigatórios',
                        style: const TextStyle(
                          fontSize: 16,
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
      ),
    );
  }
}
