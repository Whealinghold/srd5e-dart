import 'package:srd5e/src/content/application/ports/content_source.dart';
import 'package:srd5e/src/content/domain/content_id.dart';
import 'package:srd5e/src/content/domain/content_key.dart';
import 'package:srd5e/src/content/domain/content_kind.dart';
import 'package:srd5e/src/content/domain/content_query.dart';
import 'package:srd5e/src/shared_ports/errors/srd5e_exception.dart';
import 'package:test/test.dart';

void main() {
  final key = ContentKey(ContentKind.spell, ContentId('light'));
  const cause = FormatException('backend failure');
  final stackTrace = StackTrace.fromString('backend stack trace');

  /// Requirement: doc/specs/content-source-port.md FR-037, FR-039 - the
  ///   exception is const-constructible from one constructor that takes the
  ///   query as a required positional argument and stores it unchanged.
  /// Path: happy
  group('ContentSourceException construction', () {
    /// Requirement: doc/specs/content-source-port.md FR-037, FR-039 - a
    ///   const instance compiles: the constructor is const and the query is
    ///   the required positional argument. (A ContentLookupQuery over a
    ///   ContentId is not const-constructible outside the library - the id
    ///   factory is not const - so the const form uses the list query.)
    /// Path: happy
    test('the constructor is const', () {
      const exception = ContentSourceException(
        ContentListKindQuery(ContentKind.spell),
      );

      expect(exception.query, const ContentListKindQuery(ContentKind.spell));
    });

    /// Requirement: doc/specs/content-source-port.md FR-037 - the cause and
    ///   causeStackTrace it was built with are exposed unchanged (same
    ///   instance).
    /// Path: happy
    test('a runtime instance carries query, cause and stack trace', () {
      final query = ContentLookupQuery(
        ContentKey(ContentKind.spell, ContentId('light')),
      );

      final exception = ContentSourceException(
        query,
        cause: cause,
        causeStackTrace: stackTrace,
      );

      expect(exception.query, same(query));
      expect(exception.cause, same(cause));
      expect(exception.causeStackTrace, same(stackTrace));
    });

    /// Requirement: doc/specs/content-source-port.md FR-018 - a listKind
    ///   failure carries a ContentListKindQuery, and the query is never
    ///   null; there is no separate operation field.
    /// Path: happy
    test('a list query is carried as ContentListKindQuery', () {
      const exception = ContentSourceException(
        ContentListKindQuery(ContentKind.spell),
      );

      expect(exception.query, const ContentListKindQuery(ContentKind.spell));
      expect(exception.cause, isNull);
      expect(exception.causeStackTrace, isNull);
    });

    /// Requirement: doc/specs/content-source-port.md FR-018 - a lookup
    ///   failure carries a ContentLookupQuery with the requested key.
    /// Path: happy
    test('a lookup query carries the requested key', () {
      final exception = ContentSourceException(ContentLookupQuery(key));

      expect(
        exception.query,
        ContentLookupQuery(ContentKey(ContentKind.spell, ContentId('light'))),
      );
    });
  });

  /// Requirement: doc/specs/content-source-port.md FR-018 - the exception
  ///   is a subtype of Srd5eException.
  /// Path: happy
  test('it is an Srd5eException', () {
    expect(
      ContentSourceException(ContentLookupQuery(key)),
      isA<Srd5eException>(),
    );
  });

  /// Requirement: doc/specs/content-source-port.md FR-038 - errorType is
  ///   the constant content_source_exception: the snake_case of the class
  ///   name, matching ^[a-z][a-z0-9_]*$, the same for every instance.
  /// Path: happy
  test('errorType is the constant content_source_exception', () {
    const exception = ContentSourceException(
      ContentListKindQuery(ContentKind.trap),
    );

    expect(exception.errorType, 'content_source_exception');
    expect(RegExp(r'^[a-z][a-z0-9_]*$').hasMatch(exception.errorType), isTrue);
    expect(
      exception.errorType,
      ContentSourceException(ContentLookupQuery(key)).errorType,
    );
  });

  /// Requirement: doc/specs/content-source-port.md FR-018 - a switch over
  ///   the query is exhaustive without a default branch: the query variant
  ///   is the operation.
  /// Path: happy
  test('a switch over the query is exhaustive without a default', () {
    String describe(ContentQuery query) => switch (query) {
      ContentLookupQuery() => 'lookup',
      ContentListKindQuery() => 'listKind',
    };

    expect(
      describe(ContentSourceException(ContentLookupQuery(key)).query),
      'lookup',
    );
    expect(
      describe(
        const ContentSourceException(
          ContentListKindQuery(ContentKind.spell),
        ).query,
      ),
      'listKind',
    );
  });

  /// Requirement: doc/specs/content-source-port.md FR-019 - the exception
  ///   carries structured data only: no field or getter named message,
  ///   description, text or displayText.
  /// Path: unhappy (invalid design)
  test('no display-text member exists', () {
    final exception = ContentSourceException(ContentLookupQuery(key));

    expect(() => (exception as dynamic).message, throwsNoSuchMethodError);
    expect(() => (exception as dynamic).displayText, throwsNoSuchMethodError);
  });

  /// Requirement: doc/specs/content-source-port.md FR-019 - toString is the
  ///   debugging form carrying the query, not display text and not to be
  ///   relied on (architecture.md §6).
  /// Path: happy
  group('ContentSourceException debugging form', () {
    /// Requirement: doc/specs/content-source-port.md FR-019 - the
    ///   debugging form prints the carried query.
    /// Path: happy
    test('it prints the carried query', () {
      final lookupFailure = ContentSourceException(ContentLookupQuery(key));
      expect(
        lookupFailure.toString(),
        'ContentSourceException(ContentLookupQuery(spell/light))',
      );

      const listFailure = ContentSourceException(
        ContentListKindQuery(ContentKind.spell),
      );
      expect(
        listFailure.toString(),
        'ContentSourceException(ContentListKindQuery(spell))',
      );
    });
  });
}
