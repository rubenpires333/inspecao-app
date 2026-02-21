import 'package:inspecao/database/database.dart' as db;
import 'package:inspecao/models/inspection.dart';
import 'package:inspecao/models/inspection_item.dart';
import 'package:inspecao/models/inspector.dart';
import 'package:inspecao/models/establishment.dart';
import 'package:drift/drift.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';

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

    // Converter equipe (por enquanto vazio, TODO: implementar quando tiver tabela de equipe)
    final equipe = <Inspector>[];

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
      equipeId: null, // TODO: adicionar quando tiver tabela de equipe
      isTemplate: dbInspection.isTemplate,
      isSynced: dbInspection.isSynced,
      createdAt: dbInspection.createdAt,
      updatedAt: dbInspection.updatedAt,
      serverId: dbInspection.serverId,
    );
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
      
      // Salvar itens/respostas da inspeção
      await _saveInspectionItems(inspection.id, inspection.itens);
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

  /// Atualiza inspeção no banco local
  Future<void> updateInspection(Inspection inspection) async {
    try {
      final companion = _inspectionToDb(inspection.copyWith(
        updatedAt: DateTime.now(),
      ));
      await _database.updateInspecao(companion);
      
      // Atualizar itens/respostas
      await _saveInspectionItems(inspection.id, inspection.itens);
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
          valorTexto: const Value(null), // TODO: implementar quando tiver valores específicos
          valorNumero: const Value(null),
          valorData: const Value(null),
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
}
