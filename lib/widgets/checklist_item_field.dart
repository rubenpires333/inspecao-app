import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
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
const _kWarningLight   = Color(0xFFFFFBEB);
const _kNaoObservavel  = Color(0xFF9CA3AF);

/// Widget que renderiza um item do checklist conforme o seu tipo,
/// com o visual da app mobile (botões grandes, ícone de relógio, evidências).
///
/// Quando a opção selecionada tem ação `tornar_obrigatorio` com
/// `plano_acao: true`, exibe automaticamente o painel de
/// "Plano de Ação Obrigatório" com campo de observações e evidências.
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
  late TextEditingController _obsPlanoAcaoCtrl;
  String? _selectedOpcaoId;
  Set<String> _selectedMulti = {};
  int? _rating;
  bool? _simNao;

  /// Estado local para data/hora (mostra valor imediatamente após picker)
  String? _selectedData;
  String? _selectedDataHora;

  /// Controla se a secção "Evidências e observações" está expandida
  bool _evidenciasExpanded = false;

  /// Controla se o painel de plano de ação está expandido
  bool _planoAcaoExpanded = true;

  /// Evidências (imagens) adicionadas localmente para o plano de ação
  List<XFile> _evidenciasPlanoAcao = [];

  /// Flag: já foi inicializado com resposta existente (evita reset em re-renders)
  bool _initialized = false;

  final _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _textCtrl         = TextEditingController();
    _numCtrl          = TextEditingController();
    _obsPlanoAcaoCtrl = TextEditingController();
    _syncFromResposta(widget.resposta);
    _initialized = true;
  }

  @override
  void didUpdateWidget(ChecklistItemField old) {
    super.didUpdateWidget(old);

    final novaResposta = widget.resposta;
    final antigaResposta = old.resposta;

    // Sem resposta nova → nada a fazer
    if (novaResposta == null) return;

    // Primeira vez que chega uma resposta (antes era null) → sincronizar tudo
    if (antigaResposta == null) {
      _syncFromResposta(novaResposta);
      return;
    }

    // A resposta mudou de ID (item diferente) → sincronizar tudo
    if (novaResposta.id != antigaResposta.id) {
      _syncFromResposta(novaResposta);
      return;
    }

    // Mesma resposta mas opcaoId mudou no servidor
    // Só aceitar se o valor do servidor é DIFERENTE do estado local
    // (evitar reverter uma selecção que o utilizador acabou de fazer
    //  mas cuja confirmação do servidor ainda não chegou)
    if (novaResposta.opcaoId != antigaResposta.opcaoId &&
        novaResposta.opcaoId != _selectedOpcaoId) {
      _selectedOpcaoId = novaResposta.opcaoId;
    }

    // Sincronizar campos de texto/número apenas se mudaram no servidor
    // e o campo local estiver vazio (evitar sobrescrever texto que o
    // utilizador está a digitar)
    if (novaResposta.valorTexto != antigaResposta.valorTexto) {
      if (_textCtrl.text.isEmpty) {
        _textCtrl.text = novaResposta.valorTexto ?? '';
      }
    }
    if (novaResposta.valorNumero != antigaResposta.valorNumero) {
      if (_numCtrl.text.isEmpty) {
        _numCtrl.text = novaResposta.valorNumero != null
            ? novaResposta.valorNumero!.toStringAsFixed(
                novaResposta.valorNumero! ==
                        novaResposta.valorNumero!.truncateToDouble()
                    ? 0
                    : 2)
            : '';
      }
    }

    // Data/hora: aceitar sempre (não tem digitação manual)
    if (novaResposta.valorData != antigaResposta.valorData) {
      _selectedData = novaResposta.valorData;
    }
    if (novaResposta.valorDataHora != antigaResposta.valorDataHora) {
      _selectedDataHora = novaResposta.valorDataHora;
    }

    // Rating: aceitar se mudou no servidor e não foi alterado localmente
    if (novaResposta.valorRating != antigaResposta.valorRating &&
        novaResposta.valorRating != null) {
      _rating = novaResposta.valorRating;
    }

    // Observações do plano de ação: só preencher se campo local estiver vazio
    if (novaResposta.observacoes != null &&
        novaResposta.observacoes!.isNotEmpty &&
        _obsPlanoAcaoCtrl.text.isEmpty) {
      _obsPlanoAcaoCtrl.text = novaResposta.observacoes!;
    }
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    _numCtrl.dispose();
    _obsPlanoAcaoCtrl.dispose();
    super.dispose();
  }

  void _syncFromResposta(RespostaInspecaoCompleta? r) {
    if (r == null) return;
    _textCtrl.text = r.valorTexto ?? '';
    _numCtrl.text  = r.valorNumero != null
        ? r.valorNumero!.toStringAsFixed(
            r.valorNumero! == r.valorNumero!.truncateToDouble() ? 0 : 2)
        : '';
    _selectedOpcaoId = r.opcaoId;
    _selectedData    = r.valorData;
    _selectedDataHora = r.valorDataHora;
    if (r.valorRating != null) _rating = r.valorRating;
    // Observações do plano de ação (vindas do servidor)
    if (r.observacoes != null && r.observacoes!.isNotEmpty) {
      _obsPlanoAcaoCtrl.text = r.observacoes!;
    }
  }

  // ─── Detecção de plano de ação ────────────────────────────────────────────

  /// Retorna a opção actualmente selecionada que requer plano de ação,
  /// ou null se não houver nenhuma.
  OpcaoItemChecklist? get _opcaoComPlanoAcao {
    if (_selectedOpcaoId == null) return null;
    try {
      final opcao = widget.item.opcoes
          .firstWhere((o) => o.id == _selectedOpcaoId);
      return opcao.requerPlanoAcao ? opcao : null;
    } catch (_) {
      return null;
    }
  }

  bool get _mostrarPlanoAcao => _opcaoComPlanoAcao != null;

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _mostrarPlanoAcao ? _kWarning.withOpacity(0.4) : _kBorder,
          width: _mostrarPlanoAcao ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 4,
              offset: const Offset(0, 1)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Cabeçalho ─────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    widget.item.rotulo,
                    style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: _kTextPrimary),
                  ),
                ),
                if (widget.item.obrigatorio)
                  const Padding(
                    padding: EdgeInsets.only(left: 4, top: 1),
                    child: Text('*',
                        style: TextStyle(
                            color: _kError,
                            fontSize: 14,
                            fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
          ),

          // ── Descrição (se existir) ─────────────────────────────────────
          if (widget.item.descricao != null &&
              widget.item.descricao!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 6),
              child: Text(widget.item.descricao!,
                  style: const TextStyle(
                      fontSize: 12, color: _kTextSecondary)),
            ),

          // ── Campo de resposta ──────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 0),
            child: _buildField(),
          ),

          const SizedBox(height: 10),

          // ── Painel de Plano de Ação (quando aplicável) ─────────────────
          if (_mostrarPlanoAcao) ...[
            const Divider(height: 1, color: _kWarning, thickness: 0.5),
            _buildPlanoAcaoPanel(),
          ],

          // ── Divisor + "Evidências e observações" (colapsável) ──────────
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

  // ─── Painel de Plano de Ação ──────────────────────────────────────────────

  Widget _buildPlanoAcaoPanel() {
    final opcao = _opcaoComPlanoAcao;
    if (opcao == null) return const SizedBox.shrink();

    return Container(
      color: _kWarningLight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cabeçalho colapsável
          GestureDetector(
            onTap: () => setState(
                () => _planoAcaoExpanded = !_planoAcaoExpanded),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded,
                      size: 16, color: _kWarning),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Plano de Ação Obrigatório',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: _kWarning),
                        ),
                        Text(
                          'A opção "${opcao.texto}" requer um plano de ação',
                          style: const TextStyle(
                              fontSize: 11,
                              color: _kTextSecondary),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _planoAcaoExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    size: 16,
                    color: _kTextSecondary,
                  ),
                ],
              ),
            ),
          ),

          // Conteúdo expandido
          if (_planoAcaoExpanded) ...[
            const Divider(height: 1, color: _kBorder),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Campo de Observações
                  const Text(
                    'Observações *',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _kTextPrimary),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _obsPlanoAcaoCtrl,
                    enabled: widget.enabled,
                    maxLines: 4,
                    minLines: 3,
                    style: const TextStyle(
                        fontSize: 13, color: _kTextPrimary),
                    decoration: InputDecoration(
                      hintText:
                          'Descreva o problema ou não conformidade identificado...',
                      hintStyle: const TextStyle(
                          fontSize: 12, color: _kNaoObservavel),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide:
                              const BorderSide(color: _kBorder)),
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide:
                              const BorderSide(color: _kBorder)),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                              color: _kWarning, width: 1.5)),
                      disabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide:
                              const BorderSide(color: _kBorder)),
                    ),
                    onChanged: (_) => _emitPlanoAcaoPayload(),
                  ),

                  const SizedBox(height: 12),

                  // Secção de evidências (fotos) do plano de ação
                  Row(
                    children: [
                      const Text(
                        'Evidências',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _kTextPrimary),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '(opcional)',
                        style: const TextStyle(
                            fontSize: 11, color: _kTextSecondary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Grid de imagens adicionadas
                  if (_evidenciasPlanoAcao.isNotEmpty) ...[
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ..._evidenciasPlanoAcao
                            .asMap()
                            .entries
                            .map((e) => _buildEvidenciaThumbnail(
                                e.key, e.value)),
                        if (widget.enabled)
                          _buildAdicionarEvidenciaBtn(compact: true),
                      ],
                    ),
                    const SizedBox(height: 10),
                  ],

                  // Botões de adicionar (quando lista vazia)
                  if (_evidenciasPlanoAcao.isEmpty && widget.enabled)
                    _buildBotoesEvidencia(),

                  // Aviso quando desabilitado e sem evidências
                  if (!widget.enabled &&
                      _evidenciasPlanoAcao.isEmpty &&
                      (widget.resposta?.observacoes == null ||
                          widget.resposta!.observacoes!.isEmpty))
                    const Text(
                      'Nenhuma evidência registada.',
                      style: TextStyle(
                          fontSize: 12,
                          color: _kNaoObservavel,
                          fontStyle: FontStyle.italic),
                    ),

                  // Botão Salvar Plano de Ação
                  if (widget.enabled) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _onSalvarPlanoAcao,
                        icon: const Icon(Icons.save_outlined, size: 16),
                        label: const Text('Salvar Plano de Ação',
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600)),
                        style: FilledButton.styleFrom(
                          backgroundColor: _kPrimary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEvidenciaThumbnail(int index, XFile file) {
    return Stack(
      children: [
        // Thumbnail clicável → abre visualização ampliada
        GestureDetector(
          onTap: () => _abrirImagemAmpliada(file, index),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.file(
              File(file.path),
              width: 72,
              height: 72,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 72,
                height: 72,
                color: _kSurface,
                child: const Icon(Icons.broken_image_outlined,
                    color: _kTextSecondary, size: 28),
              ),
            ),
          ),
        ),
        // Botão de remover (só quando editável)
        if (widget.enabled)
          Positioned(
            top: 2,
            right: 2,
            child: GestureDetector(
              onTap: () {
                setState(() => _evidenciasPlanoAcao.removeAt(index));
                _emitPlanoAcaoPayload();
              },
              child: Container(
                decoration: const BoxDecoration(
                  color: _kError,
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(2),
                child: const Icon(Icons.close,
                    color: Colors.white, size: 12),
              ),
            ),
          ),
      ],
    );
  }

  /// Abre um diálogo fullscreen para visualizar a imagem ampliada.
  /// Permite zoom com pinch, fechar com tap fora ou botão X,
  /// e remover a evidência directamente do popup.
  void _abrirImagemAmpliada(XFile file, int index) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            // Fundo clicável para fechar
            GestureDetector(
              onTap: () => Navigator.pop(ctx),
              child: const SizedBox.expand(
                child: ColoredBox(color: Colors.transparent),
              ),
            ),
            // Imagem com zoom interactivo
            Center(
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      File(file.path),
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => Container(
                        width: 200,
                        height: 200,
                        color: _kSurface,
                        child: const Icon(Icons.broken_image_outlined,
                            color: _kTextSecondary, size: 48),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // Botão fechar (canto superior direito)
            Positioned(
              top: 40,
              right: 16,
              child: GestureDetector(
                onTap: () => Navigator.pop(ctx),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.all(8),
                  child: const Icon(Icons.close_rounded,
                      color: Colors.white, size: 20),
                ),
              ),
            ),
            // Botão remover (canto inferior direito) — só quando editável
            if (widget.enabled)
              Positioned(
                bottom: 40,
                right: 16,
                child: GestureDetector(
                  onTap: () {
                    Navigator.pop(ctx);
                    setState(() => _evidenciasPlanoAcao.removeAt(index));
                    _emitPlanoAcaoPayload();
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: _kError,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.delete_outline_rounded,
                            color: Colors.white, size: 18),
                        SizedBox(width: 6),
                        Text('Remover evidência',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
              ),
            // Contador de evidências (canto inferior esquerdo)
            Positioned(
              bottom: 40,
              left: 16,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 6),
                child: Text(
                  '${index + 1} / ${_evidenciasPlanoAcao.length}',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdicionarEvidenciaBtn({bool compact = false}) {
    return GestureDetector(
      onTap: _mostrarOpcoesImagem,
      child: Container(
        width: compact ? 72 : null,
        height: compact ? 72 : null,
        padding: compact
            ? null
            : const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
              color: _kPrimary.withOpacity(0.4), style: BorderStyle.solid),
        ),
        child: compact
            ? const Center(
                child: Icon(Icons.add_a_photo_outlined,
                    size: 28, color: _kPrimary),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.add_a_photo_outlined,
                      size: 18, color: _kPrimary),
                  SizedBox(width: 6),
                  Text('Adicionar evidência',
                      style: TextStyle(
                          fontSize: 12,
                          color: _kPrimary,
                          fontWeight: FontWeight.w500)),
                ],
              ),
      ),
    );
  }

  Widget _buildBotoesEvidencia() {
    return Row(
      children: [
        Expanded(
          child: _EvidenciaBtn(
            icon: Icons.camera_alt_outlined,
            label: 'Câmera',
            onTap: () => _selecionarImagem(ImageSource.camera),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _EvidenciaBtn(
            icon: Icons.photo_library_outlined,
            label: 'Galeria',
            onTap: () => _selecionarImagem(ImageSource.gallery),
          ),
        ),
      ],
    );
  }

  void _mostrarOpcoesImagem() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: _kBorder,
                    borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined,
                  color: _kPrimary),
              title: const Text('Tirar foto'),
              onTap: () {
                Navigator.pop(context);
                _selecionarImagem(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined,
                  color: _kPrimary),
              title: const Text('Escolher da galeria'),
              onTap: () {
                Navigator.pop(context);
                _selecionarImagem(ImageSource.gallery);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _selecionarImagem(ImageSource source) async {
    try {
      final file = await _imagePicker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1920,
      );
      if (file != null) {
        setState(() => _evidenciasPlanoAcao.add(file));
        _emitPlanoAcaoPayload();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Não foi possível selecionar a imagem: $e'),
            backgroundColor: _kError,
          ),
        );
      }
    }
  }

  void _emitPlanoAcaoPayload() {
    // Incluir dados do plano de ação no payload ao emitir
    _emitPayloadWith({
      if (_selectedOpcaoId != null) 'opcaoId': _selectedOpcaoId,
      'observacoesPlanoAcao': _obsPlanoAcaoCtrl.text,
      'evidenciasPlanoAcao':
          _evidenciasPlanoAcao.map((f) => f.path).toList(),
    });
  }

  void _onSalvarPlanoAcao() {
    final obs = _obsPlanoAcaoCtrl.text.trim();
    if (obs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Preencha as observações do plano de ação antes de guardar.'),
          backgroundColor: _kWarning,
        ),
      );
      return;
    }
    // Emitir payload com flag explícita de guardar plano de ação
    widget.onSave?.call({
      'itemChecklistId': widget.item.id,
      if (_selectedOpcaoId != null) 'opcaoId': _selectedOpcaoId,
      'observacoesPlanoAcao': obs,
      'evidenciasPlanoAcao':
          _evidenciasPlanoAcao.map((f) => f.path).toList(),
      'salvarPlanoAcao': true,
    });
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

  // ─── Campos por tipo ──────────────────────────────────────────────────────

  Widget _buildTexto() => TextField(
        controller: _textCtrl,
        enabled: widget.enabled,
        style:
            const TextStyle(fontSize: 13, color: _kTextPrimary),
        decoration: _inputDeco('Escreva aqui...'),
        onChanged: (_) => _emitPayload(),
      );

  Widget _buildTextarea() => TextField(
        controller: _textCtrl,
        enabled: widget.enabled,
        maxLines: 4,
        minLines: 3,
        style: const TextStyle(fontSize: 13, color: _kTextPrimary),
        decoration: _inputDeco('Escreva aqui...'),
        onChanged: (_) => _emitPayload(),
      );

  Widget _buildNumero() => TextField(
        controller: _numCtrl,
        enabled: widget.enabled,
        keyboardType:
            const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))
        ],
        style: const TextStyle(fontSize: 13, color: _kTextPrimary),
        decoration: _inputDeco('0'),
        onChanged: (_) => _emitPayload(),
      );

  Widget _buildData() {
    final display = _selectedData != null
        ? _formatDate(_selectedData!)
        : (widget.resposta?.valorData != null
            ? _formatDate(widget.resposta!.valorData!)
            : 'Selecionar data');

    return _DateTimeButton(
      icon: Icons.calendar_today_outlined,
      label: display,
      enabled: widget.enabled,
      onTap: () async {
        final now = DateTime.now();
        final date = await showDatePicker(
          context: context,
          initialDate: now,
          firstDate: DateTime(2020),
          lastDate: DateTime(2030),
          builder: (c, child) => Theme(
            data: Theme.of(c).copyWith(
                colorScheme:
                    const ColorScheme.light(primary: _kPrimary)),
            child: child!,
          ),
        );
        if (date == null || !mounted) return;
        final iso =
            '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
        setState(() => _selectedData = iso);
        _emitPayloadWith({'valorData': iso});
      },
    );
  }

  Widget _buildDataHora() {
    final display = _selectedDataHora != null
        ? _formatDateTime(_selectedDataHora!)
        : (widget.resposta?.valorDataHora != null
            ? _formatDateTime(widget.resposta!.valorDataHora!)
            : 'Selecionar data e hora');

    return _DateTimeButton(
      icon: Icons.access_time_rounded,
      label: display,
      enabled: widget.enabled,
      onTap: () async {
        final now = DateTime.now();
        final initial = DateTime.tryParse(_selectedDataHora ?? '') ?? now;
        final date = await showDatePicker(
          context: context,
          initialDate: initial,
          firstDate: DateTime(2020),
          lastDate: DateTime(2030),
          builder: (c, child) => Theme(
              data: Theme.of(c).copyWith(
                  colorScheme:
                      const ColorScheme.light(primary: _kPrimary)),
              child: child!),
        );
        if (date == null || !mounted) return;
        final time = await showTimePicker(
          context: context,
          initialTime:
              TimeOfDay(hour: initial.hour, minute: initial.minute),
          builder: (c, child) => Theme(
              data: Theme.of(c).copyWith(
                  colorScheme:
                      const ColorScheme.light(primary: _kPrimary)),
              child: child!),
        );
        if (time == null) return;
        final dt = DateTime(
            date.year, date.month, date.day, time.hour, time.minute);

        // Formatar como OffsetDateTime com timezone UTC (+00:00) — exigido pelo Spring
        final utc = dt.toUtc();
        final iso =
            '${utc.year.toString().padLeft(4, '0')}-${utc.month.toString().padLeft(2, '0')}-${utc.day.toString().padLeft(2, '0')}T${utc.hour.toString().padLeft(2, '0')}:${utc.minute.toString().padLeft(2, '0')}:00+00:00';

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
            padding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              color:
                  isSelected ? cor.withOpacity(0.10) : _kSurface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: isSelected ? cor : _kBorder,
                  width: isSelected ? 1.5 : 1),
            ),
            child: Row(
              children: [
                Icon(
                  isSelected
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_off_rounded,
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
                  _emitPayloadWith(
                      {'opcoesSelecionadas': _selectedMulti.toList()});
                }
              : null,
          child: Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              color:
                  isSelected ? cor.withOpacity(0.10) : _kSurface,
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
              star <= current
                  ? Icons.star_rounded
                  : Icons.star_border_rounded,
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
      padding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: has ? _kPrimaryLight : _kSurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: has ? _kPrimary.withOpacity(0.3) : _kBorder),
      ),
      child: Row(
        children: [
          Icon(
              has
                  ? Icons.check_circle_outline_rounded
                  : Icons.attach_file_rounded,
              size: 20,
              color: has ? _kPrimary : _kTextSecondary),
          const SizedBox(width: 10),
          Expanded(
              child: Text(
                  has ? 'Anexo(s) carregado(s)' : 'Sem anexo',
                  style: TextStyle(
                      fontSize: 13,
                      color: has ? _kPrimary : _kTextSecondary))),
          if (widget.enabled && !has)
            const Icon(Icons.upload_outlined,
                size: 18, color: _kPrimary),
        ],
      ),
    );
  }

  Widget _buildGeo() {
    final lat = widget.resposta?.latitude;
    final lng = widget.resposta?.longitude;
    final has = lat != null && lng != null;
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: has ? _kPrimaryLight : _kSurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: has ? _kPrimary.withOpacity(0.3) : _kBorder),
      ),
      child: Row(
        children: [
          Icon(Icons.location_on_outlined,
              size: 20,
              color: has ? _kPrimary : _kTextSecondary),
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
            style: TextStyle(
                fontSize: 13, color: _kTextSecondary)),
      );

  InputDecoration _inputDeco(String hint) => InputDecoration(
        hintText: hint,
        hintStyle:
            const TextStyle(color: _kTextSecondary, fontSize: 13),
        filled: true,
        fillColor: _kSurface,
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 12, vertical: 10),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: _kBorder)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: _kBorder)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide:
                const BorderSide(color: _kPrimary, width: 1.5)),
        disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: _kBorder)),
      );

  String _formatDate(String iso) {
    try {
      final d = DateTime.parse(iso);
      return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
    } catch (_) {
      return iso;
    }
  }

  String _formatDateTime(String iso) {
    try {
      final d = DateTime.parse(iso).toLocal();
      return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year} '
          '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return iso;
    }
  }

  // ─── Emit ─────────────────────────────────────────────────────────────────

  void _emitPayload() {
    _emitPayloadWith({
      'valorTexto':
          _textCtrl.text.isNotEmpty ? _textCtrl.text : null,
      'valorNumero': _numCtrl.text.isNotEmpty
          ? double.tryParse(_numCtrl.text.replaceAll(',', '.'))
          : null,
    });
  }

  void _emitPayloadWith(Map<String, dynamic> extra) {
    widget.onSave
        ?.call({'itemChecklistId': widget.item.id, ...extra});
  }
}

