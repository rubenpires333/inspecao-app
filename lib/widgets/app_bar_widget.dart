import 'package:flutter/material.dart';

/// Widget reutilizável para AppBar padrão do aplicativo
/// Garante consistência de design em todas as telas
class AppBarWidget extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool automaticallyImplyLeading;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double? elevation;
  final PreferredSizeWidget? bottom;
  final bool centerTitle;

  const AppBarWidget({
    super.key,
    required this.title,
    this.actions,
    this.leading,
    this.automaticallyImplyLeading = true,
    this.backgroundColor,
    this.foregroundColor,
    this.elevation,
    this.bottom,
    this.centerTitle = false,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 18,
        ),
      ),
      actions: actions,
      leading: leading,
      automaticallyImplyLeading: automaticallyImplyLeading,
      backgroundColor: backgroundColor ?? const Color(0xFF18778A),
      foregroundColor: foregroundColor ?? Colors.white,
      elevation: elevation ?? 0,
      bottom: bottom,
      centerTitle: centerTitle,
      iconTheme: IconThemeData(
        color: foregroundColor ?? Colors.white,
      ),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(
        bottom != null ? kToolbarHeight + bottom!.preferredSize.height : kToolbarHeight,
      );
}
