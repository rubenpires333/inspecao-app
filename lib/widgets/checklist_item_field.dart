import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:inspecao/models/checklist_secao.dart';

// ─── Paleta ───────────────────────────────────────────────────────────────────
const _kPrimary        = Color(0xFF18778A);
const _kPrimaryLight   = Color(0xFFE8F4F7);
const _kBorder         = Color(0xFFE2ECF0);
const _kSurface        = Color(0xFFF7FAFB);
const _kTextPrimary    = Color(0xFF0F2A31);
const _kTextSecondary  = Color(0xFF5A7A83);
const _kSuccess        = Color(0xFF1DAF6E);
const _kSuccessLight   = Color(0xFFEAF8F2);
const _kError          = Color(0xFFEF4444);
const _kErrorLight     = Color(0xFFFEF2F2);
const _kNaoAplica      = Color(0xFF6B7FD7);
const _kNaoAplicaLight = Color(0xFFEEF0FB);
const _kWarning        = Color(0xFFF59E0B);
const _kNaoObservavel  = Color(0xFF9CA3AF);

/// Widget que renderiza um item do checklist conforme o seu tipo,
/// com o visual da app mobile (botões grandes, ícone de relógio, evidências).
class ChecklistItemField extends StatefulWidget {
  final ItemChecklistCompleto item;
  final RespostaInspecaoCompleta? resposta;
  final bool enabled;
  final void Function(Map<String, dynamic> payload)? onSave;

  const ChecklistItemField({
    super.key,
    required this.item,
    this.resposta,
    this.enabled = false,
    this.onSave,
  });

  @override
  State<ChecklistItemField> createState() => _ChecklistItemFieldState();
}

class _ChecklistItemFieldState extends State<ChecklistItemField> {
  late TextEditingController _textCtrl;
  late TextEditingController _numCtrl;
  String? _selectedOpcaoId;
  Set<String> _selectedMulti = {};
  int? _rating;
  bool? _simNao;

  /// Estado local para data/hora (mostra valor imediatamente após picker)
  String? _selectedData;
  String? _selectedDataHora;

  /// Controla se a secção "Evidências e observações" está expandida
  bool _evidenciasExpanded = false;

