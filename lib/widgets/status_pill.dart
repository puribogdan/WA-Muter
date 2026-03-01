import 'package:flutter/material.dart';
import '../theme/app_tokens.dart';

class StatusPill extends StatelessWidget {
  final String label;
  final bool ok;

  const StatusPill({
    super.key,
    required this.label,
    required this.ok,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final bg = ok ? tokens.successContainer : tokens.warningContainer;
    final fg = ok ? tokens.success : tokens.warning;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: AppDecorations.pill(context).copyWith(color: bg),
      child: Text(
        label,
        style: AppTypography.micro.copyWith(
          color: fg,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
