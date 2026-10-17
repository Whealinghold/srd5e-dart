import '../support/constants.dart'
    show DeniedName, affiliateDenylist, noticeCoveredPaths;
import '../support/source_set.dart';
import '../support/violation.dart';

/// The `CLN-` licensing checks over `NOTICE.md` of
/// `doc/specs/content-licensing-and-notice.md` (FR-001, FR-002, FR-004,
/// FR-005, FR-006, FR-007, FR-011, FR-012, FR-013, FR-015, FR-024 and
/// FR-035), with the mechanical normalisation of its section 3.
///
/// The checks are pure functions over a [SourceSet]. They are owned by the
/// licensing spec and are NOT registered in the guardrails registry
/// (`registry.dart`); their ids carry the `CLN-` prefix so Violations cannot
/// collide with guardrails ids. The check files for the other requirements:
/// `notice_files.dart` (FR-008, FR-017, FR-027 to FR-029, FR-036, FR-037) and
/// `notice_marks.dart` (FR-016, FR-018, FR-019, FR-038).

/// The attribution statement of SRD 5.2.1, "Legal Information", p. 1
/// (content-licensing-and-notice.md section 2), verbatim: same words,
/// punctuation and URLs, with the PDF's typographic quotes (U+201C, U+201D)
/// around `SRD 5.2.1`.
const String attributionStatement =
    'This work includes material from the '
    'System Reference Document 5.2.1 (\u201CSRD 5.2.1\u201D) by Wizards of '
    'the Coast LLC, available at https://www.dndbeyond.com/srd. The SRD 5.2.1 '
    'is licensed under the Creative Commons Attribution 4.0 International '
    'License, available at '
    'https://creativecommons.org/licenses/by/4.0/legalcode.';

/// The exact pointer sentence a covered directory's README may carry instead
/// of the statement (content-licensing-and-notice.md FR-027).
const String attributionPointer =
    'Attribution: see NOTICE.md in the package '
    'root.';

/// The first line of the FR-029 embed header (content-licensing-and-notice.md
/// FR-029; emitted by the generator).
const String embedHeaderLine1 =
    '// GENERATED from data/srd_5_2_1/. Contains SRD 5.2.1 content.';

/// The second line of the FR-029 embed header.
const String embedHeaderLine2 =
    '// Attribution: see NOTICE.md in the package root.';

/// The keyword-normalised phrase a non-endorsement sentence contains
/// (content-licensing-and-notice.md section 3, "non-endorsement sentence").
const String nonEndorsementPhrase =
    'not published, endorsed or approved by wizards of the coast';

/// The words a sentence counts as negated by (FR-007): `not` as a whole word
/// and a word ending in `n't`; `note`, `notice` and `cannot` do not count.
final RegExp negationPattern = RegExp(
  r"\bnot\b|[A-Za-z]n't\b",
  caseSensitive: false,
);

/// Every path [sources] records: text files, then the path-only lists of
/// binary and unreadable files (FR-002).
List<String> sourcePaths(SourceSet sources) =>
    [...sources.files.keys, ...sources.binaryPaths, ...sources.unreadable.keys]
      ..sort();

/// Whether bundled content is present (content-licensing-and-notice.md
/// section 3): at least one file under a covered path other than `.gitkeep`
/// and `README.md`. Fixture files alone count. The covered paths are the
/// guardrails' [noticeCoveredPaths] constant (FR-079), which this spec's
/// FR-005 defines.
bool bundledContentPresent(SourceSet sources) {
  for (final path in sourcePaths(sources)) {
    if (!noticeCoveredPaths.any(path.startsWith)) continue;
    final name = path.substring(path.lastIndexOf('/') + 1);
    if (name != '.gitkeep' && name != 'README.md') return true;
  }
  return false;
}

