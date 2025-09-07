enum ItemStatus {
  pendente,
  conforme,
  naoConforme,
  naoAplica,
}

class InspectionItem {
  final String id;
  final String descricao;
  final String categoria;
  final ItemStatus status;
  final String? observacao;
  final List<String> fotos;
  final bool obrigatorio;
  final int ordem;

  InspectionItem({
    required this.id,
    required this.descricao,
    required this.categoria,
    required this.status,
    this.observacao,
    this.fotos = const [],
    this.obrigatorio = false,
    required this.ordem,
  });

  InspectionItem copyWith({
    String? id,
    String? descricao,
    String? categoria,
    ItemStatus? status,
    String? observacao,
    List<String>? fotos,
    bool? obrigatorio,
    int? ordem,
  }) {
    return InspectionItem(
      id: id ?? this.id,
      descricao: descricao ?? this.descricao,
      categoria: categoria ?? this.categoria,
      status: status ?? this.status,
      observacao: observacao ?? this.observacao,
      fotos: fotos ?? this.fotos,
      obrigatorio: obrigatorio ?? this.obrigatorio,
      ordem: ordem ?? this.ordem,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'descricao': descricao,
    'categoria': categoria,
    'status': status.name,
    'observacao': observacao,
    'fotos': fotos,
    'obrigatorio': obrigatorio,
    'ordem': ordem,
  };

  factory InspectionItem.fromJson(Map<String, dynamic> json) => InspectionItem(
    id: json['id'],
    descricao: json['descricao'],
    categoria: json['categoria'],
    status: ItemStatus.values.byName(json['status']),
    observacao: json['observacao'],
    fotos: List<String>.from(json['fotos'] ?? []),
    obrigatorio: json['obrigatorio'] ?? false,
    ordem: json['ordem'],
  );

  String get statusText {
    switch (status) {
      case ItemStatus.pendente:
        return 'Pendente';
      case ItemStatus.conforme:
        return 'Conforme';
      case ItemStatus.naoConforme:
        return 'Não Conforme';
      case ItemStatus.naoAplica:
        return 'N/A';
    }
  }
}
