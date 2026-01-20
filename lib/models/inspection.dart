import 'package:inspecao/models/inspection_item.dart';
import 'package:inspecao/models/inspector.dart';

enum InspectionStatus {
  rascunho,           // RASCUNHO
  emAndamento,        // EM_ANDAMENTO
  concluida,          // CONCLUIDA
  sincronizada,       // SINCRONIZADA
  porVerificar,       // POR_VERIFICAR
  verificada,         // VERIFICADA
  invalida,           // INVALIDA
  relatorioGerado,    // RELATORIO_GERADO
  parecerDdrsDdrf,    // PARECER_DDRS_DDRF
  assinaturaCa,       // ASSINATURA_CA
  finalizada,         // FINALIZADA
  disponibilizada,    // DISPONIBILIZADA
}

enum InspectionType {
  estrutural,
  eletrica,
  hidraulica,
  seguranca,
  ambiental,
}

class Inspection {
  final String id;
  final String titulo;
  final String descricao;
  final InspectionType tipo;
  final InspectionStatus status;
  final DateTime dataAgendada;
  final String endereco;
  final double latitude;
  final double longitude;
  final List<Inspector> equipe;
  final List<InspectionItem> itens;
  final DateTime? dataInicio;
  final DateTime? dataConclusao;
  final String? observacoes;
  final List<String> fotos;
  final String? establishmentId; // Nova referência ao estabelecimento
  final String? inspectorId; // ID do inspetor responsável
  final bool isTemplate; // Se é um template de auditoria
  
  // Campos de controle para sincronização
  final bool isSynced;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? serverId;

  Inspection({
    required this.id,
    required this.titulo,
    required this.descricao,
    required this.tipo,
    required this.status,
    required this.dataAgendada,
    required this.endereco,
    required this.latitude,
    required this.longitude,
    required this.equipe,
    required this.itens,
    this.dataInicio,
    this.dataConclusao,
    this.observacoes,
    this.fotos = const [],
    this.establishmentId,
    this.inspectorId,
    this.isTemplate = false,
    this.isSynced = false,
    required this.createdAt,
    required this.updatedAt,
    this.serverId,
  });

