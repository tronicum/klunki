// KLD-109: stop the wait loops of a test that has already ended.
//
// flutter_test does not stop a test body that timed out: its pump/runAsync
// loop keeps going while the next test of the file runs, and the next test
// then fails with "Guarded function conflict" or "Reentrant call to
// runAsync() denied". One timeout (e.g. after the machine slept) so turned
// into three or four failures in a file. The polling helpers capture the
// test run when they start and throw once it is over; the error lands on
// the test that already failed, the next test runs alone.
import 'package:flutter_test/flutter_test.dart';

class _Run {
  bool over = false;
}

final _runs = Expando<_Run>('test run');

/// A check for the polling loops of [tester]'s current test: call it when a
/// loop starts, call the result on every round; it throws once that test
/// has ended (timed out or failed).
///
/// One `WidgetTester` serves every variant of a `testWidgets`, so the run is
/// tracked per test run, not per tester.
void Function() testRunGuard(WidgetTester tester) {
  var run = _runs[tester];
  if (run == null || run.over) {
    final fresh = run = _Run();
    _runs[tester] = fresh;
    addTearDown(() => fresh.over = true);
  }
  final mine = run;
  return () {
    if (mine.over) throw TestFailure('this test is over (timed out?): stopping its wait loop');
  };
}
