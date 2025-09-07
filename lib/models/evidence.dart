import 'package:inspecao/models/user.dart';

enum EvidenceType {
  photo,
  document,
  video,
}

class Evidence {
  final String id;
  final String inspectionId;
  final String title;
  final String description;
  final EvidenceType type;
  final String filePath;
  final String? thumbnailPath;
  final User uploadedBy;
  final DateTime uploadedAt;
  final int fileSize;
  final String? mimeType;
  
  // Campos de controle para sincronização
  final bool isSynced;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? serverId;

  Evidence({
    required this.id,
    required this.inspectionId,
    required this.title,
    required this.description,
    required this.type,
    required this.filePath,
    this.thumbnailPath,
    required this.uploadedBy,
    required this.uploadedAt,
    required this.fileSize,
    this.mimeType,
    this.isSynced = false,
    required this.createdAt,
    required this.updatedAt,
    this.serverId,
  });

  Evidence copyWith({
    String? id,
    String? inspectionId,
    String? title,
    String? description,
    EvidenceType? type,
    String? filePath,
    String? thumbnailPath,
    User? uploadedBy,
    DateTime? uploadedAt,
    int? fileSize,
    String? mimeType,
    bool? isSynced,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? serverId,
  }) {
    return Evidence(
      id: id ?? this.id,
      inspectionId: inspectionId ?? this.inspectionId,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      filePath: filePath ?? this.filePath,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      uploadedBy: uploadedBy ?? this.uploadedBy,
      uploadedAt: uploadedAt ?? this.uploadedAt,
      fileSize: fileSize ?? this.fileSize,
      mimeType: mimeType ?? this.mimeType,
      isSynced: isSynced ?? this.isSynced,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      serverId: serverId ?? this.serverId,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'inspectionId': inspectionId,
    'title': title,
    'description': description,
    'type': type.name,
    'filePath': filePath,
    'thumbnailPath': thumbnailPath,
    'uploadedBy': uploadedBy.toJson(),
    'uploadedAt': uploadedAt.toIso8601String(),
    'fileSize': fileSize,
    'mimeType': mimeType,
    'isSynced': isSynced,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'serverId': serverId,
  };

  factory Evidence.fromJson(Map<String, dynamic> json) => Evidence(
    id: json['id'],
    inspectionId: json['inspectionId'],
    title: json['title'],
    description: json['description'],
    type: EvidenceType.values.byName(json['type']),
    filePath: json['filePath'],
    thumbnailPath: json['thumbnailPath'],
    uploadedBy: User.fromJson(json['uploadedBy']),
    uploadedAt: DateTime.parse(json['uploadedAt']),
    fileSize: json['fileSize'],
    mimeType: json['mimeType'],
    isSynced: json['isSynced'] ?? false,
    createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
    updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : DateTime.now(),
    serverId: json['serverId'],
  );

  String get fileSizeText {
    if (fileSize < 1024) {
      return '${fileSize}B';
    } else if (fileSize < 1024 * 1024) {
      return '${(fileSize / 1024).toStringAsFixed(1)}KB';
    } else {
      return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)}MB';
    }
  }

  String get typeText {
    switch (type) {
      case EvidenceType.photo:
        return 'Foto';
      case EvidenceType.document:
        return 'Documento';
      case EvidenceType.video:
        return 'Vídeo';
    }
  }
}
