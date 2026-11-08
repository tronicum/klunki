// KLD-121 follow-up: the shake detector behind "Schütteln zum Würfeln".
import 'package:flutter_test/flutter_test.dart';
import 'package:klunki/platform/shake.dart';

/// A reading of [g] (along z) at [ms].
AccelSample _s(double g, double ms) => AccelSample(0, 0, g, ms);

/// Feeds [samples]; how many shakes they made.
int _shakes(ShakeDetector d, List<AccelSample> samples) => samples.where(d.add).length;

/// One jolt at [ms]: a few readings above the threshold, then back to rest.
List<AccelSample> _jolt(double ms, {double g = 3}) => [_s(g, ms), _s(g + 0.4, ms + 20), _s(g, ms + 40), _s(1, ms + 60)];

void main() {
  test('a phone lying still or picked up is no shake', () {
    final d = ShakeDetector();
    expect(_shakes(d, [for (var t = 0.0; t < 3000; t += 20) _s(1, t)]), 0);
    // Picking it up: a swell to 1.6 g and back, twice.
    expect(_shakes(d, [_s(1.3, 3000), _s(1.6, 3020), _s(1.2, 3040), _s(1.6, 3200), _s(1, 3220)]), 0);
  });

  test('one jolt (put down hard) is no shake, however long it stays above', () {
    final d = ShakeDetector();
    expect(_shakes(d, _jolt(0)), 0);
    expect(_shakes(d, [for (var t = 1000.0; t < 1400; t += 20) _s(3, t)]), 0);
  });

  test('two jolts close together are one shake', () {
    final d = ShakeDetector();
    expect(_shakes(d, [..._jolt(0), ..._jolt(250)]), 1);
  });

  test('two jolts too far apart are no shake', () {
    final d = ShakeDetector();
    expect(ShakeDetector.window.inMilliseconds, lessThan(1200));
    expect(_shakes(d, [..._jolt(0), ..._jolt(1200)]), 0);
  });

  test('debounce: a long shaking counts once, the next shaking again', () {
    final d = ShakeDetector();
    final shaking = [for (var t = 0.0; t < 1400; t += 150) ..._jolt(t)];
    expect(_shakes(d, shaking), 1);
    final later = ShakeDetector.debounce.inMilliseconds + 1400.0;
    expect(_shakes(d, [..._jolt(later), ..._jolt(later + 200)]), 1);
  });

  test('the threshold is the total acceleration, any direction', () {
    final d = ShakeDetector();
    // 2.0 g along x and y each: 2.83 g in total.
    expect(_shakes(d, [const AccelSample(2, 2, 0, 0), _s(1, 30), const AccelSample(-2, 2, 0, 200), _s(1, 230)]), 1);
    expect(const AccelSample(0, 0, 2.1, 0).g, lessThan(ShakeDetector.thresholdG));
  });
}