/// A Markdown text after the normalisation of content-licensing-and-notice.md
/// section 3: HTML comments and fenced code blocks removed, a leading `>` and
/// following spaces stripped per line, every run of Unicode whitespace
/// (including U+00A0) replaced by one ASCII space, trimmed.
///
/// [text] holds the normalised text (no line breaks remain). [lines] maps
/// every code unit of [text] to its 1-based line in the original file, and
/// [blankBreaks] holds the indices at which a blank line preceded, for the
/// sentence split of FR-007.
final class NormalisedDoc {
  NormalisedDoc._(this.text, this.lines, this.blankBreaks)
    : assert(text.length == lines.length);

  /// The normalised text.
  final String text;

  /// The original 1-based line of every code unit of [text].
  final List<int> lines;

  /// The indices at which a blank line preceded (FR-007 sentence boundary).
  final Set<int> blankBreaks;

  /// The original 1-based line of the code unit at [index].
  int lineAt(int index) {
    if (lines.isEmpty) return 1;
    final clamped = index < 0
        ? 0
        : (index >= lines.length ? lines.length - 1 : index);
    return lines[clamped];
  }

  /// The start indices of every occurrence of [needle], left to right,
  /// non-overlapping.
  List<int> occurrences(String needle) {
    final found = <int>[];
    var from = 0;
    while (true) {
      final at = text.indexOf(needle, from);
      if (at < 0) break;
      found.add(at);
      from = at + needle.length;
    }
    return found;
  }

  /// A copy of this document without the [ranges] (start, end) pairs, which
  /// are cut in order; overlapping ranges are ignored.
  NormalisedDoc withoutRanges(List<(int, int)> ranges) {
    if (ranges.isEmpty) return this;
    final ordered = [...ranges]..sort((a, b) => a.$1.compareTo(b.$1));
    final buffer = StringBuffer();
    final newLines = <int>[];
    final newBreaks = <int>{};
    var cursor = 0;
    void append(int from, int to) {
      for (var i = from; i < to; i++) {
        if (blankBreaks.contains(i)) newBreaks.add(newLines.length);
        newLines.add(lines[i]);
        buffer.write(text[i]);
      }
    }

    for (final (start, end) in ordered) {
      if (start < cursor) continue;
      append(cursor, start);
      cursor = end;
    }
    append(cursor, text.length);
    return NormalisedDoc._(buffer.toString(), newLines, newBreaks);
  }

  /// A copy of this document with every occurrence of [needle] removed.
  NormalisedDoc withoutOccurrences(String needle) => withoutRanges([
    for (final at in occurrences(needle)) (at, at + needle.length),
  ]);

  /// A copy of this document without its non-endorsement sentences (section 3):
  /// every sentence whose keyword-normalised text contains
  /// [nonEndorsementPhrase].
  NormalisedDoc withoutNonEndorsementSentences() => withoutRanges([
    for (final sentence in sentences())
      if (keywordIndexed(sentence.text).text.contains(nonEndorsementPhrase))
        (sentence.start, sentence.end),
  ]);

  /// The sentences of FR-007: the text split at `.`, `!` or `?` followed by a
  /// space or the end of the text, and at blank lines. [start] and [end] are
  /// the sentence's range in [text], [text] the trimmed sentence, [line] its
  /// first original line.
  List<({int start, int end, String text, int line})> sentences() {
    final result = <({int start, int end, String text, int line})>[];
    void emit(int from, int to) {
      final raw = text.substring(from, to);
      final left = raw.trimLeft();
      final lead = raw.length - left.length;
      final value = left.trimRight();
      if (value.isEmpty) return;
      result.add((
        start: from + lead,
        end: from + lead + value.length,
        text: value,
        line: lineAt(from + lead),
      ));
    }

    var start = 0;
    for (var i = 0; i < text.length; i++) {
      if (i > start && blankBreaks.contains(i)) {
        emit(start, i);
        start = i;
      }
      final c = text[i];
      final endsSentence =
          (c == '.' || c == '!' || c == '?') &&
          (i + 1 == text.length || text[i + 1] == ' ');
      if (endsSentence) {
        emit(start, i + 1);
        start = i + 1;
      }
    }
    emit(start, text.length);
    return result;
  }
}

