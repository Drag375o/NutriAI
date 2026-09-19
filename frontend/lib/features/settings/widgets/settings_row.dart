import 'package:flutter/material.dart';

import '../../../app/theme/colors.dart';
import '../../../app/theme/spacing.dart';

/// One line in a settings list. A hairline row rather than a Material tile,
/// matching the rest of the app.
class SettingsRow extends StatelessWidget {
  const SettingsRow({
    super.key,
    required this.label,
    this.value,
    this.onTap,
    this.trailing,
    this.destructive = false,
  });

  final String label;
  final String? value;
  final VoidCallback? onTap;

  /// Replaces the value text, for a control rather than a reading.
  final Widget? trailing;

  /// Colours the label as a warning. For actions that cannot be undone.
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;

    final content = Container(
      constraints: const BoxConstraints(minHeight: 56),
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: p.hair)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: text.bodyLarge?.copyWith(
                color: destructive ? p.brick : p.ink,
              ),
            ),
          ),
          if (trailing != null)
            trailing!
          else if (value != null)
            Text(value!, style: text.bodyMedium),
          if (onTap != null && trailing == null) ...[
            const SizedBox(width: AppSpacing.md),
            Icon(Icons.chevron_right, size: 18, color: p.muted),
          ],
        ],
      ),
    );

    if (onTap == null) return content;
    return InkWell(onTap: onTap, child: content);
  }
}