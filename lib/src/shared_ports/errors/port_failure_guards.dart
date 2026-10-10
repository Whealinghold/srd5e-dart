import 'srd5e_exception.dart';

/// Runs [body] and converts a failure of the backend behind a port into the
/// port's typed [Srd5eException].
///
/// Adapters for synchronous ports (such as a dice roller) wrap the call that
/// can fail:
///
/// * a value returned by [body] is returned unchanged and [wrap] is not
///   called;
/// * an [Exception] that is not an [Srd5eException] is passed to [wrap], with
///   its stack trace, and the object [wrap] returns is thrown with that same
///   stack trace, so the wrapper's trace points at the underlying failure;
/// * an [Srd5eException] is rethrown as the same instance, so a failure is
///   never wrapped twice;
/// * an [Error] (for example an [ArgumentError] or [StateError]) and any other
///   object that is not an [Exception] propagate unchanged and [wrap] is not
///   called. This is a documented limitation, not a guarantee that every
///   backend failure is typed;
/// * if [wrap] itself throws, that error propagates and [wrap] is not called
///   again.
///
/// Do not pass a body that returns a [Future]: its failure arrives later and
/// would not be wrapped. Use [wrapPortFailureAsync] for that.
T wrapPortFailure<T>(
  T Function() body,
  Srd5eException Function(Object cause, StackTrace stackTrace) wrap,
) {
  try {
    return body();
  } on Srd5eException {
    rethrow;
  } on Exception catch (cause, stackTrace) {
    Error.throwWithStackTrace(wrap(cause, stackTrace), stackTrace);
  }
}

/// Runs [body] and converts a failure of the backend behind an asynchronous
/// port into the port's typed [Srd5eException].
///
/// It follows the rules of [wrapPortFailure], with one addition: it never
/// throws synchronously. Every outcome other than a value is a failed future,
/// whether [body] threw before returning a future or the future it returned
/// failed. The failed future carries the object [wrap] returned for a wrapped
/// [Exception], and the same instance for an [Srd5eException], an [Error] or
/// any other object.
Future<T> wrapPortFailureAsync<T>(
  Future<T> Function() body,
  Srd5eException Function(Object cause, StackTrace stackTrace) wrap,
) async {
  try {
    return await body();
  } on Srd5eException {
    rethrow;
  } on Exception catch (cause, stackTrace) {
    Error.throwWithStackTrace(wrap(cause, stackTrace), stackTrace);
  }
}