  Inspection copyWith({
    String? id,
    String? titulo,
    String? descricao,
    InspectionType? tipo,
    InspectionStatus? status,
    DateTime? dataAgendada,
    String? endereco,
    double? latitude,
    double? longitude,
    List<Inspector>? equipe,
    List<InspectionItem>? itens,
    DateTime? dataInicio,
    DateTime? dataConclusao,
    String? observacoes,
    List<String>? fotos,
    String? establishmentId,
    String? inspectorId,
    bool? isTemplate,
    bool? isSynced,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? serverId,
  }) {
    return Inspection(
      id: id ?? this.id,
      titulo: titulo ?? this.titulo,
      descricao: descricao ?? this.descricao,
      tipo: tipo ?? this.tipo,
      status: status ?? this.status,
      dataAgendada: dataAgendada ?? this.dataAgendada,
      endereco: endereco ?? this.endereco,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      equipe: equipe ?? this.equipe,
      itens: itens ?? this.itens,
      dataInicio: dataInicio ?? this.dataInicio,
      dataConclusao: dataConclusao ?? this.dataConclusao,
      observacoes: observacoes ?? this.observacoes,
      fotos: fotos ?? this.fotos,
      establishmentId: establishmentId ?? this.establishmentId,
      inspectorId: inspectorId ?? this.inspectorId,
      isTemplate: isTemplate ?? this.isTemplate,
      isSynced: isSynced ?? this.isSynced,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      serverId: serverId ?? this.serverId,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'titulo': titulo,
    'descricao': descricao,
    'tipo': tipo.name,
    'status': Inspection.toBackendStatus(status),
    'dataAgendada': dataAgendada.toIso8601String(),
    'endereco': endereco,
    'latitude': latitude,
    'longitude': longitude,
    'equipe': equipe.map((e) => e.toJson()).toList(),
    'itens': itens.map((e) => e.toJson()).toList(),
    'dataInicio': dataInicio?.toIso8601String(),
    'dataConclusao': dataConclusao?.toIso8601String(),
    'observacoes': observacoes,
    'fotos': fotos,
    'establishmentId': establishmentId,
    'inspectorId': inspectorId,
    'isTemplate': isTemplate,
    'isSynced': isSynced,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'serverId': serverId,
  };

  factory Inspection.fromJson(Map<String, dynamic> json) => Inspection(
    id: json['id'],
    titulo: json['titulo'],
    descricao: json['descricao'],
    tipo: InspectionType.values.byName(json['tipo']),
    status: json['status'] is String 
        ? Inspection.fromBackendStatus(json['status'])
        : InspectionStatus.values.byName(json['status']),
    dataAgendada: DateTime.parse(json['dataAgendada']),
    endereco: json['endereco'],
    latitude: json['latitude'],
    longitude: json['longitude'],
    equipe: (json['equipe'] as List).map((e) => Inspector.fromJson(e)).toList(),
    itens: (json['itens'] as List).map((e) => InspectionItem.fromJson(e)).toList(),
    dataInicio: json['dataInicio'] != null ? DateTime.parse(json['dataInicio']) : null,
    dataConclusao: json['dataConclusao'] != null ? DateTime.parse(json['dataConclusao']) : null,
      observacoes: json['observacoes'],
      fotos: List<String>.from(json['fotos'] ?? []),
      establishmentId: json['establishmentId'],
      inspectorId: json['inspectorId'],
      isTemplate: json['isTemplate'] ?? false,
      isSynced: json['isSynced'] ?? false,
    createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
    updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : DateTime.now(),
    serverId: json['serverId'],
  );

  String get statusText {
    switch (status) {
      case InspectionStatus.rascunho:
        return 'Rascunho';
      case InspectionStatus.emAndamento:
        return 'Em Andamento';
      case InspectionStatus.concluida:
        return 'Concluída';
      case InspectionStatus.sincronizada:
        return 'Sincronizada';
      case InspectionStatus.porVerificar:
        return 'Por Verificar';
      case InspectionStatus.verificada:
        return 'Verificada';
      case InspectionStatus.invalida:
        return 'Inválida';
      case InspectionStatus.relatorioGerado:
        return 'Relatório Gerado';
      case InspectionStatus.parecerDdrsDdrf:
        return 'Parecer DDRS/DDRF';
      case InspectionStatus.assinaturaCa:
        return 'Assinatura CA';
      case InspectionStatus.finalizada:
        return 'Finalizada';
      case InspectionStatus.disponibilizada:
        return 'Disponibilizada';
    }
  }
  
  /// Mapeia status do backend (UPPERCASE) para enum local
  static InspectionStatus fromBackendStatus(String backendStatus) {
    switch (backendStatus.toUpperCase()) {
      case 'RASCUNHO':
        return InspectionStatus.rascunho;
      case 'EM_ANDAMENTO':
        return InspectionStatus.emAndamento;
      case 'CONCLUIDA':
        return InspectionStatus.concluida;
      case 'SINCRONIZADA':
        return InspectionStatus.sincronizada;
      case 'POR_VERIFICAR':
        return InspectionStatus.porVerificar;
      case 'VERIFICADA':
        return InspectionStatus.verificada;
      case 'INVALIDA':
        return InspectionStatus.invalida;
      case 'RELATORIO_GERADO':
        return InspectionStatus.relatorioGerado;
      case 'PARECER_DDRS_DDRF':
        return InspectionStatus.parecerDdrsDdrf;
      case 'ASSINATURA_CA':
        return InspectionStatus.assinaturaCa;
      case 'FINALIZADA':
        return InspectionStatus.finalizada;
      case 'DISPONIBILIZADA':
        return InspectionStatus.disponibilizada;
      default:
        return InspectionStatus.rascunho; // Default
    }
  }
  
  /// Converte enum local para status do backend (UPPERCASE)
  static String toBackendStatus(InspectionStatus status) {
    switch (status) {
      case InspectionStatus.rascunho:
        return 'RASCUNHO';
      case InspectionStatus.emAndamento:
        return 'EM_ANDAMENTO';
      case InspectionStatus.concluida:
        return 'CONCLUIDA';
      case InspectionStatus.sincronizada:
        return 'SINCRONIZADA';
      case InspectionStatus.porVerificar:
        return 'POR_VERIFICAR';
      case InspectionStatus.verificada:
        return 'VERIFICADA';
      case InspectionStatus.invalida:
        return 'INVALIDA';
      case InspectionStatus.relatorioGerado:
        return 'RELATORIO_GERADO';
      case InspectionStatus.parecerDdrsDdrf:
        return 'PARECER_DDRS_DDRF';
      case InspectionStatus.assinaturaCa:
        return 'ASSINATURA_CA';
      case InspectionStatus.finalizada:
        return 'FINALIZADA';
      case InspectionStatus.disponibilizada:
        return 'DISPONIBILIZADA';
    }
  }

  String get tipoText {
    switch (tipo) {
      case InspectionType.estrutural:
        return 'Estrutural';
      case InspectionType.eletrica:
        return 'Elétrica';
      case InspectionType.hidraulica:
        return 'Hidráulica';
      case InspectionType.seguranca:
        return 'Segurança';
      case InspectionType.ambiental:
        return 'Ambiental';
    }
  }
}