  /// Flag: já foi inicializado com resposta existente (evita reset em re-renders)
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _textCtrl = TextEditingController();
    _numCtrl  = TextEditingController();
    _syncFromResposta(widget.resposta);
    _initialized = true;
  }

  @override
  void didUpdateWidget(ChecklistItemField old) {
    super.didUpdateWidget(old);
    // Só sincroniza se chegou uma NOVA resposta do servidor (salvo com sucesso)
    // Nunca reverte o estado local se a resposta for null (erro no save)
    if (widget.resposta != null && old.resposta != widget.resposta) {
      _syncFromResposta(widget.resposta);
    }
  }

  void _syncFromResposta(RespostaInspecaoCompleta? r) {
    if (r == null) return;
    _textCtrl.text = r.valorTexto ?? '';
    _numCtrl.text  = r.valorNumero != null ? r.valorNumero.toString() : '';
    _selectedOpcaoId = r.opcaoId;
    _rating   = r.valorRating;
    _selectedData    = r.valorData;
    _selectedDataHora = r.valorDataHora;
    if (r.valorTexto == 'SIM') _simNao = true;
    if (r.valorTexto == 'NAO' || r.valorTexto == 'NÃO') _simNao = false;
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    _numCtrl.dispose();
    super.dispose();
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  Color _colorFromHex(String? hex, Color fallback) {
    if (hex == null || hex.isEmpty) return fallback;
    try {
      final c = hex.replaceAll('#', '');
      return Color(int.parse('FF$c', radix: 16));
    } catch (_) {
      return fallback;
    }
  }

  String _labelForOpcao(String? id) {
    if (id == null) return '';
    try {
      return widget.item.opcoes.firstWhere((o) => o.id == id).texto;
    } catch (_) {
      return '';
    }
  }

  bool get _respondido {
    if (_selectedOpcaoId != null && _selectedOpcaoId!.isNotEmpty) return true;
    if (_textCtrl.text.isNotEmpty) return true;
    if (_numCtrl.text.isNotEmpty) return true;
    if (_rating != null) return true;
    if (_simNao != null) return true;
    if (_selectedMulti.isNotEmpty) return true;
    return false;
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kBorder),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 4,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Cabeçalho: ícone + rótulo ──────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Ícone de relógio (pendente) ou check (respondido)
                Container(
                  width: 36,
                  height: 36,
                  margin: const EdgeInsets.only(right: 12, top: 1),
                  decoration: BoxDecoration(
                    color: _respondido ? _kPrimaryLight : _kSurface,
                    shape: BoxShape.circle,
                    border: Border.all(color: _kBorder),
                  ),
                  child: Icon(
                    _respondido
                        ? Icons.check_rounded
                        : Icons.access_time_rounded,
                    size: 18,
                    color: _respondido ? _kPrimary : _kTextSecondary,
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.item.rotulo,
                        style: const TextStyle(
                          color: _kTextPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          height: 1.35,
                        ),
                      ),
                      if (widget.item.ajuda != null &&
                          widget.item.ajuda!.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          widget.item.ajuda!,
                          style: const TextStyle(
                              fontSize: 11,
                              color: _kTextSecondary,
                              fontStyle: FontStyle.italic),
                        ),
                      ],
                      if (widget.item.obrigatorio) ...[
                        const SizedBox(height: 2),
                        const Text('* Obrigatório',
                            style: TextStyle(
                                fontSize: 10,
                                color: _kError,
                                fontWeight: FontWeight.w500)),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Campo de resposta ───────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 0),
            child: _buildField(),
          ),

          const SizedBox(height: 10),

          // ── Divisor + "Evidências e observações" (colapsável) ───────────
          const Divider(height: 1, color: _kBorder),
          _EvidenciasSection(
            resposta: widget.resposta,
            expanded: _evidenciasExpanded,
            onToggle: () =>
                setState(() => _evidenciasExpanded = !_evidenciasExpanded),
          ),
        ],
      ),
    );
  }

  // ─── Roteador de tipo ─────────────────────────────────────────────────────

  Widget _buildField() {
    switch (widget.item.tipo) {
      case TipoItemChecklist.TEXTO:
        return _buildTexto();
      case TipoItemChecklist.TEXTAREA:
        return _buildTextarea();
      case TipoItemChecklist.NUMERO:
        return _buildNumero();
      case TipoItemChecklist.DATA:
        return _buildData();
      case TipoItemChecklist.DATA_HORA:
        return _buildDataHora();
      case TipoItemChecklist.SIM_NAO:
        return _buildSimNao();
      case TipoItemChecklist.MULTIPLA_ESCOLHA:
        return _buildMultiplaEscolha();
      case TipoItemChecklist.MULTIPLA_SELECAO:
        return _buildMultiplaSelecao();
      case TipoItemChecklist.CONFORME_NAO_CONFORME:
        return _buildConformeNaoConforme();
      case TipoItemChecklist.CONFORMIDADE_COMPLETA:
        return _buildConformidadeCompleta();
      case TipoItemChecklist.RATING_ESTRELAS:
        return _buildRating();
      case TipoItemChecklist.FOTO:
      case TipoItemChecklist.ARQUIVO:
      case TipoItemChecklist.ANEXO_IMAGEM_OBRIGATORIO:
        return _buildAnexo();
      case TipoItemChecklist.GEORREFERENCIACAO:
        return _buildGeo();
    }
  }

  // ─── Tipos de campo ───────────────────────────────────────────────────────

  Widget _buildTexto() {
    return TextField(
      controller: _textCtrl,
      enabled: widget.enabled,
      // Expande automaticamente para mostrar todo o texto guardado
      minLines: 1,
      maxLines: null,
      keyboardType: TextInputType.multiline,
      style: const TextStyle(fontSize: 14, color: _kTextPrimary),
      decoration: _inputDeco('Digite aqui...'),
      onChanged: (_) => _emitPayload(),
    );
  }

  Widget _buildTextarea() {
    return TextField(
      controller: _textCtrl,
      enabled: widget.enabled,
      // Mínimo 3 linhas, expande para mostrar todo o conteúdo
      minLines: 3,
      maxLines: null,
      keyboardType: TextInputType.multiline,
      style: const TextStyle(fontSize: 14, color: _kTextPrimary),
      decoration: _inputDeco('Digite aqui...'),
      onChanged: (_) => _emitPayload(),
    );
  }

  Widget _buildNumero() {
    return TextField(
      controller: _numCtrl,
      enabled: widget.enabled,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
      style: const TextStyle(fontSize: 14, color: _kTextPrimary),
      decoration: _inputDeco('Valor numérico'),
      onChanged: (_) => _emitPayload(),
    );
  }

  Widget _buildData() {
    final display = _selectedData ?? widget.resposta?.valorData ?? '';
    return _DateTimeButton(
      icon: Icons.calendar_today_outlined,
      label: display.isNotEmpty ? display : 'Selecionar data',
      enabled: widget.enabled,
      onTap: () async {
        DateTime initial = DateTime.now();
        if (_selectedData != null) {
          try { initial = DateTime.parse(_selectedData!); } catch (_) {}
        }
        final picked = await showDatePicker(
          context: context,
          initialDate: initial,
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
          builder: (c, child) => Theme(
              data: Theme.of(c).copyWith(
                  colorScheme: const ColorScheme.light(primary: _kPrimary)),
              child: child!),
        );
        if (picked != null) {
          final str =
              '${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
          setState(() => _selectedData = str);
          _emitPayloadWith({'valorData': str});
        }
      },
    );
  }

  Widget _buildDataHora() {
    // Mostrar label formatado se já foi seleccionado
    String display = '';
    if (_selectedDataHora != null && _selectedDataHora!.isNotEmpty) {
      try {
        final dt = DateTime.parse(_selectedDataHora!).toLocal();
        display = '${dt.day.toString().padLeft(2,'0')}/${dt.month.toString().padLeft(2,'0')}/${dt.year} '
                  '${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}';
      } catch (_) {
        display = _selectedDataHora!;
      }
    } else if (widget.resposta?.valorDataHora != null) {
      try {
        final dt = DateTime.parse(widget.resposta!.valorDataHora!).toLocal();
        display = '${dt.day.toString().padLeft(2,'0')}/${dt.month.toString().padLeft(2,'0')}/${dt.year} '
                  '${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}';
      } catch (_) {
        display = widget.resposta!.valorDataHora!;
      }
    }

    return _DateTimeButton(
      icon: Icons.access_time_outlined,
      label: display.isNotEmpty ? display : 'Selecionar data e hora',
      enabled: widget.enabled,
      onTap: () async {
        DateTime initial = DateTime.now();
        if (_selectedDataHora != null) {
          try { initial = DateTime.parse(_selectedDataHora!).toLocal(); } catch (_) {}
        }
        final date = await showDatePicker(
          context: context,
          initialDate: initial,
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
          builder: (c, child) => Theme(
              data: Theme.of(c).copyWith(
                  colorScheme: const ColorScheme.light(primary: _kPrimary)),
              child: child!),
        );
        if (date == null || !mounted) return;
        final time = await showTimePicker(
          context: context,
          initialTime: TimeOfDay(hour: initial.hour, minute: initial.minute),
          builder: (c, child) => Theme(
              data: Theme.of(c).copyWith(
                  colorScheme: const ColorScheme.light(primary: _kPrimary)),
              child: child!),
        );
        if (time == null) return;
        final dt = DateTime(date.year, date.month, date.day, time.hour, time.minute);

        // Formatar como OffsetDateTime com timezone UTC (+00:00) — exigido pelo Spring
        final utc = dt.toUtc();
        final iso = '${utc.year.toString().padLeft(4,'0')}-'
                    '${utc.month.toString().padLeft(2,'0')}-'
                    '${utc.day.toString().padLeft(2,'0')}T'
                    '${utc.hour.toString().padLeft(2,'0')}:'
                    '${utc.minute.toString().padLeft(2,'0')}:00+00:00';

        setState(() => _selectedDataHora = dt.toIso8601String());
        _emitPayloadWith({'valorDataHora': iso});
      },
    );
  }

  Widget _buildSimNao() {
    final selectedId =
        _simNao == null ? null : (_simNao! ? 'SIM' : 'NAO');
    return _BigButtonRow(
      opcoes: [
        _BigBtn(
            id: 'SIM',
            label: 'Sim',
            icon: Icons.check_rounded,
            activeColor: _kSuccess,
            activeBg: _kSuccessLight),
        _BigBtn(
            id: 'NAO',
            label: 'Não',
            icon: Icons.close_rounded,
            activeColor: _kError,
            activeBg: _kErrorLight),
      ],
      selectedId: selectedId,
      enabled: widget.enabled,
      onSelect: (id) {
        setState(() => _simNao = id == 'SIM');
        _emitPayloadWith({'valorTexto': id});
      },
    );
  }

  Widget _buildConformeNaoConforme() {
    return _buildOpcoesBigButtons(fallback: [
      _BigBtn(
          id: '__CONFORME__',
          label: 'Conforme',
          icon: Icons.check_rounded,
          activeColor: _kSuccess,
          activeBg: _kSuccessLight),
      _BigBtn(
          id: '__NAO_CONFORME__',
          label: 'N. Conforme',
          icon: Icons.close_rounded,
          activeColor: _kError,
          activeBg: _kErrorLight),
    ]);
  }

  Widget _buildConformidadeCompleta() {
    return _buildOpcoesBigButtons(fallback: [
      _BigBtn(
          id: '__CONFORME__',
          label: 'Conforme',
          icon: Icons.check_rounded,
          activeColor: _kSuccess,
          activeBg: _kSuccessLight),
      _BigBtn(
          id: '__NAO_CONFORME__',
          label: 'N. Conforme',
          icon: Icons.close_rounded,
          activeColor: _kError,
          activeBg: _kErrorLight),
      _BigBtn(
          id: '__NAO_APLICA__',
          label: 'N/A',
          icon: Icons.remove_rounded,
          activeColor: _kNaoAplica,
          activeBg: _kNaoAplicaLight),
    ]);
  }

  Widget _buildOpcoesBigButtons({required List<_BigBtn> fallback}) {
    final List<_BigBtn> btns;
    if (widget.item.opcoes.isNotEmpty) {
      btns = widget.item.opcoes.map((o) {
        final cor = _colorFromHex(o.cor, _kPrimary);
        return _BigBtn(
          id: o.id,
          label: o.texto,
          icon: _iconForLabel(o.texto),
          activeColor: cor,
          activeBg: cor.withOpacity(0.12),
        );
      }).toList();
    } else {
      btns = fallback;
    }
    return _BigButtonRow(
      opcoes: btns,
      selectedId: _selectedOpcaoId,
      enabled: widget.enabled,
      onSelect: (id) {
        setState(() => _selectedOpcaoId = id);
        _emitPayloadWith({'opcaoId': id});
      },
    );
  }

  IconData _iconForLabel(String label) {
    final l = label.toLowerCase();
    if (l.contains('conf') && !l.contains('não') && !l.contains('nao')) {
      return Icons.check_rounded;
    }
    if (l.contains('n') && l.contains('conf')) return Icons.close_rounded;
    if (l == 'n/a' || l.contains('aplic')) return Icons.remove_rounded;
    if (l == 'sim') return Icons.check_rounded;
    if (l == 'não' || l == 'nao') return Icons.close_rounded;
    return Icons.circle_outlined;
  }

  Widget _buildMultiplaEscolha() {
    if (widget.item.opcoes.isEmpty) return _emptyOpcoes();
    return Column(
      children: widget.item.opcoes.map((opcao) {
        final isSelected = _selectedOpcaoId == opcao.id;
        final cor = _colorFromHex(opcao.cor, _kPrimary);
        return GestureDetector(
          onTap: widget.enabled
              ? () {
                  setState(() => _selectedOpcaoId = opcao.id);
                  _emitPayloadWith({'opcaoId': opcao.id});
                }
              : null,
          child: Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              color: isSelected ? cor.withOpacity(0.10) : _kSurface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: isSelected ? cor : _kBorder,
                  width: isSelected ? 1.5 : 1),
            ),
            child: Row(
              children: [
                Icon(
                  isSelected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off,
                  size: 18,
                  color: isSelected ? cor : _kTextSecondary,
                ),
                const SizedBox(width: 10),
                Expanded(
                    child: Text(opcao.texto,
                        style: TextStyle(
                            fontSize: 14,
                            color: isSelected ? cor : _kTextPrimary,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal))),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMultiplaSelecao() {
    if (widget.item.opcoes.isEmpty) return _emptyOpcoes();
    return Column(
      children: widget.item.opcoes.map((opcao) {
        final isSelected = _selectedMulti.contains(opcao.id);
        final cor = _colorFromHex(opcao.cor, _kPrimary);
        return GestureDetector(
          onTap: widget.enabled
              ? () {
                  setState(() {
                    if (isSelected) {
                      _selectedMulti.remove(opcao.id);
                    } else {
                      _selectedMulti.add(opcao.id);
                    }
                  });
                  _emitPayloadWith({'opcaoIds': _selectedMulti.toList()});
                }
              : null,
          child: Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              color: isSelected ? cor.withOpacity(0.10) : _kSurface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: isSelected ? cor : _kBorder,
                  width: isSelected ? 1.5 : 1),
            ),
            child: Row(
              children: [
                Icon(
                  isSelected
                      ? Icons.check_box_rounded
                      : Icons.check_box_outline_blank_rounded,
                  size: 18,
                  color: isSelected ? cor : _kTextSecondary,
                ),
                const SizedBox(width: 10),
                Expanded(
                    child: Text(opcao.texto,
                        style: TextStyle(
                            fontSize: 14,
                            color: isSelected ? cor : _kTextPrimary,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal))),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRating() {
    final current = _rating ?? 0;
    return Row(
      children: List.generate(5, (i) {
        final star = i + 1;
        return GestureDetector(
          onTap: widget.enabled
              ? () {
                  setState(() => _rating = star);
                  _emitPayloadWith({'valorRating': star});
                }
              : null,
          child: Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Icon(
              star <= current ? Icons.star_rounded : Icons.star_border_rounded,
              size: 34,
              color: star <= current ? _kWarning : _kBorder,
            ),
          ),
        );
      }),
    );
  }

  Widget _buildAnexo() {
    final has = widget.resposta != null;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: has ? _kPrimaryLight : _kSurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: has ? _kPrimary.withOpacity(0.3) : _kBorder),
      ),
      child: Row(
        children: [
          Icon(has ? Icons.check_circle_outline_rounded : Icons.attach_file_rounded,
              size: 20, color: has ? _kPrimary : _kTextSecondary),
          const SizedBox(width: 10),
          Expanded(
              child: Text(has ? 'Anexo(s) carregado(s)' : 'Sem anexo',
                  style: TextStyle(
                      fontSize: 13,
                      color: has ? _kPrimary : _kTextSecondary))),
          if (widget.enabled && !has)
            const Icon(Icons.upload_outlined, size: 18, color: _kPrimary),
        ],
      ),
    );
  }

  Widget _buildGeo() {
    final lat = widget.resposta?.latitude;
    final lng = widget.resposta?.longitude;
    final has = lat != null && lng != null;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: has ? _kPrimaryLight : _kSurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: has ? _kPrimary.withOpacity(0.3) : _kBorder),
      ),
      child: Row(
        children: [
          Icon(Icons.location_on_outlined,
              size: 20, color: has ? _kPrimary : _kTextSecondary),
          const SizedBox(width: 10),
          Expanded(
              child: Text(
                  has
                      ? '${lat.toStringAsFixed(6)}, ${lng.toStringAsFixed(6)}'
                      : 'Sem localização capturada',
                  style: TextStyle(
                      fontSize: 13,
                      color: has ? _kPrimary : _kTextSecondary))),
        ],
      ),
    );
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  Widget _emptyOpcoes() => Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
            color: _kSurface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _kBorder)),
        child: const Text('Sem opções configuradas',
            style: TextStyle(fontSize: 13, color: _kTextSecondary)),
      );

  InputDecoration _inputDeco(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: _kTextSecondary, fontSize: 13),
        filled: true,
        fillColor: _kSurface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: _kBorder)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: _kBorder)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: _kPrimary, width: 1.5)),
        disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: _kBorder)),
      );

  // ─── Emit ─────────────────────────────────────────────────────────────────

  void _emitPayload() {
    _emitPayloadWith({
      'valorTexto': _textCtrl.text.isNotEmpty ? _textCtrl.text : null,
      'valorNumero': _numCtrl.text.isNotEmpty
          ? double.tryParse(_numCtrl.text.replaceAll(',', '.'))
          : null,
    });
  }

  void _emitPayloadWith(Map<String, dynamic> extra) {
    widget.onSave?.call({'itemChecklistId': widget.item.id, ...extra});
  }
}

