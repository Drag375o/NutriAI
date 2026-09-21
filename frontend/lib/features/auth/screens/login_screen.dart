import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/colors.dart';
import '../../../app/theme/spacing.dart';
import '../state/auth_controller.dart';
import '../widgets/auth_scaffold.dart';
import 'package:go_router/go_router.dart';


class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _name = TextEditingController();
  final _password = TextEditingController();

  bool _registering = false;
  bool _obscure = true;
  bool _busy = false;

  @override
  void dispose() {
    _email.dispose();
    _name.dispose();
    _password.dispose();
    super.dispose();
  }


  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _busy = true);
    final auth = ref.read(authControllerProvider.notifier);

    final ok = _registering
        ? await auth.register(
            _email.text.trim(), _name.text.trim(), _password.text)
        : await auth.login(_email.text.trim(), _password.text);

    if (mounted) setState(() => _busy = false);
    if (!mounted) return;

    // A new account has nothing in its profile, so it goes straight to
    // onboarding. Handled here rather than in the router's redirect: the
    // router would have to watch profile state, and a profile save landing
    // mid-frame rebuilds it underneath the screen that triggered it.
    if (ok && _registering) {
      context.go('/onboarding');
      return;
    }

    // On a successful sign-in the router redirects; nothing to do here.
    if (!ok) FocusScope.of(context).unfocus();
  }




  /// Offered when the credentials were correct but the account is paused.
  /// Restoring is an explicit choice rather than a side effect of signing
  /// in, so nobody reactivates an account they meant to leave closed.
  Future<void> _offerReactivation() async {
    final p = context.palette;

    final restore = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: p.paper,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: p.hair),
          borderRadius: BorderRadius.circular(AppRadii.md),
        ),
        title: Text(
          'This account is deactivated',
          style: TextStyle(
            color: p.ink,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'Would you like to restore it and sign in?',
          style: TextStyle(color: p.char, fontSize: 15, height: 1.5),
        ),
        actions: [
          TextButton(
            style: TextButton.styleFrom(foregroundColor: p.char),
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Not now'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: p.emberText),
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Restore my account',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );

    if (restore != true || !mounted) return;

    setState(() => _busy = true);
    await ref.read(authControllerProvider.notifier).reactivate(
          _email.text.trim(),
          _password.text,
        );
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final error = ref.watch(authControllerProvider).error;

    // A paused account is offered restoration rather than shown an error.
    ref.listen(authControllerProvider, (previous, next) {
      if (next.deactivated && !(previous?.deactivated ?? false)) {
        _offerReactivation();
      }
    });

    return AuthScaffold(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text.rich(
              TextSpan(
                children: [
                  const TextSpan(text: 'Nutri'),
                  TextSpan(
                    text: 'AI',
                    style: TextStyle(
                      color: p.turmericText,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              style: text.headlineMedium,
            ),
            const SizedBox(height: AppSpacing.xxxl),

            Text(
              _registering ? 'Create your account' : 'Welcome back',
              style: text.displayMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              _registering
                  ? 'A few details now, and NutriAI can start tailoring its advice to you.'
                  : 'Sign in to pick up where you left off.',
              style: text.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.xxl),

            TextFormField(
              controller: _email,
              decoration: const InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              textInputAction: TextInputAction.next,
              style: text.bodyLarge,
              validator: (v) {
                final value = v?.trim() ?? '';
                if (value.isEmpty) return 'Enter your email address.';
                if (!value.contains('@') || !value.contains('.')) {
                  return 'That does not look like an email address.';
                }
                return null;
              },
            ),

            if (_registering) ...[
              const SizedBox(height: AppSpacing.lg),
              TextFormField(
                controller: _name,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  hintText: 'What should NutriAI call you?',
                ),
                textInputAction: TextInputAction.next,
                style: text.bodyLarge,
                validator: (v) =>
                    (v?.trim().isEmpty ?? true) ? 'Enter your name.' : null,
              ),
            ],

            const SizedBox(height: AppSpacing.lg),
            TextFormField(
              controller: _password,
              obscureText: _obscure,
              decoration: InputDecoration(
                labelText: 'Password',
                helperText: _registering ? 'At least 8 characters.' : null,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscure
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    size: 20,
                    color: p.muted,
                  ),
                  tooltip: _obscure ? 'Show password' : 'Hide password',
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _submit(),
              style: text.bodyLarge,
              validator: (v) {
                final value = v ?? '';
                if (value.isEmpty) return 'Enter your password.';
                if (_registering && value.length < 8) {
                  return 'Use at least 8 characters.';
                }
                return null;
              },
            ),

            if (error != null) ...[
              const SizedBox(height: AppSpacing.lg),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  border: Border(left: BorderSide(color: p.brick, width: 2)),
                  color: p.linen,
                ),
                child: Text(
                  error,
                  style: text.bodyMedium?.copyWith(color: p.ink),
                ),
              ),
            ],

            const SizedBox(height: AppSpacing.xl),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _busy ? null : _submit,
                child: _busy
                    ? SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: p.onAccent,
                        ),
                      )
                    : Text(_registering ? 'Create account' : 'Sign in'),
              ),
            ),

            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Text(
                  _registering ? 'Already have an account?' : 'New to NutriAI?',
                  style: text.bodySmall,
                ),
                TextButton(
                  onPressed: _busy
                      ? null
                      : () => setState(() {
                            _registering = !_registering;
                            _formKey.currentState?.reset();
                          }),
                  child: Text(_registering ? 'Sign in' : 'Create an account'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}