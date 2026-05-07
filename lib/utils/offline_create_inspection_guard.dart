import 'package:flutter/material.dart';
import 'package:inspecao/services/connectivity_service.dart';

/// Confirma ligação à rede antes de abrir o fluxo de nova inspeção.
/// Mostra [AlertDialog] quando offline. Devolve `true` se pode continuar.
Future<bool> ensureOnlineBeforeCreateInspection(BuildContext context) async {
  final online = await ConnectivityService().checkConnectivity();
  if (online) return true;
  if (!context.mounted) return false;
  await showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Modo offline'),
      content: const Text(
        'Não é possível criar uma inspeção em modo offline. '
        'Ligue-se à internet e tente novamente.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('OK'),
        ),
      ],
    ),
  );
  return false;
}
