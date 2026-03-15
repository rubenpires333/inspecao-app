// ─── Tipos de item — espelha o TipoItemChecklist do backend ──────────────────
enum TipoItemChecklist {
  texto,
  textarea,
  numero,
  data,
  dataHora,
  simNao,
  multiplaEscolha,
  multiplaSelecao,
  conformeNaoConforme,
  conformidadeCompleta,
  ratingEstrelas,
  foto,
  arquivo,
  georreferenciacao,
}

extension TipoItemChecklistX on TipoItemChecklist {
  /// Converte a string vinda do banco (ex: "SIM_NAO") para o enum
  static TipoItemChecklist fromString(String? raw) {
    switch ((raw ?? '').toUpperCase()) {
      case 'TEXTO':                  return TipoItemChecklist.texto;
      case 'TEXTAREA':               return TipoItemChecklist.textarea;
      case 'NUMERO':                 return TipoItemChecklist.numero;
      case 'DATA':                   return TipoItemChecklist.data;
      case 'DATA_HORA':              return TipoItemChecklist.dataHora;
      case 'SIM_NAO':                return TipoItemChecklist.simNao;
      case 'MULTIPLA_ESCOLHA':       return TipoItemChecklist.multiplaEscolha;
      case 'MULTIPLA_SELECAO':       return TipoItemChecklist.multiplaSelecao;
      case 'CONFORME_NAO_CONFORME':  return TipoItemChecklist.conformeNaoConforme;
      case 'CONFORMIDADE_COMPLETA':  return TipoItemChecklist.conformidadeCompleta;
      case 'RATING_ESTRELAS':        return TipoItemChecklist.ratingEstrelas;
      case 'FOTO':                   return TipoItemChecklist.foto;
      case 'ARQUIVO':                return TipoItemChecklist.arquivo;
      case 'GEORREFERENCIACAO':      return TipoItemChecklist.georreferenciacao;
      default:                       return TipoItemChecklist.texto;
    }
  }

  String toRawString() {
    switch (this) {
      case TipoItemChecklist.texto:                return 'TEXTO';
      case TipoItemChecklist.textarea:             return 'TEXTAREA';
      case TipoItemChecklist.numero:               return 'NUMERO';
      case TipoItemChecklist.data:                 return 'DATA';
      case TipoItemChecklist.dataHora:             return 'DATA_HORA';
      case TipoItemChecklist.simNao:               return 'SIM_NAO';
      case TipoItemChecklist.multiplaEscolha:      return 'MULTIPLA_ESCOLHA';
      case TipoItemChecklist.multiplaSelecao:      return 'MULTIPLA_SELECAO';
      case TipoItemChecklist.conformeNaoConforme:  return 'CONFORME_NAO_CONFORME';
      case TipoItemChecklist.conformidadeCompleta: return 'CONFORMIDADE_COMPLETA';
      case TipoItemChecklist.ratingEstrelas:       return 'RATING_ESTRELAS';
      case TipoItemChecklist.foto:                 return 'FOTO';
      case TipoItemChecklist.arquivo:              return 'ARQUIVO';
      case TipoItemChecklist.georreferenciacao:    return 'GEORREFERENCIACAO';
    }
  }

  bool get usaOpcoes => const {
    TipoItemChecklist.simNao,
    TipoItemChecklist.multiplaEscolha,
    TipoItemChecklist.multiplaSelecao,
    TipoItemChecklist.conformeNaoConforme,
    TipoItemChecklist.conformidadeCompleta,
    TipoItemChecklist.ratingEstrelas,
  }.contains(this);

  bool get isTexto  => this == TipoItemChecklist.texto || this == TipoItemChecklist.textarea;
  bool get isNumero => this == TipoItemChecklist.numero;
  bool get isData   => this == TipoItemChecklist.data || this == TipoItemChecklist.dataHora;
  bool get isMulti  => this == TipoItemChecklist.multiplaSelecao;
}

// ─── Opção de item ────────────────────────────────────────────────────────────

class OpcaoItem {
  final String id;
  final String texto;
  final String? valor;
  final String? cor;
  final int? pontuacao;
  final int ordem;

  const OpcaoItem({
    required this.id,
    required this.texto,
    this.valor,
    this.cor,
    this.pontuacao,
    required this.ordem,
  });

  factory OpcaoItem.fromJson(Map<String, dynamic> json) => OpcaoItem(
    id:        json['id']?.toString()    ?? '',
    texto:     json['texto']?.toString() ?? '',
    valor:     json['valor']?.toString(),
    cor:       json['cor']?.toString(),
    pontuacao: json['pontuacao'] as int?,
    ordem:     json['ordem'] as int?     ?? 0,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'texto': texto,
    'valor': valor,
    'cor': cor,
    'pontuacao': pontuacao,
    'ordem': ordem,
  };
}

// ─── Status legacy ────────────────────────────────────────────────────────────

enum ItemStatus {
  pendente,
  conforme,
  naoConforme,
  naoAplica,
}

// ─── InspectionItem ───────────────────────────────────────────────────────────

class InspectionItem {
  final String id;
  final String descricao;
  final String? ajuda;
  final String categoria;
  final TipoItemChecklist tipo;
  final List<OpcaoItem> opcoes;

