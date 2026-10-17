import 'package:srd5e/src/content/domain/source_citation.dart';
import 'package:test/test.dart';

import '../../support/argument_error_matcher.dart';
import '../../support/operator_equals.dart';

/// One `tryCreate` input triple with the expected problem, or null when
/// accepted.
typedef _TryCreateCase = ({
  String label,
  String requirement,
  String path,
  String document,
  String section,
  int page,
  SourceCitationProblem? problem,
});

final List<_TryCreateCase> _tryCreateCases = [
  (
    label: 'the SRD citation',
    requirement:
        'doc/specs/content-schema-and-decoder.md FR-115 - tryCreate '
        'accepts the parts the constructor accepts',
    path: 'happy',
    document: 'SRD 5.2.1',
    section: 'Damage Rolls',
    page: 16,
    problem: null,
  ),
  (
    label: 'page at the minimum',
    requirement:
        'doc/specs/content-schema-and-decoder.md FR-115 - page at '
        'SourceCitation.minPage is accepted',
    path: 'unhappy (boundary)',
    document: 'd',
    section: 's',
    page: 1,
    problem: null,
  ),
  (
    label: 'blank document',
    requirement:
        'doc/specs/content-schema-and-decoder.md FR-115 - tryCreate '
        'rejects with blankDocument, the first failing check',
    path: 'unhappy (invalid input)',
    document: '',
    section: 's',
    page: 1,
    problem: SourceCitationProblem.blankDocument,
  ),
  (
    label: 'blank section',
    requirement:
        'doc/specs/content-schema-and-decoder.md FR-115 - tryCreate '
        'rejects with blankSection',
    path: 'unhappy (invalid input)',
    document: 'd',
    section: '  ',
    page: 1,
    problem: SourceCitationProblem.blankSection,
  ),
  (
    label: 'page 0',
    requirement:
        'doc/specs/content-schema-and-decoder.md FR-115 - tryCreate '
        'rejects with pageBelowMinimum',
    path: 'unhappy (boundary)',
    document: 'd',
    section: 's',
    page: 0,
    problem: SourceCitationProblem.pageBelowMinimum,
  ),
  (
    label: 'page -1',
    requirement:
        'doc/specs/content-schema-and-decoder.md FR-115 - tryCreate '
        'rejects with pageBelowMinimum',
    path: 'unhappy (boundary)',
    document: 'd',
    section: 's',
    page: -1,
    problem: SourceCitationProblem.pageBelowMinimum,
  ),
  (
    label: 'blank document, blank section and page 0',
    requirement:
        'doc/specs/content-schema-and-decoder.md FR-115 - the '
        'problem is the first failing check in the order blankDocument, '
        'blankSection, pageBelowMinimum',
    path: 'unhappy (invalid input)',
    document: ' ',
    section: ' ',
    page: 0,
    problem: SourceCitationProblem.blankDocument,
  ),
];

/// One citationsSrd521 row.
typedef _CitesCase = ({
  String label,
  String requirement,
  String path,
  String document,
  int page,
  bool cites,
});

final List<_CitesCase> _citesCases = [
  (
    label: 'the SRD document within its pages',
    requirement:
        'doc/specs/content-schema-and-decoder.md FR-138 - '
        'citesSrd521 is true iff document == srdDocument and page <= '
        'srdLastPage',
    path: 'happy',
    document: 'SRD 5.2.1',
    page: 16,
    cites: true,
  ),
  (
    label: 'the last page',
    requirement:
        'doc/specs/content-schema-and-decoder.md FR-138 - srdLastPage '
        '(364, the last PDF page) is within the range',
    path: 'unhappy (boundary)',
    document: 'SRD 5.2.1',
    page: 364,
    cites: true,
  ),
  (
    label: 'one past the last page',
    requirement:
        'doc/specs/content-schema-and-decoder.md FR-138 - a page '
        'past srdLastPage does not cite the SRD',
    path: 'unhappy (boundary)',
    document: 'SRD 5.2.1',
    page: 365,
    cites: false,
  ),
  (
    label: 'another document',
    requirement:
        'doc/specs/content-schema-and-decoder.md FR-138 - the '
        'bundled-data constraint is not a constructor rule, so the '
        'constructor accepts another document that does not cite the SRD',
    path: 'unhappy (boundary)',
    document: 'Homebrew',
    page: 1,
    cites: false,
  ),
  (
    label: 'wrong case',
    requirement:
        'doc/specs/content-schema-and-decoder.md FR-138 - the '
        'document comparison is character for character',
    path: 'unhappy (invalid input)',
    document: 'srd 5.2.1',
    page: 1,
    cites: false,
  ),
];

