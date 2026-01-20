import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:inspecao/models/inspection.dart';
import 'package:inspecao/models/inspector.dart';
import 'package:inspecao/models/inspection_item.dart';
import 'package:inspecao/models/establishment.dart';
import 'package:inspecao/services/data_service.dart';
import 'package:inspecao/screens/establishment_selection_screen.dart';
import 'package:inspecao/screens/team_selection_screen.dart';

class CreateInspectionScreen extends StatefulWidget {
  const CreateInspectionScreen({super.key});

  @override
  State<CreateInspectionScreen> createState() => _CreateInspectionScreenState();
}

class _CreateInspectionScreenState extends State<CreateInspectionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _dataService = DataService();
  
  final _tituloController = TextEditingController();
  final _descricaoController = TextEditingController();
  
  InspectionType _selectedType = InspectionType.estrutural;
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _selectedTime = TimeOfDay.now();
  
  List<Inspector> _selectedInspectors = [];
  Establishment? _selectedEstablishment;
  
  bool _isLoading = false;

  // Getter para verificar se todos os campos obrigatórios estão preenchidos
  bool get _isFormValid {
    return _tituloController.text.trim().isNotEmpty &&
           _selectedEstablishment != null &&
           _selectedInspectors.isNotEmpty;
  }

  @override
  void dispose() {
    _tituloController.dispose();
    _descricaoController.dispose();
    super.dispose();
  }

  Future<void> _selectEstablishment() async {
    await Navigator.push<Establishment>(
      context,
      MaterialPageRoute(
        builder: (context) => EstablishmentSelectionScreen(
          selectedEstablishment: _selectedEstablishment,
          onEstablishmentSelected: (establishment) {
            setState(() => _selectedEstablishment = establishment);
          },
        ),
      ),
    );
  }

  Future<void> _selectTeam() async {
    await Navigator.push<List<Inspector>>(
      context,
      MaterialPageRoute(
        builder: (context) => TeamSelectionScreen(
          selectedTeam: _selectedInspectors,
          onTeamSelected: (team) {
            setState(() => _selectedInspectors = team);
          },
        ),
      ),
    );
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      setState(() => _selectedDate = date);
    }
  }

  Future<void> _selectTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (time != null) {
      setState(() => _selectedTime = time);
    }
  }

  List<InspectionItem> _getDefaultItems() {
    switch (_selectedType) {
      case InspectionType.estrutural:
        return [
          InspectionItem(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            descricao: 'Verificar integridade das vigas principais',
            categoria: 'Estrutura',
            status: ItemStatus.pendente,
            obrigatorio: true,
            ordem: 1,
          ),
          InspectionItem(
            id: (DateTime.now().millisecondsSinceEpoch + 1).toString(),
            descricao: 'Avaliar condições das fundações',
            categoria: 'Estrutura',
            status: ItemStatus.pendente,
            obrigatorio: true,
            ordem: 2,
          ),
        ];
      case InspectionType.eletrica:
        return [
          InspectionItem(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            descricao: 'Testar instalações elétricas',
            categoria: 'Elétrica',
            status: ItemStatus.pendente,
            obrigatorio: true,
            ordem: 1,
          ),
          InspectionItem(
            id: (DateTime.now().millisecondsSinceEpoch + 1).toString(),
            descricao: 'Verificar quadro de distribuição',
            categoria: 'Elétrica',
            status: ItemStatus.pendente,
            obrigatorio: true,
            ordem: 2,
          ),
        ];
      case InspectionType.hidraulica:
        return [
          InspectionItem(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            descricao: 'Verificar sistema de água',
            categoria: 'Hidráulica',
            status: ItemStatus.pendente,
            obrigatorio: true,
            ordem: 1,
          ),
        ];
      case InspectionType.seguranca:
        return [
          InspectionItem(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            descricao: 'Avaliar sistema de combate a incêndio',
            categoria: 'Segurança',
            status: ItemStatus.pendente,
            obrigatorio: true,
            ordem: 1,
          ),
        ];
      case InspectionType.ambiental:
        return [
          InspectionItem(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            descricao: 'Avaliar impacto ambiental',
            categoria: 'Ambiental',
            status: ItemStatus.pendente,
            obrigatorio: true,
            ordem: 1,
          ),
        ];
    }
  }

  Future<void> _createInspection() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedInspectors.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione pelo menos um inspetor')),
      );
      return;
    }
    if (_selectedEstablishment == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione um estabelecimento')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final inspection = Inspection(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      titulo: _tituloController.text.trim(),
      descricao: _descricaoController.text.trim().isEmpty 
          ? 'Inspeção ${DataService.getInspectionTypeText(_selectedType).toLowerCase()}'
          : _descricaoController.text.trim(),
      tipo: _selectedType,
      status: InspectionStatus.rascunho,
      dataAgendada: DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      ),
      endereco: _selectedEstablishment!.endereco,
      latitude: _selectedEstablishment!.latitude,
      longitude: _selectedEstablishment!.longitude,
      equipe: _selectedInspectors,
      itens: _getDefaultItems(),
      establishmentId: _selectedEstablishment!.id,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    try {
      await _dataService.addInspection(inspection);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Inspeção criada com sucesso!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao criar inspeção: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nova Inspeção'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _tituloController,
                decoration: InputDecoration(
                  labelText: 'Título da Inspeção *',
                  hintText: 'Ex: Inspeção Estrutural - Edifício Central',
                  prefixIcon: const Icon(Icons.title),
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
                    return 'Digite o título da inspeção';
                  }
                  return null;
                },
                onChanged: (_) => setState(() {}), // Para atualizar o estado do botão
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descricaoController,
                decoration: InputDecoration(
                  labelText: 'Descrição',
                  hintText: 'Descreva os objetivos e escopo da inspeção',
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
                maxLines: 3,
                validator: (value) {
                  // Descrição não é mais obrigatória
                  return null;
                },
                onChanged: (_) => setState(() {}), // Para atualizar o estado do botão
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<InspectionType>(
                value: _selectedType,
                decoration: InputDecoration(
                  labelText: 'Tipo de Inspeção *',
                  prefixIcon: const Icon(Icons.category),
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
                items: InspectionType.values.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(DataService.getInspectionTypeText(type)),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedType = value);
                  }
                },
              ),
              const SizedBox(height: 16),
              
              // Seleção de Estabelecimento
              Text(
                'Estabelecimento *',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              Card(
                child: InkWell(
                  onTap: _selectEstablishment,
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          color: _selectedEstablishment != null 
                              ? Theme.of(context).colorScheme.primary 
                              : Colors.grey,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _selectedEstablishment != null
                              ? Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _selectedEstablishment!.nome,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w500,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _selectedEstablishment!.descricao,
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Row(
                                      children: [
                                        Text(
                                          _selectedEstablishment!.tipoIcon,
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          _selectedEstablishment!.tipoText,
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                )
                              : Text(
                                  'Selecione um estabelecimento',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 16,
                                  ),
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
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: _selectDate,
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
                                    'Data *',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    DateFormat('dd/MM/yyyy').format(_selectedDate),
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
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: InkWell(
                      onTap: _selectTime,
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
                              Icons.access_time,
                              color: Theme.of(context).colorScheme.primary,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Horário *',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _selectedTime.format(context),
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
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // Seleção da Equipe
              Text(
                'Equipe de Inspeção *',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              Card(
                child: InkWell(
                  onTap: _selectTeam,
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(
                          Icons.group,
                          color: _selectedInspectors.isNotEmpty 
                              ? Theme.of(context).colorScheme.primary 
                              : Colors.grey,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _selectedInspectors.isNotEmpty
                              ? Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${_selectedInspectors.length} membro(s) selecionado(s)',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w500,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Wrap(
                                      spacing: 4,
                                      runSpacing: 2,
                                      children: _selectedInspectors.take(3).map((inspector) {
                                        return Chip(
                                          label: Text(
                                            inspector.nome,
                                            style: const TextStyle(fontSize: 12),
                                          ),
                                          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                        );
                                      }).toList(),
                                    ),
                                    if (_selectedInspectors.length > 3)
                                      Text(
                                        '+${_selectedInspectors.length - 3} mais',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 12,
                                        ),
                                      ),
                                  ],
                                )
                              : Text(
                                  'Selecione a equipe de inspeção',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 16,
                                  ),
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
              ),
              
              const SizedBox(height: 32),
              
              // Botão Criar Inspeção
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isLoading || !_isFormValid ? null : _createInspection,
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
                          _isFormValid ? Icons.add_task : Icons.block,
                          size: 24,
                        ),
                  label: Text(
                    _isLoading 
                        ? 'Criando...' 
                        : _isFormValid 
                            ? 'Criar Inspeção' 
                            : 'Preencha todos os campos obrigatórios',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
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
}