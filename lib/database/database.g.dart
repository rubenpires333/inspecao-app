// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $InspecoesTable extends Inspecoes
    with TableInfo<$InspecoesTable, Inspecoe> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $InspecoesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _numeroMeta = const VerificationMeta('numero');
  @override
  late final GeneratedColumn<String> numero = GeneratedColumn<String>(
    'numero',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _tituloMeta = const VerificationMeta('titulo');
  @override
  late final GeneratedColumn<String> titulo = GeneratedColumn<String>(
    'titulo',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descricaoMeta = const VerificationMeta(
    'descricao',
  );
  @override
  late final GeneratedColumn<String> descricao = GeneratedColumn<String>(
    'descricao',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<InspectionType, String> tipo =
      GeneratedColumn<String>(
        'tipo',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<InspectionType>($InspecoesTable.$convertertipo);
  @override
  late final GeneratedColumnWithTypeConverter<InspectionStatus, String> status =
      GeneratedColumn<String>(
        'status',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<InspectionStatus>($InspecoesTable.$converterstatus);
  static const VerificationMeta _dataAgendadaMeta = const VerificationMeta(
    'dataAgendada',
  );
  @override
  late final GeneratedColumn<DateTime> dataAgendada = GeneratedColumn<DateTime>(
    'data_agendada',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dataInicioMeta = const VerificationMeta(
    'dataInicio',
  );
  @override
  late final GeneratedColumn<DateTime> dataInicio = GeneratedColumn<DateTime>(
    'data_inicio',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _dataConclusaoMeta = const VerificationMeta(
    'dataConclusao',
  );
  @override
  late final GeneratedColumn<DateTime> dataConclusao =
      GeneratedColumn<DateTime>(
        'data_conclusao',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _enderecoMeta = const VerificationMeta(
    'endereco',
  );
  @override
  late final GeneratedColumn<String> endereco = GeneratedColumn<String>(
    'endereco',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _latitudeMeta = const VerificationMeta(
    'latitude',
  );
  @override
  late final GeneratedColumn<double> latitude = GeneratedColumn<double>(
    'latitude',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _longitudeMeta = const VerificationMeta(
    'longitude',
  );
  @override
  late final GeneratedColumn<double> longitude = GeneratedColumn<double>(
    'longitude',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _observacoesMeta = const VerificationMeta(
    'observacoes',
  );
  @override
  late final GeneratedColumn<String> observacoes = GeneratedColumn<String>(
    'observacoes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _establishmentIdMeta = const VerificationMeta(
    'establishmentId',
  );
  @override
  late final GeneratedColumn<String> establishmentId = GeneratedColumn<String>(
    'establishment_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _checklistIdMeta = const VerificationMeta(
    'checklistId',
  );
  @override
  late final GeneratedColumn<String> checklistId = GeneratedColumn<String>(
    'checklist_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _inspectorIdMeta = const VerificationMeta(
    'inspectorId',
  );
  @override
  late final GeneratedColumn<String> inspectorId = GeneratedColumn<String>(
    'inspector_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _scoreConformidadeMeta = const VerificationMeta(
    'scoreConformidade',
  );
  @override
  late final GeneratedColumn<double> scoreConformidade =
      GeneratedColumn<double>(
        'score_conformidade',
        aliasedName,
        true,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _scoreNaoConformidadeMeta =
      const VerificationMeta('scoreNaoConformidade');
  @override
  late final GeneratedColumn<double> scoreNaoConformidade =
      GeneratedColumn<double>(
        'score_nao_conformidade',
        aliasedName,
        true,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _isSyncedMeta = const VerificationMeta(
    'isSynced',
  );
  @override
  late final GeneratedColumn<bool> isSynced = GeneratedColumn<bool>(
    'is_synced',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_synced" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _serverIdMeta = const VerificationMeta(
    'serverId',
  );
  @override
  late final GeneratedColumn<String> serverId = GeneratedColumn<String>(
    'server_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _deviceIdMeta = const VerificationMeta(
    'deviceId',
  );
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
    'device_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _versionHashMeta = const VerificationMeta(
    'versionHash',
  );
  @override
  late final GeneratedColumn<String> versionHash = GeneratedColumn<String>(
    'version_hash',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isTemplateMeta = const VerificationMeta(
    'isTemplate',
  );
  @override
  late final GeneratedColumn<bool> isTemplate = GeneratedColumn<bool>(
    'is_template',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_template" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _isDeletedMeta = const VerificationMeta(
    'isDeleted',
  );
  @override
  late final GeneratedColumn<bool> isDeleted = GeneratedColumn<bool>(
    'is_deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_deleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    numero,
    titulo,
    descricao,
    tipo,
    status,
    dataAgendada,
    dataInicio,
    dataConclusao,
    endereco,
    latitude,
    longitude,
    observacoes,
    establishmentId,
    checklistId,
    inspectorId,
    scoreConformidade,
    scoreNaoConformidade,
    isSynced,
    createdAt,
    updatedAt,
    serverId,
    deviceId,
    versionHash,
    isTemplate,
    isDeleted,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'inspecoes';
  @override
  VerificationContext validateIntegrity(
    Insertable<Inspecoe> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('numero')) {
      context.handle(
        _numeroMeta,
        numero.isAcceptableOrUnknown(data['numero']!, _numeroMeta),
      );
    }
    if (data.containsKey('titulo')) {
      context.handle(
        _tituloMeta,
        titulo.isAcceptableOrUnknown(data['titulo']!, _tituloMeta),
      );
    } else if (isInserting) {
      context.missing(_tituloMeta);
    }
    if (data.containsKey('descricao')) {
      context.handle(
        _descricaoMeta,
        descricao.isAcceptableOrUnknown(data['descricao']!, _descricaoMeta),
      );
    } else if (isInserting) {
      context.missing(_descricaoMeta);
    }
    if (data.containsKey('data_agendada')) {
      context.handle(
        _dataAgendadaMeta,
        dataAgendada.isAcceptableOrUnknown(
          data['data_agendada']!,
          _dataAgendadaMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_dataAgendadaMeta);
    }
    if (data.containsKey('data_inicio')) {
      context.handle(
        _dataInicioMeta,
        dataInicio.isAcceptableOrUnknown(data['data_inicio']!, _dataInicioMeta),
      );
    }
    if (data.containsKey('data_conclusao')) {
      context.handle(
        _dataConclusaoMeta,
        dataConclusao.isAcceptableOrUnknown(
          data['data_conclusao']!,
          _dataConclusaoMeta,
        ),
      );
    }
    if (data.containsKey('endereco')) {
      context.handle(
        _enderecoMeta,
        endereco.isAcceptableOrUnknown(data['endereco']!, _enderecoMeta),
      );
    } else if (isInserting) {
      context.missing(_enderecoMeta);
    }
    if (data.containsKey('latitude')) {
      context.handle(
        _latitudeMeta,
        latitude.isAcceptableOrUnknown(data['latitude']!, _latitudeMeta),
      );
    } else if (isInserting) {
      context.missing(_latitudeMeta);
    }
    if (data.containsKey('longitude')) {
      context.handle(
        _longitudeMeta,
        longitude.isAcceptableOrUnknown(data['longitude']!, _longitudeMeta),
      );
    } else if (isInserting) {
      context.missing(_longitudeMeta);
    }
    if (data.containsKey('observacoes')) {
      context.handle(
        _observacoesMeta,
        observacoes.isAcceptableOrUnknown(
          data['observacoes']!,
          _observacoesMeta,
        ),
      );
    }
    if (data.containsKey('establishment_id')) {
      context.handle(
        _establishmentIdMeta,
        establishmentId.isAcceptableOrUnknown(
          data['establishment_id']!,
          _establishmentIdMeta,
        ),
      );
    }
    if (data.containsKey('checklist_id')) {
      context.handle(
        _checklistIdMeta,
        checklistId.isAcceptableOrUnknown(
          data['checklist_id']!,
          _checklistIdMeta,
        ),
      );
    }
    if (data.containsKey('inspector_id')) {
      context.handle(
        _inspectorIdMeta,
        inspectorId.isAcceptableOrUnknown(
          data['inspector_id']!,
          _inspectorIdMeta,
        ),
      );
    }
    if (data.containsKey('score_conformidade')) {
      context.handle(
        _scoreConformidadeMeta,
        scoreConformidade.isAcceptableOrUnknown(
          data['score_conformidade']!,
          _scoreConformidadeMeta,
        ),
      );
    }
    if (data.containsKey('score_nao_conformidade')) {
      context.handle(
        _scoreNaoConformidadeMeta,
        scoreNaoConformidade.isAcceptableOrUnknown(
          data['score_nao_conformidade']!,
          _scoreNaoConformidadeMeta,
        ),
      );
    }
    if (data.containsKey('is_synced')) {
      context.handle(
        _isSyncedMeta,
        isSynced.isAcceptableOrUnknown(data['is_synced']!, _isSyncedMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('server_id')) {
      context.handle(
        _serverIdMeta,
        serverId.isAcceptableOrUnknown(data['server_id']!, _serverIdMeta),
      );
    }
    if (data.containsKey('device_id')) {
      context.handle(
        _deviceIdMeta,
        deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta),
      );
    }
    if (data.containsKey('version_hash')) {
      context.handle(
        _versionHashMeta,
        versionHash.isAcceptableOrUnknown(
          data['version_hash']!,
          _versionHashMeta,
        ),
      );
    }
    if (data.containsKey('is_template')) {
      context.handle(
        _isTemplateMeta,
        isTemplate.isAcceptableOrUnknown(data['is_template']!, _isTemplateMeta),
      );
    }
    if (data.containsKey('is_deleted')) {
      context.handle(
        _isDeletedMeta,
        isDeleted.isAcceptableOrUnknown(data['is_deleted']!, _isDeletedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Inspecoe map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Inspecoe(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      numero: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}numero'],
      ),
      titulo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}titulo'],
      )!,
      descricao: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}descricao'],
      )!,
      tipo: $InspecoesTable.$convertertipo.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}tipo'],
        )!,
      ),
      status: $InspecoesTable.$converterstatus.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}status'],
        )!,
      ),
      dataAgendada: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}data_agendada'],
      )!,
      dataInicio: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}data_inicio'],
      ),
      dataConclusao: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}data_conclusao'],
      ),
      endereco: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}endereco'],
      )!,
      latitude: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}latitude'],
      )!,
      longitude: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}longitude'],
      )!,
      observacoes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}observacoes'],
      ),
      establishmentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}establishment_id'],
      ),
      checklistId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}checklist_id'],
      ),
      inspectorId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}inspector_id'],
      ),
      scoreConformidade: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}score_conformidade'],
      ),
      scoreNaoConformidade: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}score_nao_conformidade'],
      ),
      isSynced: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_synced'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      serverId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}server_id'],
      ),
      deviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_id'],
      ),
      versionHash: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}version_hash'],
      ),
      isTemplate: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_template'],
      )!,
      isDeleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_deleted'],
      )!,
    );
  }

  @override
  $InspecoesTable createAlias(String alias) {
    return $InspecoesTable(attachedDatabase, alias);
  }

  static TypeConverter<InspectionType, String> $convertertipo =
      const InspectionTypeConverter();
  static TypeConverter<InspectionStatus, String> $converterstatus =
      const InspectionStatusConverter();
}

