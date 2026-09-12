import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/env.dart';
import '../../core/session.dart';
import '../../l10n/app_localizations.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _runner = TextEditingController(text: Env.runnerUrl);

  @override
  void initState() {
    super.initState();
    ref.read(sessionProvider.notifier).savedRunnerUrl().then((u) {
      if (mounted) _runner.text = u;
    });
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _runner.dispose();
    super.dispose();
  }

  Future<void> _submit({bool signUp = false}) async {
    if (!_form.currentState!.validate()) return;
    await ref.read(sessionProvider.notifier).signIn(
      runnerUrl: _runner.text,
      email: _email.text.trim(),
      password: Env.supabaseEnabled ? _password.text : null,
      signUp: signUp,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final session = ref.watch(sessionProvider);
    final busy = session.isLoading;
    final theme = Theme.of(context);

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Form(
              key: _form,
              child: AutofillGroup(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(Icons.code, size: 56, color: theme.colorScheme.primary),
                    const SizedBox(height: 12),
                    Text(l.appTitle, textAlign: TextAlign.center, style: theme.textTheme.headlineMedium),
                    const SizedBox(height: 4),
                    Text(l.loginSubtitle, textAlign: TextAlign.center, style: theme.textTheme.bodyMedium),
                    const SizedBox(height: 32),
                    TextFormField(
                      key: const Key('email'),
                      controller: _email,
                      decoration: InputDecoration(labelText: l.email, prefixIcon: const Icon(Icons.mail_outline)),
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      validator: (v) => v != null && RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v.trim()) ? null : l.invalidEmail,
                    ),
                    if (Env.supabaseEnabled) ...[
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _password,
                        obscureText: true,
                        decoration: InputDecoration(labelText: l.password, prefixIcon: const Icon(Icons.lock_outline)),
                        autofillHints: const [AutofillHints.password],
                        validator: (v) => (v ?? '').length >= 6 ? null : l.passwordTooShort,
                        onFieldSubmitted: (_) => _submit(),
                      ),
                    ],
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _runner,
                      decoration: InputDecoration(labelText: l.runnerUrl, prefixIcon: const Icon(Icons.dns_outlined)),
                      keyboardType: TextInputType.url,
                      validator: (v) {
                        final u = Uri.tryParse(v?.trim() ?? '');
                        return u != null && (u.scheme == 'http' || u.scheme == 'https') && u.host.isNotEmpty ? null : l.runnerUrl;
                      },
                    ),
                    if (!Env.supabaseEnabled) ...[
                      const SizedBox(height: 12),
                      Text(l.devLoginHint, style: theme.textTheme.bodySmall),
                    ],
                    if (session.hasError) ...[
                      const SizedBox(height: 12),
                      Text(
                        l.error(session.error.toString()),
                        style: TextStyle(color: theme.colorScheme.error),
                      ),
                    ],
                    const SizedBox(height: 24),
                    FilledButton(
                      key: const Key('signIn'),
                      onPressed: busy ? null : _submit,
                      child: busy
                          ? const SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2))
                          : Text(l.signIn),
                    ),
                    if (Env.supabaseEnabled)
                      TextButton(onPressed: busy ? null : () => _submit(signUp: true), child: Text(l.signUp)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
