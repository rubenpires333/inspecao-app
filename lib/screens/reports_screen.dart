import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:inspecao/models/inspection.dart';
import 'package:inspecao/models/inspection_item.dart';
import 'package:inspecao/models/establishment.dart';
import 'package:inspecao/services/data_service.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final _dataService = DataService();
  List<Inspection> _inspections = [];
  DateTimeRange? _dateRange;
  Map<String, Establishment> _establishmentsCache = {};

  @override
  void initState() {
    super.initState();
    _loadInspections();
  }

  Future<void> _loadInspections() async {
    final inspections = await _dataService.getInspections();
    
    // Carregar estabelecimentos para cache
    final establishments = await _dataService.getAllEstablishments();
    final establishmentsMap = <String, Establishment>{};
    for (final establishment in establishments) {
      establishmentsMap[establishment.id] = establishment;
    }
    
    if (mounted) {
      setState(() {
        _inspections = inspections;
        _establishmentsCache = establishmentsMap;
      });
    }
  }

  List<Inspection> get _filteredInspections {
    if (_dateRange == null) return _inspections;
    
    return _inspections.where((inspection) {
      final date = inspection.dataAgendada;
      return date.isAfter(_dateRange!.start.subtract(const Duration(days: 1))) &&
             date.isBefore(_dateRange!.end.add(const Duration(days: 1)));
    }).toList();
  }

  Future<void> _selectDateRange() async {
    final dateRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      initialDateRange: _dateRange,
    );
    
    if (dateRange != null) {
      setState(() => _dateRange = dateRange);
    }
  }

  Map<String, dynamic> get _statistics {
    final filtered = _filteredInspections;
    final total = filtered.length;
    final rascunho = filtered.where((i) => i.status == InspectionStatus.rascunho).length;
    final emAndamento = filtered.where((i) => i.status == InspectionStatus.emAndamento).length;
    final concluidas = filtered.where((i) => i.status == InspectionStatus.concluida).length;
    final invalidas = filtered.where((i) => i.status == InspectionStatus.invalida).length;

    // Estatísticas por tipo
    final tipos = <InspectionType, int>{};
    for (final tipo in InspectionType.values) {
      tipos[tipo] = filtered.where((i) => i.tipo == tipo).length;
    }

    // Taxa de conclusão
    final taxaConclusao = total > 0 ? (concluidas / total * 100) : 0.0;

    // Itens de inspeção
    final totalItens = filtered.fold<int>(0, (sum, i) => sum + i.itens.length);
    final itensConformes = filtered.fold<int>(0, (sum, i) => 
        sum + i.itens.where((item) => item.status == ItemStatus.conforme).length);
    final itensNaoConformes = filtered.fold<int>(0, (sum, i) => 
        sum + i.itens.where((item) => item.status == ItemStatus.naoConforme).length);

    return {
      'total': total,
      'rascunho': rascunho,
      'emAndamento': emAndamento,
      'concluidas': concluidas,
      'invalidas': invalidas,
      'tipos': tipos,
      'taxaConclusao': taxaConclusao,
      'totalItens': totalItens,
      'itensConformes': itensConformes,
      'itensNaoConformes': itensNaoConformes,
    };
  }

  @override
  Widget build(BuildContext context) {
    final stats = _statistics;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Relatórios'),
      ),
      body: RefreshIndicator(
        onRefresh: _loadInspections,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Filtro de período
              if (_dateRange != null)
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.date_range),
                    title: Text(
                      'Período: ${DateFormat('dd/MM/yyyy').format(_dateRange!.start)} - ${DateFormat('dd/MM/yyyy').format(_dateRange!.end)}',
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => setState(() => _dateRange = null),
                    ),
                  ),
                ),

              const SizedBox(height: 16),

              // Resumo Geral
              Row(
                children: [
                  Text(
                    'Resumo Geral',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const Spacer(),
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: Icon(
                        Icons.date_range,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      onPressed: _selectDateRange,
                      tooltip: 'Filtrar por período',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1.2,
                children: [
                  _buildStatCard(
                    'Total de Inspeções',
                    stats['total'].toString(),
                    Colors.blue,
                    Icons.assignment,
                  ),
                  _buildStatCard(
                    'Taxa de Conclusão',
                    '${stats['taxaConclusao'].toStringAsFixed(1)}%',
                    Colors.green,
                    Icons.check_circle,
                  ),
                  _buildStatCard(
                    'Em Andamento',
                    stats['emAndamento'].toString(),
                    Colors.orange,
                    Icons.play_circle,
                  ),
                  _buildStatCard(
                    'Inválidas',
                    stats['invalidas'].toString(),
                    Colors.red,
                    Icons.cancel,
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Status das Inspeções
              Text(
                'Status das Inspeções',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildStatusRow('Rascunho', stats['rascunho'], Colors.grey),
                      _buildStatusRow('Em Andamento', stats['emAndamento'], Colors.orange),
                      _buildStatusRow('Concluídas', stats['concluidas'], Colors.blue),
                      _buildStatusRow('Inválidas', stats['invalidas'], Colors.red),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Tipos de Inspeção
              Text(
                'Inspeções por Tipo',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: (stats['tipos'] as Map<InspectionType, int>)
                        .entries
                        .map((entry) => _buildTypeRow(entry.key, entry.value))
                        .toList(),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Itens de Verificação
              Text(
                'Itens de Verificação',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.list, color: Colors.grey),
                          const SizedBox(width: 8),
                          const Text('Total de Itens:'),
                          const Spacer(),
                          Text(
                            stats['totalItens'].toString(),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const Divider(),
                      Row(
                        children: [
                          const Icon(Icons.check_circle, color: Colors.green),
                          const SizedBox(width: 8),
                          const Text('Conformes:'),
                          const Spacer(),
                          Text(
                            stats['itensConformes'].toString(),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                      const Divider(),
                      Row(
                        children: [
                          const Icon(Icons.cancel, color: Colors.red),
                          const SizedBox(width: 8),
                          const Text('Não Conformes:'),
                          const Spacer(),
                          Text(
                            stats['itensNaoConformes'].toString(),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Inspeções Detalhadas
              Text(
                'Inspeções Detalhadas',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _filteredInspections.length,
                itemBuilder: (context, index) {
                  final inspection = _filteredInspections[index];
                  final completedItems = inspection.itens
                      .where((i) => i.status != ItemStatus.pendente)
                      .length;
                  final progress = inspection.itens.isNotEmpty 
                      ? completedItems / inspection.itens.length 
                      : 0.0;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ExpansionTile(
                      leading: CircleAvatar(
                        backgroundColor: _getStatusColor(inspection.status),
                        child: Text(
                          (progress * 100).toInt().toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(_getInspectionDisplayTitle(inspection)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Status: ${inspection.statusText}'),
                          Text('Data: ${DateFormat('dd/MM/yyyy').format(inspection.dataAgendada)}'),
                          LinearProgressIndicator(value: progress),
                        ],
                      ),
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Tipo: ${inspection.tipoText}'),
                              Text('Endereço: ${inspection.endereco}'),
                              Text('Equipe: ${inspection.equipe.map((e) => e.nome).join(', ')}'),
                              Text('Progresso: $completedItems/${inspection.itens.length} itens'),
                              if (inspection.observacoes != null) ...[
                                const SizedBox(height: 8),
                                Text('Observações: ${inspection.observacoes}'),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusRow(String status, int count, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(status),
          const Spacer(),
          Text(
            count.toString(),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeRow(InspectionType type, int count) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(_getTypeIcon(type), size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text(DataService.getInspectionTypeText(type)),
          const Spacer(),
          Text(
            count.toString(),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
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

  IconData _getTypeIcon(InspectionType type) {
    switch (type) {
      case InspectionType.estrutural:
        return Icons.foundation;
      case InspectionType.eletrica:
        return Icons.electrical_services;
      case InspectionType.hidraulica:
        return Icons.plumbing;
      case InspectionType.seguranca:
        return Icons.security;
      case InspectionType.ambiental:
        return Icons.eco;
    }
  }

}