// ─── _EvidenciaBtn ────────────────────────────────────────────────────────────
/// Botão de ação para selecionar evidências (câmera ou galeria)
class _EvidenciaBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _EvidenciaBtn({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _kPrimary.withOpacity(0.4)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: _kPrimary),
            const SizedBox(width: 6),
            Text(label,
                style: const TextStyle(
                    fontSize: 12,
                    color: _kPrimary,
                    fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
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
      children: opcoes.map((btn) {
        final isSelected = selectedId == btn.id;
        return Expanded(
          child: GestureDetector(
            onTap: enabled ? () => onSelect(btn.id) : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              margin: EdgeInsets.only(
                  right: btn == opcoes.last ? 0 : 6),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isSelected ? btn.activeBg : _kSurface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: isSelected
                        ? btn.activeColor
                        : _kBorder,
                    width: isSelected ? 1.5 : 1),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    btn.icon,
                    size: 24,
                    color: isSelected
                        ? btn.activeColor
                        : const Color(0xFFAFB4BB),
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
        padding: const EdgeInsets.symmetric(
            horizontal: 12, vertical: 11),
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
            padding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 10),
            child: Row(
              children: [
                const Icon(Icons.image_outlined,
                    size: 15, color: Color(0xFF5A7A83)),
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
                      border: Border.all(
                          color: const Color(0xFFE2ECF0)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.comment_outlined,
                            size: 13,
                            color: Color(0xFF5A7A83)),
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

// ─── Helpers ──────────────────────────────────────────────────────────────────

Color _colorFromHex(String? hex, Color fallback) {
  if (hex == null || hex.isEmpty) return fallback;
  try {
    final h = hex.replaceAll('#', '');
    if (h.length == 6) return Color(int.parse('FF$h', radix: 16));
    if (h.length == 8) return Color(int.parse(h, radix: 16));
  } catch (_) {}
  return fallback;
}