class Inspecoe extends DataClass implements Insertable<Inspecoe> {
  final String id;
  final String? numero;
  final String titulo;
  final String descricao;
  final InspectionType tipo;
  final InspectionStatus status;
  final DateTime dataAgendada;
  final DateTime? dataInicio;
  final DateTime? dataConclusao;
  final String endereco;
  final double latitude;
  final double longitude;
  final String? observacoes;
  final String? establishmentId;
  final String? checklistId;
  final String? inspectorId;
  final double? scoreConformidade;
  final double? scoreNaoConformidade;
  final bool isSynced;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? serverId;
  final String? deviceId;
  final String? versionHash;
  final bool isTemplate;
  final bool isDeleted;
  const Inspecoe({
    required this.id,
    this.numero,
    required this.titulo,
    required this.descricao,
    required this.tipo,
    required this.status,
    required this.dataAgendada,
    this.dataInicio,
    this.dataConclusao,
    required this.endereco,
    required this.latitude,
    required this.longitude,
    this.observacoes,
    this.establishmentId,
    this.checklistId,
    this.inspectorId,
    this.scoreConformidade,
    this.scoreNaoConformidade,
    required this.isSynced,
    required this.createdAt,
    required this.updatedAt,
    this.serverId,
    this.deviceId,
    this.versionHash,
    required this.isTemplate,
    required this.isDeleted,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || numero != null) {
      map['numero'] = Variable<String>(numero);
    }
    map['titulo'] = Variable<String>(titulo);
    map['descricao'] = Variable<String>(descricao);
    {
      map['tipo'] = Variable<String>(
        $InspecoesTable.$convertertipo.toSql(tipo),
      );
    }
    {
      map['status'] = Variable<String>(
        $InspecoesTable.$converterstatus.toSql(status),
      );
    }
    map['data_agendada'] = Variable<DateTime>(dataAgendada);
    if (!nullToAbsent || dataInicio != null) {
      map['data_inicio'] = Variable<DateTime>(dataInicio);
    }
    if (!nullToAbsent || dataConclusao != null) {
      map['data_conclusao'] = Variable<DateTime>(dataConclusao);
    }
    map['endereco'] = Variable<String>(endereco);
    map['latitude'] = Variable<double>(latitude);
    map['longitude'] = Variable<double>(longitude);
    if (!nullToAbsent || observacoes != null) {
      map['observacoes'] = Variable<String>(observacoes);
    }
    if (!nullToAbsent || establishmentId != null) {
      map['establishment_id'] = Variable<String>(establishmentId);
    }
    if (!nullToAbsent || checklistId != null) {
      map['checklist_id'] = Variable<String>(checklistId);
    }
    if (!nullToAbsent || inspectorId != null) {
      map['inspector_id'] = Variable<String>(inspectorId);
    }
    if (!nullToAbsent || scoreConformidade != null) {
      map['score_conformidade'] = Variable<double>(scoreConformidade);
    }
    if (!nullToAbsent || scoreNaoConformidade != null) {
      map['score_nao_conformidade'] = Variable<double>(scoreNaoConformidade);
    }
    map['is_synced'] = Variable<bool>(isSynced);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || serverId != null) {
      map['server_id'] = Variable<String>(serverId);
    }
    if (!nullToAbsent || deviceId != null) {
      map['device_id'] = Variable<String>(deviceId);
    }
    if (!nullToAbsent || versionHash != null) {
      map['version_hash'] = Variable<String>(versionHash);
    }
    map['is_template'] = Variable<bool>(isTemplate);
    map['is_deleted'] = Variable<bool>(isDeleted);
    return map;
  }

  InspecoesCompanion toCompanion(bool nullToAbsent) {
    return InspecoesCompanion(
      id: Value(id),
      numero: numero == null && nullToAbsent
          ? const Value.absent()
          : Value(numero),
      titulo: Value(titulo),
      descricao: Value(descricao),
      tipo: Value(tipo),
      status: Value(status),
      dataAgendada: Value(dataAgendada),
      dataInicio: dataInicio == null && nullToAbsent
          ? const Value.absent()
          : Value(dataInicio),
      dataConclusao: dataConclusao == null && nullToAbsent
          ? const Value.absent()
          : Value(dataConclusao),
      endereco: Value(endereco),
      latitude: Value(latitude),
      longitude: Value(longitude),
      observacoes: observacoes == null && nullToAbsent
          ? const Value.absent()
          : Value(observacoes),
      establishmentId: establishmentId == null && nullToAbsent
          ? const Value.absent()
          : Value(establishmentId),
      checklistId: checklistId == null && nullToAbsent
          ? const Value.absent()
          : Value(checklistId),
      inspectorId: inspectorId == null && nullToAbsent
          ? const Value.absent()
          : Value(inspectorId),
      scoreConformidade: scoreConformidade == null && nullToAbsent
          ? const Value.absent()
          : Value(scoreConformidade),
      scoreNaoConformidade: scoreNaoConformidade == null && nullToAbsent
          ? const Value.absent()
          : Value(scoreNaoConformidade),
      isSynced: Value(isSynced),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      serverId: serverId == null && nullToAbsent
          ? const Value.absent()
          : Value(serverId),
      deviceId: deviceId == null && nullToAbsent
          ? const Value.absent()
          : Value(deviceId),
      versionHash: versionHash == null && nullToAbsent
          ? const Value.absent()
          : Value(versionHash),
      isTemplate: Value(isTemplate),
      isDeleted: Value(isDeleted),
    );
  }

  factory Inspecoe.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Inspecoe(
      id: serializer.fromJson<String>(json['id']),
      numero: serializer.fromJson<String?>(json['numero']),
      titulo: serializer.fromJson<String>(json['titulo']),
      descricao: serializer.fromJson<String>(json['descricao']),
      tipo: serializer.fromJson<InspectionType>(json['tipo']),
      status: serializer.fromJson<InspectionStatus>(json['status']),
      dataAgendada: serializer.fromJson<DateTime>(json['dataAgendada']),
      dataInicio: serializer.fromJson<DateTime?>(json['dataInicio']),
      dataConclusao: serializer.fromJson<DateTime?>(json['dataConclusao']),
      endereco: serializer.fromJson<String>(json['endereco']),
      latitude: serializer.fromJson<double>(json['latitude']),
      longitude: serializer.fromJson<double>(json['longitude']),
      observacoes: serializer.fromJson<String?>(json['observacoes']),
      establishmentId: serializer.fromJson<String?>(json['establishmentId']),
      checklistId: serializer.fromJson<String?>(json['checklistId']),
      inspectorId: serializer.fromJson<String?>(json['inspectorId']),
      scoreConformidade: serializer.fromJson<double?>(
        json['scoreConformidade'],
      ),
      scoreNaoConformidade: serializer.fromJson<double?>(
        json['scoreNaoConformidade'],
      ),
      isSynced: serializer.fromJson<bool>(json['isSynced']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      serverId: serializer.fromJson<String?>(json['serverId']),
      deviceId: serializer.fromJson<String?>(json['deviceId']),
      versionHash: serializer.fromJson<String?>(json['versionHash']),
      isTemplate: serializer.fromJson<bool>(json['isTemplate']),
      isDeleted: serializer.fromJson<bool>(json['isDeleted']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'numero': serializer.toJson<String?>(numero),
      'titulo': serializer.toJson<String>(titulo),
      'descricao': serializer.toJson<String>(descricao),
      'tipo': serializer.toJson<InspectionType>(tipo),
      'status': serializer.toJson<InspectionStatus>(status),
      'dataAgendada': serializer.toJson<DateTime>(dataAgendada),
      'dataInicio': serializer.toJson<DateTime?>(dataInicio),
      'dataConclusao': serializer.toJson<DateTime?>(dataConclusao),
      'endereco': serializer.toJson<String>(endereco),
      'latitude': serializer.toJson<double>(latitude),
      'longitude': serializer.toJson<double>(longitude),
      'observacoes': serializer.toJson<String?>(observacoes),
      'establishmentId': serializer.toJson<String?>(establishmentId),
      'checklistId': serializer.toJson<String?>(checklistId),
      'inspectorId': serializer.toJson<String?>(inspectorId),
      'scoreConformidade': serializer.toJson<double?>(scoreConformidade),
      'scoreNaoConformidade': serializer.toJson<double?>(scoreNaoConformidade),
      'isSynced': serializer.toJson<bool>(isSynced),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'serverId': serializer.toJson<String?>(serverId),
      'deviceId': serializer.toJson<String?>(deviceId),
      'versionHash': serializer.toJson<String?>(versionHash),
      'isTemplate': serializer.toJson<bool>(isTemplate),
      'isDeleted': serializer.toJson<bool>(isDeleted),
    };
  }

  Inspecoe copyWith({
    String? id,
    Value<String?> numero = const Value.absent(),
    String? titulo,
    String? descricao,
    InspectionType? tipo,
    InspectionStatus? status,
    DateTime? dataAgendada,
    Value<DateTime?> dataInicio = const Value.absent(),
    Value<DateTime?> dataConclusao = const Value.absent(),
    String? endereco,
    double? latitude,
    double? longitude,
    Value<String?> observacoes = const Value.absent(),
    Value<String?> establishmentId = const Value.absent(),
    Value<String?> checklistId = const Value.absent(),
    Value<String?> inspectorId = const Value.absent(),
    Value<double?> scoreConformidade = const Value.absent(),
    Value<double?> scoreNaoConformidade = const Value.absent(),
    bool? isSynced,
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<String?> serverId = const Value.absent(),
    Value<String?> deviceId = const Value.absent(),
    Value<String?> versionHash = const Value.absent(),
    bool? isTemplate,
    bool? isDeleted,
  }) => Inspecoe(
    id: id ?? this.id,
    numero: numero.present ? numero.value : this.numero,
    titulo: titulo ?? this.titulo,
    descricao: descricao ?? this.descricao,
    tipo: tipo ?? this.tipo,
    status: status ?? this.status,
    dataAgendada: dataAgendada ?? this.dataAgendada,
    dataInicio: dataInicio.present ? dataInicio.value : this.dataInicio,
    dataConclusao: dataConclusao.present
        ? dataConclusao.value
        : this.dataConclusao,
    endereco: endereco ?? this.endereco,
    latitude: latitude ?? this.latitude,
    longitude: longitude ?? this.longitude,
    observacoes: observacoes.present ? observacoes.value : this.observacoes,
    establishmentId: establishmentId.present
        ? establishmentId.value
        : this.establishmentId,
    checklistId: checklistId.present ? checklistId.value : this.checklistId,
    inspectorId: inspectorId.present ? inspectorId.value : this.inspectorId,
    scoreConformidade: scoreConformidade.present
        ? scoreConformidade.value
        : this.scoreConformidade,
    scoreNaoConformidade: scoreNaoConformidade.present
        ? scoreNaoConformidade.value
        : this.scoreNaoConformidade,
    isSynced: isSynced ?? this.isSynced,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    serverId: serverId.present ? serverId.value : this.serverId,
    deviceId: deviceId.present ? deviceId.value : this.deviceId,
    versionHash: versionHash.present ? versionHash.value : this.versionHash,
    isTemplate: isTemplate ?? this.isTemplate,
    isDeleted: isDeleted ?? this.isDeleted,
  );
  Inspecoe copyWithCompanion(InspecoesCompanion data) {
    return Inspecoe(
      id: data.id.present ? data.id.value : this.id,
      numero: data.numero.present ? data.numero.value : this.numero,
      titulo: data.titulo.present ? data.titulo.value : this.titulo,
      descricao: data.descricao.present ? data.descricao.value : this.descricao,
      tipo: data.tipo.present ? data.tipo.value : this.tipo,
      status: data.status.present ? data.status.value : this.status,
      dataAgendada: data.dataAgendada.present
          ? data.dataAgendada.value
          : this.dataAgendada,
      dataInicio: data.dataInicio.present
          ? data.dataInicio.value
          : this.dataInicio,
      dataConclusao: data.dataConclusao.present
          ? data.dataConclusao.value
          : this.dataConclusao,
      endereco: data.endereco.present ? data.endereco.value : this.endereco,
      latitude: data.latitude.present ? data.latitude.value : this.latitude,
      longitude: data.longitude.present ? data.longitude.value : this.longitude,
      observacoes: data.observacoes.present
          ? data.observacoes.value
          : this.observacoes,
      establishmentId: data.establishmentId.present
          ? data.establishmentId.value
          : this.establishmentId,
      checklistId: data.checklistId.present
          ? data.checklistId.value
          : this.checklistId,
      inspectorId: data.inspectorId.present
          ? data.inspectorId.value
          : this.inspectorId,
      scoreConformidade: data.scoreConformidade.present
          ? data.scoreConformidade.value
          : this.scoreConformidade,
      scoreNaoConformidade: data.scoreNaoConformidade.present
          ? data.scoreNaoConformidade.value
          : this.scoreNaoConformidade,
      isSynced: data.isSynced.present ? data.isSynced.value : this.isSynced,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      serverId: data.serverId.present ? data.serverId.value : this.serverId,
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      versionHash: data.versionHash.present
          ? data.versionHash.value
          : this.versionHash,
      isTemplate: data.isTemplate.present
          ? data.isTemplate.value
          : this.isTemplate,
      isDeleted: data.isDeleted.present ? data.isDeleted.value : this.isDeleted,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Inspecoe(')
          ..write('id: $id, ')
          ..write('numero: $numero, ')
          ..write('titulo: $titulo, ')
          ..write('descricao: $descricao, ')
          ..write('tipo: $tipo, ')
          ..write('status: $status, ')
          ..write('dataAgendada: $dataAgendada, ')
          ..write('dataInicio: $dataInicio, ')
          ..write('dataConclusao: $dataConclusao, ')
          ..write('endereco: $endereco, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('observacoes: $observacoes, ')
          ..write('establishmentId: $establishmentId, ')
          ..write('checklistId: $checklistId, ')
          ..write('inspectorId: $inspectorId, ')
          ..write('scoreConformidade: $scoreConformidade, ')
          ..write('scoreNaoConformidade: $scoreNaoConformidade, ')
          ..write('isSynced: $isSynced, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('serverId: $serverId, ')
          ..write('deviceId: $deviceId, ')
          ..write('versionHash: $versionHash, ')
          ..write('isTemplate: $isTemplate, ')
          ..write('isDeleted: $isDeleted')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    numero,
    titulo,
    descricao,
    tipo,
    status,
    dataAgendada,
    dataInicio,
    dataConclusao,
    endereco,
    latitude,
    longitude,
    observacoes,
    establishmentId,
    checklistId,
    inspectorId,
    scoreConformidade,
    scoreNaoConformidade,
    isSynced,
    createdAt,
    updatedAt,
    serverId,
    deviceId,
    versionHash,
    isTemplate,
    isDeleted,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Inspecoe &&
          other.id == this.id &&
          other.numero == this.numero &&
          other.titulo == this.titulo &&
          other.descricao == this.descricao &&
          other.tipo == this.tipo &&
          other.status == this.status &&
          other.dataAgendada == this.dataAgendada &&
          other.dataInicio == this.dataInicio &&
          other.dataConclusao == this.dataConclusao &&
          other.endereco == this.endereco &&
          other.latitude == this.latitude &&
          other.longitude == this.longitude &&
          other.observacoes == this.observacoes &&
          other.establishmentId == this.establishmentId &&
          other.checklistId == this.checklistId &&
          other.inspectorId == this.inspectorId &&
          other.scoreConformidade == this.scoreConformidade &&
          other.scoreNaoConformidade == this.scoreNaoConformidade &&
          other.isSynced == this.isSynced &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.serverId == this.serverId &&
          other.deviceId == this.deviceId &&
          other.versionHash == this.versionHash &&
          other.isTemplate == this.isTemplate &&
          other.isDeleted == this.isDeleted);
}

class InspecoesCompanion extends UpdateCompanion<Inspecoe> {
  final Value<String> id;
  final Value<String?> numero;
  final Value<String> titulo;
  final Value<String> descricao;
  final Value<InspectionType> tipo;
  final Value<InspectionStatus> status;
  final Value<DateTime> dataAgendada;
  final Value<DateTime?> dataInicio;
  final Value<DateTime?> dataConclusao;
  final Value<String> endereco;
  final Value<double> latitude;
  final Value<double> longitude;
  final Value<String?> observacoes;
  final Value<String?> establishmentId;
  final Value<String?> checklistId;
  final Value<String?> inspectorId;
  final Value<double?> scoreConformidade;
  final Value<double?> scoreNaoConformidade;
  final Value<bool> isSynced;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<String?> serverId;
  final Value<String?> deviceId;
  final Value<String?> versionHash;
  final Value<bool> isTemplate;
  final Value<bool> isDeleted;
  final Value<int> rowid;
  const InspecoesCompanion({
    this.id = const Value.absent(),
    this.numero = const Value.absent(),
    this.titulo = const Value.absent(),
    this.descricao = const Value.absent(),
    this.tipo = const Value.absent(),
    this.status = const Value.absent(),
    this.dataAgendada = const Value.absent(),
    this.dataInicio = const Value.absent(),
    this.dataConclusao = const Value.absent(),
    this.endereco = const Value.absent(),
    this.latitude = const Value.absent(),
    this.longitude = const Value.absent(),
    this.observacoes = const Value.absent(),
    this.establishmentId = const Value.absent(),
    this.checklistId = const Value.absent(),
    this.inspectorId = const Value.absent(),
    this.scoreConformidade = const Value.absent(),
    this.scoreNaoConformidade = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.serverId = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.versionHash = const Value.absent(),
    this.isTemplate = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  InspecoesCompanion.insert({
    required String id,
    this.numero = const Value.absent(),
    required String titulo,
    required String descricao,
    required InspectionType tipo,
    required InspectionStatus status,
    required DateTime dataAgendada,
    this.dataInicio = const Value.absent(),
    this.dataConclusao = const Value.absent(),
    required String endereco,
    required double latitude,
    required double longitude,
    this.observacoes = const Value.absent(),
    this.establishmentId = const Value.absent(),
    this.checklistId = const Value.absent(),
    this.inspectorId = const Value.absent(),
    this.scoreConformidade = const Value.absent(),
    this.scoreNaoConformidade = const Value.absent(),
    this.isSynced = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.serverId = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.versionHash = const Value.absent(),
    this.isTemplate = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       titulo = Value(titulo),
       descricao = Value(descricao),
       tipo = Value(tipo),
       status = Value(status),
       dataAgendada = Value(dataAgendada),
       endereco = Value(endereco),
       latitude = Value(latitude),
       longitude = Value(longitude),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<Inspecoe> custom({
    Expression<String>? id,
    Expression<String>? numero,
    Expression<String>? titulo,
    Expression<String>? descricao,
    Expression<String>? tipo,
    Expression<String>? status,
    Expression<DateTime>? dataAgendada,
    Expression<DateTime>? dataInicio,
    Expression<DateTime>? dataConclusao,
    Expression<String>? endereco,
    Expression<double>? latitude,
    Expression<double>? longitude,
    Expression<String>? observacoes,
    Expression<String>? establishmentId,
    Expression<String>? checklistId,
    Expression<String>? inspectorId,
    Expression<double>? scoreConformidade,
    Expression<double>? scoreNaoConformidade,
    Expression<bool>? isSynced,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<String>? serverId,
    Expression<String>? deviceId,
    Expression<String>? versionHash,
    Expression<bool>? isTemplate,
    Expression<bool>? isDeleted,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (numero != null) 'numero': numero,
      if (titulo != null) 'titulo': titulo,
      if (descricao != null) 'descricao': descricao,
      if (tipo != null) 'tipo': tipo,
      if (status != null) 'status': status,
      if (dataAgendada != null) 'data_agendada': dataAgendada,
      if (dataInicio != null) 'data_inicio': dataInicio,
      if (dataConclusao != null) 'data_conclusao': dataConclusao,
      if (endereco != null) 'endereco': endereco,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (observacoes != null) 'observacoes': observacoes,
      if (establishmentId != null) 'establishment_id': establishmentId,
      if (checklistId != null) 'checklist_id': checklistId,
      if (inspectorId != null) 'inspector_id': inspectorId,
      if (scoreConformidade != null) 'score_conformidade': scoreConformidade,
      if (scoreNaoConformidade != null)
        'score_nao_conformidade': scoreNaoConformidade,
      if (isSynced != null) 'is_synced': isSynced,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (serverId != null) 'server_id': serverId,
      if (deviceId != null) 'device_id': deviceId,
      if (versionHash != null) 'version_hash': versionHash,
      if (isTemplate != null) 'is_template': isTemplate,
      if (isDeleted != null) 'is_deleted': isDeleted,
      if (rowid != null) 'rowid': rowid,
    });
  }

  InspecoesCompanion copyWith({
    Value<String>? id,
    Value<String?>? numero,
    Value<String>? titulo,
    Value<String>? descricao,
    Value<InspectionType>? tipo,
    Value<InspectionStatus>? status,
    Value<DateTime>? dataAgendada,
    Value<DateTime?>? dataInicio,
    Value<DateTime?>? dataConclusao,
    Value<String>? endereco,
    Value<double>? latitude,
    Value<double>? longitude,
    Value<String?>? observacoes,
    Value<String?>? establishmentId,
    Value<String?>? checklistId,
    Value<String?>? inspectorId,
    Value<double?>? scoreConformidade,
    Value<double?>? scoreNaoConformidade,
    Value<bool>? isSynced,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<String?>? serverId,
    Value<String?>? deviceId,
    Value<String?>? versionHash,
    Value<bool>? isTemplate,
    Value<bool>? isDeleted,
    Value<int>? rowid,
  }) {
    return InspecoesCompanion(
      id: id ?? this.id,
      numero: numero ?? this.numero,
      titulo: titulo ?? this.titulo,
      descricao: descricao ?? this.descricao,
      tipo: tipo ?? this.tipo,
      status: status ?? this.status,
      dataAgendada: dataAgendada ?? this.dataAgendada,
      dataInicio: dataInicio ?? this.dataInicio,
      dataConclusao: dataConclusao ?? this.dataConclusao,
      endereco: endereco ?? this.endereco,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      observacoes: observacoes ?? this.observacoes,
      establishmentId: establishmentId ?? this.establishmentId,
      checklistId: checklistId ?? this.checklistId,
      inspectorId: inspectorId ?? this.inspectorId,
      scoreConformidade: scoreConformidade ?? this.scoreConformidade,
      scoreNaoConformidade: scoreNaoConformidade ?? this.scoreNaoConformidade,
      isSynced: isSynced ?? this.isSynced,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      serverId: serverId ?? this.serverId,
      deviceId: deviceId ?? this.deviceId,
      versionHash: versionHash ?? this.versionHash,
      isTemplate: isTemplate ?? this.isTemplate,
      isDeleted: isDeleted ?? this.isDeleted,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (numero.present) {
      map['numero'] = Variable<String>(numero.value);
    }
    if (titulo.present) {
      map['titulo'] = Variable<String>(titulo.value);
    }
    if (descricao.present) {
      map['descricao'] = Variable<String>(descricao.value);
    }
    if (tipo.present) {
      map['tipo'] = Variable<String>(
        $InspecoesTable.$convertertipo.toSql(tipo.value),
      );
    }
    if (status.present) {
      map['status'] = Variable<String>(
        $InspecoesTable.$converterstatus.toSql(status.value),
      );
    }
    if (dataAgendada.present) {
      map['data_agendada'] = Variable<DateTime>(dataAgendada.value);
    }
    if (dataInicio.present) {
      map['data_inicio'] = Variable<DateTime>(dataInicio.value);
    }
    if (dataConclusao.present) {
      map['data_conclusao'] = Variable<DateTime>(dataConclusao.value);
    }
    if (endereco.present) {
      map['endereco'] = Variable<String>(endereco.value);
    }
    if (latitude.present) {
      map['latitude'] = Variable<double>(latitude.value);
    }
    if (longitude.present) {
      map['longitude'] = Variable<double>(longitude.value);
    }
    if (observacoes.present) {
      map['observacoes'] = Variable<String>(observacoes.value);
    }
    if (establishmentId.present) {
      map['establishment_id'] = Variable<String>(establishmentId.value);
    }
    if (checklistId.present) {
      map['checklist_id'] = Variable<String>(checklistId.value);
    }
    if (inspectorId.present) {
      map['inspector_id'] = Variable<String>(inspectorId.value);
    }
    if (scoreConformidade.present) {
      map['score_conformidade'] = Variable<double>(scoreConformidade.value);
    }
    if (scoreNaoConformidade.present) {
      map['score_nao_conformidade'] = Variable<double>(
        scoreNaoConformidade.value,
      );
    }
    if (isSynced.present) {
      map['is_synced'] = Variable<bool>(isSynced.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (serverId.present) {
      map['server_id'] = Variable<String>(serverId.value);
    }
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (versionHash.present) {
      map['version_hash'] = Variable<String>(versionHash.value);
    }
    if (isTemplate.present) {
      map['is_template'] = Variable<bool>(isTemplate.value);
    }
    if (isDeleted.present) {
      map['is_deleted'] = Variable<bool>(isDeleted.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('InspecoesCompanion(')
          ..write('id: $id, ')
          ..write('numero: $numero, ')
          ..write('titulo: $titulo, ')
          ..write('descricao: $descricao, ')
          ..write('tipo: $tipo, ')
          ..write('status: $status, ')
          ..write('dataAgendada: $dataAgendada, ')
          ..write('dataInicio: $dataInicio, ')
          ..write('dataConclusao: $dataConclusao, ')
          ..write('endereco: $endereco, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('observacoes: $observacoes, ')
          ..write('establishmentId: $establishmentId, ')
          ..write('checklistId: $checklistId, ')
          ..write('inspectorId: $inspectorId, ')
          ..write('scoreConformidade: $scoreConformidade, ')
          ..write('scoreNaoConformidade: $scoreNaoConformidade, ')
          ..write('isSynced: $isSynced, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('serverId: $serverId, ')
          ..write('deviceId: $deviceId, ')
          ..write('versionHash: $versionHash, ')
          ..write('isTemplate: $isTemplate, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RespostasInspecaoTable extends RespostasInspecao
    with TableInfo<$RespostasInspecaoTable, RespostasInspecaoData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RespostasInspecaoTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _inspecaoIdMeta = const VerificationMeta(
    'inspecaoId',
  );
  @override
  late final GeneratedColumn<String> inspecaoId = GeneratedColumn<String>(
    'inspecao_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _itemChecklistIdMeta = const VerificationMeta(
    'itemChecklistId',
  );
  @override
  late final GeneratedColumn<String> itemChecklistId = GeneratedColumn<String>(
    'item_checklist_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _itemDescricaoMeta = const VerificationMeta(
    'itemDescricao',
  );
  @override
  late final GeneratedColumn<String> itemDescricao = GeneratedColumn<String>(
    'item_descricao',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoriaMeta = const VerificationMeta(
    'categoria',
  );
  @override
  late final GeneratedColumn<String> categoria = GeneratedColumn<String>(
    'categoria',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<ItemStatus, String> status =
      GeneratedColumn<String>(
        'status',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<ItemStatus>($RespostasInspecaoTable.$converterstatus);
  static const VerificationMeta _valorTextoMeta = const VerificationMeta(
    'valorTexto',
  );
  @override
  late final GeneratedColumn<String> valorTexto = GeneratedColumn<String>(
    'valor_texto',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _valorNumeroMeta = const VerificationMeta(
    'valorNumero',
  );
  @override
  late final GeneratedColumn<double> valorNumero = GeneratedColumn<double>(
    'valor_numero',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _valorDataMeta = const VerificationMeta(
    'valorData',
  );
  @override
  late final GeneratedColumn<DateTime> valorData = GeneratedColumn<DateTime>(
    'valor_data',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _valorRatingMeta = const VerificationMeta(
    'valorRating',
  );
  @override
  late final GeneratedColumn<int> valorRating = GeneratedColumn<int>(
    'valor_rating',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _valorBooleanoMeta = const VerificationMeta(
    'valorBooleano',
  );
  @override
  late final GeneratedColumn<bool> valorBooleano = GeneratedColumn<bool>(
    'valor_booleano',
    aliasedName,
    true,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("valor_booleano" IN (0, 1))',
    ),
  );
  static const VerificationMeta _latitudeMeta = const VerificationMeta(
    'latitude',
  );
  @override
  late final GeneratedColumn<double> latitude = GeneratedColumn<double>(
    'latitude',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _longitudeMeta = const VerificationMeta(
    'longitude',
  );
  @override
  late final GeneratedColumn<double> longitude = GeneratedColumn<double>(
    'longitude',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _gpsTimestampMeta = const VerificationMeta(
    'gpsTimestamp',
  );
  @override
  late final GeneratedColumn<DateTime> gpsTimestamp = GeneratedColumn<DateTime>(
    'gps_timestamp',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _observacoesMeta = const VerificationMeta(
    'observacoes',
  );
  @override
  late final GeneratedColumn<String> observacoes = GeneratedColumn<String>(
    'observacoes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _ordemMeta = const VerificationMeta('ordem');
  @override
  late final GeneratedColumn<int> ordem = GeneratedColumn<int>(
    'ordem',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _obrigatorioMeta = const VerificationMeta(
    'obrigatorio',
  );
  @override
  late final GeneratedColumn<bool> obrigatorio = GeneratedColumn<bool>(
    'obrigatorio',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("obrigatorio" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isSyncedMeta = const VerificationMeta(
    'isSynced',
  );
  @override
  late final GeneratedColumn<bool> isSynced = GeneratedColumn<bool>(
    'is_synced',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_synced" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    inspecaoId,
    itemChecklistId,
    itemDescricao,
    categoria,
    status,
    valorTexto,
    valorNumero,
    valorData,
    valorRating,
    valorBooleano,
    latitude,
    longitude,
    gpsTimestamp,
    observacoes,
    ordem,
    obrigatorio,
    createdAt,
    updatedAt,
    isSynced,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'respostas_inspecao';
  @override
  VerificationContext validateIntegrity(
    Insertable<RespostasInspecaoData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('inspecao_id')) {
      context.handle(
        _inspecaoIdMeta,
        inspecaoId.isAcceptableOrUnknown(data['inspecao_id']!, _inspecaoIdMeta),
      );
    } else if (isInserting) {
      context.missing(_inspecaoIdMeta);
    }
    if (data.containsKey('item_checklist_id')) {
      context.handle(
        _itemChecklistIdMeta,
        itemChecklistId.isAcceptableOrUnknown(
          data['item_checklist_id']!,
          _itemChecklistIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_itemChecklistIdMeta);
    }
    if (data.containsKey('item_descricao')) {
      context.handle(
        _itemDescricaoMeta,
        itemDescricao.isAcceptableOrUnknown(
          data['item_descricao']!,
          _itemDescricaoMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_itemDescricaoMeta);
    }
    if (data.containsKey('categoria')) {
      context.handle(
        _categoriaMeta,
        categoria.isAcceptableOrUnknown(data['categoria']!, _categoriaMeta),
      );
    } else if (isInserting) {
      context.missing(_categoriaMeta);
    }
    if (data.containsKey('valor_texto')) {
      context.handle(
        _valorTextoMeta,
        valorTexto.isAcceptableOrUnknown(data['valor_texto']!, _valorTextoMeta),
      );
    }
    if (data.containsKey('valor_numero')) {
      context.handle(
        _valorNumeroMeta,
        valorNumero.isAcceptableOrUnknown(
          data['valor_numero']!,
          _valorNumeroMeta,
        ),
      );
    }
    if (data.containsKey('valor_data')) {
      context.handle(
        _valorDataMeta,
        valorData.isAcceptableOrUnknown(data['valor_data']!, _valorDataMeta),
      );
    }
    if (data.containsKey('valor_rating')) {
      context.handle(
        _valorRatingMeta,
        valorRating.isAcceptableOrUnknown(
          data['valor_rating']!,
          _valorRatingMeta,
        ),
      );
    }
    if (data.containsKey('valor_booleano')) {
      context.handle(
        _valorBooleanoMeta,
        valorBooleano.isAcceptableOrUnknown(
          data['valor_booleano']!,
          _valorBooleanoMeta,
        ),
      );
    }
    if (data.containsKey('latitude')) {
      context.handle(
        _latitudeMeta,
        latitude.isAcceptableOrUnknown(data['latitude']!, _latitudeMeta),
      );
    }
    if (data.containsKey('longitude')) {
      context.handle(
        _longitudeMeta,
        longitude.isAcceptableOrUnknown(data['longitude']!, _longitudeMeta),
      );
    }
    if (data.containsKey('gps_timestamp')) {
      context.handle(
        _gpsTimestampMeta,
        gpsTimestamp.isAcceptableOrUnknown(
          data['gps_timestamp']!,
          _gpsTimestampMeta,
        ),
      );
    }
    if (data.containsKey('observacoes')) {
      context.handle(
        _observacoesMeta,
        observacoes.isAcceptableOrUnknown(
          data['observacoes']!,
          _observacoesMeta,
        ),
      );
    }
    if (data.containsKey('ordem')) {
      context.handle(
        _ordemMeta,
        ordem.isAcceptableOrUnknown(data['ordem']!, _ordemMeta),
      );
    } else if (isInserting) {
      context.missing(_ordemMeta);
    }
    if (data.containsKey('obrigatorio')) {
      context.handle(
        _obrigatorioMeta,
        obrigatorio.isAcceptableOrUnknown(
          data['obrigatorio']!,
          _obrigatorioMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('is_synced')) {
      context.handle(
        _isSyncedMeta,
        isSynced.isAcceptableOrUnknown(data['is_synced']!, _isSyncedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RespostasInspecaoData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RespostasInspecaoData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      inspecaoId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}inspecao_id'],
      )!,
      itemChecklistId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}item_checklist_id'],
      )!,
      itemDescricao: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}item_descricao'],
      )!,
      categoria: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}categoria'],
      )!,
      status: $RespostasInspecaoTable.$converterstatus.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}status'],
        )!,
      ),
      valorTexto: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}valor_texto'],
      ),
      valorNumero: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}valor_numero'],
      ),
      valorData: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}valor_data'],
      ),
      valorRating: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}valor_rating'],
      ),
      valorBooleano: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}valor_booleano'],
      ),
      latitude: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}latitude'],
      ),
      longitude: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}longitude'],
      ),
      gpsTimestamp: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}gps_timestamp'],
      ),
      observacoes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}observacoes'],
      ),
      ordem: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}ordem'],
      )!,
      obrigatorio: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}obrigatorio'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      isSynced: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_synced'],
      )!,
    );
  }

  @override
  $RespostasInspecaoTable createAlias(String alias) {
    return $RespostasInspecaoTable(attachedDatabase, alias);
  }

  static TypeConverter<ItemStatus, String> $converterstatus =
      const ItemStatusConverter();
}

class RespostasInspecaoData extends DataClass
    implements Insertable<RespostasInspecaoData> {
  final String id;
  final String inspecaoId;
  final String itemChecklistId;
  final String itemDescricao;
  final String categoria;
  final ItemStatus status;
  final String? valorTexto;
  final double? valorNumero;
  final DateTime? valorData;
  final int? valorRating;
  final bool? valorBooleano;
  final double? latitude;
  final double? longitude;
  final DateTime? gpsTimestamp;
  final String? observacoes;
  final int ordem;
  final bool obrigatorio;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isSynced;
  const RespostasInspecaoData({
    required this.id,
    required this.inspecaoId,
    required this.itemChecklistId,
    required this.itemDescricao,
    required this.categoria,
    required this.status,
    this.valorTexto,
    this.valorNumero,
    this.valorData,
    this.valorRating,
    this.valorBooleano,
    this.latitude,
    this.longitude,
    this.gpsTimestamp,
    this.observacoes,
    required this.ordem,
    required this.obrigatorio,
    required this.createdAt,
    required this.updatedAt,
    required this.isSynced,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['inspecao_id'] = Variable<String>(inspecaoId);
    map['item_checklist_id'] = Variable<String>(itemChecklistId);
    map['item_descricao'] = Variable<String>(itemDescricao);
    map['categoria'] = Variable<String>(categoria);
    {
      map['status'] = Variable<String>(
        $RespostasInspecaoTable.$converterstatus.toSql(status),
      );
    }
    if (!nullToAbsent || valorTexto != null) {
      map['valor_texto'] = Variable<String>(valorTexto);
    }
    if (!nullToAbsent || valorNumero != null) {
      map['valor_numero'] = Variable<double>(valorNumero);
    }
    if (!nullToAbsent || valorData != null) {
      map['valor_data'] = Variable<DateTime>(valorData);
    }
    if (!nullToAbsent || valorRating != null) {
      map['valor_rating'] = Variable<int>(valorRating);
    }
    if (!nullToAbsent || valorBooleano != null) {
      map['valor_booleano'] = Variable<bool>(valorBooleano);
    }
    if (!nullToAbsent || latitude != null) {
      map['latitude'] = Variable<double>(latitude);
    }
    if (!nullToAbsent || longitude != null) {
      map['longitude'] = Variable<double>(longitude);
    }
    if (!nullToAbsent || gpsTimestamp != null) {
      map['gps_timestamp'] = Variable<DateTime>(gpsTimestamp);
    }
    if (!nullToAbsent || observacoes != null) {
      map['observacoes'] = Variable<String>(observacoes);
    }
    map['ordem'] = Variable<int>(ordem);
    map['obrigatorio'] = Variable<bool>(obrigatorio);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['is_synced'] = Variable<bool>(isSynced);
    return map;
  }

  RespostasInspecaoCompanion toCompanion(bool nullToAbsent) {
    return RespostasInspecaoCompanion(
      id: Value(id),
      inspecaoId: Value(inspecaoId),
      itemChecklistId: Value(itemChecklistId),
      itemDescricao: Value(itemDescricao),
      categoria: Value(categoria),
      status: Value(status),
      valorTexto: valorTexto == null && nullToAbsent
          ? const Value.absent()
          : Value(valorTexto),
      valorNumero: valorNumero == null && nullToAbsent
          ? const Value.absent()
          : Value(valorNumero),
      valorData: valorData == null && nullToAbsent
          ? const Value.absent()
          : Value(valorData),
      valorRating: valorRating == null && nullToAbsent
          ? const Value.absent()
          : Value(valorRating),
      valorBooleano: valorBooleano == null && nullToAbsent
          ? const Value.absent()
          : Value(valorBooleano),
      latitude: latitude == null && nullToAbsent
          ? const Value.absent()
          : Value(latitude),
      longitude: longitude == null && nullToAbsent
          ? const Value.absent()
          : Value(longitude),
      gpsTimestamp: gpsTimestamp == null && nullToAbsent
          ? const Value.absent()
          : Value(gpsTimestamp),
      observacoes: observacoes == null && nullToAbsent
          ? const Value.absent()
          : Value(observacoes),
      ordem: Value(ordem),
      obrigatorio: Value(obrigatorio),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      isSynced: Value(isSynced),
    );
  }

  factory RespostasInspecaoData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RespostasInspecaoData(
      id: serializer.fromJson<String>(json['id']),
      inspecaoId: serializer.fromJson<String>(json['inspecaoId']),
      itemChecklistId: serializer.fromJson<String>(json['itemChecklistId']),
      itemDescricao: serializer.fromJson<String>(json['itemDescricao']),
      categoria: serializer.fromJson<String>(json['categoria']),
      status: serializer.fromJson<ItemStatus>(json['status']),
      valorTexto: serializer.fromJson<String?>(json['valorTexto']),
      valorNumero: serializer.fromJson<double?>(json['valorNumero']),
      valorData: serializer.fromJson<DateTime?>(json['valorData']),
      valorRating: serializer.fromJson<int?>(json['valorRating']),
      valorBooleano: serializer.fromJson<bool?>(json['valorBooleano']),
      latitude: serializer.fromJson<double?>(json['latitude']),
      longitude: serializer.fromJson<double?>(json['longitude']),
      gpsTimestamp: serializer.fromJson<DateTime?>(json['gpsTimestamp']),
      observacoes: serializer.fromJson<String?>(json['observacoes']),
      ordem: serializer.fromJson<int>(json['ordem']),
      obrigatorio: serializer.fromJson<bool>(json['obrigatorio']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      isSynced: serializer.fromJson<bool>(json['isSynced']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'inspecaoId': serializer.toJson<String>(inspecaoId),
      'itemChecklistId': serializer.toJson<String>(itemChecklistId),
      'itemDescricao': serializer.toJson<String>(itemDescricao),
      'categoria': serializer.toJson<String>(categoria),
      'status': serializer.toJson<ItemStatus>(status),
      'valorTexto': serializer.toJson<String?>(valorTexto),
      'valorNumero': serializer.toJson<double?>(valorNumero),
      'valorData': serializer.toJson<DateTime?>(valorData),
      'valorRating': serializer.toJson<int?>(valorRating),
      'valorBooleano': serializer.toJson<bool?>(valorBooleano),
      'latitude': serializer.toJson<double?>(latitude),
      'longitude': serializer.toJson<double?>(longitude),
      'gpsTimestamp': serializer.toJson<DateTime?>(gpsTimestamp),
      'observacoes': serializer.toJson<String?>(observacoes),
      'ordem': serializer.toJson<int>(ordem),
      'obrigatorio': serializer.toJson<bool>(obrigatorio),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'isSynced': serializer.toJson<bool>(isSynced),
    };
  }

  RespostasInspecaoData copyWith({
    String? id,
    String? inspecaoId,
    String? itemChecklistId,
    String? itemDescricao,
    String? categoria,
    ItemStatus? status,
    Value<String?> valorTexto = const Value.absent(),
    Value<double?> valorNumero = const Value.absent(),
    Value<DateTime?> valorData = const Value.absent(),
    Value<int?> valorRating = const Value.absent(),
    Value<bool?> valorBooleano = const Value.absent(),
    Value<double?> latitude = const Value.absent(),
    Value<double?> longitude = const Value.absent(),
    Value<DateTime?> gpsTimestamp = const Value.absent(),
    Value<String?> observacoes = const Value.absent(),
    int? ordem,
    bool? obrigatorio,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isSynced,
  }) => RespostasInspecaoData(
    id: id ?? this.id,
    inspecaoId: inspecaoId ?? this.inspecaoId,
    itemChecklistId: itemChecklistId ?? this.itemChecklistId,
    itemDescricao: itemDescricao ?? this.itemDescricao,
    categoria: categoria ?? this.categoria,
    status: status ?? this.status,
    valorTexto: valorTexto.present ? valorTexto.value : this.valorTexto,
    valorNumero: valorNumero.present ? valorNumero.value : this.valorNumero,
    valorData: valorData.present ? valorData.value : this.valorData,
    valorRating: valorRating.present ? valorRating.value : this.valorRating,
    valorBooleano: valorBooleano.present
        ? valorBooleano.value
        : this.valorBooleano,
    latitude: latitude.present ? latitude.value : this.latitude,
    longitude: longitude.present ? longitude.value : this.longitude,
    gpsTimestamp: gpsTimestamp.present ? gpsTimestamp.value : this.gpsTimestamp,
    observacoes: observacoes.present ? observacoes.value : this.observacoes,
    ordem: ordem ?? this.ordem,
    obrigatorio: obrigatorio ?? this.obrigatorio,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    isSynced: isSynced ?? this.isSynced,
  );
  RespostasInspecaoData copyWithCompanion(RespostasInspecaoCompanion data) {
    return RespostasInspecaoData(
      id: data.id.present ? data.id.value : this.id,
      inspecaoId: data.inspecaoId.present
          ? data.inspecaoId.value
          : this.inspecaoId,
      itemChecklistId: data.itemChecklistId.present
          ? data.itemChecklistId.value
          : this.itemChecklistId,
      itemDescricao: data.itemDescricao.present
          ? data.itemDescricao.value
          : this.itemDescricao,
      categoria: data.categoria.present ? data.categoria.value : this.categoria,
      status: data.status.present ? data.status.value : this.status,
      valorTexto: data.valorTexto.present
          ? data.valorTexto.value
          : this.valorTexto,
      valorNumero: data.valorNumero.present
          ? data.valorNumero.value
          : this.valorNumero,
      valorData: data.valorData.present ? data.valorData.value : this.valorData,
      valorRating: data.valorRating.present
          ? data.valorRating.value
          : this.valorRating,
      valorBooleano: data.valorBooleano.present
          ? data.valorBooleano.value
          : this.valorBooleano,
      latitude: data.latitude.present ? data.latitude.value : this.latitude,
      longitude: data.longitude.present ? data.longitude.value : this.longitude,
      gpsTimestamp: data.gpsTimestamp.present
          ? data.gpsTimestamp.value
          : this.gpsTimestamp,
      observacoes: data.observacoes.present
          ? data.observacoes.value
          : this.observacoes,
      ordem: data.ordem.present ? data.ordem.value : this.ordem,
      obrigatorio: data.obrigatorio.present
          ? data.obrigatorio.value
          : this.obrigatorio,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      isSynced: data.isSynced.present ? data.isSynced.value : this.isSynced,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RespostasInspecaoData(')
          ..write('id: $id, ')
          ..write('inspecaoId: $inspecaoId, ')
          ..write('itemChecklistId: $itemChecklistId, ')
          ..write('itemDescricao: $itemDescricao, ')
          ..write('categoria: $categoria, ')
          ..write('status: $status, ')
          ..write('valorTexto: $valorTexto, ')
          ..write('valorNumero: $valorNumero, ')
          ..write('valorData: $valorData, ')
          ..write('valorRating: $valorRating, ')
          ..write('valorBooleano: $valorBooleano, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('gpsTimestamp: $gpsTimestamp, ')
          ..write('observacoes: $observacoes, ')
          ..write('ordem: $ordem, ')
          ..write('obrigatorio: $obrigatorio, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('isSynced: $isSynced')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    inspecaoId,
    itemChecklistId,
    itemDescricao,
    categoria,
    status,
    valorTexto,
    valorNumero,
    valorData,
    valorRating,
    valorBooleano,
    latitude,
    longitude,
    gpsTimestamp,
    observacoes,
    ordem,
    obrigatorio,
    createdAt,
    updatedAt,
    isSynced,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RespostasInspecaoData &&
          other.id == this.id &&
          other.inspecaoId == this.inspecaoId &&
          other.itemChecklistId == this.itemChecklistId &&
          other.itemDescricao == this.itemDescricao &&
          other.categoria == this.categoria &&
          other.status == this.status &&
          other.valorTexto == this.valorTexto &&
          other.valorNumero == this.valorNumero &&
          other.valorData == this.valorData &&
          other.valorRating == this.valorRating &&
          other.valorBooleano == this.valorBooleano &&
          other.latitude == this.latitude &&
          other.longitude == this.longitude &&
          other.gpsTimestamp == this.gpsTimestamp &&
          other.observacoes == this.observacoes &&
          other.ordem == this.ordem &&
          other.obrigatorio == this.obrigatorio &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.isSynced == this.isSynced);
}

class RespostasInspecaoCompanion
    extends UpdateCompanion<RespostasInspecaoData> {
  final Value<String> id;
  final Value<String> inspecaoId;
  final Value<String> itemChecklistId;
  final Value<String> itemDescricao;
  final Value<String> categoria;
  final Value<ItemStatus> status;
  final Value<String?> valorTexto;
  final Value<double?> valorNumero;
  final Value<DateTime?> valorData;
  final Value<int?> valorRating;
  final Value<bool?> valorBooleano;
  final Value<double?> latitude;
  final Value<double?> longitude;
  final Value<DateTime?> gpsTimestamp;
  final Value<String?> observacoes;
  final Value<int> ordem;
  final Value<bool> obrigatorio;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<bool> isSynced;
  final Value<int> rowid;
  const RespostasInspecaoCompanion({
    this.id = const Value.absent(),
    this.inspecaoId = const Value.absent(),
    this.itemChecklistId = const Value.absent(),
    this.itemDescricao = const Value.absent(),
    this.categoria = const Value.absent(),
    this.status = const Value.absent(),
    this.valorTexto = const Value.absent(),
    this.valorNumero = const Value.absent(),
    this.valorData = const Value.absent(),
    this.valorRating = const Value.absent(),
    this.valorBooleano = const Value.absent(),
    this.latitude = const Value.absent(),
    this.longitude = const Value.absent(),
    this.gpsTimestamp = const Value.absent(),
    this.observacoes = const Value.absent(),
    this.ordem = const Value.absent(),
    this.obrigatorio = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RespostasInspecaoCompanion.insert({
    required String id,
    required String inspecaoId,
    required String itemChecklistId,
    required String itemDescricao,
    required String categoria,
    required ItemStatus status,
    this.valorTexto = const Value.absent(),
    this.valorNumero = const Value.absent(),
    this.valorData = const Value.absent(),
    this.valorRating = const Value.absent(),
    this.valorBooleano = const Value.absent(),
    this.latitude = const Value.absent(),
    this.longitude = const Value.absent(),
    this.gpsTimestamp = const Value.absent(),
    this.observacoes = const Value.absent(),
    required int ordem,
    this.obrigatorio = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.isSynced = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       inspecaoId = Value(inspecaoId),
       itemChecklistId = Value(itemChecklistId),
       itemDescricao = Value(itemDescricao),
       categoria = Value(categoria),
       status = Value(status),
       ordem = Value(ordem),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<RespostasInspecaoData> custom({
    Expression<String>? id,
    Expression<String>? inspecaoId,
    Expression<String>? itemChecklistId,
    Expression<String>? itemDescricao,
    Expression<String>? categoria,
    Expression<String>? status,
    Expression<String>? valorTexto,
    Expression<double>? valorNumero,
    Expression<DateTime>? valorData,
    Expression<int>? valorRating,
    Expression<bool>? valorBooleano,
    Expression<double>? latitude,
    Expression<double>? longitude,
    Expression<DateTime>? gpsTimestamp,
    Expression<String>? observacoes,
    Expression<int>? ordem,
    Expression<bool>? obrigatorio,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<bool>? isSynced,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (inspecaoId != null) 'inspecao_id': inspecaoId,
      if (itemChecklistId != null) 'item_checklist_id': itemChecklistId,
      if (itemDescricao != null) 'item_descricao': itemDescricao,
      if (categoria != null) 'categoria': categoria,
      if (status != null) 'status': status,
      if (valorTexto != null) 'valor_texto': valorTexto,
      if (valorNumero != null) 'valor_numero': valorNumero,
      if (valorData != null) 'valor_data': valorData,
      if (valorRating != null) 'valor_rating': valorRating,
      if (valorBooleano != null) 'valor_booleano': valorBooleano,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (gpsTimestamp != null) 'gps_timestamp': gpsTimestamp,
      if (observacoes != null) 'observacoes': observacoes,
      if (ordem != null) 'ordem': ordem,
      if (obrigatorio != null) 'obrigatorio': obrigatorio,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (isSynced != null) 'is_synced': isSynced,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RespostasInspecaoCompanion copyWith({
    Value<String>? id,
    Value<String>? inspecaoId,
    Value<String>? itemChecklistId,
    Value<String>? itemDescricao,
    Value<String>? categoria,
    Value<ItemStatus>? status,
    Value<String?>? valorTexto,
    Value<double?>? valorNumero,
    Value<DateTime?>? valorData,
    Value<int?>? valorRating,
    Value<bool?>? valorBooleano,
    Value<double?>? latitude,
    Value<double?>? longitude,
    Value<DateTime?>? gpsTimestamp,
    Value<String?>? observacoes,
    Value<int>? ordem,
    Value<bool>? obrigatorio,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<bool>? isSynced,
    Value<int>? rowid,
  }) {
    return RespostasInspecaoCompanion(
      id: id ?? this.id,
      inspecaoId: inspecaoId ?? this.inspecaoId,
      itemChecklistId: itemChecklistId ?? this.itemChecklistId,
      itemDescricao: itemDescricao ?? this.itemDescricao,
      categoria: categoria ?? this.categoria,
      status: status ?? this.status,
      valorTexto: valorTexto ?? this.valorTexto,
      valorNumero: valorNumero ?? this.valorNumero,
      valorData: valorData ?? this.valorData,
      valorRating: valorRating ?? this.valorRating,
      valorBooleano: valorBooleano ?? this.valorBooleano,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      gpsTimestamp: gpsTimestamp ?? this.gpsTimestamp,
      observacoes: observacoes ?? this.observacoes,
      ordem: ordem ?? this.ordem,
      obrigatorio: obrigatorio ?? this.obrigatorio,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isSynced: isSynced ?? this.isSynced,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (inspecaoId.present) {
      map['inspecao_id'] = Variable<String>(inspecaoId.value);
    }
    if (itemChecklistId.present) {
      map['item_checklist_id'] = Variable<String>(itemChecklistId.value);
    }
    if (itemDescricao.present) {
      map['item_descricao'] = Variable<String>(itemDescricao.value);
    }
    if (categoria.present) {
      map['categoria'] = Variable<String>(categoria.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(
        $RespostasInspecaoTable.$converterstatus.toSql(status.value),
      );
    }
    if (valorTexto.present) {
      map['valor_texto'] = Variable<String>(valorTexto.value);
    }
    if (valorNumero.present) {
      map['valor_numero'] = Variable<double>(valorNumero.value);
    }
    if (valorData.present) {
      map['valor_data'] = Variable<DateTime>(valorData.value);
    }
    if (valorRating.present) {
      map['valor_rating'] = Variable<int>(valorRating.value);
    }
    if (valorBooleano.present) {
      map['valor_booleano'] = Variable<bool>(valorBooleano.value);
    }
    if (latitude.present) {
      map['latitude'] = Variable<double>(latitude.value);
    }
    if (longitude.present) {
      map['longitude'] = Variable<double>(longitude.value);
    }
    if (gpsTimestamp.present) {
      map['gps_timestamp'] = Variable<DateTime>(gpsTimestamp.value);
    }
    if (observacoes.present) {
      map['observacoes'] = Variable<String>(observacoes.value);
    }
    if (ordem.present) {
      map['ordem'] = Variable<int>(ordem.value);
    }
    if (obrigatorio.present) {
      map['obrigatorio'] = Variable<bool>(obrigatorio.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (isSynced.present) {
      map['is_synced'] = Variable<bool>(isSynced.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RespostasInspecaoCompanion(')
          ..write('id: $id, ')
          ..write('inspecaoId: $inspecaoId, ')
          ..write('itemChecklistId: $itemChecklistId, ')
          ..write('itemDescricao: $itemDescricao, ')
          ..write('categoria: $categoria, ')
          ..write('status: $status, ')
          ..write('valorTexto: $valorTexto, ')
          ..write('valorNumero: $valorNumero, ')
          ..write('valorData: $valorData, ')
          ..write('valorRating: $valorRating, ')
          ..write('valorBooleano: $valorBooleano, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('gpsTimestamp: $gpsTimestamp, ')
          ..write('observacoes: $observacoes, ')
          ..write('ordem: $ordem, ')
          ..write('obrigatorio: $obrigatorio, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('isSynced: $isSynced, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AnexosInspecaoTable extends AnexosInspecao
    with TableInfo<$AnexosInspecaoTable, AnexosInspecaoData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AnexosInspecaoTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _inspecaoIdMeta = const VerificationMeta(
    'inspecaoId',
  );
  @override
  late final GeneratedColumn<String> inspecaoId = GeneratedColumn<String>(
    'inspecao_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _respostaIdMeta = const VerificationMeta(
    'respostaId',
  );
  @override
  late final GeneratedColumn<String> respostaId = GeneratedColumn<String>(
    'resposta_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _nomeArquivoMeta = const VerificationMeta(
    'nomeArquivo',
  );
  @override
  late final GeneratedColumn<String> nomeArquivo = GeneratedColumn<String>(
    'nome_arquivo',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tipoMimeMeta = const VerificationMeta(
    'tipoMime',
  );
  @override
  late final GeneratedColumn<String> tipoMime = GeneratedColumn<String>(
    'tipo_mime',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tamanhoMeta = const VerificationMeta(
    'tamanho',
  );
  @override
  late final GeneratedColumn<int> tamanho = GeneratedColumn<int>(
    'tamanho',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _caminhoLocalMeta = const VerificationMeta(
    'caminhoLocal',
  );
  @override
  late final GeneratedColumn<String> caminhoLocal = GeneratedColumn<String>(
    'caminho_local',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _urlServidorMeta = const VerificationMeta(
    'urlServidor',
  );
  @override
  late final GeneratedColumn<String> urlServidor = GeneratedColumn<String>(
    'url_servidor',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _descricaoMeta = const VerificationMeta(
    'descricao',
  );
  @override
  late final GeneratedColumn<String> descricao = GeneratedColumn<String>(
    'descricao',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _dataCapturaMeta = const VerificationMeta(
    'dataCaptura',
  );
  @override
  late final GeneratedColumn<DateTime> dataCaptura = GeneratedColumn<DateTime>(
    'data_captura',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isSyncedMeta = const VerificationMeta(
    'isSynced',
  );
  @override
  late final GeneratedColumn<bool> isSynced = GeneratedColumn<bool>(
    'is_synced',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_synced" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _serverIdMeta = const VerificationMeta(
    'serverId',
  );
  @override
  late final GeneratedColumn<String> serverId = GeneratedColumn<String>(
    'server_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    inspecaoId,
    respostaId,
    nomeArquivo,
    tipoMime,
    tamanho,
    caminhoLocal,
    urlServidor,
    descricao,
    dataCaptura,
    isSynced,
    createdAt,
    updatedAt,
    serverId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'anexos_inspecao';
  @override
  VerificationContext validateIntegrity(
    Insertable<AnexosInspecaoData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('inspecao_id')) {
      context.handle(
        _inspecaoIdMeta,
        inspecaoId.isAcceptableOrUnknown(data['inspecao_id']!, _inspecaoIdMeta),
      );
    } else if (isInserting) {
      context.missing(_inspecaoIdMeta);
    }
    if (data.containsKey('resposta_id')) {
      context.handle(
        _respostaIdMeta,
        respostaId.isAcceptableOrUnknown(data['resposta_id']!, _respostaIdMeta),
      );
    }
    if (data.containsKey('nome_arquivo')) {
      context.handle(
        _nomeArquivoMeta,
        nomeArquivo.isAcceptableOrUnknown(
          data['nome_arquivo']!,
          _nomeArquivoMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_nomeArquivoMeta);
    }
    if (data.containsKey('tipo_mime')) {
      context.handle(
        _tipoMimeMeta,
        tipoMime.isAcceptableOrUnknown(data['tipo_mime']!, _tipoMimeMeta),
      );
    } else if (isInserting) {
      context.missing(_tipoMimeMeta);
    }
    if (data.containsKey('tamanho')) {
      context.handle(
        _tamanhoMeta,
        tamanho.isAcceptableOrUnknown(data['tamanho']!, _tamanhoMeta),
      );
    } else if (isInserting) {
      context.missing(_tamanhoMeta);
    }
    if (data.containsKey('caminho_local')) {
      context.handle(
        _caminhoLocalMeta,
        caminhoLocal.isAcceptableOrUnknown(
          data['caminho_local']!,
          _caminhoLocalMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_caminhoLocalMeta);
    }
    if (data.containsKey('url_servidor')) {
      context.handle(
        _urlServidorMeta,
        urlServidor.isAcceptableOrUnknown(
          data['url_servidor']!,
          _urlServidorMeta,
        ),
      );
    }
    if (data.containsKey('descricao')) {
      context.handle(
        _descricaoMeta,
        descricao.isAcceptableOrUnknown(data['descricao']!, _descricaoMeta),
      );
    }
    if (data.containsKey('data_captura')) {
      context.handle(
        _dataCapturaMeta,
        dataCaptura.isAcceptableOrUnknown(
          data['data_captura']!,
          _dataCapturaMeta,
        ),
      );
    }
    if (data.containsKey('is_synced')) {
      context.handle(
        _isSyncedMeta,
        isSynced.isAcceptableOrUnknown(data['is_synced']!, _isSyncedMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('server_id')) {
      context.handle(
        _serverIdMeta,
        serverId.isAcceptableOrUnknown(data['server_id']!, _serverIdMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AnexosInspecaoData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AnexosInspecaoData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      inspecaoId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}inspecao_id'],
      )!,
      respostaId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}resposta_id'],
      ),
      nomeArquivo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}nome_arquivo'],
      )!,
      tipoMime: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tipo_mime'],
      )!,
      tamanho: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}tamanho'],
      )!,
      caminhoLocal: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}caminho_local'],
      )!,
      urlServidor: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}url_servidor'],
      ),
      descricao: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}descricao'],
      ),
      dataCaptura: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}data_captura'],
      ),
      isSynced: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_synced'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      serverId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}server_id'],
      ),
    );
  }

  @override
  $AnexosInspecaoTable createAlias(String alias) {
    return $AnexosInspecaoTable(attachedDatabase, alias);
  }
}

class AnexosInspecaoData extends DataClass
    implements Insertable<AnexosInspecaoData> {
  final String id;
  final String inspecaoId;
  final String? respostaId;
  final String nomeArquivo;
  final String tipoMime;
  final int tamanho;
  final String caminhoLocal;
  final String? urlServidor;
  final String? descricao;
  final DateTime? dataCaptura;
  final bool isSynced;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? serverId;
  const AnexosInspecaoData({
    required this.id,
    required this.inspecaoId,
    this.respostaId,
    required this.nomeArquivo,
    required this.tipoMime,
    required this.tamanho,
    required this.caminhoLocal,
    this.urlServidor,
    this.descricao,
    this.dataCaptura,
    required this.isSynced,
    required this.createdAt,
    required this.updatedAt,
    this.serverId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['inspecao_id'] = Variable<String>(inspecaoId);
    if (!nullToAbsent || respostaId != null) {
      map['resposta_id'] = Variable<String>(respostaId);
    }
    map['nome_arquivo'] = Variable<String>(nomeArquivo);
    map['tipo_mime'] = Variable<String>(tipoMime);
    map['tamanho'] = Variable<int>(tamanho);
    map['caminho_local'] = Variable<String>(caminhoLocal);
    if (!nullToAbsent || urlServidor != null) {
      map['url_servidor'] = Variable<String>(urlServidor);
    }
    if (!nullToAbsent || descricao != null) {
      map['descricao'] = Variable<String>(descricao);
    }
    if (!nullToAbsent || dataCaptura != null) {
      map['data_captura'] = Variable<DateTime>(dataCaptura);
    }
    map['is_synced'] = Variable<bool>(isSynced);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || serverId != null) {
      map['server_id'] = Variable<String>(serverId);
    }
    return map;
  }

  AnexosInspecaoCompanion toCompanion(bool nullToAbsent) {
    return AnexosInspecaoCompanion(
      id: Value(id),
      inspecaoId: Value(inspecaoId),
      respostaId: respostaId == null && nullToAbsent
          ? const Value.absent()
          : Value(respostaId),
      nomeArquivo: Value(nomeArquivo),
      tipoMime: Value(tipoMime),
      tamanho: Value(tamanho),
      caminhoLocal: Value(caminhoLocal),
      urlServidor: urlServidor == null && nullToAbsent
          ? const Value.absent()
          : Value(urlServidor),
      descricao: descricao == null && nullToAbsent
          ? const Value.absent()
          : Value(descricao),
      dataCaptura: dataCaptura == null && nullToAbsent
          ? const Value.absent()
          : Value(dataCaptura),
      isSynced: Value(isSynced),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      serverId: serverId == null && nullToAbsent
          ? const Value.absent()
          : Value(serverId),
    );
  }

  factory AnexosInspecaoData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AnexosInspecaoData(
      id: serializer.fromJson<String>(json['id']),
      inspecaoId: serializer.fromJson<String>(json['inspecaoId']),
      respostaId: serializer.fromJson<String?>(json['respostaId']),
      nomeArquivo: serializer.fromJson<String>(json['nomeArquivo']),
      tipoMime: serializer.fromJson<String>(json['tipoMime']),
      tamanho: serializer.fromJson<int>(json['tamanho']),
      caminhoLocal: serializer.fromJson<String>(json['caminhoLocal']),
      urlServidor: serializer.fromJson<String?>(json['urlServidor']),
      descricao: serializer.fromJson<String?>(json['descricao']),
      dataCaptura: serializer.fromJson<DateTime?>(json['dataCaptura']),
      isSynced: serializer.fromJson<bool>(json['isSynced']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      serverId: serializer.fromJson<String?>(json['serverId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'inspecaoId': serializer.toJson<String>(inspecaoId),
      'respostaId': serializer.toJson<String?>(respostaId),
      'nomeArquivo': serializer.toJson<String>(nomeArquivo),
      'tipoMime': serializer.toJson<String>(tipoMime),
      'tamanho': serializer.toJson<int>(tamanho),
      'caminhoLocal': serializer.toJson<String>(caminhoLocal),
      'urlServidor': serializer.toJson<String?>(urlServidor),
      'descricao': serializer.toJson<String?>(descricao),
      'dataCaptura': serializer.toJson<DateTime?>(dataCaptura),
      'isSynced': serializer.toJson<bool>(isSynced),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'serverId': serializer.toJson<String?>(serverId),
    };
  }

  AnexosInspecaoData copyWith({
    String? id,
    String? inspecaoId,
    Value<String?> respostaId = const Value.absent(),
    String? nomeArquivo,
    String? tipoMime,
    int? tamanho,
    String? caminhoLocal,
    Value<String?> urlServidor = const Value.absent(),
    Value<String?> descricao = const Value.absent(),
    Value<DateTime?> dataCaptura = const Value.absent(),
    bool? isSynced,
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<String?> serverId = const Value.absent(),
  }) => AnexosInspecaoData(
    id: id ?? this.id,
    inspecaoId: inspecaoId ?? this.inspecaoId,
    respostaId: respostaId.present ? respostaId.value : this.respostaId,
    nomeArquivo: nomeArquivo ?? this.nomeArquivo,
    tipoMime: tipoMime ?? this.tipoMime,
    tamanho: tamanho ?? this.tamanho,
    caminhoLocal: caminhoLocal ?? this.caminhoLocal,
    urlServidor: urlServidor.present ? urlServidor.value : this.urlServidor,
    descricao: descricao.present ? descricao.value : this.descricao,
    dataCaptura: dataCaptura.present ? dataCaptura.value : this.dataCaptura,
    isSynced: isSynced ?? this.isSynced,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    serverId: serverId.present ? serverId.value : this.serverId,
  );
  AnexosInspecaoData copyWithCompanion(AnexosInspecaoCompanion data) {
    return AnexosInspecaoData(
      id: data.id.present ? data.id.value : this.id,
      inspecaoId: data.inspecaoId.present
          ? data.inspecaoId.value
          : this.inspecaoId,
      respostaId: data.respostaId.present
          ? data.respostaId.value
          : this.respostaId,
      nomeArquivo: data.nomeArquivo.present
          ? data.nomeArquivo.value
          : this.nomeArquivo,
      tipoMime: data.tipoMime.present ? data.tipoMime.value : this.tipoMime,
      tamanho: data.tamanho.present ? data.tamanho.value : this.tamanho,
      caminhoLocal: data.caminhoLocal.present
          ? data.caminhoLocal.value
          : this.caminhoLocal,
      urlServidor: data.urlServidor.present
          ? data.urlServidor.value
          : this.urlServidor,
      descricao: data.descricao.present ? data.descricao.value : this.descricao,
      dataCaptura: data.dataCaptura.present
          ? data.dataCaptura.value
          : this.dataCaptura,
      isSynced: data.isSynced.present ? data.isSynced.value : this.isSynced,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      serverId: data.serverId.present ? data.serverId.value : this.serverId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AnexosInspecaoData(')
          ..write('id: $id, ')
          ..write('inspecaoId: $inspecaoId, ')
          ..write('respostaId: $respostaId, ')
          ..write('nomeArquivo: $nomeArquivo, ')
          ..write('tipoMime: $tipoMime, ')
          ..write('tamanho: $tamanho, ')
          ..write('caminhoLocal: $caminhoLocal, ')
          ..write('urlServidor: $urlServidor, ')
          ..write('descricao: $descricao, ')
          ..write('dataCaptura: $dataCaptura, ')
          ..write('isSynced: $isSynced, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('serverId: $serverId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    inspecaoId,
    respostaId,
    nomeArquivo,
    tipoMime,
    tamanho,
    caminhoLocal,
    urlServidor,
    descricao,
    dataCaptura,
    isSynced,
    createdAt,
    updatedAt,
    serverId,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AnexosInspecaoData &&
          other.id == this.id &&
          other.inspecaoId == this.inspecaoId &&
          other.respostaId == this.respostaId &&
          other.nomeArquivo == this.nomeArquivo &&
          other.tipoMime == this.tipoMime &&
          other.tamanho == this.tamanho &&
          other.caminhoLocal == this.caminhoLocal &&
          other.urlServidor == this.urlServidor &&
          other.descricao == this.descricao &&
          other.dataCaptura == this.dataCaptura &&
          other.isSynced == this.isSynced &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.serverId == this.serverId);
}

class AnexosInspecaoCompanion extends UpdateCompanion<AnexosInspecaoData> {
  final Value<String> id;
  final Value<String> inspecaoId;
  final Value<String?> respostaId;
  final Value<String> nomeArquivo;
  final Value<String> tipoMime;
  final Value<int> tamanho;
  final Value<String> caminhoLocal;
  final Value<String?> urlServidor;
  final Value<String?> descricao;
  final Value<DateTime?> dataCaptura;
  final Value<bool> isSynced;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<String?> serverId;
  final Value<int> rowid;
  const AnexosInspecaoCompanion({
    this.id = const Value.absent(),
    this.inspecaoId = const Value.absent(),
    this.respostaId = const Value.absent(),
    this.nomeArquivo = const Value.absent(),
    this.tipoMime = const Value.absent(),
    this.tamanho = const Value.absent(),
    this.caminhoLocal = const Value.absent(),
    this.urlServidor = const Value.absent(),
    this.descricao = const Value.absent(),
    this.dataCaptura = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.serverId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AnexosInspecaoCompanion.insert({
    required String id,
    required String inspecaoId,
    this.respostaId = const Value.absent(),
    required String nomeArquivo,
    required String tipoMime,
    required int tamanho,
    required String caminhoLocal,
    this.urlServidor = const Value.absent(),
    this.descricao = const Value.absent(),
    this.dataCaptura = const Value.absent(),
    this.isSynced = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.serverId = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       inspecaoId = Value(inspecaoId),
       nomeArquivo = Value(nomeArquivo),
       tipoMime = Value(tipoMime),
       tamanho = Value(tamanho),
       caminhoLocal = Value(caminhoLocal),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<AnexosInspecaoData> custom({
    Expression<String>? id,
    Expression<String>? inspecaoId,
    Expression<String>? respostaId,
    Expression<String>? nomeArquivo,
    Expression<String>? tipoMime,
    Expression<int>? tamanho,
    Expression<String>? caminhoLocal,
    Expression<String>? urlServidor,
    Expression<String>? descricao,
    Expression<DateTime>? dataCaptura,
    Expression<bool>? isSynced,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<String>? serverId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (inspecaoId != null) 'inspecao_id': inspecaoId,
      if (respostaId != null) 'resposta_id': respostaId,
      if (nomeArquivo != null) 'nome_arquivo': nomeArquivo,
      if (tipoMime != null) 'tipo_mime': tipoMime,
      if (tamanho != null) 'tamanho': tamanho,
      if (caminhoLocal != null) 'caminho_local': caminhoLocal,
      if (urlServidor != null) 'url_servidor': urlServidor,
      if (descricao != null) 'descricao': descricao,
      if (dataCaptura != null) 'data_captura': dataCaptura,
      if (isSynced != null) 'is_synced': isSynced,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (serverId != null) 'server_id': serverId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AnexosInspecaoCompanion copyWith({
    Value<String>? id,
    Value<String>? inspecaoId,
    Value<String?>? respostaId,
    Value<String>? nomeArquivo,
    Value<String>? tipoMime,
    Value<int>? tamanho,
    Value<String>? caminhoLocal,
    Value<String?>? urlServidor,
    Value<String?>? descricao,
    Value<DateTime?>? dataCaptura,
    Value<bool>? isSynced,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<String?>? serverId,
    Value<int>? rowid,
  }) {
    return AnexosInspecaoCompanion(
      id: id ?? this.id,
      inspecaoId: inspecaoId ?? this.inspecaoId,
      respostaId: respostaId ?? this.respostaId,
      nomeArquivo: nomeArquivo ?? this.nomeArquivo,
      tipoMime: tipoMime ?? this.tipoMime,
      tamanho: tamanho ?? this.tamanho,
      caminhoLocal: caminhoLocal ?? this.caminhoLocal,
      urlServidor: urlServidor ?? this.urlServidor,
      descricao: descricao ?? this.descricao,
      dataCaptura: dataCaptura ?? this.dataCaptura,
      isSynced: isSynced ?? this.isSynced,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      serverId: serverId ?? this.serverId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (inspecaoId.present) {
      map['inspecao_id'] = Variable<String>(inspecaoId.value);
    }
    if (respostaId.present) {
      map['resposta_id'] = Variable<String>(respostaId.value);
    }
    if (nomeArquivo.present) {
      map['nome_arquivo'] = Variable<String>(nomeArquivo.value);
    }
    if (tipoMime.present) {
      map['tipo_mime'] = Variable<String>(tipoMime.value);
    }
    if (tamanho.present) {
      map['tamanho'] = Variable<int>(tamanho.value);
    }
    if (caminhoLocal.present) {
      map['caminho_local'] = Variable<String>(caminhoLocal.value);
    }
    if (urlServidor.present) {
      map['url_servidor'] = Variable<String>(urlServidor.value);
    }
    if (descricao.present) {
      map['descricao'] = Variable<String>(descricao.value);
    }
    if (dataCaptura.present) {
      map['data_captura'] = Variable<DateTime>(dataCaptura.value);
    }
    if (isSynced.present) {
      map['is_synced'] = Variable<bool>(isSynced.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (serverId.present) {
      map['server_id'] = Variable<String>(serverId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AnexosInspecaoCompanion(')
          ..write('id: $id, ')
          ..write('inspecaoId: $inspecaoId, ')
          ..write('respostaId: $respostaId, ')
          ..write('nomeArquivo: $nomeArquivo, ')
          ..write('tipoMime: $tipoMime, ')
          ..write('tamanho: $tamanho, ')
          ..write('caminhoLocal: $caminhoLocal, ')
          ..write('urlServidor: $urlServidor, ')
          ..write('descricao: $descricao, ')
          ..write('dataCaptura: $dataCaptura, ')
          ..write('isSynced: $isSynced, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('serverId: $serverId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ChecklistsTable extends Checklists
    with TableInfo<$ChecklistsTable, Checklist> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ChecklistsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nomeMeta = const VerificationMeta('nome');
  @override
  late final GeneratedColumn<String> nome = GeneratedColumn<String>(
    'nome',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _versaoMeta = const VerificationMeta('versao');
  @override
  late final GeneratedColumn<String> versao = GeneratedColumn<String>(
    'versao',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoriaMeta = const VerificationMeta(
    'categoria',
  );
  @override
  late final GeneratedColumn<String> categoria = GeneratedColumn<String>(
    'categoria',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _jsonDataMeta = const VerificationMeta(
    'jsonData',
  );
  @override
  late final GeneratedColumn<String> jsonData = GeneratedColumn<String>(
    'json_data',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dataDownloadMeta = const VerificationMeta(
    'dataDownload',
  );
  @override
  late final GeneratedColumn<DateTime> dataDownload = GeneratedColumn<DateTime>(
    'data_download',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ultimaAtualizacaoMeta = const VerificationMeta(
    'ultimaAtualizacao',
  );
  @override
  late final GeneratedColumn<DateTime> ultimaAtualizacao =
      GeneratedColumn<DateTime>(
        'ultima_atualizacao',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _isAtivoMeta = const VerificationMeta(
    'isAtivo',
  );
  @override
  late final GeneratedColumn<bool> isAtivo = GeneratedColumn<bool>(
    'is_ativo',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_ativo" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    nome,
    versao,
    categoria,
    jsonData,
    dataDownload,
    ultimaAtualizacao,
    isAtivo,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'checklists';
  @override
  VerificationContext validateIntegrity(
    Insertable<Checklist> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('nome')) {
      context.handle(
        _nomeMeta,
        nome.isAcceptableOrUnknown(data['nome']!, _nomeMeta),
      );
    } else if (isInserting) {
      context.missing(_nomeMeta);
    }
    if (data.containsKey('versao')) {
      context.handle(
        _versaoMeta,
        versao.isAcceptableOrUnknown(data['versao']!, _versaoMeta),
      );
    } else if (isInserting) {
      context.missing(_versaoMeta);
    }
    if (data.containsKey('categoria')) {
      context.handle(
        _categoriaMeta,
        categoria.isAcceptableOrUnknown(data['categoria']!, _categoriaMeta),
      );
    }
    if (data.containsKey('json_data')) {
      context.handle(
        _jsonDataMeta,
        jsonData.isAcceptableOrUnknown(data['json_data']!, _jsonDataMeta),
      );
    } else if (isInserting) {
      context.missing(_jsonDataMeta);
    }
    if (data.containsKey('data_download')) {
      context.handle(
        _dataDownloadMeta,
        dataDownload.isAcceptableOrUnknown(
          data['data_download']!,
          _dataDownloadMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_dataDownloadMeta);
    }
    if (data.containsKey('ultima_atualizacao')) {
      context.handle(
        _ultimaAtualizacaoMeta,
        ultimaAtualizacao.isAcceptableOrUnknown(
          data['ultima_atualizacao']!,
          _ultimaAtualizacaoMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_ultimaAtualizacaoMeta);
    }
    if (data.containsKey('is_ativo')) {
      context.handle(
        _isAtivoMeta,
        isAtivo.isAcceptableOrUnknown(data['is_ativo']!, _isAtivoMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Checklist map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Checklist(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      nome: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}nome'],
      )!,
      versao: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}versao'],
      )!,
      categoria: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}categoria'],
      ),
      jsonData: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}json_data'],
      )!,
      dataDownload: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}data_download'],
      )!,
      ultimaAtualizacao: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}ultima_atualizacao'],
      )!,
      isAtivo: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_ativo'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $ChecklistsTable createAlias(String alias) {
    return $ChecklistsTable(attachedDatabase, alias);
  }
}

class Checklist extends DataClass implements Insertable<Checklist> {
  final String id;
  final String nome;
  final String versao;
  final String? categoria;
  final String jsonData;
  final DateTime dataDownload;
  final DateTime ultimaAtualizacao;
  final bool isAtivo;
  final DateTime createdAt;
  final DateTime updatedAt;
  const Checklist({
    required this.id,
    required this.nome,
    required this.versao,
    this.categoria,
    required this.jsonData,
    required this.dataDownload,
    required this.ultimaAtualizacao,
    required this.isAtivo,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['nome'] = Variable<String>(nome);
    map['versao'] = Variable<String>(versao);
    if (!nullToAbsent || categoria != null) {
      map['categoria'] = Variable<String>(categoria);
    }
    map['json_data'] = Variable<String>(jsonData);
    map['data_download'] = Variable<DateTime>(dataDownload);
    map['ultima_atualizacao'] = Variable<DateTime>(ultimaAtualizacao);
    map['is_ativo'] = Variable<bool>(isAtivo);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  ChecklistsCompanion toCompanion(bool nullToAbsent) {
    return ChecklistsCompanion(
      id: Value(id),
      nome: Value(nome),
      versao: Value(versao),
      categoria: categoria == null && nullToAbsent
          ? const Value.absent()
          : Value(categoria),
      jsonData: Value(jsonData),
      dataDownload: Value(dataDownload),
      ultimaAtualizacao: Value(ultimaAtualizacao),
      isAtivo: Value(isAtivo),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Checklist.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Checklist(
      id: serializer.fromJson<String>(json['id']),
      nome: serializer.fromJson<String>(json['nome']),
      versao: serializer.fromJson<String>(json['versao']),
      categoria: serializer.fromJson<String?>(json['categoria']),
      jsonData: serializer.fromJson<String>(json['jsonData']),
      dataDownload: serializer.fromJson<DateTime>(json['dataDownload']),
      ultimaAtualizacao: serializer.fromJson<DateTime>(
        json['ultimaAtualizacao'],
      ),
      isAtivo: serializer.fromJson<bool>(json['isAtivo']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'nome': serializer.toJson<String>(nome),
      'versao': serializer.toJson<String>(versao),
      'categoria': serializer.toJson<String?>(categoria),
      'jsonData': serializer.toJson<String>(jsonData),
      'dataDownload': serializer.toJson<DateTime>(dataDownload),
      'ultimaAtualizacao': serializer.toJson<DateTime>(ultimaAtualizacao),
      'isAtivo': serializer.toJson<bool>(isAtivo),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Checklist copyWith({
    String? id,
    String? nome,
    String? versao,
    Value<String?> categoria = const Value.absent(),
    String? jsonData,
    DateTime? dataDownload,
    DateTime? ultimaAtualizacao,
    bool? isAtivo,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Checklist(
    id: id ?? this.id,
    nome: nome ?? this.nome,
    versao: versao ?? this.versao,
    categoria: categoria.present ? categoria.value : this.categoria,
    jsonData: jsonData ?? this.jsonData,
    dataDownload: dataDownload ?? this.dataDownload,
    ultimaAtualizacao: ultimaAtualizacao ?? this.ultimaAtualizacao,
    isAtivo: isAtivo ?? this.isAtivo,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Checklist copyWithCompanion(ChecklistsCompanion data) {
    return Checklist(
      id: data.id.present ? data.id.value : this.id,
      nome: data.nome.present ? data.nome.value : this.nome,
      versao: data.versao.present ? data.versao.value : this.versao,
      categoria: data.categoria.present ? data.categoria.value : this.categoria,
      jsonData: data.jsonData.present ? data.jsonData.value : this.jsonData,
      dataDownload: data.dataDownload.present
          ? data.dataDownload.value
          : this.dataDownload,
      ultimaAtualizacao: data.ultimaAtualizacao.present
          ? data.ultimaAtualizacao.value
          : this.ultimaAtualizacao,
      isAtivo: data.isAtivo.present ? data.isAtivo.value : this.isAtivo,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Checklist(')
          ..write('id: $id, ')
          ..write('nome: $nome, ')
          ..write('versao: $versao, ')
          ..write('categoria: $categoria, ')
          ..write('jsonData: $jsonData, ')
          ..write('dataDownload: $dataDownload, ')
          ..write('ultimaAtualizacao: $ultimaAtualizacao, ')
          ..write('isAtivo: $isAtivo, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    nome,
    versao,
    categoria,
    jsonData,
    dataDownload,
    ultimaAtualizacao,
    isAtivo,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Checklist &&
          other.id == this.id &&
          other.nome == this.nome &&
          other.versao == this.versao &&
          other.categoria == this.categoria &&
          other.jsonData == this.jsonData &&
          other.dataDownload == this.dataDownload &&
          other.ultimaAtualizacao == this.ultimaAtualizacao &&
          other.isAtivo == this.isAtivo &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class ChecklistsCompanion extends UpdateCompanion<Checklist> {
  final Value<String> id;
  final Value<String> nome;
  final Value<String> versao;
  final Value<String?> categoria;
  final Value<String> jsonData;
  final Value<DateTime> dataDownload;
  final Value<DateTime> ultimaAtualizacao;
  final Value<bool> isAtivo;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const ChecklistsCompanion({
    this.id = const Value.absent(),
    this.nome = const Value.absent(),
    this.versao = const Value.absent(),
    this.categoria = const Value.absent(),
    this.jsonData = const Value.absent(),
    this.dataDownload = const Value.absent(),
    this.ultimaAtualizacao = const Value.absent(),
    this.isAtivo = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ChecklistsCompanion.insert({
    required String id,
    required String nome,
    required String versao,
    this.categoria = const Value.absent(),
    required String jsonData,
    required DateTime dataDownload,
    required DateTime ultimaAtualizacao,
    this.isAtivo = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       nome = Value(nome),
       versao = Value(versao),
       jsonData = Value(jsonData),
       dataDownload = Value(dataDownload),
       ultimaAtualizacao = Value(ultimaAtualizacao),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<Checklist> custom({
    Expression<String>? id,
    Expression<String>? nome,
    Expression<String>? versao,
    Expression<String>? categoria,
    Expression<String>? jsonData,
    Expression<DateTime>? dataDownload,
    Expression<DateTime>? ultimaAtualizacao,
    Expression<bool>? isAtivo,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (nome != null) 'nome': nome,
      if (versao != null) 'versao': versao,
      if (categoria != null) 'categoria': categoria,
      if (jsonData != null) 'json_data': jsonData,
      if (dataDownload != null) 'data_download': dataDownload,
      if (ultimaAtualizacao != null) 'ultima_atualizacao': ultimaAtualizacao,
      if (isAtivo != null) 'is_ativo': isAtivo,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ChecklistsCompanion copyWith({
    Value<String>? id,
    Value<String>? nome,
    Value<String>? versao,
    Value<String?>? categoria,
    Value<String>? jsonData,
    Value<DateTime>? dataDownload,
    Value<DateTime>? ultimaAtualizacao,
    Value<bool>? isAtivo,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return ChecklistsCompanion(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      versao: versao ?? this.versao,
      categoria: categoria ?? this.categoria,
      jsonData: jsonData ?? this.jsonData,
      dataDownload: dataDownload ?? this.dataDownload,
      ultimaAtualizacao: ultimaAtualizacao ?? this.ultimaAtualizacao,
      isAtivo: isAtivo ?? this.isAtivo,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (nome.present) {
      map['nome'] = Variable<String>(nome.value);
    }
    if (versao.present) {
      map['versao'] = Variable<String>(versao.value);
    }
    if (categoria.present) {
      map['categoria'] = Variable<String>(categoria.value);
    }
    if (jsonData.present) {
      map['json_data'] = Variable<String>(jsonData.value);
    }
    if (dataDownload.present) {
      map['data_download'] = Variable<DateTime>(dataDownload.value);
    }
    if (ultimaAtualizacao.present) {
      map['ultima_atualizacao'] = Variable<DateTime>(ultimaAtualizacao.value);
    }
    if (isAtivo.present) {
      map['is_ativo'] = Variable<bool>(isAtivo.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ChecklistsCompanion(')
          ..write('id: $id, ')
          ..write('nome: $nome, ')
          ..write('versao: $versao, ')
          ..write('categoria: $categoria, ')
          ..write('jsonData: $jsonData, ')
          ..write('dataDownload: $dataDownload, ')
          ..write('ultimaAtualizacao: $ultimaAtualizacao, ')
          ..write('isAtivo: $isAtivo, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $EstabelecimentosTable extends Estabelecimentos
    with TableInfo<$EstabelecimentosTable, Estabelecimento> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EstabelecimentosTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _codigoMeta = const VerificationMeta('codigo');
  @override
  late final GeneratedColumn<String> codigo = GeneratedColumn<String>(
    'codigo',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _nomeMeta = const VerificationMeta('nome');
  @override
  late final GeneratedColumn<String> nome = GeneratedColumn<String>(
    'nome',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descricaoMeta = const VerificationMeta(
    'descricao',
  );
  @override
  late final GeneratedColumn<String> descricao = GeneratedColumn<String>(
    'descricao',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<EstablishmentType, String> tipo =
      GeneratedColumn<String>(
        'tipo',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<EstablishmentType>($EstabelecimentosTable.$convertertipo);
  static const VerificationMeta _enderecoMeta = const VerificationMeta(
    'endereco',
  );
  @override
  late final GeneratedColumn<String> endereco = GeneratedColumn<String>(
    'endereco',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _latitudeMeta = const VerificationMeta(
    'latitude',
  );
  @override
  late final GeneratedColumn<double> latitude = GeneratedColumn<double>(
    'latitude',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _longitudeMeta = const VerificationMeta(
    'longitude',
  );
  @override
  late final GeneratedColumn<double> longitude = GeneratedColumn<double>(
    'longitude',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _telefoneMeta = const VerificationMeta(
    'telefone',
  );
  @override
  late final GeneratedColumn<String> telefone = GeneratedColumn<String>(
    'telefone',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _emailMeta = const VerificationMeta('email');
  @override
  late final GeneratedColumn<String> email = GeneratedColumn<String>(
    'email',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _responsavelMeta = const VerificationMeta(
    'responsavel',
  );
  @override
  late final GeneratedColumn<String> responsavel = GeneratedColumn<String>(
    'responsavel',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _observacoesMeta = const VerificationMeta(
    'observacoes',
  );
  @override
  late final GeneratedColumn<String> observacoes = GeneratedColumn<String>(
    'observacoes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isSyncedMeta = const VerificationMeta(
    'isSynced',
  );
  @override
  late final GeneratedColumn<bool> isSynced = GeneratedColumn<bool>(
    'is_synced',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_synced" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _dataSincronizacaoMeta = const VerificationMeta(
    'dataSincronizacao',
  );
  @override
  late final GeneratedColumn<DateTime> dataSincronizacao =
      GeneratedColumn<DateTime>(
        'data_sincronizacao',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _serverIdMeta = const VerificationMeta(
    'serverId',
  );
  @override
  late final GeneratedColumn<String> serverId = GeneratedColumn<String>(
    'server_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    codigo,
    nome,
    descricao,
    tipo,
    endereco,
    latitude,
    longitude,
    telefone,
    email,
    responsavel,
    observacoes,
    isSynced,
    dataSincronizacao,
    createdAt,
    updatedAt,
    serverId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'estabelecimentos';
  @override
  VerificationContext validateIntegrity(
    Insertable<Estabelecimento> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('codigo')) {
      context.handle(
        _codigoMeta,
        codigo.isAcceptableOrUnknown(data['codigo']!, _codigoMeta),
      );
    }
    if (data.containsKey('nome')) {
      context.handle(
        _nomeMeta,
        nome.isAcceptableOrUnknown(data['nome']!, _nomeMeta),
      );
    } else if (isInserting) {
      context.missing(_nomeMeta);
    }
    if (data.containsKey('descricao')) {
      context.handle(
        _descricaoMeta,
        descricao.isAcceptableOrUnknown(data['descricao']!, _descricaoMeta),
      );
    } else if (isInserting) {
      context.missing(_descricaoMeta);
    }
    if (data.containsKey('endereco')) {
      context.handle(
        _enderecoMeta,
        endereco.isAcceptableOrUnknown(data['endereco']!, _enderecoMeta),
      );
    } else if (isInserting) {
      context.missing(_enderecoMeta);
    }
    if (data.containsKey('latitude')) {
      context.handle(
        _latitudeMeta,
        latitude.isAcceptableOrUnknown(data['latitude']!, _latitudeMeta),
      );
    } else if (isInserting) {
      context.missing(_latitudeMeta);
    }
    if (data.containsKey('longitude')) {
      context.handle(
        _longitudeMeta,
        longitude.isAcceptableOrUnknown(data['longitude']!, _longitudeMeta),
      );
    } else if (isInserting) {
      context.missing(_longitudeMeta);
    }
    if (data.containsKey('telefone')) {
      context.handle(
        _telefoneMeta,
        telefone.isAcceptableOrUnknown(data['telefone']!, _telefoneMeta),
      );
    }
    if (data.containsKey('email')) {
      context.handle(
        _emailMeta,
        email.isAcceptableOrUnknown(data['email']!, _emailMeta),
      );
    }
    if (data.containsKey('responsavel')) {
      context.handle(
        _responsavelMeta,
        responsavel.isAcceptableOrUnknown(
          data['responsavel']!,
          _responsavelMeta,
        ),
      );
    }
    if (data.containsKey('observacoes')) {
      context.handle(
        _observacoesMeta,
        observacoes.isAcceptableOrUnknown(
          data['observacoes']!,
          _observacoesMeta,
        ),
      );
    }
    if (data.containsKey('is_synced')) {
      context.handle(
        _isSyncedMeta,
        isSynced.isAcceptableOrUnknown(data['is_synced']!, _isSyncedMeta),
      );
    }
    if (data.containsKey('data_sincronizacao')) {
      context.handle(
        _dataSincronizacaoMeta,
        dataSincronizacao.isAcceptableOrUnknown(
          data['data_sincronizacao']!,
          _dataSincronizacaoMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('server_id')) {
      context.handle(
        _serverIdMeta,
        serverId.isAcceptableOrUnknown(data['server_id']!, _serverIdMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Estabelecimento map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Estabelecimento(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      codigo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}codigo'],
      ),
      nome: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}nome'],
      )!,
      descricao: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}descricao'],
      )!,
      tipo: $EstabelecimentosTable.$convertertipo.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}tipo'],
        )!,
      ),
      endereco: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}endereco'],
      )!,
      latitude: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}latitude'],
      )!,
      longitude: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}longitude'],
      )!,
      telefone: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}telefone'],
      ),
      email: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}email'],
      ),
      responsavel: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}responsavel'],
      ),
      observacoes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}observacoes'],
      ),
      isSynced: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_synced'],
      )!,
      dataSincronizacao: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}data_sincronizacao'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      serverId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}server_id'],
      ),
    );
  }

  @override
  $EstabelecimentosTable createAlias(String alias) {
    return $EstabelecimentosTable(attachedDatabase, alias);
  }

  static TypeConverter<EstablishmentType, String> $convertertipo =
      const EstablishmentTypeConverter();
}

class Estabelecimento extends DataClass implements Insertable<Estabelecimento> {
  final String id;
  final String? codigo;
  final String nome;
  final String descricao;
  final EstablishmentType tipo;
  final String endereco;
  final double latitude;
  final double longitude;
  final String? telefone;
  final String? email;
  final String? responsavel;
  final String? observacoes;
  final bool isSynced;
  final DateTime? dataSincronizacao;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? serverId;
  const Estabelecimento({
    required this.id,
    this.codigo,
    required this.nome,
    required this.descricao,
    required this.tipo,
    required this.endereco,
    required this.latitude,
    required this.longitude,
    this.telefone,
    this.email,
    this.responsavel,
    this.observacoes,
    required this.isSynced,
    this.dataSincronizacao,
    required this.createdAt,
    required this.updatedAt,
    this.serverId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || codigo != null) {
      map['codigo'] = Variable<String>(codigo);
    }
    map['nome'] = Variable<String>(nome);
    map['descricao'] = Variable<String>(descricao);
    {
      map['tipo'] = Variable<String>(
        $EstabelecimentosTable.$convertertipo.toSql(tipo),
      );
    }
    map['endereco'] = Variable<String>(endereco);
    map['latitude'] = Variable<double>(latitude);
    map['longitude'] = Variable<double>(longitude);
    if (!nullToAbsent || telefone != null) {
      map['telefone'] = Variable<String>(telefone);
    }
    if (!nullToAbsent || email != null) {
      map['email'] = Variable<String>(email);
    }
    if (!nullToAbsent || responsavel != null) {
      map['responsavel'] = Variable<String>(responsavel);
    }
    if (!nullToAbsent || observacoes != null) {
      map['observacoes'] = Variable<String>(observacoes);
    }
    map['is_synced'] = Variable<bool>(isSynced);
    if (!nullToAbsent || dataSincronizacao != null) {
      map['data_sincronizacao'] = Variable<DateTime>(dataSincronizacao);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || serverId != null) {
      map['server_id'] = Variable<String>(serverId);
    }
    return map;
  }

  EstabelecimentosCompanion toCompanion(bool nullToAbsent) {
    return EstabelecimentosCompanion(
      id: Value(id),
      codigo: codigo == null && nullToAbsent
          ? const Value.absent()
          : Value(codigo),
      nome: Value(nome),
      descricao: Value(descricao),
      tipo: Value(tipo),
      endereco: Value(endereco),
      latitude: Value(latitude),
      longitude: Value(longitude),
      telefone: telefone == null && nullToAbsent
          ? const Value.absent()
          : Value(telefone),
      email: email == null && nullToAbsent
          ? const Value.absent()
          : Value(email),
      responsavel: responsavel == null && nullToAbsent
          ? const Value.absent()
          : Value(responsavel),
      observacoes: observacoes == null && nullToAbsent
          ? const Value.absent()
          : Value(observacoes),
      isSynced: Value(isSynced),
      dataSincronizacao: dataSincronizacao == null && nullToAbsent
          ? const Value.absent()
          : Value(dataSincronizacao),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      serverId: serverId == null && nullToAbsent
          ? const Value.absent()
          : Value(serverId),
    );
  }

  factory Estabelecimento.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Estabelecimento(
      id: serializer.fromJson<String>(json['id']),
      codigo: serializer.fromJson<String?>(json['codigo']),
      nome: serializer.fromJson<String>(json['nome']),
      descricao: serializer.fromJson<String>(json['descricao']),
      tipo: serializer.fromJson<EstablishmentType>(json['tipo']),
      endereco: serializer.fromJson<String>(json['endereco']),
      latitude: serializer.fromJson<double>(json['latitude']),
      longitude: serializer.fromJson<double>(json['longitude']),
      telefone: serializer.fromJson<String?>(json['telefone']),
      email: serializer.fromJson<String?>(json['email']),
      responsavel: serializer.fromJson<String?>(json['responsavel']),
      observacoes: serializer.fromJson<String?>(json['observacoes']),
      isSynced: serializer.fromJson<bool>(json['isSynced']),
      dataSincronizacao: serializer.fromJson<DateTime?>(
        json['dataSincronizacao'],
      ),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      serverId: serializer.fromJson<String?>(json['serverId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'codigo': serializer.toJson<String?>(codigo),
      'nome': serializer.toJson<String>(nome),
      'descricao': serializer.toJson<String>(descricao),
      'tipo': serializer.toJson<EstablishmentType>(tipo),
      'endereco': serializer.toJson<String>(endereco),
      'latitude': serializer.toJson<double>(latitude),
      'longitude': serializer.toJson<double>(longitude),
      'telefone': serializer.toJson<String?>(telefone),
      'email': serializer.toJson<String?>(email),
      'responsavel': serializer.toJson<String?>(responsavel),
      'observacoes': serializer.toJson<String?>(observacoes),
      'isSynced': serializer.toJson<bool>(isSynced),
      'dataSincronizacao': serializer.toJson<DateTime?>(dataSincronizacao),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'serverId': serializer.toJson<String?>(serverId),
    };
  }

  Estabelecimento copyWith({
    String? id,
    Value<String?> codigo = const Value.absent(),
    String? nome,
    String? descricao,
    EstablishmentType? tipo,
    String? endereco,
    double? latitude,
    double? longitude,
    Value<String?> telefone = const Value.absent(),
    Value<String?> email = const Value.absent(),
    Value<String?> responsavel = const Value.absent(),
    Value<String?> observacoes = const Value.absent(),
    bool? isSynced,
    Value<DateTime?> dataSincronizacao = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<String?> serverId = const Value.absent(),
  }) => Estabelecimento(
    id: id ?? this.id,
    codigo: codigo.present ? codigo.value : this.codigo,
    nome: nome ?? this.nome,
    descricao: descricao ?? this.descricao,
    tipo: tipo ?? this.tipo,
    endereco: endereco ?? this.endereco,
    latitude: latitude ?? this.latitude,
    longitude: longitude ?? this.longitude,
    telefone: telefone.present ? telefone.value : this.telefone,
    email: email.present ? email.value : this.email,
    responsavel: responsavel.present ? responsavel.value : this.responsavel,
    observacoes: observacoes.present ? observacoes.value : this.observacoes,
    isSynced: isSynced ?? this.isSynced,
    dataSincronizacao: dataSincronizacao.present
        ? dataSincronizacao.value
        : this.dataSincronizacao,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    serverId: serverId.present ? serverId.value : this.serverId,
  );
  Estabelecimento copyWithCompanion(EstabelecimentosCompanion data) {
    return Estabelecimento(
      id: data.id.present ? data.id.value : this.id,
      codigo: data.codigo.present ? data.codigo.value : this.codigo,
      nome: data.nome.present ? data.nome.value : this.nome,
      descricao: data.descricao.present ? data.descricao.value : this.descricao,
      tipo: data.tipo.present ? data.tipo.value : this.tipo,
      endereco: data.endereco.present ? data.endereco.value : this.endereco,
      latitude: data.latitude.present ? data.latitude.value : this.latitude,
      longitude: data.longitude.present ? data.longitude.value : this.longitude,
      telefone: data.telefone.present ? data.telefone.value : this.telefone,
      email: data.email.present ? data.email.value : this.email,
      responsavel: data.responsavel.present
          ? data.responsavel.value
          : this.responsavel,
      observacoes: data.observacoes.present
          ? data.observacoes.value
          : this.observacoes,
      isSynced: data.isSynced.present ? data.isSynced.value : this.isSynced,
      dataSincronizacao: data.dataSincronizacao.present
          ? data.dataSincronizacao.value
          : this.dataSincronizacao,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      serverId: data.serverId.present ? data.serverId.value : this.serverId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Estabelecimento(')
          ..write('id: $id, ')
          ..write('codigo: $codigo, ')
          ..write('nome: $nome, ')
          ..write('descricao: $descricao, ')
          ..write('tipo: $tipo, ')
          ..write('endereco: $endereco, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('telefone: $telefone, ')
          ..write('email: $email, ')
          ..write('responsavel: $responsavel, ')
          ..write('observacoes: $observacoes, ')
          ..write('isSynced: $isSynced, ')
          ..write('dataSincronizacao: $dataSincronizacao, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('serverId: $serverId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    codigo,
    nome,
    descricao,
    tipo,
    endereco,
    latitude,
    longitude,
    telefone,
    email,
    responsavel,
    observacoes,
    isSynced,
    dataSincronizacao,
    createdAt,
    updatedAt,
    serverId,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Estabelecimento &&
          other.id == this.id &&
          other.codigo == this.codigo &&
          other.nome == this.nome &&
          other.descricao == this.descricao &&
          other.tipo == this.tipo &&
          other.endereco == this.endereco &&
          other.latitude == this.latitude &&
          other.longitude == this.longitude &&
          other.telefone == this.telefone &&
          other.email == this.email &&
          other.responsavel == this.responsavel &&
          other.observacoes == this.observacoes &&
          other.isSynced == this.isSynced &&
          other.dataSincronizacao == this.dataSincronizacao &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.serverId == this.serverId);
}

class EstabelecimentosCompanion extends UpdateCompanion<Estabelecimento> {
  final Value<String> id;
  final Value<String?> codigo;
  final Value<String> nome;
  final Value<String> descricao;
  final Value<EstablishmentType> tipo;
  final Value<String> endereco;
  final Value<double> latitude;
  final Value<double> longitude;
  final Value<String?> telefone;
  final Value<String?> email;
  final Value<String?> responsavel;
  final Value<String?> observacoes;
  final Value<bool> isSynced;
  final Value<DateTime?> dataSincronizacao;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<String?> serverId;
  final Value<int> rowid;
  const EstabelecimentosCompanion({
    this.id = const Value.absent(),
    this.codigo = const Value.absent(),
    this.nome = const Value.absent(),
    this.descricao = const Value.absent(),
    this.tipo = const Value.absent(),
    this.endereco = const Value.absent(),
    this.latitude = const Value.absent(),
    this.longitude = const Value.absent(),
    this.telefone = const Value.absent(),
    this.email = const Value.absent(),
    this.responsavel = const Value.absent(),
    this.observacoes = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.dataSincronizacao = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.serverId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  EstabelecimentosCompanion.insert({
    required String id,
    this.codigo = const Value.absent(),
    required String nome,
    required String descricao,
    required EstablishmentType tipo,
    required String endereco,
    required double latitude,
    required double longitude,
    this.telefone = const Value.absent(),
    this.email = const Value.absent(),
    this.responsavel = const Value.absent(),
    this.observacoes = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.dataSincronizacao = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.serverId = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       nome = Value(nome),
       descricao = Value(descricao),
       tipo = Value(tipo),
       endereco = Value(endereco),
       latitude = Value(latitude),
       longitude = Value(longitude),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<Estabelecimento> custom({
    Expression<String>? id,
    Expression<String>? codigo,
    Expression<String>? nome,
    Expression<String>? descricao,
    Expression<String>? tipo,
    Expression<String>? endereco,
    Expression<double>? latitude,
    Expression<double>? longitude,
    Expression<String>? telefone,
    Expression<String>? email,
    Expression<String>? responsavel,
    Expression<String>? observacoes,
    Expression<bool>? isSynced,
    Expression<DateTime>? dataSincronizacao,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<String>? serverId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (codigo != null) 'codigo': codigo,
      if (nome != null) 'nome': nome,
      if (descricao != null) 'descricao': descricao,
      if (tipo != null) 'tipo': tipo,
      if (endereco != null) 'endereco': endereco,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (telefone != null) 'telefone': telefone,
      if (email != null) 'email': email,
      if (responsavel != null) 'responsavel': responsavel,
      if (observacoes != null) 'observacoes': observacoes,
      if (isSynced != null) 'is_synced': isSynced,
      if (dataSincronizacao != null) 'data_sincronizacao': dataSincronizacao,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (serverId != null) 'server_id': serverId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  EstabelecimentosCompanion copyWith({
    Value<String>? id,
    Value<String?>? codigo,
    Value<String>? nome,
    Value<String>? descricao,
    Value<EstablishmentType>? tipo,
    Value<String>? endereco,
    Value<double>? latitude,
    Value<double>? longitude,
    Value<String?>? telefone,
    Value<String?>? email,
    Value<String?>? responsavel,
    Value<String?>? observacoes,
    Value<bool>? isSynced,
    Value<DateTime?>? dataSincronizacao,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<String?>? serverId,
    Value<int>? rowid,
  }) {
    return EstabelecimentosCompanion(
      id: id ?? this.id,
      codigo: codigo ?? this.codigo,
      nome: nome ?? this.nome,
      descricao: descricao ?? this.descricao,
      tipo: tipo ?? this.tipo,
      endereco: endereco ?? this.endereco,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      telefone: telefone ?? this.telefone,
      email: email ?? this.email,
      responsavel: responsavel ?? this.responsavel,
      observacoes: observacoes ?? this.observacoes,
      isSynced: isSynced ?? this.isSynced,
      dataSincronizacao: dataSincronizacao ?? this.dataSincronizacao,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      serverId: serverId ?? this.serverId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (codigo.present) {
      map['codigo'] = Variable<String>(codigo.value);
    }
    if (nome.present) {
      map['nome'] = Variable<String>(nome.value);
    }
    if (descricao.present) {
      map['descricao'] = Variable<String>(descricao.value);
    }
    if (tipo.present) {
      map['tipo'] = Variable<String>(
        $EstabelecimentosTable.$convertertipo.toSql(tipo.value),
      );
    }
    if (endereco.present) {
      map['endereco'] = Variable<String>(endereco.value);
    }
    if (latitude.present) {
      map['latitude'] = Variable<double>(latitude.value);
    }
    if (longitude.present) {
      map['longitude'] = Variable<double>(longitude.value);
    }
    if (telefone.present) {
      map['telefone'] = Variable<String>(telefone.value);
    }
    if (email.present) {
      map['email'] = Variable<String>(email.value);
    }
    if (responsavel.present) {
      map['responsavel'] = Variable<String>(responsavel.value);
    }
    if (observacoes.present) {
      map['observacoes'] = Variable<String>(observacoes.value);
    }
    if (isSynced.present) {
      map['is_synced'] = Variable<bool>(isSynced.value);
    }
    if (dataSincronizacao.present) {
      map['data_sincronizacao'] = Variable<DateTime>(dataSincronizacao.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (serverId.present) {
      map['server_id'] = Variable<String>(serverId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EstabelecimentosCompanion(')
          ..write('id: $id, ')
          ..write('codigo: $codigo, ')
          ..write('nome: $nome, ')
          ..write('descricao: $descricao, ')
          ..write('tipo: $tipo, ')
          ..write('endereco: $endereco, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('telefone: $telefone, ')
          ..write('email: $email, ')
          ..write('responsavel: $responsavel, ')
          ..write('observacoes: $observacoes, ')
          ..write('isSynced: $isSynced, ')
          ..write('dataSincronizacao: $dataSincronizacao, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('serverId: $serverId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SincronizacoesTable extends Sincronizacoes
    with TableInfo<$SincronizacoesTable, Sincronizacoe> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SincronizacoesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _inspecaoIdMeta = const VerificationMeta(
    'inspecaoId',
  );
  @override
  late final GeneratedColumn<String> inspecaoId = GeneratedColumn<String>(
    'inspecao_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dispositivoIdMeta = const VerificationMeta(
    'dispositivoId',
  );
  @override
  late final GeneratedColumn<String> dispositivoId = GeneratedColumn<String>(
    'dispositivo_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _versaoServidorMeta = const VerificationMeta(
    'versaoServidor',
  );
  @override
  late final GeneratedColumn<String> versaoServidor = GeneratedColumn<String>(
    'versao_servidor',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _versaoDispositivoMeta = const VerificationMeta(
    'versaoDispositivo',
  );
  @override
  late final GeneratedColumn<String> versaoDispositivo =
      GeneratedColumn<String>(
        'versao_dispositivo',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _timestampMeta = const VerificationMeta(
    'timestamp',
  );
  @override
  late final GeneratedColumn<DateTime> timestamp = GeneratedColumn<DateTime>(
    'timestamp',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ultimaTentativaMeta = const VerificationMeta(
    'ultimaTentativa',
  );
  @override
  late final GeneratedColumn<DateTime> ultimaTentativa =
      GeneratedColumn<DateTime>(
        'ultima_tentativa',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _tentativasMeta = const VerificationMeta(
    'tentativas',
  );
  @override
  late final GeneratedColumn<int> tentativas = GeneratedColumn<int>(
    'tentativas',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _temConflitoMeta = const VerificationMeta(
    'temConflito',
  );
  @override
  late final GeneratedColumn<bool> temConflito = GeneratedColumn<bool>(
    'tem_conflito',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("tem_conflito" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _mensagemErroMeta = const VerificationMeta(
    'mensagemErro',
  );
  @override
  late final GeneratedColumn<String> mensagemErro = GeneratedColumn<String>(
    'mensagem_erro',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _direcaoMeta = const VerificationMeta(
    'direcao',
  );
  @override
  late final GeneratedColumn<String> direcao = GeneratedColumn<String>(
    'direcao',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    inspecaoId,
    dispositivoId,
    status,
    versaoServidor,
    versaoDispositivo,
    timestamp,
    ultimaTentativa,
    tentativas,
    temConflito,
    mensagemErro,
    direcao,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sincronizacoes';
  @override
  VerificationContext validateIntegrity(
    Insertable<Sincronizacoe> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('inspecao_id')) {
      context.handle(
        _inspecaoIdMeta,
        inspecaoId.isAcceptableOrUnknown(data['inspecao_id']!, _inspecaoIdMeta),
      );
    } else if (isInserting) {
      context.missing(_inspecaoIdMeta);
    }
    if (data.containsKey('dispositivo_id')) {
      context.handle(
        _dispositivoIdMeta,
        dispositivoId.isAcceptableOrUnknown(
          data['dispositivo_id']!,
          _dispositivoIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_dispositivoIdMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('versao_servidor')) {
      context.handle(
        _versaoServidorMeta,
        versaoServidor.isAcceptableOrUnknown(
          data['versao_servidor']!,
          _versaoServidorMeta,
        ),
      );
    }
    if (data.containsKey('versao_dispositivo')) {
      context.handle(
        _versaoDispositivoMeta,
        versaoDispositivo.isAcceptableOrUnknown(
          data['versao_dispositivo']!,
          _versaoDispositivoMeta,
        ),
      );
    }
    if (data.containsKey('timestamp')) {
      context.handle(
        _timestampMeta,
        timestamp.isAcceptableOrUnknown(data['timestamp']!, _timestampMeta),
      );
    } else if (isInserting) {
      context.missing(_timestampMeta);
    }
    if (data.containsKey('ultima_tentativa')) {
      context.handle(
        _ultimaTentativaMeta,
        ultimaTentativa.isAcceptableOrUnknown(
          data['ultima_tentativa']!,
          _ultimaTentativaMeta,
        ),
      );
    }
    if (data.containsKey('tentativas')) {
      context.handle(
        _tentativasMeta,
        tentativas.isAcceptableOrUnknown(data['tentativas']!, _tentativasMeta),
      );
    }
    if (data.containsKey('tem_conflito')) {
      context.handle(
        _temConflitoMeta,
        temConflito.isAcceptableOrUnknown(
          data['tem_conflito']!,
          _temConflitoMeta,
        ),
      );
    }
    if (data.containsKey('mensagem_erro')) {
      context.handle(
        _mensagemErroMeta,
        mensagemErro.isAcceptableOrUnknown(
          data['mensagem_erro']!,
          _mensagemErroMeta,
        ),
      );
    }
    if (data.containsKey('direcao')) {
      context.handle(
        _direcaoMeta,
        direcao.isAcceptableOrUnknown(data['direcao']!, _direcaoMeta),
      );
    } else if (isInserting) {
      context.missing(_direcaoMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Sincronizacoe map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Sincronizacoe(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      inspecaoId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}inspecao_id'],
      )!,
      dispositivoId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}dispositivo_id'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      versaoServidor: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}versao_servidor'],
      ),
      versaoDispositivo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}versao_dispositivo'],
      ),
      timestamp: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}timestamp'],
      )!,
      ultimaTentativa: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}ultima_tentativa'],
      ),
      tentativas: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}tentativas'],
      )!,
      temConflito: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}tem_conflito'],
      )!,
      mensagemErro: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mensagem_erro'],
      ),
      direcao: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}direcao'],
      )!,
    );
  }

  @override
  $SincronizacoesTable createAlias(String alias) {
    return $SincronizacoesTable(attachedDatabase, alias);
  }
}

class Sincronizacoe extends DataClass implements Insertable<Sincronizacoe> {
  final int id;
  final String inspecaoId;
  final String dispositivoId;
  final String status;
  final String? versaoServidor;
  final String? versaoDispositivo;
  final DateTime timestamp;
  final DateTime? ultimaTentativa;
  final int tentativas;
  final bool temConflito;
  final String? mensagemErro;
  final String direcao;
  const Sincronizacoe({
    required this.id,
    required this.inspecaoId,
    required this.dispositivoId,
    required this.status,
    this.versaoServidor,
    this.versaoDispositivo,
    required this.timestamp,
    this.ultimaTentativa,
    required this.tentativas,
    required this.temConflito,
    this.mensagemErro,
    required this.direcao,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['inspecao_id'] = Variable<String>(inspecaoId);
    map['dispositivo_id'] = Variable<String>(dispositivoId);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || versaoServidor != null) {
      map['versao_servidor'] = Variable<String>(versaoServidor);
    }
    if (!nullToAbsent || versaoDispositivo != null) {
      map['versao_dispositivo'] = Variable<String>(versaoDispositivo);
    }
    map['timestamp'] = Variable<DateTime>(timestamp);
    if (!nullToAbsent || ultimaTentativa != null) {
      map['ultima_tentativa'] = Variable<DateTime>(ultimaTentativa);
    }
    map['tentativas'] = Variable<int>(tentativas);
    map['tem_conflito'] = Variable<bool>(temConflito);
    if (!nullToAbsent || mensagemErro != null) {
      map['mensagem_erro'] = Variable<String>(mensagemErro);
    }
    map['direcao'] = Variable<String>(direcao);
    return map;
  }

  SincronizacoesCompanion toCompanion(bool nullToAbsent) {
    return SincronizacoesCompanion(
      id: Value(id),
      inspecaoId: Value(inspecaoId),
      dispositivoId: Value(dispositivoId),
      status: Value(status),
      versaoServidor: versaoServidor == null && nullToAbsent
          ? const Value.absent()
          : Value(versaoServidor),
      versaoDispositivo: versaoDispositivo == null && nullToAbsent
          ? const Value.absent()
          : Value(versaoDispositivo),
      timestamp: Value(timestamp),
      ultimaTentativa: ultimaTentativa == null && nullToAbsent
          ? const Value.absent()
          : Value(ultimaTentativa),
      tentativas: Value(tentativas),
      temConflito: Value(temConflito),
      mensagemErro: mensagemErro == null && nullToAbsent
          ? const Value.absent()
          : Value(mensagemErro),
      direcao: Value(direcao),
    );
  }

  factory Sincronizacoe.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Sincronizacoe(
      id: serializer.fromJson<int>(json['id']),
      inspecaoId: serializer.fromJson<String>(json['inspecaoId']),
      dispositivoId: serializer.fromJson<String>(json['dispositivoId']),
      status: serializer.fromJson<String>(json['status']),
      versaoServidor: serializer.fromJson<String?>(json['versaoServidor']),
      versaoDispositivo: serializer.fromJson<String?>(
        json['versaoDispositivo'],
      ),
      timestamp: serializer.fromJson<DateTime>(json['timestamp']),
      ultimaTentativa: serializer.fromJson<DateTime?>(json['ultimaTentativa']),
      tentativas: serializer.fromJson<int>(json['tentativas']),
      temConflito: serializer.fromJson<bool>(json['temConflito']),
      mensagemErro: serializer.fromJson<String?>(json['mensagemErro']),
      direcao: serializer.fromJson<String>(json['direcao']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'inspecaoId': serializer.toJson<String>(inspecaoId),
      'dispositivoId': serializer.toJson<String>(dispositivoId),
      'status': serializer.toJson<String>(status),
      'versaoServidor': serializer.toJson<String?>(versaoServidor),
      'versaoDispositivo': serializer.toJson<String?>(versaoDispositivo),
      'timestamp': serializer.toJson<DateTime>(timestamp),
      'ultimaTentativa': serializer.toJson<DateTime?>(ultimaTentativa),
      'tentativas': serializer.toJson<int>(tentativas),
      'temConflito': serializer.toJson<bool>(temConflito),
      'mensagemErro': serializer.toJson<String?>(mensagemErro),
      'direcao': serializer.toJson<String>(direcao),
    };
  }

  Sincronizacoe copyWith({
    int? id,
    String? inspecaoId,
    String? dispositivoId,
    String? status,
    Value<String?> versaoServidor = const Value.absent(),
    Value<String?> versaoDispositivo = const Value.absent(),
    DateTime? timestamp,
    Value<DateTime?> ultimaTentativa = const Value.absent(),
    int? tentativas,
    bool? temConflito,
    Value<String?> mensagemErro = const Value.absent(),
    String? direcao,
  }) => Sincronizacoe(
    id: id ?? this.id,
    inspecaoId: inspecaoId ?? this.inspecaoId,
    dispositivoId: dispositivoId ?? this.dispositivoId,
    status: status ?? this.status,
    versaoServidor: versaoServidor.present
        ? versaoServidor.value
        : this.versaoServidor,
    versaoDispositivo: versaoDispositivo.present
        ? versaoDispositivo.value
        : this.versaoDispositivo,
    timestamp: timestamp ?? this.timestamp,
    ultimaTentativa: ultimaTentativa.present
        ? ultimaTentativa.value
        : this.ultimaTentativa,
    tentativas: tentativas ?? this.tentativas,
    temConflito: temConflito ?? this.temConflito,
    mensagemErro: mensagemErro.present ? mensagemErro.value : this.mensagemErro,
    direcao: direcao ?? this.direcao,
  );
  Sincronizacoe copyWithCompanion(SincronizacoesCompanion data) {
    return Sincronizacoe(
      id: data.id.present ? data.id.value : this.id,
      inspecaoId: data.inspecaoId.present
          ? data.inspecaoId.value
          : this.inspecaoId,
      dispositivoId: data.dispositivoId.present
          ? data.dispositivoId.value
          : this.dispositivoId,
      status: data.status.present ? data.status.value : this.status,
      versaoServidor: data.versaoServidor.present
          ? data.versaoServidor.value
          : this.versaoServidor,
      versaoDispositivo: data.versaoDispositivo.present
          ? data.versaoDispositivo.value
          : this.versaoDispositivo,
      timestamp: data.timestamp.present ? data.timestamp.value : this.timestamp,
      ultimaTentativa: data.ultimaTentativa.present
          ? data.ultimaTentativa.value
          : this.ultimaTentativa,
      tentativas: data.tentativas.present
          ? data.tentativas.value
          : this.tentativas,
      temConflito: data.temConflito.present
          ? data.temConflito.value
          : this.temConflito,
      mensagemErro: data.mensagemErro.present
          ? data.mensagemErro.value
          : this.mensagemErro,
      direcao: data.direcao.present ? data.direcao.value : this.direcao,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Sincronizacoe(')
          ..write('id: $id, ')
          ..write('inspecaoId: $inspecaoId, ')
          ..write('dispositivoId: $dispositivoId, ')
          ..write('status: $status, ')
          ..write('versaoServidor: $versaoServidor, ')
          ..write('versaoDispositivo: $versaoDispositivo, ')
          ..write('timestamp: $timestamp, ')
          ..write('ultimaTentativa: $ultimaTentativa, ')
          ..write('tentativas: $tentativas, ')
          ..write('temConflito: $temConflito, ')
          ..write('mensagemErro: $mensagemErro, ')
          ..write('direcao: $direcao')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    inspecaoId,
    dispositivoId,
    status,
    versaoServidor,
    versaoDispositivo,
    timestamp,
    ultimaTentativa,
    tentativas,
    temConflito,
    mensagemErro,
    direcao,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Sincronizacoe &&
          other.id == this.id &&
          other.inspecaoId == this.inspecaoId &&
          other.dispositivoId == this.dispositivoId &&
          other.status == this.status &&
          other.versaoServidor == this.versaoServidor &&
          other.versaoDispositivo == this.versaoDispositivo &&
          other.timestamp == this.timestamp &&
          other.ultimaTentativa == this.ultimaTentativa &&
          other.tentativas == this.tentativas &&
          other.temConflito == this.temConflito &&
          other.mensagemErro == this.mensagemErro &&
          other.direcao == this.direcao);
}

class SincronizacoesCompanion extends UpdateCompanion<Sincronizacoe> {
  final Value<int> id;
  final Value<String> inspecaoId;
  final Value<String> dispositivoId;
  final Value<String> status;
  final Value<String?> versaoServidor;
  final Value<String?> versaoDispositivo;
  final Value<DateTime> timestamp;
  final Value<DateTime?> ultimaTentativa;
  final Value<int> tentativas;
  final Value<bool> temConflito;
  final Value<String?> mensagemErro;
  final Value<String> direcao;
  const SincronizacoesCompanion({
    this.id = const Value.absent(),
    this.inspecaoId = const Value.absent(),
    this.dispositivoId = const Value.absent(),
    this.status = const Value.absent(),
    this.versaoServidor = const Value.absent(),
    this.versaoDispositivo = const Value.absent(),
    this.timestamp = const Value.absent(),
    this.ultimaTentativa = const Value.absent(),
    this.tentativas = const Value.absent(),
    this.temConflito = const Value.absent(),
    this.mensagemErro = const Value.absent(),
    this.direcao = const Value.absent(),
  });
  SincronizacoesCompanion.insert({
    this.id = const Value.absent(),
    required String inspecaoId,
    required String dispositivoId,
    required String status,
    this.versaoServidor = const Value.absent(),
    this.versaoDispositivo = const Value.absent(),
    required DateTime timestamp,
    this.ultimaTentativa = const Value.absent(),
    this.tentativas = const Value.absent(),
    this.temConflito = const Value.absent(),
    this.mensagemErro = const Value.absent(),
    required String direcao,
  }) : inspecaoId = Value(inspecaoId),
       dispositivoId = Value(dispositivoId),
       status = Value(status),
       timestamp = Value(timestamp),
       direcao = Value(direcao);
  static Insertable<Sincronizacoe> custom({
    Expression<int>? id,
    Expression<String>? inspecaoId,
    Expression<String>? dispositivoId,
    Expression<String>? status,
    Expression<String>? versaoServidor,
    Expression<String>? versaoDispositivo,
    Expression<DateTime>? timestamp,
    Expression<DateTime>? ultimaTentativa,
    Expression<int>? tentativas,
    Expression<bool>? temConflito,
    Expression<String>? mensagemErro,
    Expression<String>? direcao,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (inspecaoId != null) 'inspecao_id': inspecaoId,
      if (dispositivoId != null) 'dispositivo_id': dispositivoId,
      if (status != null) 'status': status,
      if (versaoServidor != null) 'versao_servidor': versaoServidor,
      if (versaoDispositivo != null) 'versao_dispositivo': versaoDispositivo,
      if (timestamp != null) 'timestamp': timestamp,
      if (ultimaTentativa != null) 'ultima_tentativa': ultimaTentativa,
      if (tentativas != null) 'tentativas': tentativas,
      if (temConflito != null) 'tem_conflito': temConflito,
      if (mensagemErro != null) 'mensagem_erro': mensagemErro,
      if (direcao != null) 'direcao': direcao,
    });
  }

  SincronizacoesCompanion copyWith({
    Value<int>? id,
    Value<String>? inspecaoId,
    Value<String>? dispositivoId,
    Value<String>? status,
    Value<String?>? versaoServidor,
    Value<String?>? versaoDispositivo,
    Value<DateTime>? timestamp,
    Value<DateTime?>? ultimaTentativa,
    Value<int>? tentativas,
    Value<bool>? temConflito,
    Value<String?>? mensagemErro,
    Value<String>? direcao,
  }) {
    return SincronizacoesCompanion(
      id: id ?? this.id,
      inspecaoId: inspecaoId ?? this.inspecaoId,
      dispositivoId: dispositivoId ?? this.dispositivoId,
      status: status ?? this.status,
      versaoServidor: versaoServidor ?? this.versaoServidor,
      versaoDispositivo: versaoDispositivo ?? this.versaoDispositivo,
      timestamp: timestamp ?? this.timestamp,
      ultimaTentativa: ultimaTentativa ?? this.ultimaTentativa,
      tentativas: tentativas ?? this.tentativas,
      temConflito: temConflito ?? this.temConflito,
      mensagemErro: mensagemErro ?? this.mensagemErro,
      direcao: direcao ?? this.direcao,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (inspecaoId.present) {
      map['inspecao_id'] = Variable<String>(inspecaoId.value);
    }
    if (dispositivoId.present) {
      map['dispositivo_id'] = Variable<String>(dispositivoId.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (versaoServidor.present) {
      map['versao_servidor'] = Variable<String>(versaoServidor.value);
    }
    if (versaoDispositivo.present) {
      map['versao_dispositivo'] = Variable<String>(versaoDispositivo.value);
    }
    if (timestamp.present) {
      map['timestamp'] = Variable<DateTime>(timestamp.value);
    }
    if (ultimaTentativa.present) {
      map['ultima_tentativa'] = Variable<DateTime>(ultimaTentativa.value);
    }
    if (tentativas.present) {
      map['tentativas'] = Variable<int>(tentativas.value);
    }
    if (temConflito.present) {
      map['tem_conflito'] = Variable<bool>(temConflito.value);
    }
    if (mensagemErro.present) {
      map['mensagem_erro'] = Variable<String>(mensagemErro.value);
    }
    if (direcao.present) {
      map['direcao'] = Variable<String>(direcao.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SincronizacoesCompanion(')
          ..write('id: $id, ')
          ..write('inspecaoId: $inspecaoId, ')
          ..write('dispositivoId: $dispositivoId, ')
          ..write('status: $status, ')
          ..write('versaoServidor: $versaoServidor, ')
          ..write('versaoDispositivo: $versaoDispositivo, ')
          ..write('timestamp: $timestamp, ')
          ..write('ultimaTentativa: $ultimaTentativa, ')
          ..write('tentativas: $tentativas, ')
          ..write('temConflito: $temConflito, ')
          ..write('mensagemErro: $mensagemErro, ')
          ..write('direcao: $direcao')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $InspecoesTable inspecoes = $InspecoesTable(this);
  late final $RespostasInspecaoTable respostasInspecao =
      $RespostasInspecaoTable(this);
  late final $AnexosInspecaoTable anexosInspecao = $AnexosInspecaoTable(this);
  late final $ChecklistsTable checklists = $ChecklistsTable(this);
  late final $EstabelecimentosTable estabelecimentos = $EstabelecimentosTable(
    this,
  );
  late final $SincronizacoesTable sincronizacoes = $SincronizacoesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    inspecoes,
    respostasInspecao,
    anexosInspecao,
    checklists,
    estabelecimentos,
    sincronizacoes,
  ];
}

typedef $$InspecoesTableCreateCompanionBuilder =
    InspecoesCompanion Function({
      required String id,
      Value<String?> numero,
      required String titulo,
      required String descricao,
      required InspectionType tipo,
      required InspectionStatus status,
      required DateTime dataAgendada,
      Value<DateTime?> dataInicio,
      Value<DateTime?> dataConclusao,
      required String endereco,
      required double latitude,
      required double longitude,
      Value<String?> observacoes,
      Value<String?> establishmentId,
      Value<String?> checklistId,
      Value<String?> inspectorId,
      Value<double?> scoreConformidade,
      Value<double?> scoreNaoConformidade,
      Value<bool> isSynced,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<String?> serverId,
      Value<String?> deviceId,
      Value<String?> versionHash,
      Value<bool> isTemplate,
      Value<bool> isDeleted,
      Value<int> rowid,
    });
typedef $$InspecoesTableUpdateCompanionBuilder =
    InspecoesCompanion Function({
      Value<String> id,
      Value<String?> numero,
      Value<String> titulo,
      Value<String> descricao,
      Value<InspectionType> tipo,
      Value<InspectionStatus> status,
      Value<DateTime> dataAgendada,
      Value<DateTime?> dataInicio,
      Value<DateTime?> dataConclusao,
      Value<String> endereco,
      Value<double> latitude,
      Value<double> longitude,
      Value<String?> observacoes,
      Value<String?> establishmentId,
      Value<String?> checklistId,
      Value<String?> inspectorId,
      Value<double?> scoreConformidade,
      Value<double?> scoreNaoConformidade,
      Value<bool> isSynced,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<String?> serverId,
      Value<String?> deviceId,
      Value<String?> versionHash,
      Value<bool> isTemplate,
      Value<bool> isDeleted,
      Value<int> rowid,
    });

class $$InspecoesTableFilterComposer
    extends Composer<_$AppDatabase, $InspecoesTable> {
  $$InspecoesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get numero => $composableBuilder(
    column: $table.numero,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get titulo => $composableBuilder(
    column: $table.titulo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get descricao => $composableBuilder(
    column: $table.descricao,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<InspectionType, InspectionType, String>
  get tipo => $composableBuilder(
    column: $table.tipo,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<InspectionStatus, InspectionStatus, String>
  get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<DateTime> get dataAgendada => $composableBuilder(
    column: $table.dataAgendada,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get dataInicio => $composableBuilder(
    column: $table.dataInicio,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get dataConclusao => $composableBuilder(
    column: $table.dataConclusao,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get endereco => $composableBuilder(
    column: $table.endereco,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get latitude => $composableBuilder(
    column: $table.latitude,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get longitude => $composableBuilder(
    column: $table.longitude,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get observacoes => $composableBuilder(
    column: $table.observacoes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get establishmentId => $composableBuilder(
    column: $table.establishmentId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get checklistId => $composableBuilder(
    column: $table.checklistId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get inspectorId => $composableBuilder(
    column: $table.inspectorId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get scoreConformidade => $composableBuilder(
    column: $table.scoreConformidade,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get scoreNaoConformidade => $composableBuilder(
    column: $table.scoreNaoConformidade,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isSynced => $composableBuilder(
    column: $table.isSynced,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get versionHash => $composableBuilder(
    column: $table.versionHash,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isTemplate => $composableBuilder(
    column: $table.isTemplate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnFilters(column),
  );
}

class $$InspecoesTableOrderingComposer
    extends Composer<_$AppDatabase, $InspecoesTable> {
  $$InspecoesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get numero => $composableBuilder(
    column: $table.numero,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get titulo => $composableBuilder(
    column: $table.titulo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get descricao => $composableBuilder(
    column: $table.descricao,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tipo => $composableBuilder(
    column: $table.tipo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get dataAgendada => $composableBuilder(
    column: $table.dataAgendada,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get dataInicio => $composableBuilder(
    column: $table.dataInicio,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get dataConclusao => $composableBuilder(
    column: $table.dataConclusao,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get endereco => $composableBuilder(
    column: $table.endereco,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get latitude => $composableBuilder(
    column: $table.latitude,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get longitude => $composableBuilder(
    column: $table.longitude,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get observacoes => $composableBuilder(
    column: $table.observacoes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get establishmentId => $composableBuilder(
    column: $table.establishmentId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get checklistId => $composableBuilder(
    column: $table.checklistId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get inspectorId => $composableBuilder(
    column: $table.inspectorId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get scoreConformidade => $composableBuilder(
    column: $table.scoreConformidade,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get scoreNaoConformidade => $composableBuilder(
    column: $table.scoreNaoConformidade,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isSynced => $composableBuilder(
    column: $table.isSynced,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get versionHash => $composableBuilder(
    column: $table.versionHash,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isTemplate => $composableBuilder(
    column: $table.isTemplate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$InspecoesTableAnnotationComposer
    extends Composer<_$AppDatabase, $InspecoesTable> {
  $$InspecoesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get numero =>
      $composableBuilder(column: $table.numero, builder: (column) => column);

  GeneratedColumn<String> get titulo =>
      $composableBuilder(column: $table.titulo, builder: (column) => column);

  GeneratedColumn<String> get descricao =>
      $composableBuilder(column: $table.descricao, builder: (column) => column);

  GeneratedColumnWithTypeConverter<InspectionType, String> get tipo =>
      $composableBuilder(column: $table.tipo, builder: (column) => column);

  GeneratedColumnWithTypeConverter<InspectionStatus, String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<DateTime> get dataAgendada => $composableBuilder(
    column: $table.dataAgendada,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get dataInicio => $composableBuilder(
    column: $table.dataInicio,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get dataConclusao => $composableBuilder(
    column: $table.dataConclusao,
    builder: (column) => column,
  );

  GeneratedColumn<String> get endereco =>
      $composableBuilder(column: $table.endereco, builder: (column) => column);

  GeneratedColumn<double> get latitude =>
      $composableBuilder(column: $table.latitude, builder: (column) => column);

  GeneratedColumn<double> get longitude =>
      $composableBuilder(column: $table.longitude, builder: (column) => column);

  GeneratedColumn<String> get observacoes => $composableBuilder(
    column: $table.observacoes,
    builder: (column) => column,
  );

  GeneratedColumn<String> get establishmentId => $composableBuilder(
    column: $table.establishmentId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get checklistId => $composableBuilder(
    column: $table.checklistId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get inspectorId => $composableBuilder(
    column: $table.inspectorId,
    builder: (column) => column,
  );

  GeneratedColumn<double> get scoreConformidade => $composableBuilder(
    column: $table.scoreConformidade,
    builder: (column) => column,
  );

  GeneratedColumn<double> get scoreNaoConformidade => $composableBuilder(
    column: $table.scoreNaoConformidade,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isSynced =>
      $composableBuilder(column: $table.isSynced, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get serverId =>
      $composableBuilder(column: $table.serverId, builder: (column) => column);

  GeneratedColumn<String> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => column);

  GeneratedColumn<String> get versionHash => $composableBuilder(
    column: $table.versionHash,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isTemplate => $composableBuilder(
    column: $table.isTemplate,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isDeleted =>
      $composableBuilder(column: $table.isDeleted, builder: (column) => column);
}

class $$InspecoesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $InspecoesTable,
          Inspecoe,
          $$InspecoesTableFilterComposer,
          $$InspecoesTableOrderingComposer,
          $$InspecoesTableAnnotationComposer,
          $$InspecoesTableCreateCompanionBuilder,
          $$InspecoesTableUpdateCompanionBuilder,
          (Inspecoe, BaseReferences<_$AppDatabase, $InspecoesTable, Inspecoe>),
          Inspecoe,
          PrefetchHooks Function()
        > {
  $$InspecoesTableTableManager(_$AppDatabase db, $InspecoesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$InspecoesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$InspecoesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$InspecoesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> numero = const Value.absent(),
                Value<String> titulo = const Value.absent(),
                Value<String> descricao = const Value.absent(),
                Value<InspectionType> tipo = const Value.absent(),
                Value<InspectionStatus> status = const Value.absent(),
                Value<DateTime> dataAgendada = const Value.absent(),
                Value<DateTime?> dataInicio = const Value.absent(),
                Value<DateTime?> dataConclusao = const Value.absent(),
                Value<String> endereco = const Value.absent(),
                Value<double> latitude = const Value.absent(),
                Value<double> longitude = const Value.absent(),
                Value<String?> observacoes = const Value.absent(),
                Value<String?> establishmentId = const Value.absent(),
                Value<String?> checklistId = const Value.absent(),
                Value<String?> inspectorId = const Value.absent(),
                Value<double?> scoreConformidade = const Value.absent(),
                Value<double?> scoreNaoConformidade = const Value.absent(),
                Value<bool> isSynced = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<String?> serverId = const Value.absent(),
                Value<String?> deviceId = const Value.absent(),
                Value<String?> versionHash = const Value.absent(),
                Value<bool> isTemplate = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => InspecoesCompanion(
                id: id,
                numero: numero,
                titulo: titulo,
                descricao: descricao,
                tipo: tipo,
                status: status,
                dataAgendada: dataAgendada,
                dataInicio: dataInicio,
                dataConclusao: dataConclusao,
                endereco: endereco,
                latitude: latitude,
                longitude: longitude,
                observacoes: observacoes,
                establishmentId: establishmentId,
                checklistId: checklistId,
                inspectorId: inspectorId,
                scoreConformidade: scoreConformidade,
                scoreNaoConformidade: scoreNaoConformidade,
                isSynced: isSynced,
                createdAt: createdAt,
                updatedAt: updatedAt,
                serverId: serverId,
                deviceId: deviceId,
                versionHash: versionHash,
                isTemplate: isTemplate,
                isDeleted: isDeleted,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String?> numero = const Value.absent(),
                required String titulo,
                required String descricao,
                required InspectionType tipo,
                required InspectionStatus status,
                required DateTime dataAgendada,
                Value<DateTime?> dataInicio = const Value.absent(),
                Value<DateTime?> dataConclusao = const Value.absent(),
                required String endereco,
                required double latitude,
                required double longitude,
                Value<String?> observacoes = const Value.absent(),
                Value<String?> establishmentId = const Value.absent(),
                Value<String?> checklistId = const Value.absent(),
                Value<String?> inspectorId = const Value.absent(),
                Value<double?> scoreConformidade = const Value.absent(),
                Value<double?> scoreNaoConformidade = const Value.absent(),
                Value<bool> isSynced = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<String?> serverId = const Value.absent(),
                Value<String?> deviceId = const Value.absent(),
                Value<String?> versionHash = const Value.absent(),
                Value<bool> isTemplate = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => InspecoesCompanion.insert(
                id: id,
                numero: numero,
                titulo: titulo,
                descricao: descricao,
                tipo: tipo,
                status: status,
                dataAgendada: dataAgendada,
                dataInicio: dataInicio,
                dataConclusao: dataConclusao,
                endereco: endereco,
                latitude: latitude,
                longitude: longitude,
                observacoes: observacoes,
                establishmentId: establishmentId,
                checklistId: checklistId,
                inspectorId: inspectorId,
                scoreConformidade: scoreConformidade,
                scoreNaoConformidade: scoreNaoConformidade,
                isSynced: isSynced,
                createdAt: createdAt,
                updatedAt: updatedAt,
                serverId: serverId,
                deviceId: deviceId,
                versionHash: versionHash,
                isTemplate: isTemplate,
                isDeleted: isDeleted,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$InspecoesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $InspecoesTable,
      Inspecoe,
      $$InspecoesTableFilterComposer,
      $$InspecoesTableOrderingComposer,
      $$InspecoesTableAnnotationComposer,
      $$InspecoesTableCreateCompanionBuilder,
      $$InspecoesTableUpdateCompanionBuilder,
      (Inspecoe, BaseReferences<_$AppDatabase, $InspecoesTable, Inspecoe>),
      Inspecoe,
      PrefetchHooks Function()
    >;
typedef $$RespostasInspecaoTableCreateCompanionBuilder =
    RespostasInspecaoCompanion Function({
      required String id,
      required String inspecaoId,
      required String itemChecklistId,
      required String itemDescricao,
      required String categoria,
      required ItemStatus status,
      Value<String?> valorTexto,
      Value<double?> valorNumero,
      Value<DateTime?> valorData,
      Value<int?> valorRating,
      Value<bool?> valorBooleano,
      Value<double?> latitude,
      Value<double?> longitude,
      Value<DateTime?> gpsTimestamp,
      Value<String?> observacoes,
      required int ordem,
      Value<bool> obrigatorio,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<bool> isSynced,
      Value<int> rowid,
    });
typedef $$RespostasInspecaoTableUpdateCompanionBuilder =
    RespostasInspecaoCompanion Function({
      Value<String> id,
      Value<String> inspecaoId,
      Value<String> itemChecklistId,
      Value<String> itemDescricao,
      Value<String> categoria,
      Value<ItemStatus> status,
      Value<String?> valorTexto,
      Value<double?> valorNumero,
      Value<DateTime?> valorData,
      Value<int?> valorRating,
      Value<bool?> valorBooleano,
      Value<double?> latitude,
      Value<double?> longitude,
      Value<DateTime?> gpsTimestamp,
      Value<String?> observacoes,
      Value<int> ordem,
      Value<bool> obrigatorio,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<bool> isSynced,
      Value<int> rowid,
    });

class $$RespostasInspecaoTableFilterComposer
    extends Composer<_$AppDatabase, $RespostasInspecaoTable> {
  $$RespostasInspecaoTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get inspecaoId => $composableBuilder(
    column: $table.inspecaoId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get itemChecklistId => $composableBuilder(
    column: $table.itemChecklistId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get itemDescricao => $composableBuilder(
    column: $table.itemDescricao,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get categoria => $composableBuilder(
    column: $table.categoria,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<ItemStatus, ItemStatus, String> get status =>
      $composableBuilder(
        column: $table.status,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get valorTexto => $composableBuilder(
    column: $table.valorTexto,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get valorNumero => $composableBuilder(
    column: $table.valorNumero,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get valorData => $composableBuilder(
    column: $table.valorData,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get valorRating => $composableBuilder(
    column: $table.valorRating,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get valorBooleano => $composableBuilder(
    column: $table.valorBooleano,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get latitude => $composableBuilder(
    column: $table.latitude,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get longitude => $composableBuilder(
    column: $table.longitude,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get gpsTimestamp => $composableBuilder(
    column: $table.gpsTimestamp,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get observacoes => $composableBuilder(
    column: $table.observacoes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get ordem => $composableBuilder(
    column: $table.ordem,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get obrigatorio => $composableBuilder(
    column: $table.obrigatorio,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isSynced => $composableBuilder(
    column: $table.isSynced,
    builder: (column) => ColumnFilters(column),
  );
}

class $$RespostasInspecaoTableOrderingComposer
    extends Composer<_$AppDatabase, $RespostasInspecaoTable> {
  $$RespostasInspecaoTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get inspecaoId => $composableBuilder(
    column: $table.inspecaoId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get itemChecklistId => $composableBuilder(
    column: $table.itemChecklistId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get itemDescricao => $composableBuilder(
    column: $table.itemDescricao,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get categoria => $composableBuilder(
    column: $table.categoria,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get valorTexto => $composableBuilder(
    column: $table.valorTexto,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get valorNumero => $composableBuilder(
    column: $table.valorNumero,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get valorData => $composableBuilder(
    column: $table.valorData,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get valorRating => $composableBuilder(
    column: $table.valorRating,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get valorBooleano => $composableBuilder(
    column: $table.valorBooleano,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get latitude => $composableBuilder(
    column: $table.latitude,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get longitude => $composableBuilder(
    column: $table.longitude,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get gpsTimestamp => $composableBuilder(
    column: $table.gpsTimestamp,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get observacoes => $composableBuilder(
    column: $table.observacoes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get ordem => $composableBuilder(
    column: $table.ordem,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get obrigatorio => $composableBuilder(
    column: $table.obrigatorio,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isSynced => $composableBuilder(
    column: $table.isSynced,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$RespostasInspecaoTableAnnotationComposer
    extends Composer<_$AppDatabase, $RespostasInspecaoTable> {
  $$RespostasInspecaoTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get inspecaoId => $composableBuilder(
    column: $table.inspecaoId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get itemChecklistId => $composableBuilder(
    column: $table.itemChecklistId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get itemDescricao => $composableBuilder(
    column: $table.itemDescricao,
    builder: (column) => column,
  );

  GeneratedColumn<String> get categoria =>
      $composableBuilder(column: $table.categoria, builder: (column) => column);

  GeneratedColumnWithTypeConverter<ItemStatus, String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get valorTexto => $composableBuilder(
    column: $table.valorTexto,
    builder: (column) => column,
  );

  GeneratedColumn<double> get valorNumero => $composableBuilder(
    column: $table.valorNumero,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get valorData =>
      $composableBuilder(column: $table.valorData, builder: (column) => column);

  GeneratedColumn<int> get valorRating => $composableBuilder(
    column: $table.valorRating,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get valorBooleano => $composableBuilder(
    column: $table.valorBooleano,
    builder: (column) => column,
  );

  GeneratedColumn<double> get latitude =>
      $composableBuilder(column: $table.latitude, builder: (column) => column);

  GeneratedColumn<double> get longitude =>
      $composableBuilder(column: $table.longitude, builder: (column) => column);

  GeneratedColumn<DateTime> get gpsTimestamp => $composableBuilder(
    column: $table.gpsTimestamp,
    builder: (column) => column,
  );

  GeneratedColumn<String> get observacoes => $composableBuilder(
    column: $table.observacoes,
    builder: (column) => column,
  );

  GeneratedColumn<int> get ordem =>
      $composableBuilder(column: $table.ordem, builder: (column) => column);

  GeneratedColumn<bool> get obrigatorio => $composableBuilder(
    column: $table.obrigatorio,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<bool> get isSynced =>
      $composableBuilder(column: $table.isSynced, builder: (column) => column);
}

class $$RespostasInspecaoTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RespostasInspecaoTable,
          RespostasInspecaoData,
          $$RespostasInspecaoTableFilterComposer,
          $$RespostasInspecaoTableOrderingComposer,
          $$RespostasInspecaoTableAnnotationComposer,
          $$RespostasInspecaoTableCreateCompanionBuilder,
          $$RespostasInspecaoTableUpdateCompanionBuilder,
          (
            RespostasInspecaoData,
            BaseReferences<
              _$AppDatabase,
              $RespostasInspecaoTable,
              RespostasInspecaoData
            >,
          ),
          RespostasInspecaoData,
          PrefetchHooks Function()
        > {
  $$RespostasInspecaoTableTableManager(
    _$AppDatabase db,
    $RespostasInspecaoTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RespostasInspecaoTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RespostasInspecaoTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RespostasInspecaoTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> inspecaoId = const Value.absent(),
                Value<String> itemChecklistId = const Value.absent(),
                Value<String> itemDescricao = const Value.absent(),
                Value<String> categoria = const Value.absent(),
                Value<ItemStatus> status = const Value.absent(),
                Value<String?> valorTexto = const Value.absent(),
                Value<double?> valorNumero = const Value.absent(),
                Value<DateTime?> valorData = const Value.absent(),
                Value<int?> valorRating = const Value.absent(),
                Value<bool?> valorBooleano = const Value.absent(),
                Value<double?> latitude = const Value.absent(),
                Value<double?> longitude = const Value.absent(),
                Value<DateTime?> gpsTimestamp = const Value.absent(),
                Value<String?> observacoes = const Value.absent(),
                Value<int> ordem = const Value.absent(),
                Value<bool> obrigatorio = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<bool> isSynced = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RespostasInspecaoCompanion(
                id: id,
                inspecaoId: inspecaoId,
                itemChecklistId: itemChecklistId,
                itemDescricao: itemDescricao,
                categoria: categoria,
                status: status,
                valorTexto: valorTexto,
                valorNumero: valorNumero,
                valorData: valorData,
                valorRating: valorRating,
                valorBooleano: valorBooleano,
                latitude: latitude,
                longitude: longitude,
                gpsTimestamp: gpsTimestamp,
                observacoes: observacoes,
                ordem: ordem,
                obrigatorio: obrigatorio,
                createdAt: createdAt,
                updatedAt: updatedAt,
                isSynced: isSynced,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String inspecaoId,
                required String itemChecklistId,
                required String itemDescricao,
                required String categoria,
                required ItemStatus status,
                Value<String?> valorTexto = const Value.absent(),
                Value<double?> valorNumero = const Value.absent(),
                Value<DateTime?> valorData = const Value.absent(),
                Value<int?> valorRating = const Value.absent(),
                Value<bool?> valorBooleano = const Value.absent(),
                Value<double?> latitude = const Value.absent(),
                Value<double?> longitude = const Value.absent(),
                Value<DateTime?> gpsTimestamp = const Value.absent(),
                Value<String?> observacoes = const Value.absent(),
                required int ordem,
                Value<bool> obrigatorio = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<bool> isSynced = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RespostasInspecaoCompanion.insert(
                id: id,
                inspecaoId: inspecaoId,
                itemChecklistId: itemChecklistId,
                itemDescricao: itemDescricao,
                categoria: categoria,
                status: status,
                valorTexto: valorTexto,
                valorNumero: valorNumero,
                valorData: valorData,
                valorRating: valorRating,
                valorBooleano: valorBooleano,
                latitude: latitude,
                longitude: longitude,
                gpsTimestamp: gpsTimestamp,
                observacoes: observacoes,
                ordem: ordem,
                obrigatorio: obrigatorio,
                createdAt: createdAt,
                updatedAt: updatedAt,
                isSynced: isSynced,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$RespostasInspecaoTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RespostasInspecaoTable,
      RespostasInspecaoData,
      $$RespostasInspecaoTableFilterComposer,
      $$RespostasInspecaoTableOrderingComposer,
      $$RespostasInspecaoTableAnnotationComposer,
      $$RespostasInspecaoTableCreateCompanionBuilder,
      $$RespostasInspecaoTableUpdateCompanionBuilder,
      (
        RespostasInspecaoData,
        BaseReferences<
          _$AppDatabase,
          $RespostasInspecaoTable,
          RespostasInspecaoData
        >,
      ),
      RespostasInspecaoData,
      PrefetchHooks Function()
    >;
typedef $$AnexosInspecaoTableCreateCompanionBuilder =
    AnexosInspecaoCompanion Function({
      required String id,
      required String inspecaoId,
      Value<String?> respostaId,
      required String nomeArquivo,
      required String tipoMime,
      required int tamanho,
      required String caminhoLocal,
      Value<String?> urlServidor,
      Value<String?> descricao,
      Value<DateTime?> dataCaptura,
      Value<bool> isSynced,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<String?> serverId,
      Value<int> rowid,
    });
typedef $$AnexosInspecaoTableUpdateCompanionBuilder =
    AnexosInspecaoCompanion Function({
      Value<String> id,
      Value<String> inspecaoId,
      Value<String?> respostaId,
      Value<String> nomeArquivo,
      Value<String> tipoMime,
      Value<int> tamanho,
      Value<String> caminhoLocal,
      Value<String?> urlServidor,
      Value<String?> descricao,
      Value<DateTime?> dataCaptura,
      Value<bool> isSynced,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<String?> serverId,
      Value<int> rowid,
    });

class $$AnexosInspecaoTableFilterComposer
    extends Composer<_$AppDatabase, $AnexosInspecaoTable> {
  $$AnexosInspecaoTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get inspecaoId => $composableBuilder(
    column: $table.inspecaoId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get respostaId => $composableBuilder(
    column: $table.respostaId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nomeArquivo => $composableBuilder(
    column: $table.nomeArquivo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tipoMime => $composableBuilder(
    column: $table.tipoMime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get tamanho => $composableBuilder(
    column: $table.tamanho,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get caminhoLocal => $composableBuilder(
    column: $table.caminhoLocal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get urlServidor => $composableBuilder(
    column: $table.urlServidor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get descricao => $composableBuilder(
    column: $table.descricao,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get dataCaptura => $composableBuilder(
    column: $table.dataCaptura,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isSynced => $composableBuilder(
    column: $table.isSynced,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AnexosInspecaoTableOrderingComposer
    extends Composer<_$AppDatabase, $AnexosInspecaoTable> {
  $$AnexosInspecaoTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get inspecaoId => $composableBuilder(
    column: $table.inspecaoId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get respostaId => $composableBuilder(
    column: $table.respostaId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nomeArquivo => $composableBuilder(
    column: $table.nomeArquivo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tipoMime => $composableBuilder(
    column: $table.tipoMime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get tamanho => $composableBuilder(
    column: $table.tamanho,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get caminhoLocal => $composableBuilder(
    column: $table.caminhoLocal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get urlServidor => $composableBuilder(
    column: $table.urlServidor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get descricao => $composableBuilder(
    column: $table.descricao,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get dataCaptura => $composableBuilder(
    column: $table.dataCaptura,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isSynced => $composableBuilder(
    column: $table.isSynced,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AnexosInspecaoTableAnnotationComposer
    extends Composer<_$AppDatabase, $AnexosInspecaoTable> {
  $$AnexosInspecaoTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get inspecaoId => $composableBuilder(
    column: $table.inspecaoId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get respostaId => $composableBuilder(
    column: $table.respostaId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get nomeArquivo => $composableBuilder(
    column: $table.nomeArquivo,
    builder: (column) => column,
  );

  GeneratedColumn<String> get tipoMime =>
      $composableBuilder(column: $table.tipoMime, builder: (column) => column);

  GeneratedColumn<int> get tamanho =>
      $composableBuilder(column: $table.tamanho, builder: (column) => column);

  GeneratedColumn<String> get caminhoLocal => $composableBuilder(
    column: $table.caminhoLocal,
    builder: (column) => column,
  );

  GeneratedColumn<String> get urlServidor => $composableBuilder(
    column: $table.urlServidor,
    builder: (column) => column,
  );

  GeneratedColumn<String> get descricao =>
      $composableBuilder(column: $table.descricao, builder: (column) => column);

  GeneratedColumn<DateTime> get dataCaptura => $composableBuilder(
    column: $table.dataCaptura,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isSynced =>
      $composableBuilder(column: $table.isSynced, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get serverId =>
      $composableBuilder(column: $table.serverId, builder: (column) => column);
}

class $$AnexosInspecaoTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AnexosInspecaoTable,
          AnexosInspecaoData,
          $$AnexosInspecaoTableFilterComposer,
          $$AnexosInspecaoTableOrderingComposer,
          $$AnexosInspecaoTableAnnotationComposer,
          $$AnexosInspecaoTableCreateCompanionBuilder,
          $$AnexosInspecaoTableUpdateCompanionBuilder,
          (
            AnexosInspecaoData,
            BaseReferences<
              _$AppDatabase,
              $AnexosInspecaoTable,
              AnexosInspecaoData
            >,
          ),
          AnexosInspecaoData,
          PrefetchHooks Function()
        > {
  $$AnexosInspecaoTableTableManager(
    _$AppDatabase db,
    $AnexosInspecaoTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AnexosInspecaoTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AnexosInspecaoTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AnexosInspecaoTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> inspecaoId = const Value.absent(),
                Value<String?> respostaId = const Value.absent(),
                Value<String> nomeArquivo = const Value.absent(),
                Value<String> tipoMime = const Value.absent(),
                Value<int> tamanho = const Value.absent(),
                Value<String> caminhoLocal = const Value.absent(),
                Value<String?> urlServidor = const Value.absent(),
                Value<String?> descricao = const Value.absent(),
                Value<DateTime?> dataCaptura = const Value.absent(),
                Value<bool> isSynced = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<String?> serverId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AnexosInspecaoCompanion(
                id: id,
                inspecaoId: inspecaoId,
                respostaId: respostaId,
                nomeArquivo: nomeArquivo,
                tipoMime: tipoMime,
                tamanho: tamanho,
                caminhoLocal: caminhoLocal,
                urlServidor: urlServidor,
                descricao: descricao,
                dataCaptura: dataCaptura,
                isSynced: isSynced,
                createdAt: createdAt,
                updatedAt: updatedAt,
                serverId: serverId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String inspecaoId,
                Value<String?> respostaId = const Value.absent(),
                required String nomeArquivo,
                required String tipoMime,
                required int tamanho,
                required String caminhoLocal,
                Value<String?> urlServidor = const Value.absent(),
                Value<String?> descricao = const Value.absent(),
                Value<DateTime?> dataCaptura = const Value.absent(),
                Value<bool> isSynced = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<String?> serverId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AnexosInspecaoCompanion.insert(
                id: id,
                inspecaoId: inspecaoId,
                respostaId: respostaId,
                nomeArquivo: nomeArquivo,
                tipoMime: tipoMime,
                tamanho: tamanho,
                caminhoLocal: caminhoLocal,
                urlServidor: urlServidor,
                descricao: descricao,
                dataCaptura: dataCaptura,
                isSynced: isSynced,
                createdAt: createdAt,
                updatedAt: updatedAt,
                serverId: serverId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AnexosInspecaoTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AnexosInspecaoTable,
      AnexosInspecaoData,
      $$AnexosInspecaoTableFilterComposer,
      $$AnexosInspecaoTableOrderingComposer,
      $$AnexosInspecaoTableAnnotationComposer,
      $$AnexosInspecaoTableCreateCompanionBuilder,
      $$AnexosInspecaoTableUpdateCompanionBuilder,
      (
        AnexosInspecaoData,
        BaseReferences<_$AppDatabase, $AnexosInspecaoTable, AnexosInspecaoData>,
      ),
      AnexosInspecaoData,
      PrefetchHooks Function()
    >;
typedef $$ChecklistsTableCreateCompanionBuilder =
    ChecklistsCompanion Function({
      required String id,
      required String nome,
      required String versao,
      Value<String?> categoria,
      required String jsonData,
      required DateTime dataDownload,
      required DateTime ultimaAtualizacao,
      Value<bool> isAtivo,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$ChecklistsTableUpdateCompanionBuilder =
    ChecklistsCompanion Function({
      Value<String> id,
      Value<String> nome,
      Value<String> versao,
      Value<String?> categoria,
      Value<String> jsonData,
      Value<DateTime> dataDownload,
      Value<DateTime> ultimaAtualizacao,
      Value<bool> isAtivo,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$ChecklistsTableFilterComposer
    extends Composer<_$AppDatabase, $ChecklistsTable> {
  $$ChecklistsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nome => $composableBuilder(
    column: $table.nome,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get versao => $composableBuilder(
    column: $table.versao,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get categoria => $composableBuilder(
    column: $table.categoria,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get jsonData => $composableBuilder(
    column: $table.jsonData,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get dataDownload => $composableBuilder(
    column: $table.dataDownload,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get ultimaAtualizacao => $composableBuilder(
    column: $table.ultimaAtualizacao,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isAtivo => $composableBuilder(
    column: $table.isAtivo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ChecklistsTableOrderingComposer
    extends Composer<_$AppDatabase, $ChecklistsTable> {
  $$ChecklistsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nome => $composableBuilder(
    column: $table.nome,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get versao => $composableBuilder(
    column: $table.versao,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get categoria => $composableBuilder(
    column: $table.categoria,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get jsonData => $composableBuilder(
    column: $table.jsonData,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get dataDownload => $composableBuilder(
    column: $table.dataDownload,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get ultimaAtualizacao => $composableBuilder(
    column: $table.ultimaAtualizacao,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isAtivo => $composableBuilder(
    column: $table.isAtivo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ChecklistsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ChecklistsTable> {
  $$ChecklistsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get nome =>
      $composableBuilder(column: $table.nome, builder: (column) => column);

  GeneratedColumn<String> get versao =>
      $composableBuilder(column: $table.versao, builder: (column) => column);

  GeneratedColumn<String> get categoria =>
      $composableBuilder(column: $table.categoria, builder: (column) => column);

  GeneratedColumn<String> get jsonData =>
      $composableBuilder(column: $table.jsonData, builder: (column) => column);

  GeneratedColumn<DateTime> get dataDownload => $composableBuilder(
    column: $table.dataDownload,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get ultimaAtualizacao => $composableBuilder(
    column: $table.ultimaAtualizacao,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isAtivo =>
      $composableBuilder(column: $table.isAtivo, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$ChecklistsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ChecklistsTable,
          Checklist,
          $$ChecklistsTableFilterComposer,
          $$ChecklistsTableOrderingComposer,
          $$ChecklistsTableAnnotationComposer,
          $$ChecklistsTableCreateCompanionBuilder,
          $$ChecklistsTableUpdateCompanionBuilder,
          (
            Checklist,
            BaseReferences<_$AppDatabase, $ChecklistsTable, Checklist>,
          ),
          Checklist,
          PrefetchHooks Function()
        > {
  $$ChecklistsTableTableManager(_$AppDatabase db, $ChecklistsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ChecklistsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ChecklistsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ChecklistsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> nome = const Value.absent(),
                Value<String> versao = const Value.absent(),
                Value<String?> categoria = const Value.absent(),
                Value<String> jsonData = const Value.absent(),
                Value<DateTime> dataDownload = const Value.absent(),
                Value<DateTime> ultimaAtualizacao = const Value.absent(),
                Value<bool> isAtivo = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ChecklistsCompanion(
                id: id,
                nome: nome,
                versao: versao,
                categoria: categoria,
                jsonData: jsonData,
                dataDownload: dataDownload,
                ultimaAtualizacao: ultimaAtualizacao,
                isAtivo: isAtivo,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String nome,
                required String versao,
                Value<String?> categoria = const Value.absent(),
                required String jsonData,
                required DateTime dataDownload,
                required DateTime ultimaAtualizacao,
                Value<bool> isAtivo = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => ChecklistsCompanion.insert(
                id: id,
                nome: nome,
                versao: versao,
                categoria: categoria,
                jsonData: jsonData,
                dataDownload: dataDownload,
                ultimaAtualizacao: ultimaAtualizacao,
                isAtivo: isAtivo,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ChecklistsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ChecklistsTable,
      Checklist,
      $$ChecklistsTableFilterComposer,
      $$ChecklistsTableOrderingComposer,
      $$ChecklistsTableAnnotationComposer,
      $$ChecklistsTableCreateCompanionBuilder,
      $$ChecklistsTableUpdateCompanionBuilder,
      (Checklist, BaseReferences<_$AppDatabase, $ChecklistsTable, Checklist>),
      Checklist,
      PrefetchHooks Function()
    >;
typedef $$EstabelecimentosTableCreateCompanionBuilder =
    EstabelecimentosCompanion Function({
      required String id,
      Value<String?> codigo,
      required String nome,
      required String descricao,
      required EstablishmentType tipo,
      required String endereco,
      required double latitude,
      required double longitude,
      Value<String?> telefone,
      Value<String?> email,
      Value<String?> responsavel,
      Value<String?> observacoes,
      Value<bool> isSynced,
      Value<DateTime?> dataSincronizacao,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<String?> serverId,
      Value<int> rowid,
    });
typedef $$EstabelecimentosTableUpdateCompanionBuilder =
    EstabelecimentosCompanion Function({
      Value<String> id,
      Value<String?> codigo,
      Value<String> nome,
      Value<String> descricao,
      Value<EstablishmentType> tipo,
      Value<String> endereco,
      Value<double> latitude,
      Value<double> longitude,
      Value<String?> telefone,
      Value<String?> email,
      Value<String?> responsavel,
      Value<String?> observacoes,
      Value<bool> isSynced,
      Value<DateTime?> dataSincronizacao,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<String?> serverId,
      Value<int> rowid,
    });

class $$EstabelecimentosTableFilterComposer
    extends Composer<_$AppDatabase, $EstabelecimentosTable> {
  $$EstabelecimentosTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get codigo => $composableBuilder(
    column: $table.codigo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nome => $composableBuilder(
    column: $table.nome,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get descricao => $composableBuilder(
    column: $table.descricao,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<EstablishmentType, EstablishmentType, String>
  get tipo => $composableBuilder(
    column: $table.tipo,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get endereco => $composableBuilder(
    column: $table.endereco,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get latitude => $composableBuilder(
    column: $table.latitude,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get longitude => $composableBuilder(
    column: $table.longitude,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get telefone => $composableBuilder(
    column: $table.telefone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get responsavel => $composableBuilder(
    column: $table.responsavel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get observacoes => $composableBuilder(
    column: $table.observacoes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isSynced => $composableBuilder(
    column: $table.isSynced,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get dataSincronizacao => $composableBuilder(
    column: $table.dataSincronizacao,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnFilters(column),
  );
}

class $$EstabelecimentosTableOrderingComposer
    extends Composer<_$AppDatabase, $EstabelecimentosTable> {
  $$EstabelecimentosTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get codigo => $composableBuilder(
    column: $table.codigo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nome => $composableBuilder(
    column: $table.nome,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get descricao => $composableBuilder(
    column: $table.descricao,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tipo => $composableBuilder(
    column: $table.tipo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get endereco => $composableBuilder(
    column: $table.endereco,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get latitude => $composableBuilder(
    column: $table.latitude,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get longitude => $composableBuilder(
    column: $table.longitude,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get telefone => $composableBuilder(
    column: $table.telefone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get responsavel => $composableBuilder(
    column: $table.responsavel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get observacoes => $composableBuilder(
    column: $table.observacoes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isSynced => $composableBuilder(
    column: $table.isSynced,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get dataSincronizacao => $composableBuilder(
    column: $table.dataSincronizacao,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$EstabelecimentosTableAnnotationComposer
    extends Composer<_$AppDatabase, $EstabelecimentosTable> {
  $$EstabelecimentosTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get codigo =>
      $composableBuilder(column: $table.codigo, builder: (column) => column);

  GeneratedColumn<String> get nome =>
      $composableBuilder(column: $table.nome, builder: (column) => column);

  GeneratedColumn<String> get descricao =>
      $composableBuilder(column: $table.descricao, builder: (column) => column);

  GeneratedColumnWithTypeConverter<EstablishmentType, String> get tipo =>
      $composableBuilder(column: $table.tipo, builder: (column) => column);

  GeneratedColumn<String> get endereco =>
      $composableBuilder(column: $table.endereco, builder: (column) => column);

  GeneratedColumn<double> get latitude =>
      $composableBuilder(column: $table.latitude, builder: (column) => column);

  GeneratedColumn<double> get longitude =>
      $composableBuilder(column: $table.longitude, builder: (column) => column);

  GeneratedColumn<String> get telefone =>
      $composableBuilder(column: $table.telefone, builder: (column) => column);

  GeneratedColumn<String> get email =>
      $composableBuilder(column: $table.email, builder: (column) => column);

  GeneratedColumn<String> get responsavel => $composableBuilder(
    column: $table.responsavel,
    builder: (column) => column,
  );

  GeneratedColumn<String> get observacoes => $composableBuilder(
    column: $table.observacoes,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isSynced =>
      $composableBuilder(column: $table.isSynced, builder: (column) => column);

  GeneratedColumn<DateTime> get dataSincronizacao => $composableBuilder(
    column: $table.dataSincronizacao,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get serverId =>
      $composableBuilder(column: $table.serverId, builder: (column) => column);
}

class $$EstabelecimentosTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $EstabelecimentosTable,
          Estabelecimento,
          $$EstabelecimentosTableFilterComposer,
          $$EstabelecimentosTableOrderingComposer,
          $$EstabelecimentosTableAnnotationComposer,
          $$EstabelecimentosTableCreateCompanionBuilder,
          $$EstabelecimentosTableUpdateCompanionBuilder,
          (
            Estabelecimento,
            BaseReferences<
              _$AppDatabase,
              $EstabelecimentosTable,
              Estabelecimento
            >,
          ),
          Estabelecimento,
          PrefetchHooks Function()
        > {
  $$EstabelecimentosTableTableManager(
    _$AppDatabase db,
    $EstabelecimentosTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EstabelecimentosTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EstabelecimentosTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EstabelecimentosTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> codigo = const Value.absent(),
                Value<String> nome = const Value.absent(),
                Value<String> descricao = const Value.absent(),
                Value<EstablishmentType> tipo = const Value.absent(),
                Value<String> endereco = const Value.absent(),
                Value<double> latitude = const Value.absent(),
                Value<double> longitude = const Value.absent(),
                Value<String?> telefone = const Value.absent(),
                Value<String?> email = const Value.absent(),
                Value<String?> responsavel = const Value.absent(),
                Value<String?> observacoes = const Value.absent(),
                Value<bool> isSynced = const Value.absent(),
                Value<DateTime?> dataSincronizacao = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<String?> serverId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => EstabelecimentosCompanion(
                id: id,
                codigo: codigo,
                nome: nome,
                descricao: descricao,
                tipo: tipo,
                endereco: endereco,
                latitude: latitude,
                longitude: longitude,
                telefone: telefone,
                email: email,
                responsavel: responsavel,
                observacoes: observacoes,
                isSynced: isSynced,
                dataSincronizacao: dataSincronizacao,
                createdAt: createdAt,
                updatedAt: updatedAt,
                serverId: serverId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String?> codigo = const Value.absent(),
                required String nome,
                required String descricao,
                required EstablishmentType tipo,
                required String endereco,
                required double latitude,
                required double longitude,
                Value<String?> telefone = const Value.absent(),
                Value<String?> email = const Value.absent(),
                Value<String?> responsavel = const Value.absent(),
                Value<String?> observacoes = const Value.absent(),
                Value<bool> isSynced = const Value.absent(),
                Value<DateTime?> dataSincronizacao = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<String?> serverId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => EstabelecimentosCompanion.insert(
                id: id,
                codigo: codigo,
                nome: nome,
                descricao: descricao,
                tipo: tipo,
                endereco: endereco,
                latitude: latitude,
                longitude: longitude,
                telefone: telefone,
                email: email,
                responsavel: responsavel,
                observacoes: observacoes,
                isSynced: isSynced,
                dataSincronizacao: dataSincronizacao,
                createdAt: createdAt,
                updatedAt: updatedAt,
                serverId: serverId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$EstabelecimentosTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $EstabelecimentosTable,
      Estabelecimento,
      $$EstabelecimentosTableFilterComposer,
      $$EstabelecimentosTableOrderingComposer,
      $$EstabelecimentosTableAnnotationComposer,
      $$EstabelecimentosTableCreateCompanionBuilder,
      $$EstabelecimentosTableUpdateCompanionBuilder,
      (
        Estabelecimento,
        BaseReferences<_$AppDatabase, $EstabelecimentosTable, Estabelecimento>,
      ),
      Estabelecimento,
      PrefetchHooks Function()
    >;
typedef $$SincronizacoesTableCreateCompanionBuilder =
    SincronizacoesCompanion Function({
      Value<int> id,
      required String inspecaoId,
      required String dispositivoId,
      required String status,
      Value<String?> versaoServidor,
      Value<String?> versaoDispositivo,
      required DateTime timestamp,
      Value<DateTime?> ultimaTentativa,
      Value<int> tentativas,
      Value<bool> temConflito,
      Value<String?> mensagemErro,
      required String direcao,
    });
typedef $$SincronizacoesTableUpdateCompanionBuilder =
    SincronizacoesCompanion Function({
      Value<int> id,
      Value<String> inspecaoId,
      Value<String> dispositivoId,
      Value<String> status,
      Value<String?> versaoServidor,
      Value<String?> versaoDispositivo,
      Value<DateTime> timestamp,
      Value<DateTime?> ultimaTentativa,
      Value<int> tentativas,
      Value<bool> temConflito,
      Value<String?> mensagemErro,
      Value<String> direcao,
    });

class $$SincronizacoesTableFilterComposer
    extends Composer<_$AppDatabase, $SincronizacoesTable> {
  $$SincronizacoesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get inspecaoId => $composableBuilder(
    column: $table.inspecaoId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get dispositivoId => $composableBuilder(
    column: $table.dispositivoId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get versaoServidor => $composableBuilder(
    column: $table.versaoServidor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get versaoDispositivo => $composableBuilder(
    column: $table.versaoDispositivo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get ultimaTentativa => $composableBuilder(
    column: $table.ultimaTentativa,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get tentativas => $composableBuilder(
    column: $table.tentativas,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get temConflito => $composableBuilder(
    column: $table.temConflito,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mensagemErro => $composableBuilder(
    column: $table.mensagemErro,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get direcao => $composableBuilder(
    column: $table.direcao,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SincronizacoesTableOrderingComposer
    extends Composer<_$AppDatabase, $SincronizacoesTable> {
  $$SincronizacoesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get inspecaoId => $composableBuilder(
    column: $table.inspecaoId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get dispositivoId => $composableBuilder(
    column: $table.dispositivoId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get versaoServidor => $composableBuilder(
    column: $table.versaoServidor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get versaoDispositivo => $composableBuilder(
    column: $table.versaoDispositivo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get ultimaTentativa => $composableBuilder(
    column: $table.ultimaTentativa,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get tentativas => $composableBuilder(
    column: $table.tentativas,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get temConflito => $composableBuilder(
    column: $table.temConflito,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mensagemErro => $composableBuilder(
    column: $table.mensagemErro,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get direcao => $composableBuilder(
    column: $table.direcao,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SincronizacoesTableAnnotationComposer
    extends Composer<_$AppDatabase, $SincronizacoesTable> {
  $$SincronizacoesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get inspecaoId => $composableBuilder(
    column: $table.inspecaoId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get dispositivoId => $composableBuilder(
    column: $table.dispositivoId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get versaoServidor => $composableBuilder(
    column: $table.versaoServidor,
    builder: (column) => column,
  );

  GeneratedColumn<String> get versaoDispositivo => $composableBuilder(
    column: $table.versaoDispositivo,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get timestamp =>
      $composableBuilder(column: $table.timestamp, builder: (column) => column);

  GeneratedColumn<DateTime> get ultimaTentativa => $composableBuilder(
    column: $table.ultimaTentativa,
    builder: (column) => column,
  );

  GeneratedColumn<int> get tentativas => $composableBuilder(
    column: $table.tentativas,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get temConflito => $composableBuilder(
    column: $table.temConflito,
    builder: (column) => column,
  );

  GeneratedColumn<String> get mensagemErro => $composableBuilder(
    column: $table.mensagemErro,
    builder: (column) => column,
  );

  GeneratedColumn<String> get direcao =>
      $composableBuilder(column: $table.direcao, builder: (column) => column);
}

class $$SincronizacoesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SincronizacoesTable,
          Sincronizacoe,
          $$SincronizacoesTableFilterComposer,
          $$SincronizacoesTableOrderingComposer,
          $$SincronizacoesTableAnnotationComposer,
          $$SincronizacoesTableCreateCompanionBuilder,
          $$SincronizacoesTableUpdateCompanionBuilder,
          (
            Sincronizacoe,
            BaseReferences<_$AppDatabase, $SincronizacoesTable, Sincronizacoe>,
          ),
          Sincronizacoe,
          PrefetchHooks Function()
        > {
  $$SincronizacoesTableTableManager(
    _$AppDatabase db,
    $SincronizacoesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SincronizacoesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SincronizacoesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SincronizacoesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> inspecaoId = const Value.absent(),
                Value<String> dispositivoId = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> versaoServidor = const Value.absent(),
                Value<String?> versaoDispositivo = const Value.absent(),
                Value<DateTime> timestamp = const Value.absent(),
                Value<DateTime?> ultimaTentativa = const Value.absent(),
                Value<int> tentativas = const Value.absent(),
                Value<bool> temConflito = const Value.absent(),
                Value<String?> mensagemErro = const Value.absent(),
                Value<String> direcao = const Value.absent(),
              }) => SincronizacoesCompanion(
                id: id,
                inspecaoId: inspecaoId,
                dispositivoId: dispositivoId,
                status: status,
                versaoServidor: versaoServidor,
                versaoDispositivo: versaoDispositivo,
                timestamp: timestamp,
                ultimaTentativa: ultimaTentativa,
                tentativas: tentativas,
                temConflito: temConflito,
                mensagemErro: mensagemErro,
                direcao: direcao,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String inspecaoId,
                required String dispositivoId,
                required String status,
                Value<String?> versaoServidor = const Value.absent(),
                Value<String?> versaoDispositivo = const Value.absent(),
                required DateTime timestamp,
                Value<DateTime?> ultimaTentativa = const Value.absent(),
                Value<int> tentativas = const Value.absent(),
                Value<bool> temConflito = const Value.absent(),
                Value<String?> mensagemErro = const Value.absent(),
                required String direcao,
              }) => SincronizacoesCompanion.insert(
                id: id,
                inspecaoId: inspecaoId,
                dispositivoId: dispositivoId,
                status: status,
                versaoServidor: versaoServidor,
                versaoDispositivo: versaoDispositivo,
                timestamp: timestamp,
                ultimaTentativa: ultimaTentativa,
                tentativas: tentativas,
                temConflito: temConflito,
                mensagemErro: mensagemErro,
                direcao: direcao,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SincronizacoesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SincronizacoesTable,
      Sincronizacoe,
      $$SincronizacoesTableFilterComposer,
      $$SincronizacoesTableOrderingComposer,
      $$SincronizacoesTableAnnotationComposer,
      $$SincronizacoesTableCreateCompanionBuilder,
      $$SincronizacoesTableUpdateCompanionBuilder,
      (
        Sincronizacoe,
        BaseReferences<_$AppDatabase, $SincronizacoesTable, Sincronizacoe>,
      ),
      Sincronizacoe,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$InspecoesTableTableManager get inspecoes =>
      $$InspecoesTableTableManager(_db, _db.inspecoes);
  $$RespostasInspecaoTableTableManager get respostasInspecao =>
      $$RespostasInspecaoTableTableManager(_db, _db.respostasInspecao);
  $$AnexosInspecaoTableTableManager get anexosInspecao =>
      $$AnexosInspecaoTableTableManager(_db, _db.anexosInspecao);
  $$ChecklistsTableTableManager get checklists =>
      $$ChecklistsTableTableManager(_db, _db.checklists);
  $$EstabelecimentosTableTableManager get estabelecimentos =>
      $$EstabelecimentosTableTableManager(_db, _db.estabelecimentos);
  $$SincronizacoesTableTableManager get sincronizacoes =>
      $$SincronizacoesTableTableManager(_db, _db.sincronizacoes);
}
