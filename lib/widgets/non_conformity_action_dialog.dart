import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:inspecao/models/inspection.dart';
import 'package:inspecao/models/inspection_item.dart';

class NonConformityActionDialog extends StatefulWidget {
  final InspectionItem item;
  final Inspection inspection;

  const NonConformityActionDialog({
    super.key,
    required this.item,
    required this.inspection,
  });

  @override
  State<NonConformityActionDialog> createState() => _NonConformityActionDialogState();
}

class _NonConformityActionDialogState extends State<NonConformityActionDialog> {
  final _formKey = GlobalKey<FormState>();
  final List<String> _selectedResponsibles = [];
  DateTime _dueDate = DateTime.now().add(const Duration(days: 30));
  final TextEditingController _commentsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Selecionar todos os inspetores por padrão
    _selectedResponsibles.addAll(widget.inspection.equipe.map((inspector) => inspector.nome));
  }

  @override
  void dispose() {
    _commentsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Criar Ação para Não Conformidade'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Item não conforme
              Card(
                color: Colors.red.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.warning, color: Colors.red.shade700),
                          const SizedBox(width: 8),
                          Text(
                            'Item Não Conforme',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.red.shade700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.item.descricao,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      Text(
                        'Categoria: ${widget.item.categoria}',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
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
                  children: widget.inspection.equipe.map((inspector) {
                    final isSelected = _selectedResponsibles.contains(inspector.nome);
                    return CheckboxListTile(
                      title: Text(inspector.nome),
                      subtitle: Text('${inspector.cargoText} - ${inspector.especialidades.join(', ')}'),
                      value: isSelected,
                      onChanged: (value) {
                        setState(() {
                          if (value == true) {
                            _selectedResponsibles.add(inspector.nome);
                          } else {
                            _selectedResponsibles.remove(inspector.nome);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Seleção de prazo
              Text(
                'Prazo para Correção *',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: _selectDueDate,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(DateFormat('dd/MM/yyyy').format(_dueDate)),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Comentários adicionais
              TextFormField(
                controller: _commentsController,
                decoration: const InputDecoration(
                  labelText: 'Comentários Adicionais (opcional)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.comment),
                ),
                maxLines: 3,
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
          onPressed: _selectedResponsibles.isEmpty ? null : _createAction,
          child: const Text('Criar Ação'),
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

  void _createAction() {
    if (_formKey.currentState!.validate() && _selectedResponsibles.isNotEmpty) {
      final result = {
        'responsibles': _selectedResponsibles,
        'dueDate': _dueDate,
        'comments': _commentsController.text.trim().isEmpty ? null : _commentsController.text.trim(),
      };
      
      Navigator.of(context).pop(result);
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
