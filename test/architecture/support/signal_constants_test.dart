import 'package:test/test.dart';

import 'signal_constants.dart';
import 'source_set.dart';

const String _file = 'lib/src/combat/application/combat_signals.dart';

SignalsClass _only(String source, {String path = _file}) {
  final classes = signalsClassesIn(SourceSet({path: source}), path);
  expect(classes, hasLength(1));
  return classes.single;
}

void main() {
  group('signalKindOf', () {
    /// Requirement: doc/specs/architecture-guardrails.md section 3 - the identifier suffix tells the kind
    ///   of a signals class member.
    /// Path: happy
    test('maps each suffix to its kind', () {
      expect(signalKindOf('attackMetric'), SignalKind.metric);
      expect(signalKindOf('attackSpan'), SignalKind.span);
      expect(signalKindOf('loadedLogEvent'), SignalKind.logEvent);
      expect(signalKindOf('kindAttribute'), SignalKind.attribute);
      expect(signalKindOf('okValue'), SignalKind.value);
    });

    /// Requirement: doc/specs/architecture-guardrails.md FR-037 - a name with
    ///   no known suffix has no kind.
    /// Path: unhappy (boundary)
    test('maps a bare or near-miss name to unsuffixed', () {
      expect(signalKindOf('attack'), SignalKind.unsuffixed);
      expect(signalKindOf('spanCount'), SignalKind.unsuffixed);
      expect(signalKindOf('Metrics'), SignalKind.unsuffixed);
    });
  });

  group('signalsClassesIn', () {
    /// Requirement: doc/specs/architecture-guardrails.md FR-037 - members
    ///   are static const String declarations with their plain literal.
    /// Path: happy
    test('reads names, lines, values, modifiers and doc comments', () {
      final c = _only(
        'abstract final class CombatSignals {\n'
        '  /// The `srd5e.outcome` attribute.\n'
        '  /// Second line.\n'
        "  static const String okValue = 'success';\n"
        '  static const String other = r"x";\n'
        '}\n',
      );

      expect(c.name, 'CombatSignals');
      expect(c.isAbstractFinal, isTrue);
      expect(c.members.map((m) => (m.name, m.line, m.value)), [
        ('okValue', 4, 'success'),
        ('other', 5, 'x'),
      ]);
      expect(c.members.first.docComment, contains('`srd5e.outcome`'));
      expect(c.members.first.docComment, contains('Second line.'));
      expect(c.members.last.docComment, isEmpty);
    });

    /// Requirement: doc/specs/architecture-guardrails.md FR-037 - only a
    ///   single plain literal counts as a value.
    /// Path: unhappy (invalid input)
    test(
      'gives no value to interpolated, concatenated or adjacent literals',
      () {
        final c = _only(
          'abstract final class CombatSignals {\n'
          "  static const String a = 'x\$y';\n"
          "  static const String b = 'x' + 'y';\n"
          "  static const String c = 'x' 'y';\n"
          "  static const String d = 'x' '' 'y';\n"
          '  static const String e = other;\n'
          '}\n',
        );

        expect(c.members.map((m) => m.value), everyElement(isNull));
        expect(c.members.map((m) => m.literalOffset), everyElement(isNull));
      },
    );

    /// Requirement: doc/specs/architecture-guardrails.md FR-037 - members of
    ///   nested bodies and other member shapes are not signal constants.
    /// Path: unhappy (false positive)
    test('ignores members in methods and non-const-String fields', () {
      final c = _only(
        'abstract final class CombatSignals {\n'
        "  static const int count = 1;\n"
        "  static final String s = 'x';\n"
        '  static String f() {\n'
        "    const String inner = 'x';\n"
        '    return inner;\n'
        '  }\n'
        "  static const String realSpan = 'a';\n"
        '}\n',
      );

      expect(c.members.map((m) => m.name), ['realSpan']);
    });

    /// Requirement: doc/specs/architecture-guardrails.md FR-037 - only
    ///   classes named *Signals or AttributeKeys are signals classes.
    /// Path: unhappy (false positive)
    test('skips other classes, comments and strings', () {
      final sources = SourceSet({
        _file:
            'class Helper {\n  static const String xSpan = "a";\n}\n'
            '// class FakeSignals {}\n'
            "const s = 'class FakeSignals {}';\n"
            'abstract final class AttributeKeys {\n'
            "  static const String outcome = 'srd5e.outcome';\n"
            '}\n',
      });

      final classes = signalsClassesIn(sources, _file);

      expect(classes.map((c) => c.name), [attributeKeysClassName]);
      expect(classes.single.members.single.isAttributeKey, isTrue);
      expect(classes.single.members.single.effectiveKind, SignalKind.attribute);
    });

    /// Requirement: doc/specs/architecture-guardrails.md FR-037 - a class
    ///   not declared abstract final is reported as such.
    /// Path: unhappy (invalid input)
    test('records a class that is not abstract final', () {
      expect(_only('class CombatSignals {\n}\n').isAbstractFinal, isFalse);
      expect(
        _only('final class CombatSignals {\n}\n').isAbstractFinal,
        isFalse,
      );
    });
  });

  group('SignalIndex', () {
    /// Requirement: doc/specs/architecture-guardrails.md section 3
    ///   (constants file) - application/*signals.dart files and the
    ///   shared_ports file declaring AttributeKeys.
    /// Path: happy
    test('finds the constants files', () {
      final index = SignalIndex.of(
        SourceSet({
          _file: '',
          'lib/src/combat/application/ports/x_signals.dart': '',
          'lib/src/combat/application/signals_helper.dart': '',
          'lib/src/combat/domain/x_signals.dart': '',
          'lib/src/shared_ports/signals.dart':
              'abstract final class AttributeKeys {\n}\n',
          'lib/src/shared_ports/other.dart': '',
          'lib/src/combat/domain/keys.dart':
              'abstract final class AttributeKeys {\n}\n',
        }),
      );

      expect(index.constantsFiles, {
        _file,
        'lib/src/shared_ports/signals.dart',
      });
      expect(index.isConstantsFile(_file), isTrue);
      expect(index.isConstantsFile('lib/src/combat/domain/keys.dart'), isFalse);
    });

    /// Requirement: doc/specs/architecture-guardrails.md FR-072 - only lib/
    ///   is indexed.
    /// Path: happy
    test('ignores files outside lib/', () {
      final index = SignalIndex.of(
        SourceSet({
          'test/a_test.dart': 'abstract final class XSignals {\n}\n',
          'tool/a.dart': 'abstract final class XSignals {\n}\n',
        }),
      );

      expect(index.classes, isEmpty);
      expect(index.constants, isEmpty);
    });

    /// Requirement: doc/specs/architecture-guardrails.md FR-038 - the kind
    ///   of a constant: AttributeKeys members are attributes, others by
    ///   suffix; metric, span and log event are signals.
    /// Path: unhappy (boundary)
    test('isSignal is true for metric, span and log event only', () {
      final index = SignalIndex.of(
        SourceSet({
          _file:
              'abstract final class CombatSignals {\n'
              "  static const String aMetric = 'a';\n"
              "  static const String bSpan = 'b';\n"
              "  static const String cLogEvent = 'c';\n"
              "  static const String dAttribute = 'd';\n"
              "  static const String eValue = 'e';\n"
              "  static const String f = 'f';\n"
              '}\n',
          'lib/src/shared_ports/signals.dart':
              'abstract final class AttributeKeys {\n'
              "  static const String gMetric = 'g';\n"
              '}\n',
        }),
      );

      expect(
        [for (final c in index.constants) (c.name, c.isSignal)],
        [
          ('aMetric', true),
          ('bSpan', true),
          ('cLogEvent', true),
          ('dAttribute', false),
          ('eValue', false),
          ('f', false),
          ('gMetric', false),
        ],
      );
    });
  });

  group('contextFolderOf', () {
    /// Requirement: doc/specs/architecture-guardrails.md FR-038 - the
    ///   context folder is the folder directly under lib/src/ that is not a
    ///   shared module.
    /// Path: happy
    test('names the context or null', () {
      expect(contextFolderOf(_file), 'combat');
      expect(contextFolderOf('lib/src/d20_test/domain/a.dart'), 'd20_test');
      expect(contextFolderOf('lib/src/shared_ports/signals.dart'), isNull);
      expect(contextFolderOf('lib/src/testing/a.dart'), isNull);
      expect(contextFolderOf('lib/src/a.dart'), isNull);
      expect(contextFolderOf('lib/srd5e.dart'), isNull);
      expect(contextFolderOf('test/src/combat/a/b.dart'), isNull);
    });
  });
}
