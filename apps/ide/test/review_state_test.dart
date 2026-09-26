import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ide/features/review/review_state.dart';

Map<String, dynamic> finding(String title) => {'title': title, 'detail': 'x', 'ask': 'fix $title'};

void main() {
  late ProviderContainer c;
  ReviewStates get() => c.read(reviewStatesProvider.notifier);

  setUp(() => c = ProviderContainer());
  tearDown(() => c.dispose());

  test('findings survive being sent to be fixed', () {
    get().found('p1', [finding('A'), finding('B')], const []);
    get().startFixing('p1', 'A');

    // The whole list is still there while one of them is being fixed — this is
    // what vanished before, taking the user's place in the queue with it.
    expect(get().of('p1').findings, hasLength(2));
    expect(get().of('p1').fixing, {'A'});

    get().doneFixing('p1', 'A');
    expect(get().of('p1').findings, hasLength(2), reason: 'a fixed finding stays, marked done');
    expect(get().of('p1').fixed, {'A'});
    expect(get().of('p1').fixing, isEmpty);
    expect(get().of('p1').remaining, 1);
  });

  test('a fix that fails leaves the finding to do', () {
    get().found('p1', [finding('A')], const []);
    get().startFixing('p1', 'A');
    get().failedFixing('p1', 'A');

    expect(get().of('p1').fixed, isEmpty);
    expect(get().of('p1').fixing, isEmpty);
    expect(get().of('p1').remaining, 1);
  });

  test('all fixed is only true once every one has been', () {
    get().found('p1', [finding('A'), finding('B')], const []);
    expect(get().of('p1').allFixed, isFalse);
    get().doneFixing('p1', 'A');
    expect(get().of('p1').allFixed, isFalse);
    get().doneFixing('p1', 'B');
    expect(get().of('p1').allFixed, isTrue);
  });

  test('two projects keep their own lists', () {
    get().found('p1', [finding('A')], const []);
    get().found('p2', [finding('B'), finding('C')], const []);
    get().doneFixing('p1', 'A');

    expect(get().of('p2').findings, hasLength(2));
    expect(get().of('p2').fixed, isEmpty, reason: 'fixing one app must not mark another done');
  });

  test('a fresh review starts the list over', () {
    get().found('p1', [finding('A')], const []);
    get().doneFixing('p1', 'A');
    get().found('p1', [finding('Z')], const []);

    expect(get().of('p1').findings.single['title'], 'Z');
    expect(get().of('p1').fixed, isEmpty, reason: 'what was fixed before is not fixed in the new list');
  });
}
