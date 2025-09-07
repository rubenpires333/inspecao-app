enum InspectorRole {
  lider,
  tecnico,
  assistente,
}

class Inspector {
  final String id;
  final String nome;
  final String email;
  final String telefone;
  final InspectorRole cargo;
  final List<String> especialidades;
  final bool ativo;

  Inspector({
    required this.id,
    required this.nome,
    required this.email,
    required this.telefone,
    required this.cargo,
    required this.especialidades,
    this.ativo = true,
  });

  Inspector copyWith({
    String? id,
    String? nome,
    String? email,
    String? telefone,
    InspectorRole? cargo,
    List<String>? especialidades,
    bool? ativo,
  }) {
    return Inspector(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      email: email ?? this.email,
      telefone: telefone ?? this.telefone,
      cargo: cargo ?? this.cargo,
      especialidades: especialidades ?? this.especialidades,
      ativo: ativo ?? this.ativo,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'nome': nome,
    'email': email,
    'telefone': telefone,
    'cargo': cargo.name,
    'especialidades': especialidades,
    'ativo': ativo,
  };

  factory Inspector.fromJson(Map<String, dynamic> json) => Inspector(
    id: json['id'],
    nome: json['nome'],
    email: json['email'],
    telefone: json['telefone'],
    cargo: InspectorRole.values.byName(json['cargo']),
    especialidades: List<String>.from(json['especialidades']),
    ativo: json['ativo'] ?? true,
  );

  String get cargoText {
    switch (cargo) {
      case InspectorRole.lider:
        return 'Líder';
      case InspectorRole.tecnico:
        return 'Técnico';
      case InspectorRole.assistente:
        return 'Assistente';
    }
  }
}
