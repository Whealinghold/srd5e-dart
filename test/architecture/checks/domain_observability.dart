import '../support/source_set.dart';
import '../support/violation.dart';
import 'domain_purity.dart';

/// Domain observability check FR-034 of
/// `doc/specs/architecture-guardrails.md` (section 4.3).
///
/// Every function is pure: it reads a [SourceSet] and returns [Violation]s.
/// It reads the lexer's code, so comments and string contents are ignored and
/// `${...}` interpolation is still examined (FR-008).

/// The CamelCase words that name an observability port (FR-034, FR-035).
const List<String> observabilityWords = [
  'Logger',
  'Tracer',
  'Meter',
  'Observability',
];

/// The lower-case variable names FR-034 refuses in a `domain/` file.
const Set<String> observabilityVariableNames = {
  'logger',
  'tracer',
  'meter',
  'observability',
};

final RegExp _identifier = RegExp(r'[A-Za-z_$][\w$]*');

/// Whether [identifier] is, or ends in a CamelCase word, `Logger`, `Tracer`,
/// `Meter` or `Observability`. `NoopLogger` and `MyMeter` match; `Parameter`
/// and `Loggers` do not.
bool endsInObservabilityWord(String identifier) =>
    observabilityWords.any(identifier.endsWith);

/// Whether [identifier] is a variable named `logger`, `tracer`, `meter` or
/// `observability` (leading underscores ignored).
bool isObservabilityVariableName(String identifier) =>
    observabilityVariableNames.contains(
      identifier.replaceFirst(RegExp('^_+'), ''),
    );

/// FR-034: a `domain/` file does not mention an identifier that is, or ends in
/// a CamelCase word, `Logger`, `Tracer`, `Meter` or `Observability`, nor a
/// variable named `logger`, `tracer`, `meter` or `observability`.
List<Violation> checkDomainHasNoObservability(SourceSet sources) {
  const id = 'FR-034';
  final violations = <Violation>[];
  for (final path in sources.dartPaths('lib/src/').where(isDomainFile)) {
    final lexed = sources.lexed(path);
    final seen = <String>{};
    for (final match in _identifier.allMatches(lexed.code)) {
      final name = match.group(0)!;
      if (!endsInObservabilityWord(name) &&
          !isObservabilityVariableName(name)) {
        continue;
      }
      final line = lexed.lineOf(match.start);
      if (!seen.add('$line:$name')) continue;
      violations.add(
        Violation(
          checkId: id,
          path: path,
          line: line,
          detail:
              'a domain file mentions $name; telemetry is produced in the '
              'application layer, never in the domain',
        ),
      );
    }
  }
  return sortedViolations(violations);
}

/// The check function per id, for the registry (`registry.dart`).
const Map<String, List<Violation> Function(SourceSet)>
domainObservabilityChecks = {'FR-034': checkDomainHasNoObservability};

/// One minimal violating fixture per check id; the registry merges this map
/// into its own (`registry.dart`, FR-005).
final Map<String, SourceSet Function()> domainObservabilityViolatingFixtures = {
  'FR-034': () => SourceSet({
    'lib/src/d20_test/domain/a.dart': 'void f(Logger logger) {}\n',
  }),
};
