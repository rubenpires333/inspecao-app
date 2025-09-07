import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:inspecao/models/action_plan.dart';
import 'package:inspecao/services/data_service.dart';

class ActionPlanDialog extends StatefulWidget {
  final String inspectionId;
  final ActionPlan? actionPlan; // null para criar novo, não null para editar
  final List<String> availableResponsibles; // Lista de responsáveis disponíveis

  const ActionPlanDialog({
    super.key,
    required this.inspectionId,
    this.actionPlan,
    required this.availableResponsibles,
  });

  @override
  State<ActionPlanDialog> createState() => _ActionPlanDialogState();
}

class _ActionPlanDialogState extends State<ActionPlanDialog> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _commentsController = TextEditingController();
  late List<String> _selectedResponsibles;
  late ActionStatus _status;
  late DateTime _dueDate;

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

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.actionPlan != null ? 'Editar Ação' : 'Nova Ação'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Descrição da Ação',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Descrição é obrigatória';
                  }
                  return null;
                },
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              
              // Seleção de responsáveis
              Text(
                'Responsáveis *',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: widget.availableResponsibles.map((responsible) {
                    final isSelected = _selectedResponsibles.contains(responsible);
                    return CheckboxListTile(
                      title: Text(responsible),
                      value: isSelected,
                      onChanged: (value) {
                        setState(() {
                          if (value == true) {
                            _selectedResponsibles.add(responsible);
                          } else {
                            _selectedResponsibles.remove(responsible);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ),
              
              const SizedBox(height: 16),
              
              DropdownButtonFormField<ActionStatus>(
                value: _status,
                decoration: const InputDecoration(
                  labelText: 'Status',
                  border: OutlineInputBorder(),
                ),
                items: ActionStatus.values.map((status) {
                  return DropdownMenuItem(
                    value: status,
                    child: Text(status.name),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _status = value);
                  }
                },
              ),
              const SizedBox(height: 16),
              
              InkWell(
                onTap: _selectDueDate,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Prazo',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(DateFormat('dd/MM/yyyy').format(_dueDate)),
                ),
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _commentsController,
                decoration: const InputDecoration(
                  labelText: 'Comentários (opcional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _selectedResponsibles.isEmpty ? null : _saveAction,
          child: Text(widget.actionPlan != null ? 'Salvar' : 'Criar'),
        ),
      ],
    );
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

  void _saveAction() {
    if (_formKey.currentState!.validate() && _selectedResponsibles.isNotEmpty) {
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

      Navigator.of(context).pop(actionPlan);
    } else if (_selectedResponsibles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecione pelo menos um responsável'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
