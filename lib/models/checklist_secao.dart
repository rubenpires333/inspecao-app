import 'package:inspecao/utils/app_logger.dart';

// ─── Enum de tipos de item ────────────────────────────────────────────────────

enum TipoItemChecklist {
  TEXTO,
  TEXTAREA,
  NUMERO,
  DATA,
  DATA_HORA,
  SIM_NAO,
  MULTIPLA_ESCOLHA,
  MULTIPLA_SELECAO,
  FOTO,
  ARQUIVO,
  CONFORME_NAO_CONFORME,
  CONFORMIDADE_COMPLETA,
  RATING_ESTRELAS,
  ANEXO_IMAGEM_OBRIGATORIO,
  GEORREFERENCIACAO,
}

TipoItemChecklist tipoFromString(String? s) {
  switch (s) {
    case 'TEXTO':                    return TipoItemChecklist.TEXTO;
    case 'TEXTAREA':                 return TipoItemChecklist.TEXTAREA;
    case 'NUMERO':                   return TipoItemChecklist.NUMERO;
    case 'DATA':                     return TipoItemChecklist.DATA;
    case 'DATA_HORA':                return TipoItemChecklist.DATA_HORA;
    case 'SIM_NAO':                  return TipoItemChecklist.SIM_NAO;
    case 'MULTIPLA_ESCOLHA':         return TipoItemChecklist.MULTIPLA_ESCOLHA;
    case 'MULTIPLA_SELECAO':         return TipoItemChecklist.MULTIPLA_SELECAO;
    case 'FOTO':                     return TipoItemChecklist.FOTO;
    case 'ARQUIVO':                  return TipoItemChecklist.ARQUIVO;
    case 'CONFORME_NAO_CONFORME':    return TipoItemChecklist.CONFORME_NAO_CONFORME;
    case 'CONFORMIDADE_COMPLETA':    return TipoItemChecklist.CONFORMIDADE_COMPLETA;
    case 'RATING_ESTRELAS':          return TipoItemChecklist.RATING_ESTRELAS;
    case 'ANEXO_IMAGEM_OBRIGATORIO': return TipoItemChecklist.ANEXO_IMAGEM_OBRIGATORIO;
    case 'GEORREFERENCIACAO':        return TipoItemChecklist.GEORREFERENCIACAO;
    default:
      AppLogger.log('⚠️ [tipoFromString] tipo desconhecido: "$s" → fallback TEXTO');
      return TipoItemChecklist.TEXTO;
  }
}

// ─── Opção de item ────────────────────────────────────────────────────────────

class OpcaoItemChecklist {
  final String id;
  final String itemId;
  final String texto;
  final String? valor;
  final int ordem;
  final String? cor;
  final double? pontuacao;

  const OpcaoItemChecklist({
    required this.id,
    required this.itemId,
    required this.texto,
    this.valor,
    required this.ordem,
    this.cor,
    this.pontuacao,
  });

  factory OpcaoItemChecklist.fromJson(Map<String, dynamic> json) {
    return OpcaoItemChecklist(
      id:        json['id']?.toString()    ?? '',
      itemId:    json['itemId']?.toString() ?? '',
      texto:     json['texto']?.toString()  ?? '',
      valor:     json['valor']?.toString(),
      ordem:     (json['ordem'] as num?)?.toInt() ?? 0,
      cor:       json['cor']?.toString(),
      pontuacao: (json['pontuacao'] as num?)?.toDouble(),
    );
  }
}

// ─── Item do checklist ────────────────────────────────────────────────────────

class ItemChecklistCompleto {
  final String id;
  final String secaoId;
  final String rotulo;
  final String? descricao;
  final String? ajuda;
  final TipoItemChecklist tipo;
  final int ordem;
  final bool obrigatorio;
  final bool ativo;
  final List<OpcaoItemChecklist> opcoes;

  const ItemChecklistCompleto({
    required this.id,
    required this.secaoId,
    required this.rotulo,
    this.descricao,
    this.ajuda,
    required this.tipo,
    required this.ordem,
    required this.obrigatorio,
    required this.ativo,
    required this.opcoes,
  });

  factory ItemChecklistCompleto.fromJson(Map<String, dynamic> json) {
    final id       = json['id']?.toString()      ?? '';
    final secaoId  = json['secaoId']?.toString() ?? '';
    final rotulo   = json['rotulo']?.toString()  ?? '';
    final tipoStr  = json['tipo']?.toString();
    final tipo     = tipoFromString(tipoStr);
    final ativo    = json['ativo'] as bool? ?? true;
    final opcRaw   = json['opcoes'] as List<dynamic>? ?? [];

    AppLogger.log('   🔧 [ItemChecklistCompleto.fromJson] id=$id rotulo="$rotulo" '
        'tipo=$tipoStr→${tipo.name} ativo=$ativo opcoes=${opcRaw.length}');

    return ItemChecklistCompleto(
      id:         id,
      secaoId:    secaoId,
      rotulo:     rotulo,
      descricao:  json['descricao']?.toString(),
      ajuda:      json['ajuda']?.toString(),
      tipo:       tipo,
      ordem:      (json['ordem'] as num?)?.toInt() ?? 0,
      obrigatorio: json['obrigatorio'] as bool? ?? false,
      ativo:      ativo,
      opcoes:     opcRaw
          .map((o) => OpcaoItemChecklist.fromJson(o as Map<String, dynamic>))
          .toList(),
    );
  }
}

