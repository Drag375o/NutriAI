import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/colors.dart';
import '../../../app/theme/spacing.dart';
import '../../../app/theme/typography.dart';
import '../state/auth_controller.dart';
import '../widgets/auth_scaffold.dart';

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
        ? await auth.register(_email.text.trim(), _name.text.trim(), _password.text)
        : await auth.login(_email.text.trim(), _password.text);

    if (mounted) setState(() => _busy = false);
    // On success the router redirects; nothing to do here.
    if (!ok && mounted) FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final error = ref.watch(authControllerProvider).error;

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
                    _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
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