import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:inspecao/models/inspection.dart';
import 'package:inspecao/models/inspection_item.dart';
import 'package:inspecao/models/evidence.dart';
import 'package:inspecao/models/establishment.dart';
import 'package:inspecao/services/data_service.dart';
import 'package:inspecao/widgets/item_evidence_widget.dart';
import 'package:inspecao/widgets/action_plan_widget.dart';
import 'package:inspecao/widgets/non_conformity_action_dialog.dart';

class InspectionDetailScreen extends StatefulWidget {
  final Inspection inspection;

  const InspectionDetailScreen({super.key, required this.inspection});

  @override
  State<InspectionDetailScreen> createState() => _InspectionDetailScreenState();
}

class _InspectionDetailScreenState extends State<InspectionDetailScreen> {
  final _dataService = DataService();
  late Inspection _inspection;
  bool _isLoading = false;
  final TextEditingController _generalCommentsController = TextEditingController();
  Establishment? _establishment;

  @override
  void initState() {
    super.initState();
    _inspection = widget.inspection;
    _loadEstablishment();
    _generalCommentsController.text = _inspection.observacoes ?? '';
  }

  Future<void> _loadEstablishment() async {
    if (_inspection.establishmentId != null) {
      final establishment = await _dataService.getEstablishmentById(_inspection.establishmentId!);
      if (mounted) {
        setState(() => _establishment = establishment);
      }
    }
  }