// ─── _BigButtonRow ────────────────────────────────────────────────────────────
/// Linha de botões grandes com ícone (Conforme / N. Conforme / N/A)
class _BigButtonRow extends StatelessWidget {
  final List<_BigBtn> opcoes;
  final String? selectedId;
  final bool enabled;
  final void Function(String id) onSelect;

  const _BigButtonRow({
    required this.opcoes,
    required this.selectedId,
    required this.enabled,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: opcoes.asMap().entries.map((e) {
        final btn = e.value;
        final isSelected = selectedId == btn.id;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              left: e.key == 0 ? 0 : 5,
              right: e.key == opcoes.length - 1 ? 0 : 5,
            ),
            child: GestureDetector(
              onTap: enabled ? () => onSelect(btn.id) : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: isSelected ? btn.activeBg : const Color(0xFFF7FAFB),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: isSelected ? btn.activeColor : const Color(0xFFE2ECF0),
                      width: isSelected ? 1.5 : 1),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      btn.icon,
                      size: 22,
                      color: isSelected ? btn.activeColor : const Color(0xFFAFB4BB),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      btn.label,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: isSelected
                              ? btn.activeColor
                              : const Color(0xFF5A7A83)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _BigBtn {
  final String id;
  final String label;
  final IconData icon;
  final Color activeColor;
  final Color activeBg;

  const _BigBtn({
    required this.id,
    required this.label,
    required this.icon,
    required this.activeColor,
    required this.activeBg,
  });
}

// ─── _DateTimeButton ─────────────────────────────────────────────────────────
/// Botão de acção para selecionar data/hora
class _DateTimeButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool enabled;
  final VoidCallback onTap;

  const _DateTimeButton({
    required this.icon,
    required this.label,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: const Color(0xFFF7FAFB),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE2ECF0)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: const Color(0xFF18778A)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                    fontSize: 13, color: Color(0xFF0F2A31)),
              ),
            ),
            if (enabled)
              const Icon(Icons.chevron_right_rounded,
                  size: 18, color: Color(0xFF5A7A83)),
          ],
        ),
      ),
    );
  }
}

