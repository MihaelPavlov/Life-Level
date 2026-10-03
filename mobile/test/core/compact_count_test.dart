import 'package:flutter_test/flutter_test.dart';
import 'package:life_level/core/utils/compact_count.dart';

void main() {
  test('compact count uses K, M, B and T without crossing thresholds early',
      () {
    expect(compactCount(999), '999');
    expect(compactCount(163750), '163.8K');
    expect(compactCount(999999), '1M');
    expect(compactCount(1250000), '1.3M');
    expect(compactCount(2500000000), '2.5B');
    expect(compactCount(1200000000000), '1.2T');
  });
}