  Future<void> _saveGeneralComments() async {
    if (_generalCommentsController.text.trim().isEmpty) return;
    
    setState(() => _isLoading = true);
    
    try {
      // Simular salvamento dos comentários
      await Future.delayed(const Duration(milliseconds: 500));
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Comentários salvos com sucesso!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao salvar comentários: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateInspectionStatus(InspectionStatus newStatus) async {
    // Mostrar dialog de confirmação antes de iniciar ou finalizar
    if (newStatus == InspectionStatus.emAndamento) {
      final confirmed = await _showStartConfirmationDialog();
      if (!confirmed) return;
    } else if (newStatus == InspectionStatus.concluida) {
      final confirmed = await _showFinalizeConfirmationDialog();
      if (!confirmed) return;
    }

    setState(() => _isLoading = true);

    DateTime? dataInicio = _inspection.dataInicio;
    DateTime? dataConclusao = _inspection.dataConclusao;

    if (newStatus == InspectionStatus.emAndamento && dataInicio == null) {
      dataInicio = DateTime.now();
    }

    if (newStatus == InspectionStatus.concluida && dataConclusao == null) {
      dataConclusao = DateTime.now();
    }

    final updatedInspection = _inspection.copyWith(
      status: newStatus,
      dataInicio: dataInicio,
      dataConclusao: dataConclusao,
    );

    try {
      await _dataService.updateInspection(updatedInspection);
      setState(() => _inspection = updatedInspection);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Status atualizado para: ${updatedInspection.statusText}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao atualizar status: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<bool> _showStartConfirmationDialog() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(
              Icons.play_circle_outline,
              color: isDark ? Colors.green[400] : Colors.green[600],
              size: 28,
            ),
            const SizedBox(width: 12),
            Text(
              'Iniciar Inspeção',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tem certeza que deseja iniciar esta inspeção?',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark 
                    ? Colors.green[900]?.withOpacity(0.3)
                    : Colors.green[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isDark 
                      ? Colors.green[700]!
                      : Colors.green[200]!,
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: isDark ? Colors.green[300] : Colors.green[700],
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Importante:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.green[300] : Colors.green[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• Após iniciar, você poderá editar os itens do checklist\n'
                    '• Poderá adicionar evidências e comentários\n'
                    '• A inspeção será marcada como "Em Andamento"',
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.4,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              foregroundColor: Theme.of(context).colorScheme.onSurface,
            ),
            child: const Text(
              'Cancelar',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: isDark ? Colors.green[600] : Colors.green[600],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 2,
            ),
            child: const Text(
              'Sim, Iniciar',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    ) ?? false;
  }

  Future<bool> _showFinalizeConfirmationDialog() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: isDark ? Colors.orange[400] : Colors.orange[600],
              size: 28,
            ),
            const SizedBox(width: 12),
            Text(
              'Finalizar Inspeção',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tem certeza que deseja finalizar esta inspeção?',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark 
                    ? Colors.orange[900]?.withOpacity(0.3)
                    : Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isDark 
                      ? Colors.orange[700]!
                      : Colors.orange[200]!,
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: isDark ? Colors.orange[300] : Colors.orange[700],
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Importante:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.orange[300] : Colors.orange[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• Após finalizar, não será possível editar os itens do checklist\n'
                    '• As evidências ficarão bloqueadas para edição\n'
                    '• A inspeção será marcada como concluída',
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.4,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              foregroundColor: Theme.of(context).colorScheme.onSurface,
            ),
            child: const Text(
              'Cancelar',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: isDark ? Colors.orange[600] : Colors.orange[600],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 2,
            ),
            child: const Text(
              'Sim, Finalizar',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    ) ?? false;
  }

  void _updateItemStatus(InspectionItem item, ItemStatus newStatus) {
    if (newStatus == ItemStatus.naoConforme) {
      _showNonConformityDialog(item);
    } else {
      _updateItemStatusDirectly(item, newStatus);
    }
  }

  void _updateItemStatusDirectly(InspectionItem item, ItemStatus newStatus) {
    final updatedItem = item.copyWith(status: newStatus);
    final updatedItems = _inspection.itens.map((i) => i.id == item.id ? updatedItem : i).toList();
    final updatedInspection = _inspection.copyWith(itens: updatedItems);
    
    setState(() => _inspection = updatedInspection);
    _dataService.updateInspection(updatedInspection);
  }

  Future<void> _showNonConformityDialog(InspectionItem item) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => NonConformityActionDialog(
        item: item,
        inspection: _inspection,
      ),
    );

    if (result != null) {
      final responsibles = result['responsibles'] as List<String>;
      final dueDate = result['dueDate'] as DateTime;
      
      // Criar plano de ação automaticamente
      await _dataService.createActionPlanForNonConformity(
        inspectionId: _inspection.id,
        inspectionItemId: item.id,
        itemDescription: item.descricao,
        responsibles: responsibles,
        dueDate: dueDate,
      );
      
      // Atualizar status do item
      _updateItemStatusDirectly(item, ItemStatus.naoConforme);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Plano de ação criado automaticamente!')),
        );
      }
    }
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
    final completedItems = _inspection.itens.where((i) => i.status != ItemStatus.pendente).length;
    final progress = _inspection.itens.isNotEmpty ? completedItems / _inspection.itens.length : 0.0;

    return Scaffold(
      appBar: AppBar(
        title: Text(_inspection.titulo),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _getStatusColor(_inspection.status),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        _inspection.statusText,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Progresso: ${completedItems}/${_inspection.itens.length} itens',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 4),
                          LinearProgressIndicator(
                            value: progress,
                            backgroundColor: Colors.grey[300],
                            valueColor: AlwaysStoppedAnimation<Color>(
                              _getStatusColor(_inspection.status),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Informações da Inspeção
            Text('Informações', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildInfoRow(Icons.location_on, 'Local', _establishment?.nome ?? _inspection.endereco),
                    const SizedBox(height: 8),
                    _buildInfoRow(Icons.calendar_today, 'Data', DateFormat('dd/MM/yyyy').format(_inspection.dataAgendada)),
                    const SizedBox(height: 8),
                    _buildInfoRow(Icons.access_time, 'Horário', DateFormat('HH:mm').format(_inspection.dataAgendada)),
                    const SizedBox(height: 8),
                    _buildInfoRow(Icons.category, 'Tipo', DataService.getInspectionTypeText(_inspection.tipo)),
                    if (_establishment != null) ...[
                      const SizedBox(height: 8),
                      _buildInfoRow(Icons.business, 'Estabelecimento', _establishment!.nome),
                      const SizedBox(height: 8),
                      _buildInfoRow(Icons.description, 'Descrição', _establishment!.descricao),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Checklist
            Text('Checklist', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Card(
              child: Column(
                children: _inspection.itens.map((item) => InspectionItemTile(
                  key: ValueKey(item.id),
                  item: item,
                  onStatusChanged: (newStatus) => _updateItemStatus(item, newStatus),
                  inspectionId: _inspection.id,
                  inspectionStatus: _inspection.status,
                  enabled: _inspection.status == InspectionStatus.emAndamento,
                )).toList(),
              ),
            ),

            // Plano de Ação e Comentários Gerais - apenas se inspeção iniciada
            if (_inspection.status == InspectionStatus.emAndamento || _inspection.status == InspectionStatus.concluida) ...[
              const SizedBox(height: 16),

              // Plano de Ação
              Text('Plano de Ação', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              ActionPlanWidget(
                inspectionId: _inspection.id,
                availableResponsibles: ['Inspetor 1', 'Inspetor 2', 'Supervisor'],
                inspectionItems: _inspection.itens,
              ),

              const SizedBox(height: 16),

              // Comentários Gerais
              Text('Comentários Gerais', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _generalCommentsController,
                        maxLines: 4,
                        decoration: InputDecoration(
                          labelText: 'Comentários Gerais',
                          hintText: 'Adicione comentários gerais sobre a inspeção...',
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
                        enabled: _inspection.status == InspectionStatus.emAndamento,
                      ),
                      if (_inspection.status == InspectionStatus.emAndamento) ...[
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            ElevatedButton.icon(
                              onPressed: _isLoading ? null : _saveGeneralComments,
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                backgroundColor: Theme.of(context).colorScheme.primary,
                                foregroundColor: Colors.white,
                                elevation: 2,
                              ),
                              icon: _isLoading
                                  ? const SizedBox(
                                      height: 16,
                                      width: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    )
                                  : const Icon(Icons.save, size: 18),
                              label: Text(
                                _isLoading ? 'Salvando...' : 'Salvar Comentários',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],

            if (_inspection.observacoes != null) ...[
              const SizedBox(height: 16),
              Text('Observações', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(_inspection.observacoes!),
                ),
              ),
            ],
            
            const SizedBox(height: 32),
            
            // Botões de Ação
            if (_inspection.status == InspectionStatus.rascunho || 
                _inspection.status == InspectionStatus.emAndamento)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: SafeArea(
                  child: Column(
                    children: [
                      // Botão de Status (Iniciar/Finalizar)
                      if (_inspection.status == InspectionStatus.rascunho)
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _isLoading ? null : () => _updateInspectionStatus(InspectionStatus.emAndamento),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              elevation: 4,
                              shadowColor: Colors.green.withOpacity(0.3),
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
                                : const Icon(
                                    Icons.play_arrow,
                                    size: 24,
                                  ),
                            label: Text(
                              _isLoading ? 'Iniciando...' : 'Iniciar Inspeção',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        )
                      else if (_inspection.status == InspectionStatus.emAndamento)
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _isLoading ? null : () => _updateInspectionStatus(InspectionStatus.concluida),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              backgroundColor: Theme.of(context).colorScheme.primary,
                              foregroundColor: Colors.white,
                              elevation: 4,
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
                                : const Icon(
                                    Icons.check_circle,
                                    size: 24,
                                  ),
                            label: Text(
                              _isLoading ? 'Finalizando...' : 'Finalizar Inspeção',
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
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text('$label:', style: const TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(width: 8),
        Expanded(child: Text(value)),
      ],
    );
  }
}

class InspectionItemTile extends StatefulWidget {
  final InspectionItem item;
  final Function(ItemStatus) onStatusChanged;
  final bool enabled;
  final String inspectionId;
  final InspectionStatus inspectionStatus;

  const InspectionItemTile({
    super.key,
    required this.item,
    required this.onStatusChanged,
    required this.inspectionId,
    required this.inspectionStatus,
    this.enabled = true,
  });

  @override
  State<InspectionItemTile> createState() => _InspectionItemTileState();
}

class _InspectionItemTileState extends State<InspectionItemTile> {
  List<Evidence> _itemEvidences = [];
  
  @override
  void initState() {
    super.initState();
    _loadItemEvidences();
  }
  
  Future<void> _loadItemEvidences() async {
    final dataService = DataService();
    final evidences = await dataService.getEvidencesByInspection(widget.inspectionId);
    final itemEvidences = evidences.where((e) => e.description.contains('Item: ${widget.item.id}')).toList();
    
    if (mounted) {
      setState(() => _itemEvidences = itemEvidences);
    }
  }
  
  void _onEvidencesChanged(List<Evidence> evidences) {
    setState(() => _itemEvidences = evidences);
  }

  Color _getStatusColor(ItemStatus status) {
    switch (status) {
      case ItemStatus.pendente:
        return Colors.grey;
      case ItemStatus.conforme:
        return Colors.green;
      case ItemStatus.naoConforme:
        return Colors.red;
      case ItemStatus.naoAplica:
        return Colors.blue;
    }
  }

  IconData _getStatusIcon(ItemStatus status) {
    switch (status) {
      case ItemStatus.pendente:
        return Icons.schedule;
      case ItemStatus.conforme:
        return Icons.check_circle;
      case ItemStatus.naoConforme:
        return Icons.cancel;
      case ItemStatus.naoAplica:
        return Icons.remove_circle;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      title: Row(
        children: [
          Icon(
            _getStatusIcon(widget.item.status),
            color: _getStatusColor(widget.item.status),
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              widget.item.descricao,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: widget.item.status == ItemStatus.pendente 
                    ? Colors.grey[600] 
                    : null,
              ),
            ),
          ),
          if (_itemEvidences.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${_itemEvidences.length}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          // Menu de status (3 pontinhos) - apenas se habilitado
          if (widget.enabled)
            PopupMenuButton<ItemStatus>(
              icon: Icon(
                Icons.more_vert,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                size: 20,
              ),
              onSelected: (ItemStatus status) {
                widget.onStatusChanged(status);
              },
              itemBuilder: (BuildContext context) => [
                PopupMenuItem<ItemStatus>(
                  value: ItemStatus.conforme,
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: Colors.green,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      const Text('Conforme'),
                    ],
                  ),
                ),
                PopupMenuItem<ItemStatus>(
                  value: ItemStatus.naoConforme,
                  child: Row(
                    children: [
                      Icon(
                        Icons.cancel,
                        color: Colors.red,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      const Text('Não Conforme'),
                    ],
                  ),
                ),
                PopupMenuItem<ItemStatus>(
                  value: ItemStatus.naoAplica,
                  child: Row(
                    children: [
                      Icon(
                        Icons.remove_circle,
                        color: Colors.blue,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      const Text('Não Aplica'),
                    ],
                  ),
                ),
                PopupMenuItem<ItemStatus>(
                  value: ItemStatus.pendente,
                  child: Row(
                    children: [
                      Icon(
                        Icons.schedule,
                        color: Colors.grey,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      const Text('Pendente'),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      subtitle: widget.item.status != ItemStatus.pendente
          ? Text(
              widget.item.statusText,
              style: TextStyle(
                color: _getStatusColor(widget.item.status),
                fontWeight: FontWeight.w500,
              ),
            )
          : null,
      initiallyExpanded: false,
      children: [
        if (widget.item.status != ItemStatus.pendente) ...[
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.item.observacao != null && widget.item.observacao!.isNotEmpty) ...[
                  Text(
                    'Observação:',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('Observação: ${widget.item.observacao}'),
                  ),
                ],
                // Sempre mostrar evidências, mas em modo visualização se inspeção concluída
                ItemEvidenceWidget(
                  inspectionId: widget.inspectionId,
                  itemId: widget.item.id,
                  itemTitle: widget.item.descricao,
                  onEvidencesChanged: _onEvidencesChanged,
                  enabled: widget.enabled,
                  allowDeletion: widget.enabled,
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