final RegExp _whitespaceRun = RegExp(r'\s+');
final RegExp _heading = RegExp(r'^ {0,3}(#{1,6})\s+(.*?)\s*#*\s*$');

/// Normalises [text] (content-licensing-and-notice.md section 3); [lineOffset]
/// is added to the reported line numbers, for a slice of a larger file. With
/// [stripQuotes] false, step (2) is skipped: the keyword normalisation of
/// section 3 names only steps (1) and (3).
NormalisedDoc normalise(
  String text, {
  int lineOffset = 0,
  bool stripQuotes = true,
}) {
  final rawLines = text.split('\n');
  final kept = <({String collapsed, int line, bool blank})>[];
  var inComment = false;
  var fenceUnit = -1;
  for (var i = 0; i < rawLines.length; i++) {
    var line = rawLines[i];
    // (1) HTML comments and fenced code blocks are hidden.
    if (inComment) {
      final close = line.indexOf('-->');
      if (close < 0) continue;
      line = line.substring(close + 3);
      inComment = false;
    }
    while (!inComment) {
      final open = line.indexOf('<!--');
      if (open < 0) break;
      final close = line.indexOf('-->', open + 4);
      if (close < 0) {
        line = line.substring(0, open);
        inComment = true;
        break;
      }
      line = line.substring(0, open) + line.substring(close + 3);
    }
    var removed = false;
    if (fenceUnit >= 0) {
      final trimmed = line.trim();
      final closing =
          trimmed.length >= 3 &&
          trimmed.runes.every((unit) => unit == fenceUnit);
      if (closing) fenceUnit = -1;
      removed = true;
    } else {
      final trimmed = line.trim();
      if (trimmed.startsWith('```') || trimmed.startsWith('~~~')) {
        fenceUnit = trimmed.runes.first;
        removed = true;
      }
    }
    if (removed) continue;
    // (2) a leading `>` and following spaces are stripped per line.
    if (stripQuotes && line.startsWith('>')) {
      line = line.substring(1);
      while (line.startsWith(' ') || line.startsWith('\t')) {
        line = line.substring(1);
      }
    }
    // (3) runs of Unicode whitespace become one ASCII space, trimmed.
    final collapsed = line.replaceAll(_whitespaceRun, ' ').trim();
    kept.add((
      collapsed: collapsed,
      line: i + 1 + lineOffset,
      blank: collapsed.isEmpty,
    ));
  }
  final buffer = StringBuffer();
  final lines = <int>[];
  final breaks = <int>{};
  var pendingBlank = false;
  for (final segment in kept) {
    if (segment.blank) {
      pendingBlank = true;
      continue;
    }
    if (buffer.isNotEmpty) {
      lines.add(segment.line);
      buffer.write(' ');
      if (pendingBlank) breaks.add(lines.length);
    }
    for (var i = 0; i < segment.collapsed.length; i++) {
      buffer.write(segment.collapsed[i]);
      lines.add(segment.line);
    }
    pendingBlank = false;
  }
  return NormalisedDoc._(buffer.toString(), lines, breaks);
}

/// The keyword normalisation of section 3 applied to [text]: lower-cased with
/// every `*` deleted, with the input index of every kept code unit, so a
/// keyword hit can be mapped back to a line.
({String text, List<int> sources}) keywordIndexed(String text) {
  final buffer = StringBuffer();
  final sources = <int>[];
  for (var i = 0; i < text.length; i++) {
    final c = text[i];
    if (c == '*') continue;
    buffer.write(c.toLowerCase());
    sources.add(i);
  }
  return (text: buffer.toString(), sources: sources);
}

/// The keyword-normalised text of [text]: lower-cased, every `*` deleted.
String keywordForm(String text) => keywordIndexed(text).text;

