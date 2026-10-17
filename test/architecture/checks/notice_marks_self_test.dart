import 'package:test/test.dart';

import '../support/constants.dart' show trademarkDenylist;
import '../support/source_set.dart';
import '../support/violation.dart';
import 'notice_marks.dart';

const String _spec = 'doc/specs/content-licensing-and-notice.md';

List<String> _where(List<Violation> violations) => [
  for (final v in violations) '${v.checkId} ${v.path}:${v.line}',
];

/// A brand name assembled from the denylist (FR-031), never spelled here.
final String _brand = trademarkDenylist.first.name;
final String _brandSpaced = trademarkDenylist.first.spelled(' ');
final String _secondBrand = trademarkDenylist[5].name;

typedef _Case = ({
  String label,
  String requirement,
  String path,
  SourceSet sources,
  List<Violation> Function(SourceSet sources) check,
  List<String> expected,
});

_Case _case(
  String label,
  String requirement,
  String path,
  SourceSet sources,
  List<Violation> Function(SourceSet) check,
  List<String> expected,
) => (
  label: label,
  requirement: '$_spec $requirement',
  path: path,
  sources: sources,
  check: check,
  expected: expected,
);

final List<_Case> _cases = [
  _case(
    'S-18: a denylisted brand in a compatibility claim, capitalised',
    'FR-038',
    'unhappy (invalid input)',
    SourceSet({
      'README.md': 'Compatible with ${_brandSpaced.toUpperCase()} products.\n',
    }),
    checkCompatibilityWording,
    ['CLN-FR-038 README.md:1'],
  ),
  _case(
    'S-18: only the permitted compatibility wording',
    'FR-038',
    'happy',
    SourceSet({
      'README.md':
          'This package is compatible with fifth edition and 5E '
          'compatible.\n',
    }),
    checkCompatibilityWording,
    [],
  ),
  _case(
    'S-21: a denylisted term in the pubspec name',
    'FR-016',
    'unhappy (invalid input)',
    SourceSet({'pubspec.yaml': 'name: pkg_$_brand\n'}),
    checkTrademarkFreeIdentifiers,
    ['CLN-FR-016 pubspec.yaml:1'],
  ),
  _case(
    'S-21: a class so named under lib/',
    'FR-016',
    'unhappy (invalid input)',
    SourceSet({'lib/src/x.dart': 'class $_secondBrand {}\n'}),
    checkTrademarkFreeIdentifiers,
    ['CLN-FR-016 lib/src/x.dart:1'],
  ),
  _case(
    'S-21: neutral names',
    'FR-016',
    'happy',
    SourceSet({
      'pubspec.yaml': 'name: srd5e\ndescription: A pure-Dart rules package.\n',
      'lib/src/x.dart': 'class D20Roll {}\n',
    }),
    checkTrademarkFreeIdentifiers,
    [],
  ),
  _case(
    'S-24: *.md excludes NOTICE.md',
    'FR-018',
    'unhappy (state error)',
    SourceSet({'.pubignore': '*.md\n'}),
    checkPubignoreKeepsNotice,
    ['CLN-FR-018 .pubignore:1'],
  ),
  _case(
    'S-24: the notice named directly',
    'FR-018',
    'unhappy (state error)',
    SourceSet({'.pubignore': 'NOTICE.md\n'}),
    checkPubignoreKeepsNotice,
    ['CLN-FR-018 .pubignore:1'],
  ),
  _case(
    'S-24: the anchored licence pattern',
    'FR-018',
    'unhappy (state error)',
    SourceSet({'.pubignore': '/LICENSE\n'}),
    checkPubignoreKeepsNotice,
    ['CLN-FR-018 .pubignore:1'],
  ),
  _case(
    'S-24: the negation case is clean',
    'FR-018',
    'happy',
    SourceSet({'.pubignore': '*.md\n!NOTICE.md\n'}),
    checkPubignoreKeepsNotice,
    [],
  ),
  _case(
    'S-24: the current .pubignore is clean',
    'FR-018',
    'happy',
    SourceSet({'.pubignore': 'AGENTS.md\nCLAUDE.md\n.github/\ndoc/\n'}),
    checkPubignoreKeepsNotice,
    [],
  ),
  _case(
    'S-25: the whole content directory excluded',
    'FR-019',
    'unhappy (state error)',
    SourceSet({'.pubignore': 'lib/src/content/\n'}),
    checkPubignoreKeepsEmbeds,
    ['CLN-FR-019 .pubignore:1'],
  ),
  _case(
    'S-25: the embed directory excluded',
    'FR-019',
    'unhappy (state error)',
    SourceSet({'.pubignore': 'lib/src/content/data/\n'}),
    checkPubignoreKeepsEmbeds,
    ['CLN-FR-019 .pubignore:1'],
  ),
  _case(
    'S-25: lib/ excluded',
    'FR-019',
    'unhappy (state error)',
    SourceSet({'.pubignore': 'lib/\n'}),
    checkPubignoreKeepsEmbeds,
    ['CLN-FR-019 .pubignore:1'],
  ),
  _case(
    'S-25: a bare data/ matches at any depth',
    'FR-019',
    'unhappy (state error)',
    SourceSet({'.pubignore': 'data/\n'}),
    checkPubignoreKeepsEmbeds,
    ['CLN-FR-019 .pubignore:1'],
  ),
  _case(
    'S-25: **/data/ matches too',
    'FR-019',
    'unhappy (state error)',
    SourceSet({'.pubignore': '**/data/\n'}),
    checkPubignoreKeepsEmbeds,
    ['CLN-FR-019 .pubignore:1'],
  ),
  _case(
    'S-25: the anchored /data/ is clean',
    'FR-019',
    'happy',
    SourceSet({'.pubignore': '/data/\n'}),
    checkPubignoreKeepsEmbeds,
    [],
  ),
  _case(
    'S-25: a later negation re-includes the embeds',
    'FR-019',
    'happy',
    SourceSet({'.pubignore': 'data/\n!lib/src/content/data/\n'}),
    checkPubignoreKeepsEmbeds,
    [],
  ),
  _case(
    'S-25: the fixture and test trees may be excluded',
    'FR-019',
    'happy',
    SourceSet({'.pubignore': 'test/fixtures/srd/\ntest/\n'}),
    checkPubignoreKeepsEmbeds,
    [],
  ),
];

