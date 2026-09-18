import 'package:flutter/material.dart';

import '../../../app/theme/colors.dart';
import '../../../app/theme/spacing.dart';
import '../../../app/theme/typography.dart';
import '../data/chat_models.dart';

class MessageBubble extends StatelessWidget {
  const MessageBubble({super.key, required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final isUser = message.isUser;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          Flexible(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 620),
              child: Column(
                crossAxisAlignment:
                    isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  Text(
                    isUser ? 'YOU' : 'NUTRIAI',
                    style: AppTypography.mono(color: p.muted, size: 10.5),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: isUser ? p.linen : Colors.transparent,
                      border: isUser ? null : Border.all(color: p.hair),
                      borderRadius: BorderRadius.circular(AppRadii.md),
                    ),
                    child: Opacity(
                      // Pending messages are dimmed so it is visible that
                      // they have not been confirmed yet.
                      opacity: message.pending ? 0.5 : 1.0,
                      child: _Markdownish(
                        content: message.content,
                        style: text.bodyLarge!,
                        boldColour: p.ink,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Renders the small subset of Markdown the model actually produces:
/// **bold**, bullet lines, and paragraphs.
///
/// A full Markdown package would be a heavy dependency for this much, and
/// section 55 says prefer what we already have.
class _Markdownish extends StatelessWidget {
  const _Markdownish({
    required this.content,
    required this.style,
    required this.boldColour,
  });

  final String content;
  final TextStyle style;
  final Color boldColour;

  @override
  Widget build(BuildContext context) {
    final lines = content.split('\n');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final line in lines)
          if (line.trim().isEmpty)
            const SizedBox(height: AppSpacing.md)
          else
            Padding(
              padding: EdgeInsets.only(
                bottom: 2,
                left: _isBullet(line) ? AppSpacing.md : 0,
              ),
              child: Text.rich(
                _parse(_stripBullet(line), isBullet: _isBullet(line)),
                style: style,
              ),
            ),
      ],
    );
  }

  static bool _isBullet(String line) {
    final t = line.trimLeft();
    return t.startsWith('- ') || t.startsWith('* ') || t.startsWith('• ');
  }

  static String _stripBullet(String line) {
    if (!_isBullet(line)) return line;
    return line.trimLeft().substring(2);
  }

  TextSpan _parse(String line, {required bool isBullet}) {
    final spans = <TextSpan>[];

    if (isBullet) {
      spans.add(TextSpan(text: '·  ', style: TextStyle(color: boldColour)));
    }

    // Split on ** pairs; odd indices are the bold segments.
    final parts = line.split('**');
    for (var i = 0; i < parts.length; i++) {
      if (parts[i].isEmpty) continue;
      spans.add(
        TextSpan(
          text: parts[i],
          style: i.isOdd
              ? TextStyle(fontWeight: FontWeight.w600, color: boldColour)
              : null,
        ),
      );
    }

    return TextSpan(children: spans);
  }
}