/// The FR-031 normalisation of [text] (lower-cased, `-`, `_` and whitespace
/// removed) with the input index of every kept code unit, so a denylist hit
/// can be mapped back to a line.
({String text, List<int> sources}) normaliseNameIndexed(String text) {
  final buffer = StringBuffer();
  final sources = <int>[];
  for (var i = 0; i < text.length; i++) {
    final c = text[i];
    if (c == '-' || c == '_' || _whitespaceRun.hasMatch(c)) continue;
    buffer.write(c.toLowerCase());
    sources.add(i);
  }
  return (text: buffer.toString(), sources: sources);
}

/// A Markdown section: text from an exact, case-sensitive heading to the next
/// heading of the same or higher level, or the end of the file (section 3,
/// "section extraction").
final class MarkdownSection {
  /// Creates a section record.
  const MarkdownSection({
    required this.title,
    required this.level,
    required this.headingLine,
    required this.bodyFrom,
    required this.bodyTo,
  });

  /// The exact heading title.
  final String title;

  /// The heading level (1 to 6).
  final int level;

  /// The 1-based line of the heading.
  final int headingLine;

  /// The 0-based raw-line index of the first body line.
  final int bodyFrom;

  /// The 0-based raw-line index just past the last body line.
  final int bodyTo;

  /// The body text, joined from the raw [lines] of the file.
  String bodyText(List<String> lines) =>
      lines.sublist(bodyFrom, bodyTo).join('\n');
}

/// The section of [text] titled exactly [title] (case-sensitive), or null.
MarkdownSection? findSection(String text, String title) {
  final lines = text.split('\n');
  final headings = <({int index, int level, String title})>[];
  for (var i = 0; i < lines.length; i++) {
    final match = _heading.firstMatch(lines[i]);
    if (match == null) continue;
    headings.add((
      index: i,
      level: match.group(1)!.length,
      title: match.group(2)!,
    ));
  }
  for (var i = 0; i < headings.length; i++) {
    if (headings[i].title != title) continue;
    var end = lines.length;
    for (var j = i + 1; j < headings.length; j++) {
      if (headings[j].level <= headings[i].level) {
        end = headings[j].index;
        break;
      }
    }
    return MarkdownSection(
      title: title,
      level: headings[i].level,
      headingLine: headings[i].index + 1,
      bodyFrom: headings[i].index + 1,
      bodyTo: end,
    );
  }
  return null;
}

/// One Violation per entry of [list] that the denylist-normalised [doc] names,
/// reported at the hit's line. The detail names the entry by position, never
/// by name.
List<Violation> denylistHits(
  String id,
  String path,
  NormalisedDoc doc,
  List<DeniedName> list,
  String listName,
) {
  final indexed = normaliseNameIndexed(doc.text);
  final violations = <Violation>[];
  for (var i = 0; i < list.length; i++) {
    final at = indexed.text.indexOf(list[i].normalised);
    if (at < 0) continue;
    violations.add(
      Violation(
        checkId: id,
        path: path,
        line: doc.lineAt(indexed.sources[at]),
        detail: 'the text names $listName denylist entry #${i + 1}',
      ),
    );
  }
  return violations;
}

/// FR-001: the repository root contains `NOTICE.md` next to `LICENSE`.
List<Violation> checkNoticeFilesPresent(SourceSet sources) {
  const id = 'CLN-FR-001';
  return sortedViolations([
    if (!sources.files.containsKey('NOTICE.md'))
      const Violation(
        checkId: id,
        path: 'NOTICE.md',
        line: 1,
        detail: 'NOTICE.md is missing from the repository root.',
      ),
    if (!sources.files.containsKey('LICENSE'))
      const Violation(
        checkId: id,
        path: 'LICENSE',
        line: 1,
        detail: 'LICENSE is missing from beside NOTICE.md.',
      ),
  ]);
}

