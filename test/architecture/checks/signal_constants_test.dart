import 'package:test/test.dart';

import '../support/real_repository.dart';
import '../support/signal_constants.dart';
import '../support/source_set.dart';
import '../support/violation.dart';
import 'signal_constants.dart';

/// The repository, loaded once per test file and never mutated.
final SourceSet _repository = realRepository;

const Timeout _budget = Timeout(Duration(seconds: 10));

void _expectNone(List<Violation> violations) {
  expect(violations, isEmpty, reason: '\n${formatViolations(violations)}');
}

void main() {
  /// Requirement: doc/specs/architecture-guardrails.md FR-012, FR-037 - a
  ///   check must not pass vacuously: the real run finds the AttributeKeys
  ///   constants file, which is the one signals class that exists today.
  /// Path: unhappy (empty and minimal)
  test('the real repository declares AttributeKeys in a constants file', () {
    final index = SignalIndex.of(_repository);

    expect(index.constantsFiles, contains('lib/src/shared_ports/signals.dart'));
    expect(index.classes.map((c) => c.name), contains(attributeKeysClassName));
  }, timeout: _budget);

  /// Requirement: doc/specs/architecture-guardrails.md FR-036, FR-072 - a
  ///   srd5e. or reserved-key literal under lib/ sits only in a constants
  ///   file (observability.md section 10, bullet 5).
  /// Path: happy
  test(
    'FR-036: signal and attribute names are spelled only in constants files',
    () => _expectNone(checkSignalLiteralsOnlyInConstantsFiles(_repository)),
    timeout: _budget,
  );

  /// Requirement: doc/specs/architecture-guardrails.md FR-037 - signals
  ///   classes are abstract final classes of plain static const String
  ///   members with kind suffixes, in constants files.
  /// Path: happy
  test(
    'FR-037: signals classes have the documented shape',
    () => _expectNone(checkSignalsClassShape(_repository)),
    timeout: _budget,
  );

  /// Requirement: doc/specs/architecture-guardrails.md FR-038 - metric, span
  ///   and log event constants have the documented value shape.
  /// Path: happy
  test(
    'FR-038: signal names have the documented shape',
    () => _expectNone(checkSignalNameShape(_repository)),
    timeout: _budget,
  );

  /// Requirement: doc/specs/architecture-guardrails.md FR-039 - attribute
  ///   keys are srd5e.-prefixed lowercase dotted names or reserved keys.
  /// Path: happy
  test(
    'FR-039: attribute keys have the documented shape',
    () => _expectNone(checkAttributeNameShape(_repository)),
    timeout: _budget,
  );

  /// Requirement: doc/specs/architecture-guardrails.md FR-040 - no two signal
  ///   constants in lib/ share a value (observability.md section 10, bullet
  ///   6).
  /// Path: happy
  test(
    'FR-040: signal values are unique',
    () => _expectNone(checkSignalValuesUnique(_repository)),
    timeout: _budget,
  );
}
