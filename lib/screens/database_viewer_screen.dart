import 'package:flutter/material.dart';
import 'package:inspecao/models/inspection.dart';
import 'package:inspecao/models/establishment.dart';
import 'package:inspecao/services/database_service.dart';
import 'package:inspecao/database/database.dart' as db;

/// Tela temporária para visualizar o banco de dados local
/// Será removida após desenvolvimento
class DatabaseViewerScreen extends StatefulWidget {
  const DatabaseViewerScreen({super.key});

  @override
  State<DatabaseViewerScreen> createState() => _DatabaseViewerScreenState();
}

class _DatabaseViewerScreenState extends State<DatabaseViewerScreen> {
  final _dbService = DatabaseService();
  
  List<Inspection> _inspections = [];
  List<Establishment> _establishments = [];
  List<db.CategoriasEstabelecimentoData> _categorias = [];
  bool _isLoading = true;
  
  // Estatísticas
  int _totalInspections = 0;
  int _syncedInspections = 0;
  int _pendingInspections = 0;
  int _totalEstablishments = 0;
  int _syncedEstablishments = 0;
  int _totalCategorias = 0;
  int _syncedCategorias = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      print('🔄 [DB Viewer] Inicializando banco de dados...');
      await _dbService.initialize();
      print('✅ [DB Viewer] Banco de dados inicializado');
      
      // Carregar inspeções
      print('📥 [DB Viewer] Carregando inspeções...');
      _inspections = await _dbService.getInspections();
      _totalInspections = _inspections.length;
      _syncedInspections = _inspections.where((i) => i.isSynced).length;
      _pendingInspections = _inspections.where((i) => !i.isSynced).length;
      print('📊 [DB Viewer] Inspeções carregadas: $_totalInspections (sincronizadas: $_syncedInspections, pendentes: $_pendingInspections)');
      
      // Carregar estabelecimentos
      print('📥 [DB Viewer] Carregando estabelecimentos...');
      _establishments = await _dbService.getEstablishments();
      _totalEstablishments = _establishments.length;
      _syncedEstablishments = _establishments.where((e) => e.isSynced).length;
      print('📊 [DB Viewer] Estabelecimentos carregados: $_totalEstablishments (sincronizados: $_syncedEstablishments)');
      
