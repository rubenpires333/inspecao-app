import 'package:flutter/material.dart';
import 'package:inspecao/services/connectivity_service.dart';
import 'package:inspecao/services/data_service.dart';
import 'package:inspecao/services/sync_service.dart';

/// Folha opcional (fecha ao arrastar / fora).
Future<void> showPendingSyncSheet(BuildContext context) async {
  final overview = await SyncService().loadPendingOverview();
  if (!context.mounted) return;

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) {
      return PopScope(
        canPop: true,
        child: _PendingSyncSheetBody(
          initialOverview: overview,
          mandatory: false,
        ),
      );
    },
  );
}

/// Obrigatório quando há Internet e dados pendentes: não fecha ao tocar fora nem com voltar.
/// Só encerra quando não existirem pendências (`totalItems == 0`) após sync bem‑sucedido.
Future<void> showMandatoryPendingSyncSheet(BuildContext context) async {
  final overview = await SyncService().loadPendingOverview();
  if (!context.mounted || overview.totalItems == 0) return;

  await showModalBottomSheet<void>(
    context: context,
    isDismissible: false,
    enableDrag: false,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) {
      return PopScope(
        canPop: false,
        child: _PendingSyncSheetBody(
          initialOverview: overview,
          mandatory: true,
        ),
      );
    },
  );
}

class _PendingSyncSheetBody extends StatefulWidget {
  final PendingSyncOverview initialOverview;
  final bool mandatory;

  const _PendingSyncSheetBody({
    required this.initialOverview,
    required this.mandatory,
  });

  @override
  State<_PendingSyncSheetBody> createState() => _PendingSyncSheetBodyState();
}

class _PendingSyncSheetBodyState extends State<_PendingSyncSheetBody> {
  late PendingSyncOverview _overview;
  bool _busy = false;
  String? _feedback;

  @override
  void initState() {
    super.initState();
    _overview = widget.initialOverview;
  }

  Future<void> _applyPolicy(PendingInspectionConflictPolicy policy) async {
    if (_busy) return;

    setState(() {
      _busy = true;
      _feedback = null;
    });

    try {
      if (!ConnectivityService().isConnected) {
        if (!mounted) return;
        setState(() {
          _busy = false;
          _feedback =
              'Sem ligação à Internet. Os dados só podem ser enviados ou alinhados com o servidor quando houver rede.';
        });
        return;
      }

      final remaining =
          await SyncService().runFullPendingSync(inspectionConflicts: policy);

      if (!mounted) return;

      setState(() {
        _overview = remaining;
        _busy = false;
        if (remaining.totalItems > 0) {
          _feedback =
              'Ainda há ${remaining.totalItems} item(ns) pendente(s). '
              'Tente novamente ou escolha a outra opção se estiver em conflito com o servidor.';
        }
      });

      if (remaining.totalItems == 0 && mounted) {
        Navigator.of(context).pop();
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _feedback =
            'Ocorreu um erro ao sincronizar. Verifique a ligação e tente novamente.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final padBottom = MediaQuery.paddingOf(context).bottom + 20;

    final body = Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20, padBottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_busy) const LinearProgressIndicator(),
          if (_busy) const SizedBox(height: 12),
          if (!widget.mandatory)
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          if (!widget.mandatory) const SizedBox(height: 16),
          if (widget.mandatory) ...[
            Row(
              children: [
                Icon(Icons.sync_problem_rounded, color: Colors.orange[800]),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Sincronização necessária',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ] else
            const Text(
              'Dados por sincronizar',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
          if (!widget.mandatory) const SizedBox(height: 8),
          Text(
            '${_overview.pendingInspections} inspeção(ões) com alterações locais\n'
            '${_overview.queuedRespostas} resposta(s) de checklist na fila',
            style: TextStyle(color: Colors.grey[700], height: 1.4),
          ),
          if (_overview.inspectionTitles.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text('Inspeções',
                style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 160),
              child: ListView.builder(
                shrinkWrap: true,
                physics: const ClampingScrollPhysics(),
                itemCount: _overview.inspectionTitles.length,
                itemBuilder: (_, i) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('• '),
                      Expanded(
                        child: Text(
                          _overview.inspectionTitles[i],
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
          if (_feedback != null) ...[
            const SizedBox(height: 12),
            Material(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.warning_amber_rounded,
                        color: Colors.orange[800], size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _feedback!,
                        style: TextStyle(
                          color: Colors.grey[900],
                          height: 1.35,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          const Text(
            'Conflitos: se alguém alterou a mesma inspeção no servidor com data mais recente, pode escolher enviar as suas alterações ou descartá-las e ficar com a versão do servidor.',
            style: TextStyle(fontSize: 12, height: 1.35),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _busy
                      ? null
                      : () => _applyPolicy(
                            PendingInspectionConflictPolicy
                                .discardLocalUseServer,
                          ),
                  child: const Text('Usar servidor'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  onPressed: _busy
                      ? null
                      : () => _applyPolicy(
                            PendingInspectionConflictPolicy.uploadLocal,
                          ),
                  child: const Text('Enviar local'),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    return SafeArea(
      child: SingleChildScrollView(
        child: body,
      ),
    );
  }
}
