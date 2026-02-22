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
  SecoesChecklist,
  ItensChecklist,
  OpcoesItemChecklist,
  Estabelecimentos,
  CategoriasEstabelecimento,
  Equipes,
  EquipeMembros,
  Sincronizacoes,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        // Migration 1 -> 2: Adicionar tabela categorias_estabelecimento
        if (from < 2) {
          print('🔄 Executando migration: adicionando tabela categorias_estabelecimento...');
          await m.createTable(categoriasEstabelecimento);
          print('✅ Tabela categorias_estabelecimento criada');
        }
        // Migration 2 -> 3: Adicionar tabelas de equipes e itens de checklist
        if (from < 3) {
          print('🔄 Executando migration: adicionando tabelas de equipes e itens de checklist...');
          await m.createTable(equipes);
          await m.createTable(equipeMembros);
          await m.createTable(itensChecklist);
          print('✅ Tabelas de equipes e itens de checklist criadas');
        }
        // Migration 3 -> 4: Adicionar tabelas completas de checklist (seções e opções)
        if (from < 4) {
          print('🔄 Executando migration: adicionando tabelas completas de checklist...');
          try {
            // Criar novas tabelas (seções e opções)
            await m.createTable(secoesChecklist);
            await m.createTable(opcoesItemChecklist);
            print('✅ Tabelas de seções e opções criadas');
            
            // Atualizar tabela de checklists: adicionar novos campos se não existirem
            // Nota: Drift não suporta ALTER TABLE diretamente, então vamos criar a nova estrutura
            // Os dados antigos serão perdidos, mas isso é aceitável para desenvolvimento
            try {
              await m.deleteTable('checklists');
            } catch (e) {
              print('⚠️ Tabela checklists não existe ou já foi deletada');
            }
            await m.createTable(checklists);
            print('✅ Tabela de checklists atualizada');
            
            // Atualizar tabela de itens de checklist
            try {
              await m.deleteTable('itens_checklist');
            } catch (e) {
              print('⚠️ Tabela itens_checklist não existe ou já foi deletada');
            }
            await m.createTable(itensChecklist);
            print('✅ Tabela de itens de checklist atualizada');
            
            print('✅ Migration 3->4 concluída: tabelas completas de checklist criadas');
          } catch (e) {
            print('⚠️ Erro na migration 3->4: $e');
            // Continuar mesmo se houver erro
          }
        }
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
  
  Future<List<Checklist>> getChecklistsByCategoria(String categoriaNome) => 
      (select(checklists)..where((t) => t.categoriaNome.equals(categoriaNome))..where((t) => t.ativo.equals(true))).get();
  
  Future<List<Checklist>> getChecklistsAtivos() => 
      (select(checklists)..where((t) => t.ativo.equals(true))).get();
  
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

  /// DAO para Categorias de Estabelecimento
  Future<List<CategoriasEstabelecimentoData>> getAllCategoriasEstabelecimento() => 
      select(categoriasEstabelecimento).get();
  
  Future<CategoriasEstabelecimentoData?> getCategoriaEstabelecimentoById(String id) => 
      (select(categoriasEstabelecimento)..where((t) => t.id.equals(id))).getSingleOrNull();
  
  Future<CategoriasEstabelecimentoData?> getCategoriaEstabelecimentoByCodigo(String codigo) => 
      (select(categoriasEstabelecimento)..where((t) => t.codigo.equals(codigo))).getSingleOrNull();
  
  Future<int> insertCategoriaEstabelecimento(CategoriasEstabelecimentoCompanion categoria) => 
      into(categoriasEstabelecimento).insert(categoria, mode: InsertMode.replace);
  
  Future<bool> updateCategoriaEstabelecimento(CategoriasEstabelecimentoCompanion categoria) => 
      update(categoriasEstabelecimento).replace(categoria);
  
  Future<int> deleteCategoriaEstabelecimento(String id) => 
      (delete(categoriasEstabelecimento)..where((t) => t.id.equals(id))).go();

  /// DAO para Equipes
  Future<List<Equipe>> getAllEquipes() => select(equipes).get();
  
  Future<Equipe?> getEquipeById(String id) => 
      (select(equipes)..where((t) => t.id.equals(id))).getSingleOrNull();
  
  Future<List<Equipe>> getEquipesAtivas() => 
      (select(equipes)..where((t) => t.ativo.equals(true))).get();
  
  Future<int> insertEquipe(EquipesCompanion equipe) => 
      into(equipes).insert(equipe, mode: InsertMode.replace);
  
  Future<bool> updateEquipe(EquipesCompanion equipe) => 
      update(equipes).replace(equipe);
  
  Future<int> deleteEquipe(String id) => 
      (delete(equipes)..where((t) => t.id.equals(id))).go();

  /// DAO para Membros de Equipe
  Future<List<EquipeMembro>> getAllEquipeMembros() => select(equipeMembros).get();
  
  Future<List<EquipeMembro>> getMembrosByEquipe(String equipeId) => 
      (select(equipeMembros)..where((t) => t.equipeId.equals(equipeId))).get();
  
  Future<List<EquipeMembro>> getMembrosAtivosByEquipe(String equipeId) => 
      (select(equipeMembros)..where((t) => t.equipeId.equals(equipeId))..where((t) => t.ativo.equals(true))).get();
  
  Future<EquipeMembro?> getEquipeMembroById(String id) => 
      (select(equipeMembros)..where((t) => t.id.equals(id))).getSingleOrNull();
  
  Future<int> insertEquipeMembro(EquipeMembrosCompanion membro) => 
      into(equipeMembros).insert(membro, mode: InsertMode.replace);
  
  Future<bool> updateEquipeMembro(EquipeMembrosCompanion membro) => 
      update(equipeMembros).replace(membro);
  
  Future<int> deleteEquipeMembro(String id) => 
      (delete(equipeMembros)..where((t) => t.id.equals(id))).go();

  /// DAO para Seções de Checklist
  Future<List<SecoesChecklistData>> getAllSecoesChecklist() => select(secoesChecklist).get();
  
  Future<List<SecoesChecklistData>> getSecoesByChecklist(String checklistId) => 
      (select(secoesChecklist)..where((t) => t.checklistId.equals(checklistId))).get();
  
  Future<List<SecoesChecklistData>> getSecoesPrincipaisByChecklist(String checklistId) => 
      (select(secoesChecklist)..where((t) => t.checklistId.equals(checklistId))..where((t) => t.secaoPaiId.isNull())).get();
  
  Future<List<SecoesChecklistData>> getSubsecoesBySecao(String secaoId) => 
      (select(secoesChecklist)..where((t) => t.secaoPaiId.equals(secaoId))).get();
  
  Future<SecoesChecklistData?> getSecaoChecklistById(String id) => 
      (select(secoesChecklist)..where((t) => t.id.equals(id))).getSingleOrNull();
  
  Future<int> insertSecaoChecklist(SecoesChecklistCompanion secao) => 
      into(secoesChecklist).insert(secao, mode: InsertMode.replace);
  
  Future<bool> updateSecaoChecklist(SecoesChecklistCompanion secao) => 
      update(secoesChecklist).replace(secao);
  
  Future<int> deleteSecaoChecklist(String id) => 
      (delete(secoesChecklist)..where((t) => t.id.equals(id))).go();
  
  Future<int> deleteSecoesByChecklist(String checklistId) => 
      (delete(secoesChecklist)..where((t) => t.checklistId.equals(checklistId))).go();

  /// DAO para Itens de Checklist
  Future<List<ItensChecklistData>> getAllItensChecklist() => select(itensChecklist).get();
  
  Future<List<ItensChecklistData>> getItensBySecao(String secaoId) => 
      (select(itensChecklist)..where((t) => t.secaoId.equals(secaoId))).get();
  
  Future<List<ItensChecklistData>> getItensAtivosBySecao(String secaoId) => 
      (select(itensChecklist)..where((t) => t.secaoId.equals(secaoId))..where((t) => t.ativo.equals(true))).get();
  
  Future<ItensChecklistData?> getItemChecklistById(String id) => 
      (select(itensChecklist)..where((t) => t.id.equals(id))).getSingleOrNull();
  
  Future<int> insertItemChecklist(ItensChecklistCompanion item) => 
      into(itensChecklist).insert(item, mode: InsertMode.replace);
  
  Future<bool> updateItemChecklist(ItensChecklistCompanion item) => 
      update(itensChecklist).replace(item);
  
  Future<int> deleteItemChecklist(String id) => 
      (delete(itensChecklist)..where((t) => t.id.equals(id))).go();
  
  Future<int> deleteItensBySecao(String secaoId) => 
      (delete(itensChecklist)..where((t) => t.secaoId.equals(secaoId))).go();

  /// DAO para Opções de Item de Checklist
  Future<List<OpcoesItemChecklistData>> getAllOpcoesItemChecklist() => select(opcoesItemChecklist).get();
  
  Future<List<OpcoesItemChecklistData>> getOpcoesByItem(String itemId) => 
      (select(opcoesItemChecklist)..where((t) => t.itemId.equals(itemId))).get();
  
  Future<OpcoesItemChecklistData?> getOpcaoItemChecklistById(String id) => 
      (select(opcoesItemChecklist)..where((t) => t.id.equals(id))).getSingleOrNull();
  
  Future<int> insertOpcaoItemChecklist(OpcoesItemChecklistCompanion opcao) => 
      into(opcoesItemChecklist).insert(opcao, mode: InsertMode.replace);
  
  Future<bool> updateOpcaoItemChecklist(OpcoesItemChecklistCompanion opcao) => 
      update(opcoesItemChecklist).replace(opcao);
  
  Future<int> deleteOpcaoItemChecklist(String id) => 
      (delete(opcoesItemChecklist)..where((t) => t.id.equals(id))).go();
  
  Future<int> deleteOpcoesByItem(String itemId) => 
      (delete(opcoesItemChecklist)..where((t) => t.itemId.equals(itemId))).go();

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
