import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ide/features/ai/ai_settings.dart';
import 'package:ide/features/create/access_links.dart';
import 'package:ide/features/create/app_builder.dart';
import 'package:ide/features/create/engines.dart';
import 'package:ide/features/create/subscription_login.dart';
import 'package:ide/l10n/app_localizations.dart';

/// Qwen Code is the fourth subscription engine, next to Claude Code, Codex and Gemini CLI.
void main() {
  test('it is a subscription engine the Runner knows by name', () {
    expect(BuildEngine.qwenCode.cli, 'qwen-code');
    expect(BuildEngine.qwenCode.isCli, isTrue);
    expect(BuildEngine.qwenCode.cliLabel, 'Qwen Code');
    expect(subscriptionEngines, contains(BuildEngine.qwenCode));
  });

  test('it counts as connected when the Runner says so', () {
    expect(
      subscriptionConnected({
        'engines': {'qwenCode': true},
      }, BuildEngine.qwenCode),
      isTrue,
    );
    expect(
      subscriptionConnected({
        'engines': {'qwenCode': false},
      }, BuildEngine.qwenCode),
      isFalse,
    );
    expect(subscriptionConnected(const {}, BuildEngine.qwenCode), isFalse);
    // Another engine being ready does not light it up.
    expect(
      subscriptionConnected({
        'engines': {'codex': true},
      }, BuildEngine.qwenCode),
      isFalse,
    );
  });

  test('it tells where the plan is and how to sign in', () {
    final access = engineAccess[BuildEngine.qwenCode]!;
    expect(access.plan, 'https://qwen.ai');
    expect(access.connectCommand, contains('qwen'));
    expect(access.connectCommand, contains('/auth'));
    // The paid Qwen through OpenRouter points at the subscription one.
    expect(AccessLinks.subscriptionOf[BuildEngine.qwen], BuildEngine.qwenCode);
  });

  test('it is offered with the other subscriptions, usable only when connected', () {
    final l = lookupAppLocalizations(const Locale('en'));
    EngineOption option(Map<String, dynamic> health) =>
        engineOptions(l, const AiSettings(), false, health: health).firstWhere((o) => o.engine == BuildEngine.qwenCode);
    expect(
      option({
        'engines': {'qwenCode': true},
      }).available,
      isTrue,
    );
    final off = option(const {});
    expect(off.available, isFalse);
    expect(off.badge, l.badgeSubscription);
    expect(off.reason, l.subscriptionNotConnected('Qwen Code'));
  });
}