/// FR-002: after normalisation, `NOTICE.md` contains the attribution statement
/// verbatim (same words, punctuation and two URLs, typographic quotes).
/// Unconditional: applies whether or not content is bundled.
List<Violation> checkAttributionStatement(SourceSet sources) {
  const id = 'CLN-FR-002';
  final notice = sources.files['NOTICE.md'];
  if (notice == null) return const [];
  if (normalise(notice).text.contains(attributionStatement)) return const [];
  return const [
    Violation(
      checkId: id,
      path: 'NOTICE.md',
      line: 1,
      detail:
          'the attribution statement is not contained verbatim (exact words, '
          'punctuation, URLs and typographic quotes)',
    ),
  ];
}

/// FR-004: `NOTICE.md` and `README.md` credit no parent or affiliate of the
/// licensor outside the verbatim statement and the non-endorsement sentence.
List<Violation> checkNoAffiliateCredits(
  SourceSet sources, {
  List<DeniedName> denylist = affiliateDenylist,
}) {
  const id = 'CLN-FR-004';
  final violations = <Violation>[];
  for (final path in const ['NOTICE.md', 'README.md']) {
    final text = sources.files[path];
    if (text == null) continue;
    final doc = normalise(
      text,
    ).withoutOccurrences(attributionStatement).withoutNonEndorsementSentences();
    violations.addAll(denylistHits(id, path, doc, denylist, 'affiliate'));
  }
  return sortedViolations(violations);
}

/// FR-005: `NOTICE.md` has a "Scope" section stating it covers only the
/// bundled game content. The path-list equality is guardrails FR-079's, not
/// this check's.
List<Violation> checkScopeSection(SourceSet sources) {
  const id = 'CLN-FR-005';
  final notice = sources.files['NOTICE.md'];
  if (notice == null) return const [];
  final section = findSection(notice, 'Scope');
  if (section == null) {
    return const [
      Violation(
        checkId: id,
        path: 'NOTICE.md',
        line: 1,
        detail: 'no "Scope" section',
      ),
    ];
  }
  final keywords = keywordForm(
    normalise(section.bodyText(notice.split('\n')), stripQuotes: false).text,
  );
  final missing = [
    for (final keyword in const ['only', 'game content', 'bundled'])
      if (!keywords.contains(keyword)) keyword,
  ];
  if (missing.isEmpty) return const [];
  return [
    Violation(
      checkId: id,
      path: 'NOTICE.md',
      line: section.headingLine,
      detail: 'the Scope section lacks: ${missing.join(', ')}',
    ),
  ];
}

/// FR-006: `NOTICE.md` states that the code is MIT-licensed and that
/// `LICENSE` covers the code: the whole words `MIT` and `LICENSE`,
/// case-sensitive, as markup-insensitive text.
List<Violation> checkMitLicenseStatement(SourceSet sources) {
  const id = 'CLN-FR-006';
  final notice = sources.files['NOTICE.md'];
  if (notice == null) return const [];
  final starred = normalise(notice).text.replaceAll('*', '');
  final missing = [
    if (!RegExp(r'\bMIT\b').hasMatch(starred)) 'MIT',
    if (!RegExp(r'\bLICENSE\b').hasMatch(starred)) 'LICENSE',
  ];
  if (missing.isEmpty) return const [];
  return [
    Violation(
      checkId: id,
      path: 'NOTICE.md',
      line: 1,
      detail:
          'the notice does not state the code licence; missing whole '
          'words: ${missing.join(', ')}',
    ),
  ];
}

/// FR-007: no sentence of `NOTICE.md` states that the bundled game content is
/// MIT-licensed: no sentence contains the whole word `MIT` and one of
/// `game content`, `SRD`, `rules data` without `not` or an `n't` ending.
List<Violation> checkGameContentNotMit(SourceSet sources) {
  const id = 'CLN-FR-007';
  final notice = sources.files['NOTICE.md'];
  if (notice == null) return const [];
  return sortedViolations([
    for (final sentence in normalise(notice).sentences())
      if (_saysGameContentIsMit(sentence.text))
        Violation(
          checkId: id,
          path: 'NOTICE.md',
          line: sentence.line,
          detail: 'a sentence says the game content is MIT-licensed',
        ),
  ]);
}

