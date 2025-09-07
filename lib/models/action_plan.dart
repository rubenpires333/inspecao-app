import 'package:inspecao/models/user.dart';

enum ActionStatus {
  pendente,
  emAndamento,
  concluida,
  cancelada,
}

class ActionPlan {
  final String id;
  final String inspectionId;
  final String inspectionItemId;
  final String description;
  final ActionStatus status;
  final List<String> responsibles; // Mudança: Lista de responsáveis
  final DateTime dueDate;
  final String? comments;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isSynced;
  final String? serverId;

  ActionPlan({
    required this.id,
    required this.inspectionId,
    required this.inspectionItemId,
    required this.description,
    required this.status,
    required this.responsibles, // Mudança: Lista de responsáveis
    required this.dueDate,
    this.comments,
    required this.createdAt,
    required this.updatedAt,
    this.isSynced = false,
    this.serverId,
  });

  ActionPlan copyWith({
    String? id,
    String? inspectionId,
    String? inspectionItemId,
    String? description,
    ActionStatus? status,
    List<String>? responsibles, // Mudança: Lista de responsáveis
    DateTime? dueDate,
    String? comments,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isSynced,
    String? serverId,
  }) {
    return ActionPlan(
      id: id ?? this.id,
      inspectionId: inspectionId ?? this.inspectionId,
      inspectionItemId: inspectionItemId ?? this.inspectionItemId,
      description: description ?? this.description,
      status: status ?? this.status,
      responsibles: responsibles ?? this.responsibles, // Mudança: Lista de responsáveis
      dueDate: dueDate ?? this.dueDate,
      comments: comments ?? this.comments,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isSynced: isSynced ?? this.isSynced,
      serverId: serverId ?? this.serverId,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'inspectionId': inspectionId,
    'inspectionItemId': inspectionItemId,
    'description': description,
    'status': status.name,
    'responsibles': responsibles, // Mudança: Lista de responsáveis
    'dueDate': dueDate.toIso8601String(),
    'comments': comments,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'isSynced': isSynced,
    'serverId': serverId,
  };

  factory ActionPlan.fromJson(Map<String, dynamic> json) => ActionPlan(
    id: json['id'],
    inspectionId: json['inspectionId'],
    inspectionItemId: json['inspectionItemId'],
    description: json['description'],
    status: ActionStatus.values.byName(json['status']),
    responsibles: List<String>.from(json['responsibles'] ?? []), // Mudança: Lista de responsáveis
    dueDate: DateTime.parse(json['dueDate']),
    comments: json['comments'],
    createdAt: DateTime.parse(json['createdAt']),
    updatedAt: DateTime.parse(json['updatedAt']),
    isSynced: json['isSynced'] ?? false,
    serverId: json['serverId'],
  );

  String get statusText {
    switch (status) {
      case ActionStatus.pendente:
        return 'Pendente';
      case ActionStatus.emAndamento:
        return 'Em Andamento';
      case ActionStatus.concluida:
        return 'Concluída';
      case ActionStatus.cancelada:
        return 'Cancelada';
    }
  }

  String get statusColor {
    switch (status) {
      case ActionStatus.pendente:
        return '#FF9800'; // Orange
      case ActionStatus.emAndamento:
        return '#2196F3'; // Blue
      case ActionStatus.concluida:
        return '#4CAF50'; // Green
      case ActionStatus.cancelada:
        return '#F44336'; // Red
    }
  }

  bool get isOverdue {
    return status != ActionStatus.concluida && 
           status != ActionStatus.cancelada && 
           DateTime.now().isAfter(dueDate);
  }

  String get responsiblesText {
    if (responsibles.isEmpty) return 'Responsável não definido';
    if (responsibles.length == 1) return responsibles.first;
    return '${responsibles.length} responsáveis';
  }

  String get responsiblesList {
    return responsibles.join(', ');
  }
}
