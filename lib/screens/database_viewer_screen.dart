import 'package:flutter/material.dart';
import 'package:inspecao/models/inspection.dart';
import 'package:inspecao/models/establishment.dart';
import 'package:inspecao/services/database_service.dart';
import 'package:inspecao/services/data_service.dart';
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
  final _dataService = DataService();
  
  List<Inspection> _inspections = [];
  List<Establishment> _establishments = [];
  List<db.CategoriasEstabelecimentoData> _categorias = [];
  List<db.Equipe> _equipes = [];
  List<db.EquipeMembro> _equipeMembros = [];
  List<db.Checklist> _checklists = [];
  List<db.SecoesChecklistData> _secoes = [];
  List<db.ItensChecklistData> _itens = [];
  List<db.OpcoesItemChecklistData> _opcoes = [];
  
  bool _isLoading = true;
  bool _isSyncing = false;
  
  // Paginação
  static const int _itemsPerPage = 10;
  int _currentPageInspections = 0;
  int _currentPageEstablishments = 0;
  int _currentPageCategorias = 0;
  int _currentPageEquipes = 0;
  int _currentPageChecklists = 0;
  int _currentPageSecoes = 0;
  int _currentPageItens = 0;
  int _currentPageOpcoes = 0;
  
  // Estatísticas
  int _totalInspections = 0;
  int _syncedInspections = 0;
  int _pendingInspections = 0;
  int _totalEstablishments = 0;
  int _syncedEstablishments = 0;
  int _totalCategorias = 0;
  int _syncedCategorias = 0;
  int _totalEquipes = 0;
  int _syncedEquipes = 0;
  int _totalEquipeMembros = 0;
  int _totalChecklists = 0;
  int _syncedChecklists = 0;
  int _totalSecoes = 0;
  int _totalItens = 0;
  int _totalOpcoes = 0;

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
      
      // Carregar equipes
      print('📥 [DB Viewer] Carregando equipes...');
      _equipes = await _dbService.getAllEquipes();
      _totalEquipes = _equipes.length;
      _syncedEquipes = _equipes.where((e) => e.isSynced).length;
      print('📊 [DB Viewer] Equipes carregadas: $_totalEquipes (sincronizadas: $_syncedEquipes)');
      
      // Carregar membros de equipe
      print('📥 [DB Viewer] Carregando membros de equipe...');
      _equipeMembros = await _dbService.getAllEquipeMembros();
      _totalEquipeMembros = _equipeMembros.length;
      print('📊 [DB Viewer] Membros de equipe carregados: $_totalEquipeMembros');
      
      // Carregar checklists
      print('📥 [DB Viewer] Carregando checklists...');
      _checklists = await _dbService.getAllChecklists();
      _totalChecklists = _checklists.length;
      _syncedChecklists = _checklists.where((c) => c.isSynced).length;
      print('📊 [DB Viewer] Checklists carregados: $_totalChecklists (sincronizados: $_syncedChecklists)');
      
      // Carregar seções
      print('📥 [DB Viewer] Carregando seções...');
      _secoes = await _dbService.getAllSecoesChecklist();
      _totalSecoes = _secoes.length;
      print('📊 [DB Viewer] Seções carregadas: $_totalSecoes');
      
      // Carregar itens
      print('📥 [DB Viewer] Carregando itens...');
      _itens = await _dbService.getAllItensChecklist();
      _totalItens = _itens.length;
      print('📊 [DB Viewer] Itens carregados: $_totalItens');
      
      // Carregar opções
      print('📥 [DB Viewer] Carregando opções...');
      _opcoes = await _dbService.getAllOpcoesItemChecklist();
      _totalOpcoes = _opcoes.length;
      print('📊 [DB Viewer] Opções carregadas: $_totalOpcoes');
      
    } catch (e, stackTrace) {
      print('❌ [DB Viewer] Erro ao carregar dados do banco: $e');
      print('❌ [DB Viewer] Stack trace: $stackTrace');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
        print('✅ [DB Viewer] Estado atualizado. Total: $_totalInspections inspeções, $_totalEstablishments estabelecimentos, $_totalCategorias categorias, $_totalEquipes equipes, $_totalChecklists checklists');
      }
    }
  }

  Future<void> _syncData() async {
    if (_isSyncing) return;
    
    setState(() => _isSyncing = true);
    
    try {
      // Verificar se há usuário logado
      final user = await _dataService.getCurrentUser();
      if (user == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Você precisa estar logado para sincronizar'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Iniciando sincronização...'),
            backgroundColor: Colors.blue,
            duration: Duration(seconds: 2),
          ),
        );
      }
      
      print('🔄 [DB Viewer] Iniciando sincronização manual...');
      
      // Executar sincronização
      await _dataService.syncInitialData();
      
      print('✅ [DB Viewer] Sincronização concluída');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sincronização concluída com sucesso!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
        
        // Recarregar dados após sincronização
        await _loadData();
      }
    } catch (e) {
      print('❌ [DB Viewer] Erro na sincronização: $e');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro na sincronização: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSyncing = false);
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
            icon: _isSyncing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.sync),
            onPressed: _isSyncing ? null : _syncData,
            tooltip: 'Sincronizar',
          ),
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
                    const SizedBox(height: 24),
                    
                    // Equipes
                    _buildSectionTitle('Equipes ($_totalEquipes)'),
                    const SizedBox(height: 8),
                    _buildEquipesTable(),
                    const SizedBox(height: 24),
                    
                    // Checklists
                    _buildSectionTitle('Checklists ($_totalChecklists)'),
                    const SizedBox(height: 8),
                    _buildChecklistsTable(),
                    const SizedBox(height: 24),
                    
                    // Seções
                    _buildSectionTitle('Seções de Checklist ($_totalSecoes)'),
                    const SizedBox(height: 8),
                    _buildSecoesTable(),
                    const SizedBox(height: 24),
                    
                    // Itens
                    _buildSectionTitle('Itens de Checklist ($_totalItens)'),
                    const SizedBox(height: 8),
                    _buildItensTable(),
                    const SizedBox(height: 24),
                    
                    // Opções
                    _buildSectionTitle('Opções de Itens ($_totalOpcoes)'),
                    const SizedBox(height: 8),
                    _buildOpcoesTable(),
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
            const Divider(height: 24),
            _buildStatRow('Total de Equipes', '$_totalEquipes', Colors.indigo),
            _buildStatRow('Sincronizadas', '$_syncedEquipes', Colors.green),
            const Divider(height: 24),
            _buildStatRow('Total de Checklists', '$_totalChecklists', Colors.deepOrange),
            _buildStatRow('Sincronizados', '$_syncedChecklists', Colors.green),
            const Divider(height: 24),
            _buildStatRow('Total de Seções', '$_totalSecoes', Colors.cyan),
            _buildStatRow('Total de Itens', '$_totalItens', Colors.amber),
            _buildStatRow('Total de Opções', '$_totalOpcoes', Colors.pink),
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

  // Métodos auxiliares de paginação
  List<Inspection> _getPaginatedInspections() {
    final start = _currentPageInspections * _itemsPerPage;
    final end = (start + _itemsPerPage).clamp(0, _inspections.length);
    return _inspections.sublist(start, end);
  }

  List<Establishment> _getPaginatedEstablishments() {
    final start = _currentPageEstablishments * _itemsPerPage;
    final end = (start + _itemsPerPage).clamp(0, _establishments.length);
    return _establishments.sublist(start, end);
  }

  List<db.CategoriasEstabelecimentoData> _getPaginatedCategorias() {
    final start = _currentPageCategorias * _itemsPerPage;
    final end = (start + _itemsPerPage).clamp(0, _categorias.length);
    return _categorias.sublist(start, end);
  }

  List<db.Equipe> _getPaginatedEquipes() {
    final start = _currentPageEquipes * _itemsPerPage;
    final end = (start + _itemsPerPage).clamp(0, _equipes.length);
    return _equipes.sublist(start, end);
  }

  List<db.Checklist> _getPaginatedChecklists() {
    final start = _currentPageChecklists * _itemsPerPage;
    final end = (start + _itemsPerPage).clamp(0, _checklists.length);
    return _checklists.sublist(start, end);
  }

  List<db.SecoesChecklistData> _getPaginatedSecoes() {
    final start = _currentPageSecoes * _itemsPerPage;
    final end = (start + _itemsPerPage).clamp(0, _secoes.length);
    return _secoes.sublist(start, end);
  }

  List<db.ItensChecklistData> _getPaginatedItens() {
    final start = _currentPageItens * _itemsPerPage;
    final end = (start + _itemsPerPage).clamp(0, _itens.length);
    return _itens.sublist(start, end);
  }

  List<db.OpcoesItemChecklistData> _getPaginatedOpcoes() {
    final start = _currentPageOpcoes * _itemsPerPage;
    final end = (start + _itemsPerPage).clamp(0, _opcoes.length);
    return _opcoes.sublist(start, end);
  }

  // Widget auxiliar para controles de paginação
  Widget _buildPaginationControls(String type, int currentPage, int totalItems, Function(int) onPageChanged) {
    final totalPages = (totalItems / _itemsPerPage).ceil();
    if (totalPages <= 1) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: currentPage > 0 ? () => onPageChanged(currentPage - 1) : null,
          ),
          Text(
            'Página ${currentPage + 1} de $totalPages (${totalItems} itens)',
            style: const TextStyle(fontSize: 12),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: currentPage < totalPages - 1 ? () => onPageChanged(currentPage + 1) : null,
          ),
        ],
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

    final paginated = _getPaginatedInspections();

    return Column(
      children: [
        _buildPaginationControls('inspections', _currentPageInspections, _inspections.length, (page) {
          setState(() => _currentPageInspections = page);
        }),
        Card(
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
              rows: paginated.map((inspection) {
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
        ),
      ],
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

    final paginated = _getPaginatedEstablishments();

    return Column(
      children: [
        _buildPaginationControls('establishments', _currentPageEstablishments, _establishments.length, (page) {
          setState(() => _currentPageEstablishments = page);
        }),
        Card(
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
              rows: paginated.map((establishment) {
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
        ),
      ],
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

    final paginated = _getPaginatedCategorias();

    return Column(
      children: [
        _buildPaginationControls('categorias', _currentPageCategorias, _categorias.length, (page) {
          setState(() => _currentPageCategorias = page);
        }),
        Card(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: const [
                DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Código', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Nome', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('ID Local', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('ID Servidor', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Ordem', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Sincronizado', style: TextStyle(fontWeight: FontWeight.bold))),
              ],
              rows: paginated.map((categoria) {
                return DataRow(
                  cells: [
                    DataCell(
                      Icon(
                        categoria.isSynced ? Icons.check_circle : Icons.sync,
                        color: categoria.isSynced ? Colors.green : Colors.orange,
                        size: 20,
                      ),
                    ),
                    DataCell(Text(categoria.codigo)),
                    DataCell(
                      SizedBox(
                        width: 200,
                        child: Text(
                          categoria.nome,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
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
        ),
      ],
    );
  }

  // Novas tabelas
  Widget _buildEquipesTable() {
    if (_equipes.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(
            child: Text(
              'Nenhuma equipe no banco local',
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ),
      );
    }

    final paginated = _getPaginatedEquipes();

    return Column(
      children: [
        _buildPaginationControls('equipes', _currentPageEquipes, _equipes.length, (page) {
          setState(() => _currentPageEquipes = page);
        }),
        Card(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: const [
                DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Código', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Nome', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Supervisor', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Ativo', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Sincronizado', style: TextStyle(fontWeight: FontWeight.bold))),
              ],
              rows: paginated.map((equipe) {
                return DataRow(
                  cells: [
                    DataCell(
                      Icon(
                        equipe.isSynced ? Icons.check_circle : Icons.sync,
                        color: equipe.isSynced ? Colors.green : Colors.orange,
                        size: 20,
                      ),
                    ),
                    DataCell(Text(equipe.codigo)),
                    DataCell(
                      SizedBox(
                        width: 200,
                        child: Text(
                          equipe.nome,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    DataCell(Text(equipe.supervisorNome ?? '-')),
                    DataCell(
                      Text(
                        equipe.ativo ? 'Sim' : 'Não',
                        style: TextStyle(
                          color: equipe.ativo ? Colors.green : Colors.red,
                        ),
                      ),
                    ),
                    DataCell(
                      Text(
                        equipe.isSynced ? 'Sim' : 'Não',
                        style: TextStyle(
                          color: equipe.isSynced ? Colors.green : Colors.orange,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChecklistsTable() {
    if (_checklists.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(
            child: Text(
              'Nenhum checklist no banco local',
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ),
      );
    }

    final paginated = _getPaginatedChecklists();

    return Column(
      children: [
        _buildPaginationControls('checklists', _currentPageChecklists, _checklists.length, (page) {
          setState(() => _currentPageChecklists = page);
        }),
        Card(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: const [
                DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Nome', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Categoria', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Público', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Ativo', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Sincronizado', style: TextStyle(fontWeight: FontWeight.bold))),
              ],
              rows: paginated.map((checklist) {
                return DataRow(
                  cells: [
                    DataCell(
                      Icon(
                        checklist.isSynced ? Icons.check_circle : Icons.sync,
                        color: checklist.isSynced ? Colors.green : Colors.orange,
                        size: 20,
                      ),
                    ),
                    DataCell(
                      SizedBox(
                        width: 200,
                        child: Text(
                          checklist.nome,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    DataCell(Text(checklist.categoriaNome ?? '-')),
                    DataCell(
                      Text(
                        checklist.publico ? 'Sim' : 'Não',
                        style: TextStyle(
                          color: checklist.publico ? Colors.green : Colors.grey,
                        ),
                      ),
                    ),
                    DataCell(
                      Text(
                        checklist.ativo ? 'Sim' : 'Não',
                        style: TextStyle(
                          color: checklist.ativo ? Colors.green : Colors.red,
                        ),
                      ),
                    ),
                    DataCell(
                      Text(
                        checklist.isSynced ? 'Sim' : 'Não',
                        style: TextStyle(
                          color: checklist.isSynced ? Colors.green : Colors.orange,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSecoesTable() {
    if (_secoes.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(
            child: Text(
              'Nenhuma seção no banco local',
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ),
      );
    }

    final paginated = _getPaginatedSecoes();

    return Column(
      children: [
        _buildPaginationControls('secoes', _currentPageSecoes, _secoes.length, (page) {
          setState(() => _currentPageSecoes = page);
        }),
        Card(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: const [
                DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Título', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Checklist ID', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Ordem', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Ativo', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Sincronizado', style: TextStyle(fontWeight: FontWeight.bold))),
              ],
              rows: paginated.map((secao) {
                return DataRow(
                  cells: [
                    DataCell(
                      Icon(
                        secao.isSynced ? Icons.check_circle : Icons.sync,
                        color: secao.isSynced ? Colors.green : Colors.orange,
                        size: 20,
                      ),
                    ),
                    DataCell(
                      SizedBox(
                        width: 200,
                        child: Text(
                          secao.titulo,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    DataCell(
                      SizedBox(
                        width: 100,
                        child: Text(
                          '${secao.checklistId.substring(0, 8)}...',
                          style: const TextStyle(fontSize: 11),
                        ),
                      ),
                    ),
                    DataCell(Text('${secao.ordem}')),
                    DataCell(
                      Text(
                        secao.ativo ? 'Sim' : 'Não',
                        style: TextStyle(
                          color: secao.ativo ? Colors.green : Colors.red,
                        ),
                      ),
                    ),
                    DataCell(
                      Text(
                        secao.isSynced ? 'Sim' : 'Não',
                        style: TextStyle(
                          color: secao.isSynced ? Colors.green : Colors.orange,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildItensTable() {
    if (_itens.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(
            child: Text(
              'Nenhum item no banco local',
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ),
      );
    }

    final paginated = _getPaginatedItens();

    return Column(
      children: [
        _buildPaginationControls('itens', _currentPageItens, _itens.length, (page) {
          setState(() => _currentPageItens = page);
        }),
        Card(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: const [
                DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Rótulo', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Tipo', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Ordem', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Obrigatório', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Sincronizado', style: TextStyle(fontWeight: FontWeight.bold))),
              ],
              rows: paginated.map((item) {
                return DataRow(
                  cells: [
                    DataCell(
                      Icon(
                        item.isSynced ? Icons.check_circle : Icons.sync,
                        color: item.isSynced ? Colors.green : Colors.orange,
                        size: 20,
                      ),
                    ),
                    DataCell(
                      SizedBox(
                        width: 200,
                        child: Text(
                          item.rotulo,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    DataCell(Text(item.tipo)),
                    DataCell(Text('${item.ordem}')),
                    DataCell(
                      Text(
                        item.obrigatorio ? 'Sim' : 'Não',
                        style: TextStyle(
                          color: item.obrigatorio ? Colors.red : Colors.grey,
                        ),
                      ),
                    ),
                    DataCell(
                      Text(
                        item.isSynced ? 'Sim' : 'Não',
                        style: TextStyle(
                          color: item.isSynced ? Colors.green : Colors.orange,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOpcoesTable() {
    if (_opcoes.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(
            child: Text(
              'Nenhuma opção no banco local',
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ),
      );
    }

    final paginated = _getPaginatedOpcoes();

    return Column(
      children: [
        _buildPaginationControls('opcoes', _currentPageOpcoes, _opcoes.length, (page) {
          setState(() => _currentPageOpcoes = page);
        }),
        Card(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: const [
                DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Texto', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Valor', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Ordem', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Pontuação', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Sincronizado', style: TextStyle(fontWeight: FontWeight.bold))),
              ],
              rows: paginated.map((opcao) {
                return DataRow(
                  cells: [
                    DataCell(
                      Icon(
                        opcao.isSynced ? Icons.check_circle : Icons.sync,
                        color: opcao.isSynced ? Colors.green : Colors.orange,
                        size: 20,
                      ),
                    ),
                    DataCell(
                      SizedBox(
                        width: 200,
                        child: Text(
                          opcao.texto,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    DataCell(Text(opcao.valor ?? '-')),
                    DataCell(Text('${opcao.ordem}')),
                    DataCell(Text(opcao.pontuacao?.toString() ?? '-')),
                    DataCell(
                      Text(
                        opcao.isSynced ? 'Sim' : 'Não',
                        style: TextStyle(
                          color: opcao.isSynced ? Colors.green : Colors.orange,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }
}
