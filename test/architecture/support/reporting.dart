import 'package:test/test.dart';

import 'violation.dart';

/// The report lines for [violations]: one `<path>:<line> <check id> <detail>`
/// per violation, sorted by path, line and id, every violation kept (FR-004,
/// FR-011).
///
/// Throws [ArgumentError] for a violation that cannot be one line: an empty
/// field, a line below 1, or a line break in a field. That is a defect in the
/// check, not a finding.
List<String> violationLines(Iterable<Violation> violations) {
  final list = violations.toList();
  for (final v in list) {
    _requireReportable(v);
  }
  return [for (final v in sortedViolations(list)) v.toString()];
}

void _requireReportable(Violation v) {
  void bad(String why) =>
      throw ArgumentError.value(v.toString(), 'violation', why);
  if (v.checkId.isEmpty || v.path.isEmpty || v.detail.isEmpty) {
    bad('check id, path and detail must not be empty');
  }
  if (v.line < 1) bad('line must be 1 or more');
  final fields = '${v.checkId}${v.path}${v.detail}';
  if (fields.contains('\n') || fields.contains('\r')) {
    bad('a field must not contain a line break');
  }
}

/// The failure text for [violations]: a count line, then [violationLines].
String violationReport(Iterable<Violation> violations) {
  final lines = violationLines(violations);
  return '${lines.length} architecture violation(s):\n${lines.join('\n')}';
}

/// Fails the running test, printing every violation per FR-004, when
/// [violations] is not empty (FR-059). Passes silently otherwise.
void expectNoViolations(Iterable<Violation> violations) {
  final list = violations.toList();
  if (list.isEmpty) return;
  fail(violationReport(list));
}
