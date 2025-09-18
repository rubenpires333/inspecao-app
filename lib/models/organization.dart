// Modelo para organizações/empresas
class Organization {
  final String id;
  final String name;
  final String description;
  final bool isActive;

  Organization({
    required this.id,
    required this.name,
    required this.description,
    required this.isActive,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'isActive': isActive,
    };
  }

  factory Organization.fromJson(Map<String, dynamic> json) {
    return Organization(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      isActive: json['isActive'],
    );
  }
}
