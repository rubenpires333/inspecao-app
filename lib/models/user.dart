enum UserRole {
  admin,
  supervisor,
  inspetor,
}

class User {
  final String id;
  final String nome;
  final String email;
  final UserRole role;
  final String? avatar;
  final DateTime? dataCriacao;
  final DateTime? ultimoAcesso;

  User({
    required this.id,
    required this.nome,
    required this.email,
    required this.role,
    this.avatar,
    this.dataCriacao,
    this.ultimoAcesso,
  });

  User copyWith({
    String? id,
    String? nome,
    String? email,
    UserRole? role,
    String? avatar,
    DateTime? dataCriacao,
    DateTime? ultimoAcesso,
  }) {
    return User(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      email: email ?? this.email,
      role: role ?? this.role,
      avatar: avatar ?? this.avatar,
      dataCriacao: dataCriacao ?? this.dataCriacao,
      ultimoAcesso: ultimoAcesso ?? this.ultimoAcesso,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'nome': nome,
    'email': email,
    'role': role.name,
    'avatar': avatar,
    'dataCriacao': dataCriacao?.toIso8601String(),
    'ultimoAcesso': ultimoAcesso?.toIso8601String(),
  };

  factory User.fromJson(Map<String, dynamic> json) => User(
    id: json['id'],
    nome: json['nome'],
    email: json['email'],
    role: UserRole.values.byName(json['role']),
    avatar: json['avatar'],
    dataCriacao: json['dataCriacao'] != null ? DateTime.parse(json['dataCriacao']) : null,
    ultimoAcesso: json['ultimoAcesso'] != null ? DateTime.parse(json['ultimoAcesso']) : null,
  );

  String get roleText {
    switch (role) {
      case UserRole.admin:
        return 'Administrador';
      case UserRole.supervisor:
        return 'Supervisor';
      case UserRole.inspetor:
        return 'Inspetor';
    }
  }
}