bool _saysGameContentIsMit(String sentence) {
  final starred = sentence.replaceAll('*', '');
  if (!RegExp(r'\bMIT\b').hasMatch(starred)) return false;
  final lower = starred.toLowerCase();
  final subject =
      lower.contains('game content') ||
      lower.contains('srd') ||
      lower.contains('rules data');
  return subject && !negationPattern.hasMatch(lower);
}

/// FR-011: while bundled content is present, `NOTICE.md` carries no status
/// line. While absent, the status line is permitted, not required.
List<Violation> checkStatusLine(SourceSet sources) {
  const id = 'CLN-FR-011';
  if (!bundledContentPresent(sources)) return const [];
  final notice = sources.files['NOTICE.md'];
  if (notice == null) return const [];
  final lines = notice.split('\n');
  return sortedViolations([
    for (var i = 0; i < lines.length; i++)
      if (lines[i].trim().startsWith('**Status:**') &&
          lines[i].contains('no game content is bundled'))
        Violation(
          checkId: id,
          path: 'NOTICE.md',
          line: i + 1,
          detail:
              'the status line says no game content is bundled, but '
              'bundled content is present',
        ),
  ]);
}

/// FR-012: while bundled content is present, `NOTICE.md` has a "Changes"
/// section stating that the SRD's rules are restructured into code and data.
List<Violation> checkChangesSection(SourceSet sources) {
  const id = 'CLN-FR-012';
  if (!bundledContentPresent(sources)) return const [];
  final notice = sources.files['NOTICE.md'];
  if (notice == null) return const [];
  final section = findSection(notice, 'Changes');
  if (section == null) {
    return const [
      Violation(
        checkId: id,
        path: 'NOTICE.md',
        line: 1,
        detail: 'no "Changes" section while bundled content is present',
      ),
    ];
  }
  final keywords = keywordForm(
    normalise(section.bodyText(notice.split('\n')), stripQuotes: false).text,
  );
  if (keywords.contains('restructured')) return const [];
  return [
    Violation(
      checkId: id,
      path: 'NOTICE.md',
      line: section.headingLine,
      detail: 'the Changes section does not say the rules are restructured',
    ),
  ];
}

/// FR-013: the "Changes" section does not describe the changes as endorsed,
/// approved or reviewed by the licensor, outside the non-endorsement sentence.
List<Violation> checkChangesEndorsement(SourceSet sources) {
  const id = 'CLN-FR-013';
  final notice = sources.files['NOTICE.md'];
  if (notice == null) return const [];
  final section = findSection(notice, 'Changes');
  if (section == null) return const [];
  final doc = normalise(
    section.bodyText(notice.split('\n')),
    lineOffset: section.bodyFrom,
  ).withoutOccurrences(attributionStatement).withoutNonEndorsementSentences();
  final indexed = keywordIndexed(doc.text);
  return sortedViolations([
    for (final keyword in const [
      'endorsed by',
      'approved by',
      'reviewed by',
      'certified by',
      'sanctioned by',
    ])
      if (indexed.text.contains(keyword))
        Violation(
          checkId: id,
          path: 'NOTICE.md',
          line: doc.lineAt(indexed.sources[indexed.text.indexOf(keyword)]),
          detail: 'the Changes section says "$keyword"',
        ),
  ]);
}

/// FR-015: `NOTICE.md` contains the non-endorsement sentence: one sentence
/// with `independent` and the "not published, endorsed or approved" phrase.
List<Violation> checkNonEndorsementSentence(SourceSet sources) {
  const id = 'CLN-FR-015';
  final notice = sources.files['NOTICE.md'];
  if (notice == null) return const [];
  final present = normalise(notice).sentences().any((sentence) {
    final keywords = keywordForm(sentence.text);
    return keywords.contains('independent') &&
        keywords.contains(nonEndorsementPhrase);
  });
  if (present) return const [];
  return const [
    Violation(
      checkId: id,
      path: 'NOTICE.md',
      line: 1,
      detail:
          'no sentence states the package is independent and not '
          'published, endorsed or approved by Wizards of the Coast',
    ),
  ];
}

