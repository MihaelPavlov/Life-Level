import '../services/client_experience_service.dart';

/// Runs one optimistic mutation at a time for a provider-owned state value.
/// Success reconciles with the server response; failure restores the snapshot.
class OptimisticMutationController<T> {
  bool _pending = false;

  bool get isPending => _pending;

  Future<R> run<R>({
    required T current,
    required T Function(T current) optimistic,
    required Future<R> Function() request,
    required T Function(T optimisticState, R result) reconcile,
    required void Function(T state) publish,
    String? feature,
    String? action,
  }) async {
    if (_pending) throw StateError('An action is already in progress.');
    _pending = true;
    final snapshot = current;
    final predicted = optimistic(current);
    final started = DateTime.now();
    publish(predicted);
    if (feature != null && action != null) {
      ClientExperienceService.instance.record(
        name: 'optimistic_applied',
        feature: feature,
        outcome: action,
        durationMs: 0,
      );
    }
    try {
      final result = await request();
      publish(reconcile(predicted, result));
      if (feature != null && action != null) {
        ClientExperienceService.instance.record(
          name: 'mutation_confirmed',
          feature: feature,
          outcome: action,
          durationMs: DateTime.now().difference(started).inMilliseconds,
        );
      }
      return result;
    } catch (_) {
      publish(snapshot);
      if (feature != null && action != null) {
        ClientExperienceService.instance.record(
          name: 'mutation_rolled_back',
          feature: feature,
          outcome: action,
          durationMs: DateTime.now().difference(started).inMilliseconds,
        );
      }
      rethrow;
    } finally {
      _pending = false;
    }
  }
}
