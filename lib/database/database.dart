import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:inspecao/models/inspection.dart';
import 'package:inspecao/models/establishment.dart';
import 'package:inspecao/models/inspection_item.dart';
import 'tables.dart';

part 'database.g.dart';

@DriftDatabase(tables: [
  Inspecoes,
  RespostasInspecao,
  AnexosInspecao,
  Checklists,
  Estabelecimentos,
  Sincronizacoes,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        // Implementar migrations futuras aqui
        // Exemplo:
        // if (from < 2) {
        //   await m.addColumn(inspecoes, inspecoes.novoCampo);
        // }
      },
    );
  }

  // ============================================================================
  // DAOs - Data Access Objects
  // ============================================================================

  /// DAO para Inspeções
  Future<List<Inspecoe>> getAllInspecoes() => select(inspecoes).get();
  
  Future<Inspecoe?> getInspecaoById(String id) => 
      (select(inspecoes)..where((t) => t.id.equals(id))).getSingleOrNull();
  
  Future<List<Inspecoe>> getInspecoesPendentes() => 
      (select(inspecoes)..where((t) => t.isSynced.equals(false))).get();
  
  Future<List<Inspecoe>> getInspecoesByStatus(InspectionStatus status) => 
      (select(inspecoes)..where((t) => t.status.equals(status.name))).get();
  
  Future<List<Inspecoe>> getInspecoesByEstabelecimento(String establishmentId) => 
      (select(inspecoes)..where((t) => t.establishmentId.equals(establishmentId))).get();
  
  Future<int> insertInspecao(InspecoesCompanion inspecao) => 
      into(inspecoes).insert(inspecao, mode: InsertMode.replace);
  
  Future<bool> updateInspecao(InspecoesCompanion inspecao) => 
      update(inspecoes).replace(inspecao);
  
  Future<int> deleteInspecao(String id) => 
      (delete(inspecoes)..where((t) => t.id.equals(id))).go();
  
  Future<int> deleteInspecaoPermanente(String id) => 
      (delete(inspecoes)..where((t) => t.id.equals(id))).go();

  /// DAO para Respostas de Inspeção
  Future<List<RespostasInspecaoData>> getRespostasByInspecao(String inspecaoId) => 
      (select(respostasInspecao)..where((t) => t.inspecaoId.equals(inspecaoId))..orderBy([(t) => OrderingTerm(expression: t.ordem)])).get();
  
  Future<RespostasInspecaoData?> getRespostaById(String id) => 
      (select(respostasInspecao)..where((t) => t.id.equals(id))).getSingleOrNull();
  
  Future<int> insertResposta(RespostasInspecaoCompanion resposta) => 
      into(respostasInspecao).insert(resposta, mode: InsertMode.replace);
  
  Future<bool> updateResposta(RespostasInspecaoCompanion resposta) => 
      update(respostasInspecao).replace(resposta);
  
  Future<int> deleteResposta(String id) => 
      (delete(respostasInspecao)..where((t) => t.id.equals(id))).go();
  
  Future<int> deleteRespostasByInspecao(String inspecaoId) => 
      (delete(respostasInspecao)..where((t) => t.inspecaoId.equals(inspecaoId))).go();

  /// DAO para Anexos
  Future<List<AnexosInspecaoData>> getAnexosByInspecao(String inspecaoId) => 
      (select(anexosInspecao)..where((t) => t.inspecaoId.equals(inspecaoId))).get();
  
  Future<List<AnexosInspecaoData>> getAnexosByResposta(String respostaId) => 
      (select(anexosInspecao)..where((t) => t.respostaId.equals(respostaId))).get();
  
  Future<List<AnexosInspecaoData>> getAnexosPendentes() => 
      (select(anexosInspecao)..where((t) => t.isSynced.equals(false))).get();
  
  Future<AnexosInspecaoData?> getAnexoById(String id) => 
      (select(anexosInspecao)..where((t) => t.id.equals(id))).getSingleOrNull();
  
  Future<int> insertAnexo(AnexosInspecaoCompanion anexo) => 
      into(anexosInspecao).insert(anexo, mode: InsertMode.replace);
  
  Future<bool> updateAnexo(AnexosInspecaoCompanion anexo) => 
      update(anexosInspecao).replace(anexo);
  
  Future<int> deleteAnexo(String id) => 
      (delete(anexosInspecao)..where((t) => t.id.equals(id))).go();
  
  Future<int> deleteAnexosByInspecao(String inspecaoId) => 
      (delete(anexosInspecao)..where((t) => t.inspecaoId.equals(inspecaoId))).go();

  /// DAO para Checklists
  Future<List<Checklist>> getAllChecklists() => select(checklists).get();
  
  Future<Checklist?> getChecklistById(String id) => 
      (select(checklists)..where((t) => t.id.equals(id))).getSingleOrNull();
  
  Future<List<Checklist>> getChecklistsByCategoria(String categoria) => 
      (select(checklists)..where((t) => t.categoria.equals(categoria))..where((t) => t.isAtivo.equals(true))).get();
  
  Future<List<Checklist>> getChecklistsAtivos() => 
      (select(checklists)..where((t) => t.isAtivo.equals(true))).get();
  
  Future<int> insertChecklist(ChecklistsCompanion checklist) => 
      into(checklists).insert(checklist, mode: InsertMode.replace);
  
  Future<bool> updateChecklist(ChecklistsCompanion checklist) => 
      update(checklists).replace(checklist);
  
  Future<int> deleteChecklist(String id) => 
      (delete(checklists)..where((t) => t.id.equals(id))).go();

  /// DAO para Estabelecimentos
  Future<List<Estabelecimento>> getAllEstabelecimentos() => select(estabelecimentos).get();
  
  Future<Estabelecimento?> getEstabelecimentoById(String id) => 
      (select(estabelecimentos)..where((t) => t.id.equals(id))).getSingleOrNull();
  
  Future<Estabelecimento?> getEstabelecimentoByCodigo(String codigo) => 
      (select(estabelecimentos)..where((t) => t.codigo.equals(codigo))).getSingleOrNull();
  
  Future<List<Estabelecimento>> getEstabelecimentosPendentes() => 
      (select(estabelecimentos)..where((t) => t.isSynced.equals(false))).get();
  
  Future<int> insertEstabelecimento(EstabelecimentosCompanion estabelecimento) => 
      into(estabelecimentos).insert(estabelecimento, mode: InsertMode.replace);
  
  Future<bool> updateEstabelecimento(EstabelecimentosCompanion estabelecimento) => 
      update(estabelecimentos).replace(estabelecimento);
  
  Future<int> deleteEstabelecimento(String id) => 
      (delete(estabelecimentos)..where((t) => t.id.equals(id))).go();

  /// DAO para Sincronizações
  Future<List<Sincronizacoe>> getSincronizacoesPendentes() => 
      (select(sincronizacoes)..where((t) => t.status.equals('pendente'))).get();
  
  Future<List<Sincronizacoe>> getSincronizacoesComConflito() => 
      (select(sincronizacoes)..where((t) => t.temConflito.equals(true))).get();
  
  Future<Sincronizacoe?> getSincronizacaoByInspecao(String inspecaoId) => 
      (select(sincronizacoes)..where((t) => t.inspecaoId.equals(inspecaoId))).getSingleOrNull();
  
  Future<int> insertSincronizacao(SincronizacoesCompanion sincronizacao) => 
      into(sincronizacoes).insert(sincronizacao);
  
  Future<bool> updateSincronizacao(SincronizacoesCompanion sincronizacao) => 
      update(sincronizacoes).replace(sincronizacao);
  
  Future<int> deleteSincronizacao(int id) => 
      (delete(sincronizacoes)..where((t) => t.id.equals(id))).go();
  
  Future<int> deleteSincronizacaoByInspecao(String inspecaoId) => 
      (delete(sincronizacoes)..where((t) => t.inspecaoId.equals(inspecaoId))).go();
}

/// Abre conexão com o banco de dados SQLite
LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'inspev.db'));
    return NativeDatabase(file);
  });
}