void main() {
  /// Requirement: doc/specs/content-schema-and-decoder.md FR-115 - a value
  ///   object with non-blank document and section and a page of at least
  ///   minPage; all fields final.
  /// Path: happy
  test('a valid citation holds its parts verbatim', () {
    final citation = SourceCitation(
      document: 'SRD 5.2.1',
      section: 'Damage Rolls',
      page: 16,
    );

    expect(citation.document, 'SRD 5.2.1');
    expect(citation.section, 'Damage Rolls');
    expect(citation.page, 16);
  });

  /// Requirement: doc/specs/content-schema-and-decoder.md FR-115 - the
  ///   constructor throws ArgumentError for the blank parts and a page below
  ///   minPage (a missing section has no constructor input).
  /// Path: unhappy (invalid input)
  test('the constructor rejects blank and out-of-range parts', () {
    expect(
      () => SourceCitation(document: '  ', section: 's', page: 1),
      throwsArgumentErrorFor('document', '  '),
    );
    expect(
      () => SourceCitation(document: 'd', section: '', page: 1),
      throwsArgumentErrorFor('section', ''),
    );
    expect(
      () => SourceCitation(document: 'd', section: 's', page: 0),
      throwsArgumentErrorFor('page', 0),
    );
  });

  /// Requirement: per case
  /// Path: per case
  for (final c in _tryCreateCases) {
    test('tryCreate ${c.label} [${c.path}]', () {
      final parse = SourceCitation.tryCreate(
        document: c.document,
        section: c.section,
        page: c.page,
      );
      if (c.problem == null) {
        expect(parse, isA<SourceCitationParsed>());
        expect(
          (parse as SourceCitationParsed).citation,
          SourceCitation(
            document: c.document,
            section: c.section,
            page: c.page,
          ),
        );
      } else {
        expect(parse, SourceCitationRejected(c.problem!));
      }
    });
  }

  /// Requirement: per case
  /// Path: per case
  for (final c in _tryCreateCases) {
    test('tryCreate agrees with the constructor: ${c.label} [${c.path}]', () {
      if (c.problem == null) {
        expect(
          SourceCitation(
            document: c.document,
            section: c.section,
            page: c.page,
          ),
          isA<SourceCitation>(),
        );
      } else {
        expect(
          () => SourceCitation(
            document: c.document,
            section: c.section,
            page: c.page,
          ),
          throwsArgumentError,
        );
      }
    });
  }

  /// Requirement: doc/specs/content-schema-and-decoder.md FR-138 - the
  ///   bundled-data facts are public constants.
  /// Path: happy
  test('the SRD constants are the FR-138 values', () {
    expect(SourceCitation.srdDocument, 'SRD 5.2.1');
    expect(SourceCitation.minPage, 1);
    expect(SourceCitation.srdLastPage, 364);
  });

  /// Requirement: per case
  /// Path: per case
  for (final c in _citesCases) {
    test('citesSrd521 ${c.label} [${c.path}]', () {
      final citation = SourceCitation(
        document: c.document,
        section: 's',
        page: c.page,
      );

      expect(citation.citesSrd521, c.cites);
    });
  }

  /// Requirement: doc/specs/content-schema-and-decoder.md FR-138 -
  ///   citationText returns `<document>, "<section>", p. <page>`, parts
  ///   character for character.
  /// Path: happy
  test('citationText follows the printed form', () {
    final citation = SourceCitation(
      document: 'SRD 5.2.1',
      section: 'Damage Rolls',
      page: 16,
    );

    expect(citation.citationText, 'SRD 5.2.1, "Damage Rolls", p. 16');
  });

  /// Requirement: doc/specs/content-schema-and-decoder.md FR-115 - value
  ///   equality: equal parts equal, any part differing unequal.
  /// Path: happy
  test('citations compare by all three parts', () {
    final citation = SourceCitation(
      document: 'SRD 5.2.1',
      section: 'Damage Rolls',
      page: 16,
    );
    final same = SourceCitation(
      document: 'SRD 5.2.1',
      section: 'Damage Rolls',
      page: 16,
    );
    final otherPage = SourceCitation(
      document: 'SRD 5.2.1',
      section: 'Damage Rolls',
      page: 17,
    );

    expect(citation, same);
    expect(citation.hashCode, same.hashCode);
    expect(citation == otherPage, isFalse);
  });

  /// Requirement: doc/specs/content-schema-and-decoder.md FR-138 - toString
  ///   is the citationText form.
  /// Path: happy
  test('a citation prints its citationText', () {
    final citation = SourceCitation(
      document: 'SRD 5.2.1',
      section: 'Damage Rolls',
      page: 16,
    );

    expect(citation.toString(), 'SRD 5.2.1, "Damage Rolls", p. 16');
  });

  /// Requirement: doc/specs/content-schema-and-decoder.md FR-115 - the
  ///   parse results are value objects: they compare by value, hash
  ///   consistently and print their parts.
  /// Path: happy
  test('citation parse results compare by value and print their parts', () {
    final parsed = SourceCitation.tryCreate(
      document: 'SRD 5.2.1',
      section: 'Damage Rolls',
      page: 16,
    );
    final same = SourceCitation.tryCreate(
      document: 'SRD 5.2.1',
      section: 'Damage Rolls',
      page: 16,
    );
    final other = SourceCitation.tryCreate(
      document: 'SRD 5.2.1',
      section: 'Damage Rolls',
      page: 17,
    );
    final rejected = SourceCitation.tryCreate(
      document: '',
      section: 's',
      page: 1,
    );

    expect(parsed, same);
    expect(parsed.hashCode, same.hashCode);
    expect(operatorEquals(parsed, other), isFalse);
    expect(operatorEquals(parsed, rejected), isFalse);
    expect(
      parsed.toString(),
      'SourceCitationParsed(SRD 5.2.1, "Damage Rolls", p. 16)',
    );

    final sameRejected = SourceCitation.tryCreate(
      document: ' ',
      section: 's',
      page: 1,
    );
    expect(rejected, sameRejected);
    expect(rejected.hashCode, sameRejected.hashCode);
    expect(operatorEquals(rejected, parsed), isFalse);
    expect(rejected.toString(), 'SourceCitationRejected(blankDocument)');
  });
}
