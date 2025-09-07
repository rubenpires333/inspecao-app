enum EstablishmentType {
  instituicao,
  estabelecimento,
  veiculo,
  entidadeSaude,
  equipamento,
  predio,
  area,
  outros,
}

class Establishment {
  final String id;
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
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isSynced;
  final String? serverId;

  Establishment({
    required this.id,
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
    required this.createdAt,
    required this.updatedAt,
    this.isSynced = false,
    this.serverId,
  });

  Establishment copyWith({
    String? id,
    String? nome,
    String? descricao,
    EstablishmentType? tipo,
    String? endereco,
    double? latitude,
    double? longitude,
    String? telefone,
    String? email,
    String? responsavel,
    String? observacoes,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isSynced,
    String? serverId,
  }) {
    return Establishment(
      id: id ?? this.id,
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
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isSynced: isSynced ?? this.isSynced,
      serverId: serverId ?? this.serverId,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'nome': nome,
    'descricao': descricao,
    'tipo': tipo.name,
    'endereco': endereco,
    'latitude': latitude,
    'longitude': longitude,
    'telefone': telefone,
    'email': email,
    'responsavel': responsavel,
    'observacoes': observacoes,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'isSynced': isSynced,
    'serverId': serverId,
  };

  factory Establishment.fromJson(Map<String, dynamic> json) => Establishment(
    id: json['id'],
    nome: json['nome'],
    descricao: json['descricao'],
    tipo: EstablishmentType.values.byName(json['tipo']),
    endereco: json['endereco'],
    latitude: json['latitude'].toDouble(),
    longitude: json['longitude'].toDouble(),
    telefone: json['telefone'],
    email: json['email'],
    responsavel: json['responsavel'],
    observacoes: json['observacoes'],
    createdAt: DateTime.parse(json['createdAt']),
    updatedAt: DateTime.parse(json['updatedAt']),
    isSynced: json['isSynced'] ?? false,
    serverId: json['serverId'],
  );

  String get tipoText {
    switch (tipo) {
      case EstablishmentType.instituicao:
        return 'Instituição';
      case EstablishmentType.estabelecimento:
        return 'Estabelecimento';
      case EstablishmentType.veiculo:
        return 'Veículo';
      case EstablishmentType.entidadeSaude:
        return 'Entidade de Saúde';
      case EstablishmentType.equipamento:
        return 'Equipamento';
      case EstablishmentType.predio:
        return 'Prédio';
      case EstablishmentType.area:
        return 'Área';
      case EstablishmentType.outros:
        return 'Outros';
    }
  }

  String get tipoIcon {
    switch (tipo) {
      case EstablishmentType.instituicao:
        return '🏛️';
      case EstablishmentType.estabelecimento:
        return '🏢';
      case EstablishmentType.veiculo:
        return '🚗';
      case EstablishmentType.entidadeSaude:
        return '🏥';
      case EstablishmentType.equipamento:
        return '⚙️';
      case EstablishmentType.predio:
        return '🏗️';
      case EstablishmentType.area:
        return '📍';
      case EstablishmentType.outros:
        return '📋';
    }
  }

  String get enderecoCompleto {
    return '$endereco\nLat: ${latitude.toStringAsFixed(6)}, Lng: ${longitude.toStringAsFixed(6)}';
  }
}