// ─── Seção do checklist ───────────────────────────────────────────────────────

class SecaoChecklistCompleta {
  final String id;
  final String checklistId;
  final String titulo;
  final String? descricao;
  final int ordem;
  final String? secaoPaiId;
  final bool ativo;
  List<ItemChecklistCompleto> itens;
  List<SecaoChecklistCompleta> subsecoes;

  SecaoChecklistCompleta({
    required this.id,
    required this.checklistId,
    required this.titulo,
    this.descricao,
    required this.ordem,
    this.secaoPaiId,
    required this.ativo,
    required this.itens,
    required this.subsecoes,
  });

  factory SecaoChecklistCompleta.fromJson(Map<String, dynamic> json) {
    final id          = json['id']?.toString()          ?? '';
    final checklistId = json['checklistId']?.toString() ?? '';
    final titulo      = json['titulo']?.toString()      ?? '';
    final ativo       = json['ativo'] as bool?          ?? true;
    final ordem       = (json['ordem'] as num?)?.toInt() ?? 0;

    AppLogger.log('   🗂️ [SecaoChecklistCompleta.fromJson] id=$id titulo="$titulo" '
        'ordem=$ordem ativo=$ativo checklistId=$checklistId');

    // Subseções embutidas (quando a API retorna nested)
    final subRaw = json['subsecoes'] as List<dynamic>? ?? [];
    final subsecoes = subRaw
        .map((s) => SecaoChecklistCompleta.fromJson(s as Map<String, dynamic>))
        .where((s) => s.ativo)
        .toList()
      ..sort((a, b) => a.ordem.compareTo(b.ordem));

    if (subRaw.isNotEmpty) {
      AppLogger.log('      subsecoes embutidas=${subsecoes.length}');
    }

    return SecaoChecklistCompleta(
      id:          id,
      checklistId: checklistId,
      titulo:      titulo,
      descricao:   json['descricao']?.toString(),
      ordem:       ordem,
      secaoPaiId:  json['secaoPaiId']?.toString(),
      ativo:       ativo,
      itens:       [],      // preenchido depois por getItensBySecao
      subsecoes:   subsecoes,
    );
  }
}

// ─── Resposta de inspeção ─────────────────────────────────────────────────────

class RespostaInspecaoCompleta {
  final String id;
  final String inspecaoId;
  final String itemChecklistId;
  final String? opcaoId;
  final String? valorTexto;
  final double? valorNumero;
  final String? valorData;
  final String? valorDataHora;
  final int? valorRating;
  final double? latitude;
  final double? longitude;
  final String? observacoes;

  const RespostaInspecaoCompleta({
    required this.id,
    required this.inspecaoId,
    required this.itemChecklistId,
    this.opcaoId,
    this.valorTexto,
    this.valorNumero,
    this.valorData,
    this.valorDataHora,
    this.valorRating,
    this.latitude,
    this.longitude,
    this.observacoes,
  });

  factory RespostaInspecaoCompleta.fromJson(Map<String, dynamic> json) {
    // O backend pode devolver opcaoId directamente ou dentro de opcaoSelecionada
    String? opcaoId = json['opcaoId']?.toString();
    if (opcaoId == null && json['opcaoSelecionada'] is Map) {
      opcaoId = (json['opcaoSelecionada'] as Map)['id']?.toString();
    }

    // itemChecklistId pode estar directo ou dentro de itemChecklist
    String itemChecklistId = json['itemChecklistId']?.toString() ?? '';
    if (itemChecklistId.isEmpty && json['itemChecklist'] is Map) {
      itemChecklistId = (json['itemChecklist'] as Map)['id']?.toString() ?? '';
    }

    AppLogger.log('   💬 [RespostaInspecaoCompleta.fromJson] '
        'itemChecklistId=$itemChecklistId opcaoId=$opcaoId '
        'valorTexto=${json['valorTexto']} valorNumero=${json['valorNumero']}');

    return RespostaInspecaoCompleta(
      id:               json['id']?.toString() ?? '',
      inspecaoId:       json['inspecaoId']?.toString() ?? '',
      itemChecklistId:  itemChecklistId,
      opcaoId:          opcaoId,
      valorTexto:       json['valorTexto']?.toString(),
      valorNumero:      (json['valorNumero'] as num?)?.toDouble(),
      valorData:        json['valorData']?.toString(),
      valorDataHora:    json['valorDataHora']?.toString(),
      valorRating:      (json['valorRating'] as num?)?.toInt(),
      latitude:         (json['latitude']  as num?)?.toDouble(),
      longitude:        (json['longitude'] as num?)?.toDouble(),
      observacoes:      json['observacoes']?.toString(),
    );
  }

  String get displayValue {
    if (opcaoId != null && opcaoId!.isNotEmpty) return '(opção seleccionada)';
    if (valorTexto  != null && valorTexto!.isNotEmpty) return valorTexto!;
    if (valorNumero != null) return valorNumero.toString();
    if (valorRating != null) return '$valorRating ⭐';
    if (valorData   != null) return valorData!;
    if (valorDataHora != null) return valorDataHora!;
    if (latitude != null && longitude != null) return '$latitude, $longitude';
    return '';
  }
}