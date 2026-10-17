import '../support/constants.dart' show DeniedName, trademarkDenylist;
import '../support/gitignore.dart';
import '../support/source_set.dart';
import '../support/violation.dart';
import 'notice.dart';

/// The trademark checks of `doc/specs/content-licensing-and-notice.md`
/// (FR-016, FR-018, FR-019 and FR-038): no trademarked name as a brand, no
/// compatibility wording that names one, and a `.pubignore` that cannot drop
/// the notice, the licence or the embeds.
///
/// Pure functions over a [SourceSet]; not registered in the guardrails
/// registry. The names come from the FR-031 denylists in
/// `test/architecture/support/constants.dart`, held as fragments.

final RegExp _declaredIdentifier = RegExp(
  r'\b(?:class|enum|mixin|typedef)\s+([A-Za-z_$][\w$]*)',
);
final RegExp _libraryDirective = RegExp(
  r'^\s*library\s+([A-Za-z_$][\w$]*)',
  multiLine: true,
);

/// FR-016: identifiers declared in `lib/` (class, mixin, enum, typedef,
/// library and file names) and the pubspec `name` and `description` contain
/// no trademark denylist term, compared after the FR-031 normalisation.
List<Violation> checkTrademarkFreeIdentifiers(SourceSet sources) {
  const id = 'CLN-FR-016';
  final violations = <Violation>[];
  final pubspec = sources.files['pubspec.yaml'];
  if (pubspec != null) {
    for (final key in const ['name', 'description']) {
      for (final value in _pubspecValueLines(pubspec, key)) {
        violations.addAll(
          _namedEntries(
            id,
            'pubspec.yaml',
            value.line,
            value.text,
            trademarkDenylist,
            'trademark',
          ),
        );
      }
    }
  }
  for (final path in sources.dartPaths('lib/')) {
    final base = path.substring(path.lastIndexOf('/') + 1);
    violations.addAll(
      _namedEntries(id, path, 1, base, trademarkDenylist, 'trademark'),
    );
    final lexed = sources.lexed(path);
    for (final match in _declaredIdentifier.allMatches(lexed.code)) {
      violations.addAll(
        _namedEntries(
          id,
          path,
          lexed.lineOf(match.start),
          match.group(1)!,
          trademarkDenylist,
          'trademark',
        ),
      );
    }
    for (final match in _libraryDirective.allMatches(lexed.code)) {
      violations.addAll(
        _namedEntries(
          id,
          path,
          lexed.lineOf(match.start),
          match.group(1)!,
          trademarkDenylist,
          'trademark',
        ),
      );
    }
  }
  return sortedViolations(violations);
}

/// The lines of the `name:` or `description:` value of a pubspec [text], with
/// their 1-based numbers; a block scalar's indented continuation lines count
/// in.
List<({String text, int line})> _pubspecValueLines(String text, String key) {
  final lines = text.split('\n');
  final values = <({String text, int line})>[];
  for (var i = 0; i < lines.length; i++) {
    if (!RegExp('^$key:').hasMatch(lines[i])) continue;
    values.add((text: lines[i], line: i + 1));
    for (var j = i + 1; j < lines.length; j++) {
      if (!lines[j].startsWith(' ') && !lines[j].startsWith('\t')) break;
      values.add((text: lines[j], line: j + 1));
    }
    break;
  }
  return values;
}

/// One Violation per entry of [list] that [text] names (FR-031 matching).
List<Violation> _namedEntries(
  String id,
  String path,
  int line,
  String text,
  List<DeniedName> list,
  String listName,
) => [
  for (var i = 0; i < list.length; i++)
    if (list[i].appearsIn(text))
      Violation(
        checkId: id,
        path: path,
        line: line,
        detail: 'the identifier names $listName denylist entry #${i + 1}',
      ),
];

/// FR-018: `.pubignore` excludes neither `NOTICE.md` nor `LICENSE` (gitignore
/// semantics, evaluated with the shared evaluator). A missing `.pubignore`
/// excludes nothing and is clean.
List<Violation> checkPubignoreKeepsNotice(SourceSet sources) {
  const id = 'CLN-FR-018';
  const protected = ['LICENSE', 'NOTICE.md'];
  final text = sources.files['.pubignore'];
  if (text == null) return const [];
  final rules = GitignoreRules.parse(text);
  return sortedViolations([
    for (final path in protected)
      if (rules.excludes(path))
        Violation(
          checkId: id,
          path: '.pubignore',
          line: rules.excludedByLine(path) ?? 1,
          detail:
              'the .pubignore excludes $path; the notice accompanies '
              'every redistribution',
        ),
  ]);
}

/// FR-019: `.pubignore` does not exclude `lib/src/content/data/` (the embeds
/// are the only covered path that ships). A bare `data/` is unanchored and
/// matches the embed directory at any depth; the anchored `/data/` is clean,
/// as is a later `!lib/src/content/data/`.
List<Violation> checkPubignoreKeepsEmbeds(SourceSet sources) {
  const id = 'CLN-FR-019';
  const embeds = 'lib/src/content/data';
  final text = sources.files['.pubignore'];
  if (text == null) return const [];
  final rules = GitignoreRules.parse(text);
  if (!rules.excludes(embeds, isDirectory: true)) return const [];
  return [
    Violation(
      checkId: id,
      path: '.pubignore',
      line: rules.excludedByLine(embeds, isDirectory: true) ?? 1,
      detail:
          'the .pubignore excludes lib/src/content/data/, which ships '
          'under the notice',
    ),
  ];
}

/// FR-038: compatibility wording that names a trademarked edition, product or
/// brand appears in no scanned file. `NOTICE.md` and `README.md` are scanned
/// after the verbatim statement and the non-endorsement sentence are removed
/// (the statement names the licensor, which no list holds); `pubspec.yaml` is
/// scanned in full. "Compatible with fifth edition" / "5E compatible" is a
/// MAY and is not checked.
List<Violation> checkCompatibilityWording(
  SourceSet sources, {
  List<DeniedName> denylist = trademarkDenylist,
}) {
  const id = 'CLN-FR-038';
  final violations = <Violation>[];
  for (final path in const ['NOTICE.md', 'README.md']) {
    final text = sources.files[path];
    if (text == null) continue;
    final doc = normalise(
      text,
    ).withoutOccurrences(attributionStatement).withoutNonEndorsementSentences();
    violations.addAll(denylistHits(id, path, doc, denylist, 'trademark'));
  }
  final pubspec = sources.files['pubspec.yaml'];
  if (pubspec != null) {
    final doc = normalise(pubspec);
    violations.addAll(
      denylistHits(id, 'pubspec.yaml', doc, denylist, 'trademark'),
    );
  }
  return sortedViolations(violations);
}

/// The check functions of this file by `CLN-` id; not registered in the
/// guardrails registry.
const Map<String, List<Violation> Function(SourceSet)> noticeMarkChecks = {
  'CLN-FR-016': checkTrademarkFreeIdentifiers,
  'CLN-FR-018': checkPubignoreKeepsNotice,
  'CLN-FR-019': checkPubignoreKeepsEmbeds,
  'CLN-FR-038': checkCompatibilityWording,
};
