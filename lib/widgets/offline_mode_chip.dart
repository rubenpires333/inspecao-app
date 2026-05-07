import 'package:flutter/material.dart';
import 'package:inspecao/services/connectivity_service.dart';

/// Chip compacto para cabeçalhos escuros ([highContrast] false) ou uso global sobre qualquer fundo.
class OfflineModeChip extends StatelessWidget {
  const OfflineModeChip({super.key, this.highContrast = false});

  final bool highContrast;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: ConnectivityService().onlineNotifier,
      builder: (_, online, __) {
        if (online) return const SizedBox.shrink();
        if (highContrast) {
          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: Material(
              elevation: 2,
              borderRadius: BorderRadius.circular(20),
              color: Colors.amber.shade700,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.cloud_off_rounded, size: 16, color: Colors.grey.shade900),
                    const SizedBox(width: 6),
                    Text(
                      'Offline',
                      style: TextStyle(
                        color: Colors.grey.shade900,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
        return Padding(
          padding: const EdgeInsets.only(right: 6),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.25),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.35)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.cloud_off_rounded, size: 14, color: Colors.white),
                SizedBox(width: 4),
                Text(
                  'Offline',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Indicador offline fixo no topo direito, sobre qualquer rota (login, splash, detalhe, etc.).
class GlobalOfflineOverlay extends StatelessWidget {
  const GlobalOfflineOverlay({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      fit: StackFit.expand,
      children: [
        child,
        SafeArea(
          bottom: false,
          child: Align(
            alignment: Alignment.topRight,
            child: Padding(
              padding: const EdgeInsets.only(top: 4, right: 8),
              child: OfflineModeChip(highContrast: true),
            ),
          ),
        ),
      ],
    );
  }
}