  // Valores de resposta
  final String? opcaoSelecionadaId;
  final List<String> opcoesSelecionadasIds;
  final String? valorTexto;
  final double? valorNumero;
  final DateTime? valorData;

  // Campos legacy
  final ItemStatus status;
  final String? observacao;
  final List<String> fotos;
  final bool obrigatorio;
  final int ordem;

  const InspectionItem({
    required this.id,
    required this.descricao,
    this.ajuda,
    required this.categoria,
    this.tipo = TipoItemChecklist.texto,
    this.opcoes = const [],
    this.opcaoSelecionadaId,
    this.opcoesSelecionadasIds = const [],
    this.valorTexto,
    this.valorNumero,
    this.valorData,
    required this.status,
    this.observacao,
    this.fotos = const [],
    this.obrigatorio = false,
    required this.ordem,
  });

  bool get respondido {
    if (tipo.usaOpcoes) return opcaoSelecionadaId != null || opcoesSelecionadasIds.isNotEmpty;
    if (tipo.isTexto)   return valorTexto != null && valorTexto!.trim().isNotEmpty;
    if (tipo.isNumero)  return valorNumero != null;
    if (tipo.isData)    return valorData != null;
    return status != ItemStatus.pendente;
  }

  OpcaoItem? get opcaoSelecionada =>
      opcaoSelecionadaId == null
          ? null
          : opcoes.cast<OpcaoItem?>().firstWhere(
              (o) => o?.id == opcaoSelecionadaId,
              orElse: () => null,
            );

  InspectionItem copyWith({
    String? id,
    String? descricao,
    String? ajuda,
    String? categoria,
    TipoItemChecklist? tipo,
    List<OpcaoItem>? opcoes,
    String? opcaoSelecionadaId,
    List<String>? opcoesSelecionadasIds,
    String? valorTexto,
    double? valorNumero,
    DateTime? valorData,
    ItemStatus? status,
    String? observacao,
    List<String>? fotos,
    bool? obrigatorio,
    int? ordem,
    bool clearOpcaoSelecionada = false,
  }) {
    return InspectionItem(
      id:                    id                    ?? this.id,
      descricao:             descricao             ?? this.descricao,
      ajuda:                 ajuda                 ?? this.ajuda,
      categoria:             categoria             ?? this.categoria,
      tipo:                  tipo                  ?? this.tipo,
      opcoes:                opcoes                ?? this.opcoes,
      opcaoSelecionadaId:    clearOpcaoSelecionada ? null : (opcaoSelecionadaId ?? this.opcaoSelecionadaId),
      opcoesSelecionadasIds: opcoesSelecionadasIds ?? this.opcoesSelecionadasIds,
      valorTexto:            valorTexto            ?? this.valorTexto,
      valorNumero:           valorNumero           ?? this.valorNumero,
      valorData:             valorData             ?? this.valorData,
      status:                status                ?? this.status,
      observacao:            observacao            ?? this.observacao,
      fotos:                 fotos                 ?? this.fotos,
      obrigatorio:           obrigatorio           ?? this.obrigatorio,
      ordem:                 ordem                 ?? this.ordem,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'descricao': descricao,
    'ajuda': ajuda,
    'categoria': categoria,
    'tipo': tipo.toRawString(),
    'opcoes': opcoes.map((o) => o.toJson()).toList(),
    'opcaoSelecionadaId': opcaoSelecionadaId,
    'opcoesSelecionadasIds': opcoesSelecionadasIds,
    'valorTexto': valorTexto,
    'valorNumero': valorNumero,
    'valorData': valorData?.toIso8601String(),
    'status': status.name,
    'observacao': observacao,
    'fotos': fotos,
    'obrigatorio': obrigatorio,
    'ordem': ordem,
  };

  factory InspectionItem.fromJson(Map<String, dynamic> json) => InspectionItem(
    id:                    json['id']?.toString()        ?? '',
    descricao:             json['descricao']?.toString() ?? '',
    ajuda:                 json['ajuda']?.toString(),
    categoria:             json['categoria']?.toString() ?? '',
    tipo:                  TipoItemChecklistX.fromString(json['tipo']?.toString()),
    opcoes:               (json['opcoes'] as List<dynamic>? ?? [])
                              .map((e) => OpcaoItem.fromJson(e as Map<String, dynamic>))
                              .toList(),
    opcaoSelecionadaId:    json['opcaoSelecionadaId']?.toString(),
    opcoesSelecionadasIds: List<String>.from(json['opcoesSelecionadasIds'] ?? []),
    valorTexto:            json['valorTexto']?.toString(),
    valorNumero:           (json['valorNumero'] as num?)?.toDouble(),
    valorData:             json['valorData'] != null ? DateTime.tryParse(json['valorData']) : null,
    status:                ItemStatus.values.byName(json['status'] ?? 'pendente'),
    observacao:            json['observacao']?.toString(),
    fotos:                 List<String>.from(json['fotos'] ?? []),
    obrigatorio:           json['obrigatorio'] as bool? ?? false,
    ordem:                 json['ordem'] as int?        ?? 0,
  );

  String get statusText {
    switch (status) {
      case ItemStatus.pendente:    return 'Pendente';
      case ItemStatus.conforme:    return 'Conforme';
      case ItemStatus.naoConforme: return 'Não Conforme';
      case ItemStatus.naoAplica:   return 'N/A';
    }
  }
}