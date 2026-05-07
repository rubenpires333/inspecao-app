import 'package:inspecao/database/database.dart' as db;
import 'package:inspecao/models/inspection.dart';
import 'package:inspecao/models/inspection_item.dart';
import 'package:inspecao/models/inspector.dart';
import 'package:inspecao/models/establishment.dart';
import 'package:inspecao/models/checklist_secao.dart';
import 'package:drift/drift.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:uuid/uuid.dart';

/// Serviço de banco de dados local (SQLite/Drift)
/// Implementa estratégia offline-first: dados locais são a fonte de verdade
/// Sincronização com servidor acontece em background
class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  late final db.AppDatabase _database;

  /// Inicializa o banco de dados
  Future<void> initialize() async {
    if (!_isInitialized) {
      print('🔄 [DatabaseService] Criando nova instância do banco de dados...');
      _database = db.AppDatabase();
      _isInitialized = true;
      print('✅ [DatabaseService] Banco de dados inicializado');
    } else {
      print('ℹ️ [DatabaseService] Banco de dados já estava inicializado');
    }
  }
  
  bool _isInitialized = false;

  /// Fecha a conexão com o banco
  Future<void> close() async {
    await _database.close();
  }

  // ============================================================================
  // CONVERSÃO: Inspection (Modelo) <-> Inspecoe (Banco)
  // ============================================================================

  /// Converte Inspection (modelo) para InspecoesCompanion (banco)
  db.InspecoesCompanion _inspectionToDb(Inspection inspection) {
    // Calcular hash da versão para detecção de conflitos
    final versionHash = _calculateVersionHash(inspection);

    return db.InspecoesCompanion(
      id: Value(inspection.id),
      numero: Value(inspection.serverId), // Usar serverId como número
      titulo: Value(inspection.titulo),
      descricao: Value(inspection.descricao),
      tipo: Value(inspection.tipo),
      status: Value(inspection.status),
      dataAgendada: Value(inspection.dataAgendada),
      dataInicio: Value(inspection.dataInicio),
      dataConclusao: Value(inspection.dataConclusao),
      endereco: Value(inspection.endereco),
      latitude: Value(inspection.latitude),
      longitude: Value(inspection.longitude),
      observacoes: Value(inspection.observacoes),
      establishmentId: Value(inspection.establishmentId),
      checklistId: Value(inspection.checklistId),
      inspectorId: Value(inspection.inspectorId),
      equipeId: Value(inspection.equipeId),
      scoreConformidade: Value(null), // TODO: calcular scores
      scoreNaoConformidade: Value(null),
      isSynced: Value(inspection.isSynced),
      createdAt: Value(inspection.createdAt),
      updatedAt: Value(inspection.updatedAt),
      serverId: Value(inspection.serverId),
      deviceId: Value(null), // TODO: obter device ID
      versionHash: Value(versionHash),
      isTemplate: Value(inspection.isTemplate),
      isDeleted: const Value(false),
    );
  }

  /// Converte Inspecoe (banco) para Inspection (modelo)
  Future<Inspection> _dbToInspection(db.Inspecoe dbInspection) async {
    // Buscar respostas/itens da inspeção
    final respostas = await _database.getRespostasByInspecao(dbInspection.id);
    final itens = await Future.wait(respostas.map((r) => _respostaToInspectionItem(r)));

    // Buscar anexos/fotos
    final anexos = await _database.getAnexosByInspecao(dbInspection.id);
    final fotos = anexos.map((a) => a.caminhoLocal).toList();

    final equipe = await _localEquipeInspectors(dbInspection.equipeId);

    return Inspection(
      id: dbInspection.id,
      titulo: dbInspection.titulo,
      descricao: dbInspection.descricao,
      tipo: dbInspection.tipo,
      status: dbInspection.status,
      dataAgendada: dbInspection.dataAgendada,
      dataInicio: dbInspection.dataInicio,
      dataConclusao: dbInspection.dataConclusao,
      endereco: dbInspection.endereco,
      latitude: dbInspection.latitude,
      longitude: dbInspection.longitude,
      equipe: equipe,
      itens: itens,
      observacoes: dbInspection.observacoes,
      fotos: fotos,
      establishmentId: dbInspection.establishmentId,
      inspectorId: dbInspection.inspectorId,
      checklistId: dbInspection.checklistId,
      equipeId: dbInspection.equipeId,
      isTemplate: dbInspection.isTemplate,
      isSynced: dbInspection.isSynced,
      createdAt: dbInspection.createdAt,
      updatedAt: dbInspection.updatedAt,
      serverId: dbInspection.serverId,
    );
  }

  Future<List<Inspector>> _localEquipeInspectors(String? equipeId) async {
    if (equipeId == null || equipeId.trim().isEmpty) return [];
    final membros =
        await _database.getMembrosAtivosByEquipe(equipeId.trim());
    return membros
        .map(
          (m) => Inspector(
            id: m.usuarioId,
            nome: (m.usuarioNome ?? '').trim(),
            email: (m.usuarioEmail ?? '').trim(),
            telefone: '',
            cargo: InspectorRole.tecnico,
            especialidades: const [],
            ativo: m.ativo,
          ),
        )
        .toList();
  }

  /// Mesmo formato aproximado da API para preencher o cartão de equipa offline.
  Future<Map<String, dynamic>?> getEquipeCompletaSnapshotFromLocalDb(
      String equipeId) async {
    await initialize();
    final id = equipeId.trim();
    if (id.isEmpty) return null;
    final eq = await _database.getEquipeById(id);
    if (eq == null) return null;
    final membrosDb = await _database.getMembrosAtivosByEquipe(id);
    final membros = membrosDb
        .map(
          (m) => <String, dynamic>{
            'id': m.usuarioId,
            'usuarioId': m.usuarioId,
            'usuarioNome': m.usuarioNome,
            'usuarioEmail': m.usuarioEmail,
            'nome': m.usuarioNome,
            'email': m.usuarioEmail,
          },
        )
        .toList();
    return <String, dynamic>{
      'nome': eq.nome,
      'codigo': eq.codigo,
      'supervisorNome': eq.supervisorNome ?? '',
      'membros': membros,
    };
  }

  /// Converte RespostasInspecaoData para InspectionItem
  Future<InspectionItem> _respostaToInspectionItem(db.RespostasInspecaoData resposta) async {
    // Buscar fotos/anexos relacionados a esta resposta
    final anexos = await _database.getAnexosByResposta(resposta.id);
    final fotos = anexos.map((a) => a.caminhoLocal).toList();

    return InspectionItem(
      id: resposta.id,
      descricao: resposta.itemDescricao,
      categoria: resposta.categoria,
      status: resposta.status,
      observacao: resposta.observacoes,
      fotos: fotos,
      ordem: resposta.ordem,
      obrigatorio: resposta.obrigatorio,
    );
  }

  /// Calcula hash da versão para detecção de conflitos
  String _calculateVersionHash(Inspection inspection) {
    final json = inspection.toJson();
    // Remover campos que não devem afetar o hash
    json.remove('isSynced');
    json.remove('createdAt');
    json.remove('updatedAt');
    json.remove('versionHash');
    
    final jsonString = jsonEncode(json);
    final bytes = utf8.encode(jsonString);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // ============================================================================
  // MÉTODOS DE INSPEÇÕES
  // ============================================================================

  /// Busca todas as inspeções do banco local
  Future<List<Inspection>> getInspections() async {
    try {
      final dbInspections = await _database.getAllInspecoes();
      print('📊 Total de inspeções no banco: ${dbInspections.length}');
      final inspections = <Inspection>[];
      
      for (final dbInspection in dbInspections) {
        // Ignorar inspeções deletadas
        if (dbInspection.isDeleted) continue;
        
        final inspection = await _dbToInspection(dbInspection);
        inspections.add(inspection);
      }
      
      print('📊 Inspeções válidas (não deletadas): ${inspections.length}');
      print('📊 Inspeções sincronizadas: ${inspections.where((i) => i.isSynced).length}');
      return inspections;
    } catch (e) {
      print('Erro ao buscar inspeções do banco local: $e');
      return [];
    }
  }

  /// Busca inspeção por ID
  Future<Inspection?> getInspectionById(String id) async {
    try {
      final dbInspection = await _database.getInspecaoById(id);
      if (dbInspection == null || dbInspection.isDeleted) return null;
      return await _dbToInspection(dbInspection);
    } catch (e) {
      print('Erro ao buscar inspeção por ID: $e');
      return null;
    }
  }

  /// Busca inspeções pendentes de sincronização
  Future<List<Inspection>> getPendingInspections() async {
    try {
      final dbInspections = await _database.getInspecoesPendentes();
      final inspections = <Inspection>[];
      
      for (final dbInspection in dbInspections) {
        if (dbInspection.isDeleted) continue;
        final inspection = await _dbToInspection(dbInspection);
        inspections.add(inspection);
      }
      
      return inspections;
    } catch (e) {
      print('Erro ao buscar inspeções pendentes: $e');
      return [];
    }
  }

  /// Busca inspeções por status
  Future<List<Inspection>> getInspectionsByStatus(InspectionStatus status) async {
    try {
      final dbInspections = await _database.getInspecoesByStatus(status);
      final inspections = <Inspection>[];
      
      for (final dbInspection in dbInspections) {
        if (dbInspection.isDeleted) continue;
        final inspection = await _dbToInspection(dbInspection);
        inspections.add(inspection);
      }
      
      return inspections;
    } catch (e) {
      print('Erro ao buscar inspeções por status: $e');
      return [];
    }
  }

  /// Salva inspeção no banco local (cria ou atualiza)
  Future<void> saveInspection(Inspection inspection) async {
    try {
      // Verificar se inspeção já existe
      final existing = await getInspectionById(inspection.id);
      
      final companion = _inspectionToDb(inspection);
      
      if (existing != null) {
        // Se já existe, fazer update
        await _database.updateInspecao(companion);
      } else {
        // Se não existe, fazer insert
        await _database.insertInspecao(companion);
      }
      
      // Lista da API não inclui itens; não substituir respostas locais por lista vazia
      if (inspection.itens.isNotEmpty) {
        await _saveInspectionItems(inspection.id, inspection.itens);
      }
    } catch (e) {
      print('Erro ao salvar inspeção no banco local: $e');
      rethrow;
    }
  }

  /// Salva múltiplas inspeções
  Future<void> saveInspections(List<Inspection> inspections) async {
    try {
      for (final inspection in inspections) {
        await saveInspection(inspection);
      }
    } catch (e) {
      print('Erro ao salvar inspeções no banco local: $e');
      rethrow;
    }
  }

  /// Quando o servidor devolve lista vazia de inspeções ativas, remove o espelho antigo
  /// (evita mostrar inspeções de outra sessão). Preserva rascunhos offline (`serverId` nulo).
  Future<int> softDeleteServerMirroredInspections() async {
    try {
      final n = await _database.softDeleteInspecoesEspelhadasDoServidor();
      print(
          '🗑️ Espelho servidor: $n inspeção(ões) com server_id foram marcadas como removidas');
      return n;
    } catch (e) {
      print('Erro ao limpar espelho de inspeções do servidor: $e');
      rethrow;
    }
  }

  /// Remove do espelho local inspeções com `server_id` que não vieram na
  /// última lista de ativas devolvida pelo servidor.
  Future<int> softDeleteServerMirroredInspectionsNotIn(List<String> activeServerIds) async {
    try {
      final n = await _database.softDeleteInspecoesEspelhadasDoServidorNotIn(activeServerIds);
      print(
          '🧹 Espelho servidor: $n inspeção(ões) fora da lista ativa foram marcadas como removidas');
      return n;
    } catch (e) {
      print('Erro ao limpar espelho de inspeções fora da lista ativa: $e');
      rethrow;
    }
  }

  /// Atualiza inspeção no banco local
  Future<void> updateInspection(Inspection inspection) async {
    try {
      final companion = _inspectionToDb(inspection.copyWith(
        updatedAt: DateTime.now(),
      ));
      await _database.updateInspecao(companion);
      
      if (inspection.itens.isNotEmpty) {
        await _saveInspectionItems(inspection.id, inspection.itens);
      }
    } catch (e) {
      print('Erro ao atualizar inspeção no banco local: $e');
      rethrow;
    }
  }

  /// Deleta inspeção (soft delete - marca como deletada)
  Future<void> deleteInspection(String id) async {
    try {
      final inspection = await getInspectionById(id);
      if (inspection != null) {
        // Soft delete: marca como deletada
        final companion = db.InspecoesCompanion(
          id: Value(id),
          isDeleted: const Value(true),
          updatedAt: Value(DateTime.now()),
        );
        await _database.updateInspecao(companion);
      }
    } catch (e) {
      print('Erro ao deletar inspeção: $e');
      rethrow;
    }
  }

  /// Salva itens/respostas da inspeção
  Future<void> _saveInspectionItems(String inspecaoId, List<InspectionItem> itens) async {
    try {
      // Deletar itens antigos
      await _database.deleteRespostasByInspecao(inspecaoId);
      
      // Inserir novos itens
      for (int i = 0; i < itens.length; i++) {
        final item = itens[i];
        final resposta = db.RespostasInspecaoCompanion(
          id: Value(item.id),
          inspecaoId: Value(inspecaoId),
          itemChecklistId: Value(item.id),
          itemDescricao: Value(item.descricao),
          categoria: Value(item.categoria),
          status: Value(item.status),
          opcaoId: Value(item.opcaoSelecionadaId),
          valorTexto: Value(item.valorTexto),
          valorNumero: Value(item.valorNumero),
          valorData: Value(item.valorData),
          valorRating: const Value(null),
          valorBooleano: const Value(null),
          observacoes: Value(item.observacao),
          ordem: Value(i),
          obrigatorio: Value(item.obrigatorio),
          createdAt: Value(DateTime.now()),
          updatedAt: Value(DateTime.now()),
          isSynced: const Value(false),
        );
        await _database.insertResposta(resposta);
        
        // Salvar fotos como anexos
        for (final fotoPath in item.fotos) {
          final anexo = db.AnexosInspecaoCompanion(
            id: Value('${item.id}_${item.fotos.indexOf(fotoPath)}'),
            inspecaoId: Value(inspecaoId),
            respostaId: Value(item.id),
            nomeArquivo: Value(fotoPath.split('/').last),
            tipoMime: Value('image/jpeg'),
            tamanho: const Value(0), // TODO: obter tamanho real
            caminhoLocal: Value(fotoPath),
            urlServidor: const Value(null),
            isSynced: const Value(false),
            createdAt: Value(DateTime.now()),
            updatedAt: Value(DateTime.now()),
          );
          await _database.insertAnexo(anexo);
        }
      }
    } catch (e) {
      print('Erro ao salvar itens da inspeção: $e');
      rethrow;
    }
  }

  /// Marca inspeção como sincronizada
  Future<void> markInspectionAsSynced(String id, String? serverId) async {
    try {
      // Buscar inspeção existente primeiro
      final existingInspection = await getInspectionById(id);
      if (existingInspection == null) {
        print('⚠️ Inspeção $id não encontrada para marcar como sincronizada');
        return;
      }
      
      // Criar companion com todos os dados existentes, atualizando apenas os campos necessários
      final companion = _inspectionToDb(existingInspection.copyWith(
        isSynced: true,
        serverId: serverId ?? existingInspection.serverId,
        updatedAt: DateTime.now(),
      ));
      
      await _database.updateInspecao(companion);
      
      // Marcar respostas como sincronizadas
      final respostas = await _database.getRespostasByInspecao(id);
      for (final resposta in respostas) {
        // Criar companion completo com todos os campos obrigatórios
        final respostaCompanion = db.RespostasInspecaoCompanion(
          id: Value(resposta.id),
          inspecaoId: Value(resposta.inspecaoId),
          itemChecklistId: Value(resposta.itemChecklistId),
          itemDescricao: Value(resposta.itemDescricao),
          categoria: Value(resposta.categoria),
          status: Value(resposta.status),
          opcaoId: Value(resposta.opcaoId),
          valorTexto: Value(resposta.valorTexto),
          valorNumero: Value(resposta.valorNumero),
          valorData: Value(resposta.valorData),
          valorRating: Value(resposta.valorRating),
          valorBooleano: Value(resposta.valorBooleano),
          latitude: Value(resposta.latitude),
          longitude: Value(resposta.longitude),
          gpsTimestamp: Value(resposta.gpsTimestamp),
          observacoes: Value(resposta.observacoes),
          ordem: Value(resposta.ordem),
          obrigatorio: Value(resposta.obrigatorio),
          isSynced: const Value(true),
          createdAt: Value(resposta.createdAt),
          updatedAt: Value(DateTime.now()),
        );
        await _database.updateResposta(respostaCompanion);
      }
    } catch (e) {
      print('Erro ao marcar inspeção como sincronizada: $e');
      rethrow;
    }
  }

  // ============================================================================
  // MÉTODOS DE ESTABELECIMENTOS
  // ============================================================================

  /// Salva estabelecimento no banco local
  Future<void> saveEstablishment(Establishment establishment) async {
    try {
      final companion = db.EstabelecimentosCompanion(
        id: Value(establishment.id),
        codigo: const Value(null), // Establishment não tem codigo no modelo
        nome: Value(establishment.nome),
        descricao: Value(establishment.descricao),
        tipo: Value(establishment.tipo),
        endereco: Value(establishment.endereco),
        latitude: Value(establishment.latitude),
        longitude: Value(establishment.longitude),
        telefone: Value(establishment.telefone),
        email: Value(establishment.email),
        responsavel: Value(establishment.responsavel),
        observacoes: Value(establishment.observacoes),
        categoriaEstabelecimentoId: Value(establishment.categoriaEstabelecimentoId),
        categoriaEstabelecimentoNome: Value(establishment.categoriaEstabelecimentoNome),
        isSynced: Value(establishment.isSynced),
        dataSincronizacao: Value(establishment.isSynced ? DateTime.now() : null),
        createdAt: Value(establishment.createdAt),
        updatedAt: Value(establishment.updatedAt),
        serverId: Value(establishment.serverId ?? establishment.id),
      );
      await _database.insertEstabelecimento(companion);
    } catch (e) {
      print('Erro ao salvar estabelecimento no banco local: $e');
      rethrow;
    }
  }

  /// Salva categoria de estabelecimento no banco local
  Future<void> saveCategoriaEstabelecimento(db.CategoriasEstabelecimentoCompanion categoria) async {
    try {
      await _database.insertCategoriaEstabelecimento(categoria);
    } catch (e) {
      print('Erro ao salvar categoria de estabelecimento no banco local: $e');
      rethrow;
    }
  }

  /// Busca todas as categorias de estabelecimento
  Future<List<db.CategoriasEstabelecimentoData>> getCategoriasEstabelecimento() async {
    try {
      final categorias = await _database.getAllCategoriasEstabelecimento();
      print('📊 Total de categorias no banco: ${categorias.length}');
      print('📊 Categorias sincronizadas: ${categorias.where((c) => c.isSynced).length}');
      return categorias;
    } catch (e) {
      print('Erro ao buscar categorias de estabelecimento do banco local: $e');
      return [];
    }
  }

  /// Busca categoria de estabelecimento por ID
  Future<db.CategoriasEstabelecimentoData?> getCategoriaEstabelecimentoById(String id) async {
    try {
      return await _database.getCategoriaEstabelecimentoById(id);
    } catch (e) {
      print('Erro ao buscar categoria de estabelecimento por ID: $e');
      return null;
    }
  }

  /// Salva equipe no banco local
  Future<void> saveEquipe(db.EquipesCompanion equipe) async {
    try {
      await _database.insertEquipe(equipe);
    } catch (e) {
      print('Erro ao salvar equipe no banco local: $e');
      rethrow;
    }
  }

  /// Salva membro de equipe no banco local
  Future<void> saveEquipeMembro(db.EquipeMembrosCompanion membro) async {
    try {
      await _database.insertEquipeMembro(membro);
    } catch (e) {
      print('Erro ao salvar membro de equipe no banco local: $e');
      rethrow;
    }
  }

  /// Salva checklist no banco local
  Future<void> saveChecklist(db.ChecklistsCompanion checklist) async {
    try {
      await _database.insertChecklist(checklist);
    } catch (e) {
      print('Erro ao salvar checklist no banco local: $e');
      rethrow;
    }
  }

  /// Salva seção de checklist no banco local
  Future<void> saveSecaoChecklist(db.SecoesChecklistCompanion secao) async {
    try {
      await _database.insertSecaoChecklist(secao);
    } catch (e) {
      print('Erro ao salvar seção de checklist no banco local: $e');
      rethrow;
    }
  }

  /// Salva item de checklist no banco local
  Future<void> saveItemChecklist(db.ItensChecklistCompanion item) async {
    try {
      await _database.insertItemChecklist(item);
    } catch (e) {
      print('Erro ao salvar item de checklist no banco local: $e');
      rethrow;
    }
  }

  /// Salva opção de item de checklist no banco local
  Future<void> saveOpcaoItemChecklist(db.OpcoesItemChecklistCompanion opcao) async {
    try {
      await _database.insertOpcaoItemChecklist(opcao);
    } catch (e) {
      print('Erro ao salvar opção de item de checklist no banco local: $e');
      rethrow;
    }
  }

  /// Busca estabelecimento por ID
  Future<Establishment?> getEstablishmentById(String id) async {
    try {
      final dbEstabelecimento = await _database.getEstabelecimentoById(id);
      if (dbEstabelecimento == null) return null;
      
      return Establishment(
        id: dbEstabelecimento.id,
        nome: dbEstabelecimento.nome,
        descricao: dbEstabelecimento.descricao,
        tipo: dbEstabelecimento.tipo,
        endereco: dbEstabelecimento.endereco,
        latitude: dbEstabelecimento.latitude,
        longitude: dbEstabelecimento.longitude,
        telefone: dbEstabelecimento.telefone,
        email: dbEstabelecimento.email,
        responsavel: dbEstabelecimento.responsavel,
        observacoes: dbEstabelecimento.observacoes,
        createdAt: dbEstabelecimento.createdAt,
        updatedAt: dbEstabelecimento.updatedAt,
        isSynced: dbEstabelecimento.isSynced,
        serverId: dbEstabelecimento.serverId,
        categoriaEstabelecimentoId: dbEstabelecimento.categoriaEstabelecimentoId,
        categoriaEstabelecimentoNome: dbEstabelecimento.categoriaEstabelecimentoNome,
      );
    } catch (e) {
      print('Erro ao buscar estabelecimento por ID: $e');
      return null;
    }
  }

  /// Busca todos os estabelecimentos
  Future<List<Establishment>> getEstablishments() async {
    try {
      final dbEstabelecimentos = await _database.getAllEstabelecimentos();
      print('📊 Total de estabelecimentos no banco: ${dbEstabelecimentos.length}');
      final establishments = dbEstabelecimentos.map((e) => Establishment(
        id: e.id,
        nome: e.nome,
        descricao: e.descricao,
        tipo: e.tipo,
        endereco: e.endereco,
        latitude: e.latitude,
        longitude: e.longitude,
        telefone: e.telefone,
        email: e.email,
        responsavel: e.responsavel,
        observacoes: e.observacoes,
        createdAt: e.createdAt,
        updatedAt: e.updatedAt,
        isSynced: e.isSynced,
        serverId: e.serverId,
        categoriaEstabelecimentoId: e.categoriaEstabelecimentoId,
        categoriaEstabelecimentoNome: e.categoriaEstabelecimentoNome,
      )).toList();
      
      print('📊 Estabelecimentos válidos: ${establishments.length}');
      print('📊 Estabelecimentos sincronizados: ${establishments.where((e) => e.isSynced).length}');
      return establishments;
    } catch (e) {
      print('Erro ao buscar estabelecimentos: $e');
      return [];
    }
  }

  // ============================================================================
  // MÉTODOS DE SINCRONIZAÇÃO
  // ============================================================================

  /// Limpa dados antigos (opcional - para limpeza periódica)
  Future<void> cleanupOldData({int daysToKeep = 90}) async {
    try {
      // TODO: Implementar limpeza de dados antigos se necessário
      // Por enquanto, manter todos os dados
    } catch (e) {
      print('Erro ao limpar dados antigos: $e');
    }
  }

  /// Busca todas as equipes
  Future<List<db.Equipe>> getAllEquipes() async {
    try {
      return await _database.getAllEquipes();
    } catch (e) {
      print('Erro ao buscar equipes: $e');
      return [];
    }
  }

  /// Busca todos os membros de equipe
  Future<List<db.EquipeMembro>> getAllEquipeMembros() async {
    try {
      return await _database.getAllEquipeMembros();
    } catch (e) {
      print('Erro ao buscar membros de equipe: $e');
      return [];
    }
  }

  /// Busca todos os checklists
  Future<List<db.Checklist>> getAllChecklists() async {
    try {
      return await _database.getAllChecklists();
    } catch (e) {
      print('Erro ao buscar checklists: $e');
      return [];
    }
  }

  /// Nome do checklist no SQLite (sincronizado com a API).
  Future<String?> getChecklistNomeById(String id) async {
    try {
      await initialize();
      final row = await _database.getChecklistById(id);
      return row?.nome;
    } catch (e) {
      print('Erro ao buscar checklist por id: $e');
      return null;
    }
  }

  /// Busca todas as seções de checklist
  Future<List<db.SecoesChecklistData>> getAllSecoesChecklist() async {
    try {
      return await _database.getAllSecoesChecklist();
    } catch (e) {
      print('Erro ao buscar seções de checklist: $e');
      return [];
    }
  }

  /// Busca todos os itens de checklist
  Future<List<db.ItensChecklistData>> getAllItensChecklist() async {
    try {
      return await _database.getAllItensChecklist();
    } catch (e) {
      print('Erro ao buscar itens de checklist: $e');
      return [];
    }
  }

  /// Busca todas as opções de item de checklist
  Future<List<db.OpcoesItemChecklistData>> getAllOpcoesItemChecklist() async {
    try {
      return await _database.getAllOpcoesItemChecklist();
    } catch (e) {
      print('Erro ao buscar opções de item de checklist: $e');
      return [];
    }
  }

  /// Busca seções de um checklist pelo checklistId
  Future<List<db.SecoesChecklistData>> getSecoesByChecklist(String checklistId) async {
    try {
      return await _database.getSecoesByChecklist(checklistId);
    } catch (e) {
      print('Erro ao buscar seções do checklist $checklistId: $e');
      return [];
    }
  }

  /// Busca itens ativos de uma seção pelo secaoId
  Future<List<db.ItensChecklistData>> getItensAtivosBySecao(String secaoId) async {
    try {
      return await _database.getItensAtivosBySecao(secaoId);
    } catch (e) {
      print('Erro ao buscar itens da seção $secaoId: $e');
      return [];
    }
  }

  List<AcaoOpcaoChecklist> _parseAcoesOpcaoJson(String? raw) {
    if (raw == null || raw.isEmpty) return [];
    try {
      final d = jsonDecode(raw);
      if (d is List) {
        return d
            .whereType<Map<String, dynamic>>()
            .map(AcaoOpcaoChecklist.fromJson)
            .toList();
      }
    } catch (_) {}
    return [];
  }

  dynamic _jsonSerializable(dynamic v) {
    if (v == null || v is num || v is String || v is bool) return v;
    if (v is Map) {
      return v.map((k, e) => MapEntry(k.toString(), _jsonSerializable(e)));
    }
    if (v is List) return v.map(_jsonSerializable).toList();
    return v.toString();
  }

  Map<String, dynamic> _jsonSafePayload(Map<String, dynamic> payload) {
    return Map<String, dynamic>.from(
      payload.map((k, v) => MapEntry(k, _jsonSerializable(v))),
    );
  }

  /// Checklist completo a partir do SQLite (após `syncInitialData`).
  Future<List<SecaoChecklistCompleta>> loadChecklistCompletoFromCache(
      String checklistId) async {
    await initialize();
    final allSecoes = await _database.getSecoesByChecklist(checklistId);
    if (allSecoes.isEmpty) return [];

    final byParent = <String?, List<db.SecoesChecklistData>>{};
    for (final s in allSecoes) {
      byParent.putIfAbsent(s.secaoPaiId, () => []).add(s);
    }
    for (final list in byParent.values) {
      list.sort((a, b) => a.ordem.compareTo(b.ordem));
    }

    Future<SecaoChecklistCompleta> buildSecao(db.SecoesChecklistData s) async {
      final subRaw = byParent[s.id] ?? [];
      final subsecoes = await Future.wait(subRaw.map(buildSecao));

      final itensRows = await _database.getItensAtivosBySecao(s.id);
      itensRows.sort((a, b) => a.ordem.compareTo(b.ordem));

      final itens = <ItemChecklistCompleto>[];
      for (final row in itensRows) {
        final opRows = await _database.getOpcoesByItem(row.id);
        opRows.sort((a, b) => a.ordem.compareTo(b.ordem));
        final opcoes = opRows
            .map(
              (o) => OpcaoItemChecklist(
                id: o.id,
                itemId: o.itemId,
                texto: o.texto,
                valor: o.valor,
                ordem: o.ordem,
                cor: o.cor,
                pontuacao: o.pontuacao?.toDouble(),
                acoes: _parseAcoesOpcaoJson(o.acoesJson),
              ),
            )
            .toList();

        itens.add(
          ItemChecklistCompleto(
            id: row.id,
            secaoId: row.secaoId,
            rotulo: row.rotulo,
            descricao: row.descricao,
            ajuda: row.ajuda,
            tipo: tipoFromString(row.tipo),
            ordem: row.ordem,
            obrigatorio: row.obrigatorio,
            ativo: row.ativo,
            opcoes: opcoes,
          ),
        );
      }

      return SecaoChecklistCompleta(
        id: s.id,
        checklistId: s.checklistId,
        titulo: s.titulo,
        descricao: s.descricao,
        ordem: s.ordem,
        secaoPaiId: s.secaoPaiId,
        ativo: s.ativo,
        itens: itens,
        subsecoes: subsecoes,
      );
    }

    final roots = byParent[null] ?? [];
    return Future.wait(roots.map(buildSecao));
  }

  Future<List<RespostaInspecaoCompleta>> listRespostasChecklistCompleta(
      String inspecaoLocalId) async {
    await initialize();
    final rows = await _database.getRespostasByInspecao(inspecaoLocalId);
    return rows
        .map(
          (r) => RespostaInspecaoCompleta(
            id: r.id,
            inspecaoId: r.inspecaoId,
            itemChecklistId: r.itemChecklistId,
            opcaoId: r.opcaoId,
            valorTexto: r.valorTexto,
            valorNumero: r.valorNumero,
            valorData: r.valorData?.toUtc().toIso8601String(),
            valorDataHora: null,
            valorRating: r.valorRating,
            latitude: r.latitude,
            longitude: r.longitude,
            observacoes: r.observacoes,
          ),
        )
        .toList();
  }

  Future<Set<String>> _pendingItemChecklistIdsForInspecao(
      String inspecaoLocalId) async {
    final ids = <String>{};
    final ops = await _database.getAllPendingRespostaOps();
    for (final op in ops) {
      if (op.inspecaoLocalId != inspecaoLocalId) continue;
      try {
        final m = jsonDecode(op.payloadJson) as Map<String, dynamic>;
        final iid = m['itemChecklistId']?.toString().trim() ?? '';
        if (iid.isNotEmpty) ids.add(iid);
      } catch (_) {}
    }
    return ids;
  }

  /// Espelha na BD local as respostas obtidas do servidor para o checklist poder
  /// mostrar opções/valores em modo offline.
  ///
  /// Não substitui linhas com `isSynced == false` (alterações locais por sincronizar)
  /// nem itens que já tenham operação na fila offline.
  Future<void> mergeChecklistRespostasFromServer(
    String inspecaoLocalId,
    List<RespostaInspecaoCompleta> respostas,
  ) async {
    await initialize();
    if (respostas.isEmpty) return;

    final now = DateTime.now();
    const uuid = Uuid();
    final pendingIds = await _pendingItemChecklistIdsForInspecao(inspecaoLocalId);
    var rowsSnapshot = await _database.getRespostasByInspecao(inspecaoLocalId);

    for (final r in respostas) {
      final itemId = r.itemChecklistId.trim();
      if (itemId.isEmpty || pendingIds.contains(itemId)) continue;

      final sameItem =
          rowsSnapshot.where((e) => e.itemChecklistId == itemId).toList();
      if (sameItem.isNotEmpty && !sameItem.first.isSynced) continue;

      for (final e in sameItem) {
        await _database.deleteResposta(e.id);
      }
      rowsSnapshot =
          rowsSnapshot.where((e) => e.itemChecklistId != itemId).toList();

      final rowId = r.id.trim().isNotEmpty ? r.id : uuid.v4();
      DateTime? vd;
      final vdRaw = r.valorData?.trim();
      if (vdRaw != null && vdRaw.isNotEmpty) {
        vd = DateTime.tryParse(vdRaw);
      }

      final companion = db.RespostasInspecaoCompanion(
        id: Value(rowId),
        inspecaoId: Value(inspecaoLocalId),
        itemChecklistId: Value(itemId),
        itemDescricao: const Value(''),
        categoria: const Value(''),
        status: const Value(ItemStatus.conforme),
        opcaoId: Value(r.opcaoId),
        valorTexto: Value(r.valorTexto),
        valorNumero: Value(r.valorNumero),
        valorData: Value(vd),
        valorRating: Value(r.valorRating),
        valorBooleano: const Value(null),
        latitude: Value(r.latitude),
        longitude: Value(r.longitude),
        gpsTimestamp: const Value(null),
        observacoes: Value(r.observacoes),
        ordem: const Value(0),
        obrigatorio: const Value(false),
        createdAt: Value(now),
        updatedAt: Value(now),
        isSynced: const Value(true),
      );
      await _database.insertResposta(companion);
    }
  }

  Future<void> upsertRespostaFromChecklistPayload({
    required String inspecaoLocalId,
    required Map<String, dynamic> payload,
    required String respostaRowId,
    String itemDescricao = '',
    String categoria = '',
  }) async {
    await initialize();
    final itemChecklistId = payload['itemChecklistId']?.toString() ?? '';
    final existing = await _database.getRespostasByInspecao(inspecaoLocalId);
    for (final e in existing) {
      if (e.itemChecklistId == itemChecklistId) {
        await _database.deleteResposta(e.id);
      }
    }

    final opcaoId = payload['opcaoId']?.toString();
    final vt = payload['valorTexto']?.toString();
    final vn = (payload['valorNumero'] as num?)?.toDouble();
    DateTime? vd;
    final vdRaw = payload['valorData'];
    if (vdRaw is String) vd = DateTime.tryParse(vdRaw);
    final vr = (payload['valorRating'] as num?)?.toInt();
    final lat = (payload['latitude'] as num?)?.toDouble();
    final lng = (payload['longitude'] as num?)?.toDouble();
    final obs = payload['observacoes']?.toString();

    final now = DateTime.now();
    final companion = db.RespostasInspecaoCompanion(
      id: Value(respostaRowId),
      inspecaoId: Value(inspecaoLocalId),
      itemChecklistId: Value(itemChecklistId),
      itemDescricao: Value(itemDescricao),
      categoria: Value(categoria),
      status: const Value(ItemStatus.conforme),
      opcaoId: Value(opcaoId),
      valorTexto: Value(vt),
      valorNumero: Value(vn),
      valorData: Value(vd),
      valorRating: Value(vr),
      valorBooleano: const Value(null),
      latitude: Value(lat),
      longitude: Value(lng),
      gpsTimestamp: const Value(null),
      observacoes: Value(obs),
      ordem: const Value(0),
      obrigatorio: const Value(false),
      createdAt: Value(now),
      updatedAt: Value(now),
      isSynced: const Value(false),
    );
    await _database.insertResposta(companion);
  }

  Future<int> enqueuePendingRespostaOp({
    required String inspecaoLocalId,
    required Map<String, dynamic> payloadResposta,
    required bool salvarPlanoAcao,
    Map<String, dynamic>? planoExtras,
  }) async {
    await initialize();
    final companion = db.PendingRespostaOpsCompanion(
      inspecaoLocalId: Value(inspecaoLocalId),
      payloadJson: Value(jsonEncode(_jsonSafePayload(payloadResposta))),
      salvarPlanoAcao: Value(salvarPlanoAcao),
      planoExtrasJson: Value(
        planoExtras == null ? null : jsonEncode(_jsonSafePayload(planoExtras)),
      ),
      createdAt: Value(DateTime.now()),
    );
    return _database.insertPendingRespostaOp(companion);
  }

  Future<int> countPendingRespostaOps() async {
    await initialize();
    return (await _database.getAllPendingRespostaOps()).length;
  }

  Future<List<db.PendingRespostaOp>> getPendingRespostaOpsList() async {
    await initialize();
    return _database.getAllPendingRespostaOps();
  }

  Future<void> deletePendingRespostaOpById(int id) async {
    await initialize();
    await _database.deletePendingRespostaOp(id);
  }
}
