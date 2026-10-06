import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ide/features/factory/factory_models.dart';

/// The answers below were taken from a simulated Runner (`EMBER_FACTORY_SIMULATE=1`)
/// running a batch of twelve apps. They prove the screens read what the real
/// Runner sends, not only what the tests invent.
Map<String, dynamic> _fixture(String name) =>
    jsonDecode(File('test/fixtures/$name.json').readAsStringSync()) as Map<String, dynamic>;

void main() {
  final state = FactoryData.fromJson(_fixture('factory_state'));

  test('the state: every app, with all its stages and a known engine', () {
    expect(state.apps, isNotEmpty);
    expect(state.rev, greaterThan(0));
    expect(state.simulated, isTrue);
    for (final a in state.apps) {
      expect(a.id, isNotEmpty);
      expect(a.name, isNotEmpty, reason: a.id);
      expect(factoryEngines, contains(a.engine), reason: a.name);
      for (final s in factoryStages) {
        expect(a.stages.containsKey(s), isTrue, reason: '${a.name} lacks the $s stage');
      }
    }
  });

  test('the summary adds up to the apps', () {
    final s = state.summary;
    expect(s.total, state.apps.length);
    expect(s.queued + s.running + s.needsYou + s.done + s.failed + s.cancelled, s.total);
    expect(s.progress, inInclusiveRange(0, 1));
  });

  test('the upload limits are per store and have a moment when they start over', () {
    expect(state.uploads.capPlay, greaterThan(0));
    expect(state.uploads.capAppstore, greaterThan(0));
    expect(state.uploads.resetsAt, isNotNull);
    expect(state.settings.dailyPlayCap, state.uploads.capPlay);
    expect(state.settings.maxInFlight, greaterThan(0));
  });

  test('the batch knows how far it goes', () {
    expect(state.batches, hasLength(greaterThan(0)));
    expect(state.batches.last.goal, Goal.ios);
    expect(state.batches.last.appIds, isNotEmpty);
  });

  test('what needs the owner is something we know how to say', () {
    const known = {'play_console_app', 'apple_app_record', 'mac', 'play_key', 'apple_key', 'login', 'other'};
    for (final n in state.needs) {
      expect(known, contains(n.kind));
      expect(n.id, isNotEmpty);
      expect(n.appId, isNotEmpty);
      expect(factoryStages, contains(n.stage));
    }
  });

  test('the supervisor’s plan', () {
    final plan = PlanResult.fromJson(_fixture('factory_plan'));
    expect(plan.proposals, isNotEmpty);
    for (final p in plan.proposals) {
      expect(p.name, isNotEmpty);
      expect(p.summary, isNotEmpty);
      expect(['small', 'big'], contains(p.size));
    }
    expect(plan.source, isNotEmpty);
    for (final d in plan.dropped) {
      expect(['duplicate_name', 'similar_idea', 'too_many'], contains(d.reason));
    }
  });

  test('the connections', () {
    final c = FactoryConnections.fromJson(_fixture('factory_connections'));
    for (final id in const [
      'claude',
      'qwen',
      'gemini',
      'codex',
      'flutter',
      'android',
      'chrome',
      'playKey',
      'appleKey',
      'mac',
    ]) {
      expect(c.links.any((l) => l.id == id), isTrue, reason: 'no $id');
    }
    expect(c.cpus, greaterThan(0));
    expect(c.agentSlots, greaterThan(0));
  });
}
