import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/colors.dart';
import '../../../app/theme/spacing.dart';
import '../../../app/theme/typography.dart';
import '../state/chat_controller.dart';

class ConversationList extends ConsumerWidget {
  const ConversationList({super.key, this.onSelected});

  /// Called after a conversation is opened, so a sheet can close itself.
  final VoidCallback? onSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final conversations = ref.watch(conversationsProvider);
    final current = ref.watch(chatControllerProvider).conversationId;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: OutlinedButton(
            onPressed: () {
              ref.read(chatControllerProvider.notifier).startNew();
              onSelected?.call();
            },
            child: const Text('New conversation'),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Text(
            'EARLIER',
            style: AppTypography.mono(color: p.muted, size: 10.5),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Expanded(
          child: conversations.when(
            loading: () => const Center(
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
            error: (e, _) => Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Text(
                'Could not load your conversations.',
                style: text.bodySmall,
              ),
            ),
            data: (items) {
              if (items.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Text(
                    'Your conversations will appear here.',
                    style: text.bodySmall,
                  ),
                );
              }

              return ListView.builder(
                padding: EdgeInsets.zero,
                itemCount: items.length,
                itemBuilder: (context, i) {
                  final c = items[i];
                  final selected = c.id == current;

                  return InkWell(
                    onTap: () {
                      ref.read(chatControllerProvider.notifier).open(c.id);
                      onSelected?.call();
                    },
                    child: Container(
                      constraints: const BoxConstraints(minHeight: 48),
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                        vertical: AppSpacing.md,
                      ),
                      decoration: BoxDecoration(
                        border: Border(
                          left: BorderSide(
                            color: selected ? p.ember : Colors.transparent,
                            width: AppBorders.mark,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              c.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: text.bodyMedium?.copyWith(
                                color: selected ? p.ink : p.char,
                                fontWeight: selected
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.close, size: 16, color: p.muted),
                            tooltip: 'Delete conversation',
                            onPressed: () => _confirmDelete(context, ref, c.id),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  /// Deleting removes messages permanently, so it asks first.
  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    int id,
  ) async {
    final p = context.palette;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: p.paper,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: p.hair),
          borderRadius: BorderRadius.circular(AppRadii.md),
        ),
        title: Text(
          'Delete this conversation?',
          style: TextStyle(
            color: p.ink,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'The messages in it will be gone for good.',
          style: TextStyle(color: p.char, fontSize: 15, height: 1.5),
        ),
        actions: [
          TextButton(
            // foregroundColor on the button itself, since TextButton
            // overrides the child's colour otherwise.
            style: TextButton.styleFrom(foregroundColor: p.char),
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep it'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: p.brick),
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Delete',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(chatControllerProvider.notifier).deleteConversation(id);
    }
  }
}