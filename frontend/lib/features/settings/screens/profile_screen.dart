import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/colors.dart';
import '../../../app/theme/spacing.dart';
import '../../../app/theme/theme_provider.dart';
import '../../../app/theme/typography.dart';
import '../../auth/state/auth_controller.dart';
import '../widgets/account_dialogs.dart';
import '../widgets/change_password_sheet.dart';
import '../widgets/settings_row.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).user;
    final mode = ref.watch(themeModeProvider);
    final p = context.palette;
    final text = Theme.of(context).textTheme;

    if (user == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.xxl),
            children: [
              Text('Profile', style: text.displayMedium),
              const SizedBox(height: AppSpacing.xxl),

              Text('ACCOUNT',
                  style: AppTypography.mono(color: p.muted, size: 11)),
              const SizedBox(height: AppSpacing.sm),
              SettingsRow(label: 'Name', value: user.name),
              SettingsRow(label: 'Email', value: user.email),
              if (user.isAdmin)
                SettingsRow(
                  label: 'Role',
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: p.turmeric),
                      borderRadius: BorderRadius.circular(AppRadii.sm),
                    ),
                    child: Text(
                      'ADMIN',
                      style: AppTypography.mono(
                        color: p.turmericText,
                        size: 10,
                      ),
                    ),
                  ),
                ),
              SettingsRow(
                label: 'Password',
                value: 'Change',
                onTap: () async {
                  final changed = await showChangePasswordSheet(context);
                  if (changed && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Password changed.')),
                    );
                  }
                },
              ),

              const SizedBox(height: AppSpacing.xxxl),
              Text('APPEARANCE',
                  style: AppTypography.mono(color: p.muted, size: 11)),
              const SizedBox(height: AppSpacing.sm),
              SettingsRow(
                label: 'Theme',
                trailing: _ThemePicker(
                  mode: mode,
                  onChanged: (m) =>
                      ref.read(themeModeProvider.notifier).set(m),
                ),
              ),

              const SizedBox(height: AppSpacing.xxxl),
              Text('YOUR DATA',
                  style: AppTypography.mono(color: p.muted, size: 11)),
              const SizedBox(height: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: p.hair)),
                ),
                // Said plainly rather than buried in a policy nobody reads.
                child: Text(
                  'Your profile, conversations, plans and weight history are '
                  'stored on the machine running NutriAI. When you use the '
                  'coach or build a plan, the details relevant to that '
                  'question are sent to the AI provider. Your name and email '
                  'are never sent.',
                  style: text.bodySmall,
                ),
              ),

              const SizedBox(height: AppSpacing.xxxl),
              Text('ACCOUNT ACTIONS',
                  style: AppTypography.mono(color: p.muted, size: 11)),
              const SizedBox(height: AppSpacing.sm),
              SettingsRow(
                label: 'Sign out',
                onTap: () =>
                    ref.read(authControllerProvider.notifier).logout(),
              ),
              SettingsRow(
                label: 'Deactivate account',
                destructive: true,
                onTap: () => confirmDeactivate(context, ref),
              ),
              SettingsRow(
                label: 'Delete account',
                destructive: true,
                onTap: () => confirmDelete(context, ref),
              ),

              const SizedBox(height: AppSpacing.xxxl),
              Text(
                'NutriAI — general nutrition and wellness guidance. Not a '
                'medical device, and no substitute for a doctor or a '
                'registered dietitian.',
                style: text.bodySmall,
              ),
              const SizedBox(height: AppSpacing.huge),
            ],
          ),
        ),
      ),
    );
  }
}

/// Three-state theme control. System is the default and stays available,
/// rather than forcing a choice between only light and dark.
class _ThemePicker extends StatelessWidget {
  const _ThemePicker({required this.mode, required this.onChanged});

  final ThemeMode mode;
  final ValueChanged<ThemeMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: p.hair),
        borderRadius: BorderRadius.circular(AppRadii.sm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _segment(context, 'System', ThemeMode.system),
          Container(width: 1, height: 28, color: p.hair),
          _segment(context, 'Light', ThemeMode.light),
          Container(width: 1, height: 28, color: p.hair),
          _segment(context, 'Dark', ThemeMode.dark),
        ],
      ),
    );
  }

  Widget _segment(BuildContext context, String label, ThemeMode value) {
    final p = context.palette;
    final selected = mode == value;

    return InkWell(
      onTap: () => onChanged(value),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        color: selected ? p.ink : Colors.transparent,
        child: Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: selected ? p.paper : p.char,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              ),
        ),
      ),
    );
  }
}