void main() {
  group('trademarks and .pubignore', () {
    /// Requirement: per case - doc/specs/content-licensing-and-notice.md
    ///   table S (S-18, S-21, S-24, S-25): one violating and one clean
    ///   fixture per requirement, with the exact Violations (path and line).
    /// Path: per case
    for (final c in _cases) {
      test('${c.label} [${c.path}] (${c.requirement})', () {
        expect(_where(c.check(c.sources)), c.expected);
      });
    }
  });

  /// Requirement: doc/specs/content-licensing-and-notice.md FR-031 (S-33) -
  ///   matching ignores case, `-`, `_` and whitespace, exercised through the
  ///   FR-016 identifier scan, including a term with separators inserted.
  /// Path: unhappy (invalid input)
  test('S-33: matching survives separators and case', () {
    final separated = SourceSet({
      'lib/src/x.dart':
          "class ${trademarkDenylist[1].spelled('_').toUpperCase()} {}\n",
    });

    expect(_where(checkTrademarkFreeIdentifiers(separated)), [
      'CLN-FR-016 lib/src/x.dart:1',
    ]);
  });

  /// Requirement: doc/specs/content-licensing-and-notice.md FR-031 (S-33) -
  ///   fragments alone do not match: only the assembled name does.
  /// Path: unhappy (false positive)
  test('S-33: a fragment alone is not the name', () {
    final fragment = SourceSet({
      'lib/src/x.dart': 'class ${trademarkDenylist[5].fragments.first} {}\n',
    });

    expect(_where(checkTrademarkFreeIdentifiers(fragment)), isEmpty);
  });

  /// Requirement: doc/specs/content-licensing-and-notice.md FR-038 - the
  ///   pubspec is scanned in full, not only name and description.
  /// Path: unhappy (invalid input)
  test('FR-038: the whole pubspec is scanned', () {
    final pubspec = SourceSet({
      'pubspec.yaml':
          'name: srd5e\n'
          'description: Fine.\n'
          'homepage: https://example.org/$_brand\n',
    });

    expect(_where(checkCompatibilityWording(pubspec)), [
      'CLN-FR-038 pubspec.yaml:3',
    ]);
  });

  /// Requirement: doc/specs/architecture-guardrails.md FR-011 - the same
  ///   files in another order give the same violations.
  /// Path: unhappy (determinism)
  test('the checks are independent of the SourceSet order', () {
    final files = {
      '.pubignore': 'NOTICE.md\ndata/\n',
      'pubspec.yaml': 'name: pkg_$_brand\n',
    };
    List<Violation> run(Map<String, String> order) => sortedViolations([
      for (final check in noticeMarkChecks.values) ...check(SourceSet(order)),
    ]);
    final forward = run(files);
    final reversed = run({
      for (final key in files.keys.toList().reversed) key: files[key]!,
    });

    expect(_where(reversed), _where(forward));
    expect(_where(forward), [
      'CLN-FR-018 .pubignore:1',
      'CLN-FR-019 .pubignore:2',
      'CLN-FR-016 pubspec.yaml:1',
      'CLN-FR-038 pubspec.yaml:1',
    ]);
  });
}
