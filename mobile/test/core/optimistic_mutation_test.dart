import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:life_level/core/state/optimistic_mutation.dart';

void main() {
  test('publishes immediately and reconciles with the server result', () async {
    final gate = Completer<int>();
    final published = <int>[];
    final mutation = OptimisticMutationController<int>();

    final future = mutation.run(
      current: 10,
      optimistic: (value) => value + 5,
      request: () => gate.future,
      reconcile: (_, result) => result,
      publish: published.add,
    );

    expect(published, [15]);
    expect(mutation.isPending, isTrue);
    gate.complete(16);
    expect(await future, 16);
    expect(published, [15, 16]);
    expect(mutation.isPending, isFalse);
  });

  test('rolls back the exact snapshot when the request fails', () async {
    final published = <int>[];
    final mutation = OptimisticMutationController<int>();

    await expectLater(
      mutation.run<void>(
        current: 10,
        optimistic: (value) => value + 5,
        request: () => Future<void>.error(StateError('offline')),
        reconcile: (predicted, _) => predicted,
        publish: published.add,
      ),
      throwsStateError,
    );

    expect(published, [15, 10]);
    expect(mutation.isPending, isFalse);
  });

  test('rejects duplicate taps while a mutation is pending', () async {
    final gate = Completer<void>();
    final mutation = OptimisticMutationController<int>();
    final first = mutation.run<void>(
      current: 1,
      optimistic: (value) => value + 1,
      request: () => gate.future,
      reconcile: (predicted, _) => predicted,
      publish: (_) {},
    );

    await expectLater(
      mutation.run<void>(
        current: 2,
        optimistic: (value) => value,
        request: () async {},
        reconcile: (predicted, _) => predicted,
        publish: (_) {},
      ),
      throwsStateError,
    );
    gate.complete();
    await first;
  });
}
