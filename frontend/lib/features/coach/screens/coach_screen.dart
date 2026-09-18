import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/colors.dart';
import '../../../app/theme/spacing.dart';
import '../../../app/theme/typography.dart';
import '../state/chat_controller.dart';
import '../widgets/conversation_list.dart';
import '../widgets/message_bubble.dart';

import '../widgets/suggestion_chips.dart';

class CoachScreen extends ConsumerStatefulWidget {
  const CoachScreen({super.key});

  @override
  ConsumerState<CoachScreen> createState() => _CoachScreenState();
}

class _CoachScreenState extends ConsumerState<CoachScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _send() {
    final text = _input.text;
    if (text.trim().isEmpty) return;

    _input.clear();
    ref.read(chatControllerProvider.notifier).send(text);
    _scrollToEnd();
  }

  /// Runs after the frame so the new message has been laid out first.
  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    // Listening rather than watching: this reacts to new messages without
    // rebuilding the whole screen.
    ref.listen(chatControllerProvider, (previous, next) {
      if (previous?.messages.length != next.messages.length) _scrollToEnd();
    });

    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 900;

          return Row(
            children: [
              if (wide)
                Container(
                  width: 260,
                  decoration: BoxDecoration(
                    border: Border(right: BorderSide(color: p.hair)),
                  ),
                  child: const ConversationList(),
                ),
              Expanded(child: _ChatPane(input: _input, scroll: _scroll, onSend: _send, wide: wide)),
            ],
          );
        },
      ),
    );
  }
}

class _ChatPane extends ConsumerWidget {
  const _ChatPane({
    required this.input,
    required this.scroll,
    required this.onSend,
    required this.wide,
  });

  final TextEditingController input;
  final ScrollController scroll;
  final VoidCallback onSend;
  final bool wide;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final chat = ref.watch(chatControllerProvider);

    return Column(
      children: [
        // Header only on narrow screens, where the sidebar is hidden.
        if (!wide)
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: p.hair)),
            ),
            child: Row(
              children: [
                Text('Coach', style: text.titleLarge),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.history, size: 20),
                  tooltip: 'Past conversations',
                  onPressed: () => _showHistory(context),
                ),
                IconButton(
                  icon: const Icon(Icons.add, size: 20),
                  tooltip: 'New conversation',
                  onPressed: () =>
                      ref.read(chatControllerProvider.notifier).startNew(),
                ),
              ],
            ),
          ),



        Expanded(
          child: chat.loading
              ? const Center(child: CircularProgressIndicator())
              : chat.isEmpty
                  ? _EmptyState(
                      onSelected: (question) => ref
                          .read(chatControllerProvider.notifier)
                          .send(question),
                    )
                  : ListView.builder(
                      controller: scroll,
                      padding: const EdgeInsets.all(AppSpacing.xxl),
                      itemCount: chat.messages.length + (chat.sending ? 1 : 0),
                      itemBuilder: (context, i) {
                        if (i == chat.messages.length) return const _Thinking();
                        return MessageBubble(message: chat.messages[i]);
                      },
                    ),
        ),




        if (chat.error != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.md),
            color: p.linen,
            child: Row(
              children: [
                Container(width: 2, height: 32, color: p.brick),
                const SizedBox(width: AppSpacing.md),
                Expanded(child: Text(chat.error!, style: text.bodyMedium)),
              ],
            ),
          ),

        _Composer(controller: input, onSend: onSend, busy: chat.sending),
      ],
    );
  }

  void _showHistory(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: context.palette.paper,
      builder: (context) => SizedBox(
        height: 420,
        child: ConversationList(onSelected: () => Navigator.pop(context)),
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.onSend,
    required this.busy,
  });

  final TextEditingController controller;
  final VoidCallback onSend;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: p.hair)),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  style: text.bodyLarge,
                  minLines: 1,
                  maxLines: 5,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => onSend(),
                  decoration: const InputDecoration(
                    hintText: 'Ask about a meal, a portion, a craving…',
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: busy ? null : onSend,
                  child: busy
                      ? SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: p.onAccent,
                          ),
                        )
                      : const Text('Send'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


/// Shown while waiting for a reply. A moving line rather than a percentage,
/// since we cannot know how far along the model is (section 46).
class _Thinking extends StatelessWidget {
  const _Thinking();

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('NUTRIAI', style: AppTypography.mono(color: p.muted, size: 10.5)),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            width: 120,
            child: LinearProgressIndicator(
              minHeight: 2,
              backgroundColor: p.clay,
              color: p.ember,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends ConsumerWidget {
  const _EmptyState({required this.onSelected});

  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Ask NutriAI anything', style: text.displayMedium),
              const SizedBox(height: AppSpacing.md),
              Text(
                'About your meals, your goals, or what to cook tonight. '
                'It already knows your profile, so you do not have to repeat '
                'yourself.',
                style: text.bodyLarge,
              ),
              const SizedBox(height: AppSpacing.xxl),
              SuggestionChips(onSelected: onSelected),
            ],
          ),
        ),
      ),
    );
  }
}