final RegExp _versionPattern = RegExp(
  r'(?:System Reference Document|SRD)\s*\|?\s*(\d+\.\d+\.\d+)',
);

Set<String> _srdVersions(String? text) => text == null
    ? {}
    : {
        for (final match in _versionPattern.allMatches(normalise(text).text))
          match.group(1)!,
      };

/// FR-024: the SRD version sets of `NOTICE.md` and `doc/research/sources.md`
/// are equal and non-empty. An empty set is reported on the file that has no
/// version; unequal sets are reported on `NOTICE.md`.
List<Violation> checkSrdVersionsAgree(SourceSet sources) {
  const id = 'CLN-FR-024';
  final notice = _srdVersions(sources.files['NOTICE.md']);
  final research = _srdVersions(sources.files['doc/research/sources.md']);
  if (notice.isEmpty) {
    return const [
      Violation(
        checkId: id,
        path: 'NOTICE.md',
        line: 1,
        detail: 'no SRD version of the form d.d.d found',
      ),
    ];
  }
  if (research.isEmpty) {
    return const [
      Violation(
        checkId: id,
        path: 'doc/research/sources.md',
        line: 1,
        detail: 'no SRD version of the form d.d.d found',
      ),
    ];
  }
  final same = notice.length == research.length && notice.containsAll(research);
  if (same) return const [];
  return [
    Violation(
      checkId: id,
      path: 'NOTICE.md',
      line: 1,
      detail:
          'SRD versions differ from doc/research/sources.md: '
          '{${notice.join(', ')}} vs {${research.join(', ')}}',
    ),
  ];
}

/// FR-035: after normalisation, the attribution statement appears in
/// `NOTICE.md` exactly once, inside its "Attribution" section. Absence is
/// FR-002's; extra occurrences and occurrences outside the section are this
/// check's.
List<Violation> checkStatementOnceInAttribution(SourceSet sources) {
  const id = 'CLN-FR-035';
  final notice = sources.files['NOTICE.md'];
  if (notice == null) return const [];
  final doc = normalise(notice);
  final at = doc.occurrences(attributionStatement);
  if (at.isEmpty) return const [];
  final section = findSection(notice, 'Attribution');
  final violations = <Violation>[];
  for (var i = 0; i < at.length; i++) {
    final line = doc.lineAt(at[i]);
    final inside =
        section != null &&
        line - 1 >= section.bodyFrom &&
        line - 1 < section.bodyTo;
    if (i > 0) {
      violations.add(
        Violation(
          checkId: id,
          path: 'NOTICE.md',
          line: line,
          detail: 'the attribution statement appears ${at.length} times',
        ),
      );
    } else if (!inside) {
      violations.add(
        Violation(
          checkId: id,
          path: 'NOTICE.md',
          line: line,
          detail:
              'the attribution statement is outside the "Attribution" '
              'section',
        ),
      );
    }
  }
  return sortedViolations(violations);
}

/// The check functions of this file by `CLN-` id. The licensing spec owns
/// them; they are NOT registered in the guardrails registry (`registry.dart`,
/// architecture-guardrails.md section 9 declined R-1).
const Map<String, List<Violation> Function(SourceSet)> noticeChecks = {
  'CLN-FR-001': checkNoticeFilesPresent,
  'CLN-FR-002': checkAttributionStatement,
  'CLN-FR-004': checkNoAffiliateCredits,
  'CLN-FR-005': checkScopeSection,
  'CLN-FR-006': checkMitLicenseStatement,
  'CLN-FR-007': checkGameContentNotMit,
  'CLN-FR-011': checkStatusLine,
  'CLN-FR-012': checkChangesSection,
  'CLN-FR-013': checkChangesEndorsement,
  'CLN-FR-015': checkNonEndorsementSentence,
  'CLN-FR-024': checkSrdVersionsAgree,
  'CLN-FR-035': checkStatementOnceInAttribution,
};
