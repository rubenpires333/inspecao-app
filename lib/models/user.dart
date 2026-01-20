enum UserRole {
  diretor,      // ROLE_DIRETOR
  gestor,       // ROLE_GESTOR
  inspetor,     // ROLE_INSPETOR
  supervisor,   // ROLE_SUPERVISOR
}

class User {
  final String id;
  final String nome;
  final String email;
  final UserRole role;
  final String? avatar;
  final DateTime? dataCriacao;
  final DateTime? ultimoAcesso;
  final Set<String> permissions; // Permissões retornadas da API

  User({
    required this.id,
    required this.nome,
    required this.email,
    required this.role,
    this.avatar,
    this.dataCriacao,
    this.ultimoAcesso,
    Set<String>? permissions,
  }) : permissions = permissions ?? {};

  User copyWith({
    String? id,
    String? nome,
    String? email,
    UserRole? role,
    String? avatar,
    DateTime? dataCriacao,
    DateTime? ultimoAcesso,
    Set<String>? permissions,
  }) {
    return User(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      email: email ?? this.email,
      role: role ?? this.role,
      avatar: avatar ?? this.avatar,
      dataCriacao: dataCriacao ?? this.dataCriacao,
      ultimoAcesso: ultimoAcesso ?? this.ultimoAcesso,
      permissions: permissions ?? this.permissions,
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
    'permissions': permissions.toList(),
  };

  factory User.fromJson(Map<String, dynamic> json) => User(
    id: json['id'],
    nome: json['nome'],
    email: json['email'],
    role: UserRole.values.byName(json['role']),
    avatar: json['avatar'],
    dataCriacao: json['dataCriacao'] != null ? DateTime.parse(json['dataCriacao']) : null,
    ultimoAcesso: json['ultimoAcesso'] != null ? DateTime.parse(json['ultimoAcesso']) : null,
    permissions: json['permissions'] != null 
        ? Set<String>.from(json['permissions'] as List)
        : null,
  );

  String get roleText {
    switch (role) {
      case UserRole.diretor:
        return 'Diretor';
      case UserRole.gestor:
        return 'Gestor';
      case UserRole.inspetor:
        return 'Inspetor';
      case UserRole.supervisor:
        return 'Supervisor';
    }
  }
  
  /// Verifica se o usuário tem uma permissão específica
  bool hasPermission(String permission) {
    return permissions.contains(permission);
  }
  
  /// Verifica se o usuário tem alguma das permissões fornecidas
  bool hasAnyPermission(List<String> permissionList) {
    return permissionList.any((perm) => permissions.contains(perm));
  }
}