      // Carregar categorias de estabelecimento
      print('📥 [DB Viewer] Carregando categorias...');
      _categorias = await _dbService.getCategoriasEstabelecimento();
      _totalCategorias = _categorias.length;
      _syncedCategorias = _categorias.where((c) => c.isSynced).length;
      print('📊 [DB Viewer] Categorias carregadas: $_totalCategorias (sincronizadas: $_syncedCategorias)');
      
    } catch (e, stackTrace) {
      print('❌ [DB Viewer] Erro ao carregar dados do banco: $e');
      print('❌ [DB Viewer] Stack trace: $stackTrace');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
        print('✅ [DB Viewer] Estado atualizado. Total: $_totalInspections inspeções, $_totalEstablishments estabelecimentos, $_totalCategorias categorias');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE3F0E9),
      appBar: AppBar(
        title: const Text('Banco de Dados Local'),
        backgroundColor: const Color(0xFF1976D2),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Atualizar',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Estatísticas
                    _buildStatisticsCard(),
                    const SizedBox(height: 16),
                    
                    // Inspeções
                    _buildSectionTitle('Inspeções ($_totalInspections)'),
                    const SizedBox(height: 8),
                    _buildInspectionsTable(),
                    const SizedBox(height: 24),
                    
                    // Estabelecimentos
                    _buildSectionTitle('Estabelecimentos ($_totalEstablishments)'),
                    const SizedBox(height: 8),
                    _buildEstablishmentsTable(),
                    const SizedBox(height: 24),
                    
                    // Categorias de Estabelecimento
                    _buildSectionTitle('Categorias de Estabelecimento ($_totalCategorias)'),
                    const SizedBox(height: 8),
                    _buildCategoriasTable(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStatisticsCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Estatísticas',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildStatRow('Total de Inspeções', '$_totalInspections', Colors.blue),
            _buildStatRow('Sincronizadas', '$_syncedInspections', Colors.green),
            _buildStatRow('Pendentes', '$_pendingInspections', Colors.orange),
            const Divider(height: 24),
            _buildStatRow('Total de Estabelecimentos', '$_totalEstablishments', Colors.purple),
            _buildStatRow('Sincronizados', '$_syncedEstablishments', Colors.green),
            const Divider(height: 24),
            _buildStatRow('Total de Categorias', '$_totalCategorias', Colors.teal),
            _buildStatRow('Sincronizadas', '$_syncedCategorias', Colors.green),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 14),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Color(0xFF2E2E2E),
      ),
    );
  }

  Widget _buildInspectionsTable() {
    if (_inspections.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(
            child: Text(
              'Nenhuma inspeção no banco local',
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ),
      );
    }

    return Card(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: const [
            DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Título', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('ID Local', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('ID Servidor', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Sincronizado', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Data Agendada', style: TextStyle(fontWeight: FontWeight.bold))),
          ],
          rows: _inspections.take(50).map((inspection) {
            return DataRow(
              cells: [
                DataCell(
                  Icon(
                    inspection.isSynced ? Icons.check_circle : Icons.sync,
                    color: inspection.isSynced ? Colors.green : Colors.orange,
                    size: 20,
                  ),
                ),
                DataCell(
                  SizedBox(
                    width: 200,
                    child: Text(
                      inspection.titulo,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                DataCell(Text(inspection.statusText)),
                DataCell(
                  SizedBox(
                    width: 100,
                    child: Text(
                      '${inspection.id.substring(0, 8)}...',
                      style: const TextStyle(fontSize: 11),
                    ),
                  ),
                ),
                DataCell(
                  SizedBox(
                    width: 100,
                    child: Text(
                      inspection.serverId != null 
                          ? '${inspection.serverId!.substring(0, 8)}...'
                          : '-',
                      style: const TextStyle(fontSize: 11),
                    ),
                  ),
                ),
                DataCell(
                  Text(
                    inspection.isSynced ? 'Sim' : 'Não',
                    style: TextStyle(
                      color: inspection.isSynced ? Colors.green : Colors.orange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                DataCell(
                  Text(
                    '${inspection.dataAgendada.day}/${inspection.dataAgendada.month}/${inspection.dataAgendada.year}',
                    style: const TextStyle(fontSize: 11),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildEstablishmentsTable() {
    if (_establishments.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(
            child: Text(
              'Nenhum estabelecimento no banco local',
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ),
      );
    }

    return Card(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: const [
            DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Nome', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Tipo', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('ID Local', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('ID Servidor', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Sincronizado', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Endereço', style: TextStyle(fontWeight: FontWeight.bold))),
          ],
          rows: _establishments.take(50).map((establishment) {
            return DataRow(
              cells: [
                DataCell(
                  Icon(
                    establishment.isSynced ? Icons.check_circle : Icons.sync,
                    color: establishment.isSynced ? Colors.green : Colors.orange,
                    size: 20,
                  ),
                ),
                DataCell(
                  SizedBox(
                    width: 200,
                    child: Text(
                      establishment.nome,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                DataCell(Text(establishment.tipoText)),
                DataCell(
                  SizedBox(
                    width: 100,
                    child: Text(
                      '${establishment.id.substring(0, 8)}...',
                      style: const TextStyle(fontSize: 11),
                    ),
                  ),
                ),
                DataCell(
                  SizedBox(
                    width: 100,
                    child: Text(
                      establishment.serverId != null 
                          ? '${establishment.serverId!.substring(0, 8)}...'
                          : '-',
                      style: const TextStyle(fontSize: 11),
                    ),
                  ),
                ),
                DataCell(
                  Text(
                    establishment.isSynced ? 'Sim' : 'Não',
                    style: TextStyle(
                      color: establishment.isSynced ? Colors.green : Colors.orange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                DataCell(
                  SizedBox(
                    width: 200,
                    child: Text(
                      establishment.endereco.isNotEmpty 
                          ? establishment.endereco
                          : '-',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11),
                    ),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildCategoriasTable() {
    if (_categorias.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(
            child: Text(
              'Nenhuma categoria no banco local',
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ),
      );
    }

    return Card(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: const [
            DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Nome', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Código', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('ID Local', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('ID Servidor', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Ativo', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Ordem', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Sincronizado', style: TextStyle(fontWeight: FontWeight.bold))),
          ],
          rows: _categorias.take(50).map((categoria) {
            return DataRow(
              cells: [
                DataCell(
                  Icon(
                    categoria.isSynced ? Icons.check_circle : Icons.sync,
                    color: categoria.isSynced ? Colors.green : Colors.orange,
                    size: 20,
                  ),
                ),
                DataCell(
                  SizedBox(
                    width: 150,
                    child: Text(
                      categoria.nome,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                DataCell(Text(categoria.codigo)),
                DataCell(
                  SizedBox(
                    width: 100,
                    child: Text(
                      '${categoria.id.substring(0, 8)}...',
                      style: const TextStyle(fontSize: 11),
                    ),
                  ),
                ),
                DataCell(
                  SizedBox(
                    width: 100,
                    child: Text(
                      categoria.serverId != null 
                          ? '${categoria.serverId!.substring(0, 8)}...'
                          : '-',
                      style: const TextStyle(fontSize: 11),
                    ),
                  ),
                ),
                DataCell(
                  Text(
                    categoria.ativo ? 'Sim' : 'Não',
                    style: TextStyle(
                      color: categoria.ativo ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                DataCell(Text('${categoria.ordem}')),
                DataCell(
                  Text(
                    categoria.isSynced ? 'Sim' : 'Não',
                    style: TextStyle(
                      color: categoria.isSynced ? Colors.green : Colors.orange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}
