import 'package:flutter_test/flutter_test.dart';
import 'package:ide/features/projects/build_watch.dart';

void main() {
  test('a project being written says how far it has got', () {
    const known = BuildState(building: true, files: 3, plannedFiles: 32);
    expect(known.progress, '3/32');
    // Before the engine says how many files it plans, only the count is known.
    const unknown = BuildState(building: true, files: 7);
    expect(unknown.progress, '7');
    // A plan of zero is not a plan.
    expect(const BuildState(building: true, files: 2, plannedFiles: 0).progress, '2');
  });

  test('waiting on the user is its own state, separate from building', () {
    const working = BuildState(building: true, files: 4);
    expect(working.waiting, isFalse);

    const stuck = BuildState(building: true, files: 4, needsYou: ['Log in to Firebase']);
    expect(stuck.waiting, isTrue, reason: 'this is what the yellow mark is for');
    expect(stuck.building, isTrue, reason: 'it is still a running build, just blocked');

    // A finished project waiting on nothing shows neither.
    const done = BuildState(building: false);
    expect(done.waiting, isFalse);
    expect(done.building, isFalse);
  });
}