// ─── _EvidenciasSection ───────────────────────────────────────────────────────
/// Rodapé colapsável "Evidências e observações"
class _EvidenciasSection extends StatelessWidget {
  final RespostaInspecaoCompleta? resposta;
  final bool expanded;
  final VoidCallback onToggle;

  const _EvidenciasSection({
    required this.resposta,
    required this.expanded,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Linha clicável
        GestureDetector(
          onTap: onToggle,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                const Icon(Icons.image_outlined, size: 15, color: Color(0xFF5A7A83)),
                const SizedBox(width: 6),
                const Expanded(
                  child: Text(
                    'Evidências e observações',
                    style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF5A7A83),
                        fontWeight: FontWeight.w500),
                  ),
                ),
                Icon(
                  expanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  size: 16,
                  color: const Color(0xFF5A7A83),
                ),
              ],
            ),
          ),
        ),
        // Conteúdo expandido
        if (expanded)
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Observações guardadas
                if (resposta?.observacoes != null &&
                    resposta!.observacoes!.isNotEmpty) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7FAFB),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE2ECF0)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.comment_outlined,
                            size: 13, color: Color(0xFF5A7A83)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            resposta!.observacoes!,
                            style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF5A7A83),
                                fontStyle: FontStyle.italic),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                // Placeholder quando sem evidências
                if (resposta == null ||
                    (resposta!.observacoes == null ||
                        resposta!.observacoes!.isEmpty))
                  const Text(
                    'Sem evidências registadas.',
                    style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF9CA3AF),
                        fontStyle: FontStyle.italic),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}