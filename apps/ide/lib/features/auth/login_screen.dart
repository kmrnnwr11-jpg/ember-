import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/env.dart';
import '../../core/locale.dart';
import '../../core/session.dart';
import '../../l10n/app_localizations.dart';
import '../../ui/ui.dart';
import '../../widgets/ember_logo.dart';

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

  /// The Runner address is right for almost everyone: it stays folded away.
  bool _advanced = false;

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

  bool get _runnerValid {
    final u = Uri.tryParse(_runner.text.trim());
    return u != null && (u.scheme == 'http' || u.scheme == 'https') && u.host.isNotEmpty;
  }

  Future<void> _submit({bool signUp = false}) async {
    // A wrong address must be seen to be corrected.
    if (!_runnerValid && !_advanced) setState(() => _advanced = true);
    if (!_form.currentState!.validate() || !_runnerValid) return;
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

    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.transparent, actions: const [LanguageButton(), Gap.hSm]),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(Gap.xl),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: Widths.form),
            child: Form(
              key: _form,
              child: AutofillGroup(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Center(child: ExcludeSemantics(child: EmberMark(size: 96))),
                    Gap.vMd,
                    const Center(child: EmberWordmark(size: 34, center: true)),
                    Gap.vSm,
                    Text(l.loginSubtitle, textAlign: TextAlign.center, style: context.text.bodyMedium?.copyWith(color: context.scheme.onSurfaceVariant)),
                    // Ember signs in by itself when it can reach its computer:
                    // being here without an account system means it could not.
                    if (!Env.supabaseEnabled && !busy) ...[
                      Gap.vLg,
                      SectionCard(
                        icon: Icons.power_settings_new,
                        title: l.offlineTitle,
                        hint: l.offlineHint,
                        tone: Tone.attention,
                        margin: EdgeInsets.zero,
                        children: [
                          Gap.vMd,
                          Align(
                            alignment: AlignmentDirectional.centerStart,
                            child: FilledButton.icon(key: const Key('retryConnect'), onPressed: () => ref.invalidate(sessionProvider), icon: const Icon(Icons.refresh), label: Text(l.retry)),
                          ),
                        ],
                      ),
                    ],
                    Gap.vXl,
                    TextFormField(
                      key: const Key('email'),
                      controller: _email,
                      decoration: InputDecoration(labelText: l.email, prefixIcon: const Icon(Icons.mail_outline)),
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      validator: (v) => v != null && RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v.trim()) ? null : l.invalidEmail,
                      onFieldSubmitted: Env.supabaseEnabled ? null : (_) => _submit(),
                    ),
                    if (Env.supabaseEnabled) ...[
                      Gap.vMd,
                      TextFormField(
                        controller: _password,
                        obscureText: true,
                        decoration: InputDecoration(labelText: l.password, prefixIcon: const Icon(Icons.lock_outline)),
                        autofillHints: const [AutofillHints.password],
                        validator: (v) => (v ?? '').length >= 6 ? null : l.passwordTooShort,
                        onFieldSubmitted: (_) => _submit(),
                      ),
                    ],
                    if (session.hasError) ...[
                      Gap.vMd,
                      InlineMessage(l.error(session.error.toString()), error: true),
                    ],
                    Gap.vXl,
                    FilledButton(
                      key: const Key('signIn'),
                      onPressed: busy ? null : _submit,
                      child: busy ? const SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2)) : Text(l.signIn),
                    ),
                    if (Env.supabaseEnabled) TextButton(onPressed: busy ? null : () => _submit(signUp: true), child: Text(l.signUp)),
                    Gap.vSm,
                    Center(
                      child: TextButton.icon(
                        key: const Key('loginAdvanced'),
                        onPressed: () => setState(() => _advanced = !_advanced),
                        icon: Icon(_advanced ? Icons.expand_less : Icons.expand_more, size: 18),
                        label: Text(l.advanced),
                        style: TextButton.styleFrom(foregroundColor: context.scheme.onSurfaceVariant),
                      ),
                    ),
                    AnimatedSize(
                      duration: Motion.of(context),
                      curve: Motion.curve,
                      alignment: Alignment.topCenter,
                      child: !_advanced
                          ? const SizedBox(width: double.infinity)
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Gap.vSm,
                                TextFormField(
                                  key: const Key('runnerUrl'),
                                  controller: _runner,
                                  decoration: InputDecoration(labelText: l.runnerAddress, helperText: l.runnerAddressHint, helperMaxLines: 3, prefixIcon: const Icon(Icons.dns_outlined)),
                                  keyboardType: TextInputType.url,
                                  validator: (_) => _runnerValid ? null : l.runnerUrl,
                                ),
                                if (!Env.supabaseEnabled) ...[
                                  Gap.vMd,
                                  Text(l.devLoginHint, style: context.text.bodySmall),
                                ],
                              ],
                            ),
                    ),
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
