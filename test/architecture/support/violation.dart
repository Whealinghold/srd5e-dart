/// One finding of an architecture check: which check, where, and what.
final class Violation implements Comparable<Violation> {
  /// Creates a violation of [checkId] at [path]:[line] described by [detail].
  const Violation({
    required this.checkId,
    required this.path,
    required this.line,
    required this.detail,
  });

  /// The id of the check that found it, for example `E4` or `FR-053`.
  final String checkId;

  /// The repository-relative path with `/` separators.
  final String path;

  /// The 1-based line, or 1 for a file-level finding.
  final int line;

  /// What is wrong, as data a developer can act on.
  final String detail;

  @override
  int compareTo(Violation other) {
    final byPath = path.compareTo(other.path);
    if (byPath != 0) return byPath;
    final byLine = line.compareTo(other.line);
    if (byLine != 0) return byLine;
    final byId = checkId.compareTo(other.checkId);
    if (byId != 0) return byId;
    return detail.compareTo(other.detail);
  }

  @override
  bool operator ==(Object other) =>
      other is Violation &&
      other.checkId == checkId &&
      other.path == path &&
      other.line == line &&
      other.detail == detail;

  @override
  int get hashCode => Object.hash(checkId, path, line, detail);

  /// The report line: `<path>:<line> <check id> <detail>`.
  @override
  String toString() => '$path:$line $checkId $detail';
}

/// Sorts [violations] by path, line and check id, so output is deterministic.
List<Violation> sortedViolations(Iterable<Violation> violations) =>
    violations.toList()..sort();

/// Formats [violations] one per line, as failing tests print them.
String formatViolations(Iterable<Violation> violations) =>
    sortedViolations(violations).join('\n');
