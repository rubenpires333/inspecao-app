import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:inspecao/models/inspection.dart';
import 'package:inspecao/models/establishment.dart';
import 'package:inspecao/models/inspection_item.dart';

// ============================================================================
// CONVERSORES DE TIPO
// ============================================================================

/// Conversor para List<String> (JSON)
class StringListConverter extends TypeConverter<List<String>, String> {
  const StringListConverter();

  @override
  List<String> fromSql(String fromDb) {
    if (fromDb.isEmpty) return [];
    return List<String>.from(json.decode(fromDb));
  }

  @override
  String toSql(List<String> value) {
    return json.encode(value);
  }
}

/// Conversor para InspectionStatus
class InspectionStatusConverter extends TypeConverter<InspectionStatus, String> {
  const InspectionStatusConverter();

  @override
  InspectionStatus fromSql(String fromDb) {
    return InspectionStatus.values.byName(fromDb);
  }

  @override
  String toSql(InspectionStatus value) {
    return value.name;
  }
}

/// Conversor para InspectionType
class InspectionTypeConverter extends TypeConverter<InspectionType, String> {
  const InspectionTypeConverter();

  @override
  InspectionType fromSql(String fromDb) {
    return InspectionType.values.byName(fromDb);
  }

  @override
  String toSql(InspectionType value) {
    return value.name;
  }
}

/// Conversor para EstablishmentType
class EstablishmentTypeConverter extends TypeConverter<EstablishmentType, String> {
  const EstablishmentTypeConverter();

  @override
  EstablishmentType fromSql(String fromDb) {
    return EstablishmentType.values.byName(fromDb);
  }

  @override
  String toSql(EstablishmentType value) {
    return value.name;
  }
}

/// Conversor para ItemStatus
class ItemStatusConverter extends TypeConverter<ItemStatus, String> {
  const ItemStatusConverter();

  @override
  ItemStatus fromSql(String fromDb) {
    return ItemStatus.values.byName(fromDb);
  }

  @override
  String toSql(ItemStatus value) {
    return value.name;
  }
}

// ============================================================================
// TABELAS
// ============================================================================

/// Tabela de Inspeções
class Inspecoes extends Table {
  TextColumn get id => text()();
  TextColumn get numero => text().nullable()();
  TextColumn get titulo => text()();
  TextColumn get descricao => text()();
  TextColumn get tipo => text().map(const InspectionTypeConverter())();
  TextColumn get status => text().map(const InspectionStatusConverter())();
  DateTimeColumn get dataAgendada => dateTime()();
  DateTimeColumn get dataInicio => dateTime().nullable()();
  DateTimeColumn get dataConclusao => dateTime().nullable()();
  TextColumn get endereco => text()();
  RealColumn get latitude => real()();
  RealColumn get longitude => real()();
  TextColumn get observacoes => text().nullable()();
  
  // Referências
  TextColumn get establishmentId => text().nullable()();
  TextColumn get checklistId => text().nullable()();
  TextColumn get inspectorId => text().nullable()();
  
  // Scores
  RealColumn get scoreConformidade => real().nullable()();
  RealColumn get scoreNaoConformidade => real().nullable()();
  
  // Controle de sincronização
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  TextColumn get serverId => text().nullable()();
  TextColumn get deviceId => text().nullable()();
  TextColumn get versionHash => text().nullable()(); // SHA-256 para detecção de conflitos
  
  // Flags
  BoolColumn get isTemplate => boolean().withDefault(const Constant(false))();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Tabela de Respostas de Inspeção (itens do checklist)
class RespostasInspecao extends Table {
  TextColumn get id => text()();
  TextColumn get inspecaoId => text()();
  TextColumn get itemChecklistId => text()();
  TextColumn get itemDescricao => text()();
  TextColumn get categoria => text()();
  TextColumn get status => text().map(const ItemStatusConverter())();
  
  // Valores da resposta
  TextColumn get valorTexto => text().nullable()();
  RealColumn get valorNumero => real().nullable()();
  DateTimeColumn get valorData => dateTime().nullable()();
  IntColumn get valorRating => integer().nullable()();
  BoolColumn get valorBooleano => boolean().nullable()();
  
  // Coordenadas GPS da resposta
  RealColumn get latitude => real().nullable()();
  RealColumn get longitude => real().nullable()();
  DateTimeColumn get gpsTimestamp => dateTime().nullable()();
  
  // Observações
  TextColumn get observacoes => text().nullable()();
  
  // Ordem e obrigatoriedade
  IntColumn get ordem => integer()();
  BoolColumn get obrigatorio => boolean().withDefault(const Constant(false))();
  
  // Controle
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Tabela de Anexos/Fotos de Inspeção
class AnexosInspecao extends Table {
  TextColumn get id => text()();
  TextColumn get inspecaoId => text()();
  TextColumn get respostaId => text().nullable()(); // Opcional: pode estar vinculado a uma resposta específica
  TextColumn get nomeArquivo => text()();
  TextColumn get tipoMime => text()();
  IntColumn get tamanho => integer()();
  TextColumn get caminhoLocal => text()();
  TextColumn get urlServidor => text().nullable()();
  
  // Metadados
  TextColumn get descricao => text().nullable()();
  DateTimeColumn get dataCaptura => dateTime().nullable()();
  
  // Controle de sincronização
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  TextColumn get serverId => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Tabela de Checklists (armazenamento local)
class Checklists extends Table {
  TextColumn get id => text()();
  TextColumn get nome => text()();
  TextColumn get versao => text()();
  TextColumn get categoria => text().nullable()();
  
  // JSON completo do checklist
  TextColumn get jsonData => text()();
  
  // Metadados
  DateTimeColumn get dataDownload => dateTime()();
  DateTimeColumn get ultimaAtualizacao => dateTime()();
  BoolColumn get isAtivo => boolean().withDefault(const Constant(true))();
  
  // Controle
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Tabela de Estabelecimentos
class Estabelecimentos extends Table {
  TextColumn get id => text()();
  TextColumn get codigo => text().nullable()();
  TextColumn get nome => text()();
  TextColumn get descricao => text()();
  TextColumn get tipo => text().map(const EstablishmentTypeConverter())();
  TextColumn get endereco => text()();
  RealColumn get latitude => real()();
  RealColumn get longitude => real()();
  TextColumn get telefone => text().nullable()();
  TextColumn get email => text().nullable()();
  TextColumn get responsavel => text().nullable()();
  TextColumn get observacoes => text().nullable()();
  
  // Controle de sincronização
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
  DateTimeColumn get dataSincronizacao => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  TextColumn get serverId => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Tabela de Controle de Sincronização
class Sincronizacoes extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get inspecaoId => text()();
  TextColumn get dispositivoId => text()();
  
  // Status da sincronização
  TextColumn get status => text()(); // 'pendente', 'em_progresso', 'concluida', 'erro', 'conflito'
  
  // Versões para detecção de conflitos
  TextColumn get versaoServidor => text().nullable()();
  TextColumn get versaoDispositivo => text().nullable()();
  
  // Timestamps
  DateTimeColumn get timestamp => dateTime()();
  DateTimeColumn get ultimaTentativa => dateTime().nullable()();
  
  // Controle
  IntColumn get tentativas => integer().withDefault(const Constant(0))();
  BoolColumn get temConflito => boolean().withDefault(const Constant(false))();
  TextColumn get mensagemErro => text().nullable()();
  
  // Direção da sincronização
  TextColumn get direcao => text()(); // 'upload', 'download', 'bidirecional'
  
  // Nota: autoIncrement() já define id como primary key automaticamente
}
