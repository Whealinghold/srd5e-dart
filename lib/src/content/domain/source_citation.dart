import 'package:meta/meta.dart';

/// Why a citation is not a [SourceCitation], checked in this order (FR-115).
enum SourceCitationProblem {
  /// The document is blank.
  blankDocument,

  /// The section is blank.
  blankSection,

  /// The page is below [SourceCitation.minPage].
  pageBelowMinimum,
}

/// The result of [SourceCitation.tryCreate]: a valid citation or a typed
/// rejection.
///
/// Switch over it exhaustively, with no default branch.
@immutable
sealed class SourceCitationParse {
  const SourceCitationParse();
}

/// [SourceCitation.tryCreate] accepted the parts.
@immutable
final class SourceCitationParsed extends SourceCitationParse {
  /// Wraps the created [citation].
  const SourceCitationParsed(this.citation);

  /// The citation that was created.
  final SourceCitation citation;

  @override
  bool operator ==(Object other) =>
      other is SourceCitationParsed && other.citation == citation;

  @override
  int get hashCode => Object.hash(SourceCitationParsed, citation);

  @override
  String toString() => 'SourceCitationParsed($citation)';
}

/// [SourceCitation.tryCreate] rejected the parts.
@immutable
final class SourceCitationRejected extends SourceCitationParse {
  /// Carries the typed [problem].
  const SourceCitationRejected(this.problem);

  /// Why the parts were rejected, the first failing check in the order
  /// [SourceCitationProblem] declares it.
  final SourceCitationProblem problem;

  @override
  bool operator ==(Object other) =>
      other is SourceCitationRejected && other.problem == problem;

  @override
  int get hashCode => Object.hash(SourceCitationRejected, problem);

  @override
  String toString() => 'SourceCitationRejected(${problem.name})';
}

/// Where one piece of game content comes from: a document, a section and a
/// page (FR-115).
///
/// A value object: `document` and `section` are non-blank and `page` is at
/// least [minPage], otherwise the constructor throws an [ArgumentError]
/// carrying the offending part's name and value; [tryCreate] is the
/// non-throwing form for untrusted input. The bundled-data constraint that
/// the document be [srdDocument] within [minPage] to [srdLastPage] is not a
/// constructor rule (FR-138), so host content may cite its own document.
@immutable
final class SourceCitation {
  /// Creates a citation from the parts.
  ///
  /// Throws an [ArgumentError] carrying the name `document`, `section` or
  /// `page` and the offending value when a part breaks the rules above. Use
  /// [tryCreate] for untrusted input.
  SourceCitation({
    required String document,
    required String section,
    required int page,
  }) : document = _validatedDocument(document),
       section = _validatedSection(section),
       page = _validatedPage(page);

  /// The smallest page a citation may name.
  static const int minPage = 1;

  /// The last page of the SRD 5.2.1 PDF (the last page of the document).
  static const int srdLastPage = 364;

  /// The document the bundled content cites.
  static const String srdDocument = 'SRD 5.2.1';

  /// The cited document, character for character.
  final String document;

  /// The cited section, character for character.
  final String section;

  /// The cited page.
  final int page;

  /// Creates a citation from untrusted parts without throwing.
  ///
  /// Returns [SourceCitationParsed] exactly when the constructor would
  /// accept the parts, and [SourceCitationRejected] with the first failing
  /// check — [SourceCitationProblem.blankDocument], [blankSection],
  /// [pageBelowMinimum] in that order — otherwise.
  static SourceCitationParse tryCreate({
    required String document,
    required String section,
    required int page,
  }) {
    if (_isBlank(document)) {
      return const SourceCitationRejected(SourceCitationProblem.blankDocument);
    }
    if (_isBlank(section)) {
      return const SourceCitationRejected(SourceCitationProblem.blankSection);
    }
    if (page < minPage) {
      return const SourceCitationRejected(
        SourceCitationProblem.pageBelowMinimum,
      );
    }
    return SourceCitationParsed(
      SourceCitation(document: document, section: section, page: page),
    );
  }

  /// Whether this citation names [srdDocument] within its page range: the
  /// bundled-data rule of FR-090 exists once, here (FR-138).
  bool get citesSrd521 => document == srdDocument && page <= srdLastPage;

  /// The citation as it is written in prose:
  /// `SRD 5.2.1, "Damage Rolls", p. 16`, parts character for character (FR-138).
  ///
  /// A plain [String] for debugging and display; it is never parsed back.
  String get citationText => '$document, "$section", p. $page';

  static bool _isBlank(String value) => value.trim().isEmpty;

  static String _validatedDocument(String document) {
    if (_isBlank(document)) {
      throw ArgumentError.value(document, 'document', 'must not be blank');
    }
    return document;
  }

  static String _validatedSection(String section) {
    if (_isBlank(section)) {
      throw ArgumentError.value(section, 'section', 'must not be blank');
    }
    return section;
  }

  static int _validatedPage(int page) {
    if (page < minPage) {
      throw ArgumentError.value(page, 'page', 'must be at least $minPage');
    }
    return page;
  }

  @override
  bool operator ==(Object other) =>
      other is SourceCitation &&
      other.document == document &&
      other.section == section &&
      other.page == page;

  @override
  int get hashCode => Object.hash(document, section, page);

  @override
  String toString() => citationText;
}
