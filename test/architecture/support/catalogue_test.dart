import 'package:test/test.dart';

import 'catalogue.dart';
import 'source_set.dart';

const String _code = 'lib/src/combat/application/combat_signals.dart';

SourceSet _set(Map<String, String> files) => SourceSet(files);

void main() {
  /// Requirement: doc/specs/architecture-guardrails.md FR-042, FR-048 - the
  ///   signal and attribute constants of the *Signals classes and
  ///   AttributeKeys are read with their kind, value and line.
  /// Path: happy
  group('signalConstants', () {
    /// Requirement: doc/specs/architecture-guardrails.md FR-042, FR-048 -
    ///   the kind comes from the identifier suffix, the value from the
    ///   literal, the line from the member.
    /// Path: happy
    test('reads every kind with value and line', () {
      final found = signalConstants(
        _set({
          _code:
              'abstract final class CombatSignals {\n'
              "  static const String hitMetric = 'srd5e.combat.hit';\n"
              "  static const String turnSpan = 'srd5e.combat.turn';\n"
              "  static const String logLogEvent = 'turn started';\n"
              "  static const String kindAttribute = 'srd5e.combat.kind';\n"
              "  static const String meleeValue = 'melee';\n"
              '}\n',
        }),
      );

      expect(
        [for (final c in found) (c.kind, c.value, c.line, c.member)],
        [
          (SignalConstantKind.metric, 'srd5e.combat.hit', 2, 'hitMetric'),
          (SignalConstantKind.span, 'srd5e.combat.turn', 3, 'turnSpan'),
          (SignalConstantKind.logEvent, 'turn started', 4, 'logLogEvent'),
          (
            SignalConstantKind.attribute,
            'srd5e.combat.kind',
            5,
            'kindAttribute',
          ),
          (SignalConstantKind.value, 'melee', 6, 'meleeValue'),
        ],
      );
      expect(found.map((c) => c.isSignal), [true, true, true, false, false]);
    });

    /// Requirement: doc/specs/architecture-guardrails.md FR-048 - every
    ///   AttributeKeys member is an attribute constant, whatever its name.
    /// Path: happy
    test('AttributeKeys members need no suffix', () {
      final found = signalConstants(
        _set({
          'lib/src/shared_ports/signals.dart':
              'abstract final class AttributeKeys {\n'
              "  static const String outcome = 'srd5e.outcome';\n"
              '}\n',
        }),
      );

      expect(found.single.kind, SignalConstantKind.attribute);
      expect(found.single.className, 'AttributeKeys');
    });

    /// Requirement: doc/specs/architecture-guardrails.md FR-042 - a member
    ///   with an unknown suffix, a non-literal initialiser, a class that is
    ///   not a signals class, a file outside lib/ and text in a comment are
    ///   all ignored.
    /// Path: unhappy (false positive)
    test('ignores what is not a signal constant', () {
      final found = signalConstants(
        _set({
          _code:
              'abstract final class CombatSignals {\n'
              "  static const String other = 'srd5e.combat.other';\n"
              '  static const String hitMetric = otherName;\n'
              "  // static const String aMetric = 'srd5e.combat.a';\n"
              '}\n'
              'class Plain {\n'
              "  static const String xMetric = 'srd5e.combat.x';\n"
              '}\n',
          'test/x_signals.dart':
              'abstract final class XSignals {\n'
              "  static const String xMetric = 'srd5e.x.y';\n"
              '}\n',
        }),
      );

      expect(found, isEmpty);
    });

    /// Requirement: doc/specs/architecture-guardrails.md FR-042 - results
    ///   are sorted by path then line, and a literal on the next line is read.
    /// Path: unhappy (boundary)
    test('sorts by path and reads a wrapped initialiser', () {
      final found = signalConstants(
        _set({
          'lib/src/d20_test/application/b_signals.dart':
              'abstract final class BSignals {\n'
              '  static const String bMetric =\n'
              "      'srd5e.d20_test.b';\n"
              '}\n',
          'lib/src/combat/application/a_signals.dart':
              'abstract final class ASignals {\n'
              "  static const String aMetric = 'srd5e.combat.a';\n"
              '}\n',
        }),
      );

      expect(found.map((c) => c.value), ['srd5e.combat.a', 'srd5e.d20_test.b']);
      expect(found.last.line, 2);
    });
  });

  /// Requirement: doc/specs/architecture-guardrails.md FR-041 - the table
  ///   with the seven header cells is found and its rows split by cell count.
  /// Path: happy
  group('parseSignalCatalogue', () {
    const header =
        '| Name | Type | Unit | Attributes | Emitted by | Purpose | '
        'Suggested monitoring |\n|---|---|---|---|---|---|---|\n';

    /// Requirement: doc/specs/architecture-guardrails.md FR-041 - Name has
    ///   its backticks stripped and rows keep their lines.
    /// Path: happy
    test('reads rows and strips backticks from the Name', () {
      final parsed = parseSignalCatalogue(
        _set({
          signalCataloguePath:
              '# S\n\n$header| `a.b` | Counter | 1 | `k` | E | P | M |\n',
        }),
      );

      expect(parsed.hasTable, isTrue);
      expect(parsed.tableLine, 3);
      expect(parsed.rows.single.name, 'a.b');
      expect(parsed.rows.single.line, 5);
      expect(parsed.rows.single.attributes, '`k`');
      expect(parsed.rows.single.purpose, 'P');
      expect(parsed.rows.single.monitoring, 'M');
      expect(parsed.rows.single.type, 'Counter');
    });

    /// Requirement: doc/specs/architecture-guardrails.md FR-041 - zero data
    ///   rows is valid.
    /// Path: unhappy (empty case)
    test('a table with no rows has a table and no rows', () {
      final parsed = parseSignalCatalogue(
        _set({signalCataloguePath: '# S\n\n$header'}),
      );

      expect(parsed.hasTable, isTrue);
      expect(parsed.rows, isEmpty);
      expect(parsed.malformedRows, isEmpty);
    });

    /// Requirement: doc/specs/architecture-guardrails.md FR-041 - a row with
    ///   another cell count is set aside with its line and count.
    /// Path: unhappy (invalid input)
    test('a short row is malformed', () {
      final parsed = parseSignalCatalogue(
        _set({signalCataloguePath: '# S\n\n$header| a | b |\n'}),
      );

      expect(parsed.rows, isEmpty);
      expect(parsed.malformedRows.single, (line: 5, cells: 2));
    });

    /// Requirement: doc/specs/architecture-guardrails.md FR-041 - a table
    ///   whose header differs is not the catalogue, and an absent file is
    ///   reported as absent.
    /// Path: unhappy (missing content)
    test('other headers and a missing file', () {
      final other = parseSignalCatalogue(
        _set({signalCataloguePath: '| A | B |\n|---|---|\n| 1 | 2 |\n'}),
      );
      final absent = parseSignalCatalogue(_set({}));

      expect(other.present, isTrue);
      expect(other.hasTable, isFalse);
      expect(absent.present, isFalse);
      expect(absent.hasTable, isFalse);
    });
  });

  /// Requirement: doc/specs/architecture-guardrails.md FR-045, FR-046, FR-048
  ///   - cell helpers.
  /// Path: unhappy (boundary)
  group('cell helpers', () {
    /// Requirement: doc/specs/architecture-guardrails.md FR-048 - backticked
    ///   tokens are returned trimmed, in order.
    /// Path: happy
    test('backtickedTokens', () {
      expect(backtickedTokens('`a` (`b`, ` c `) d'), ['a', 'b', 'c']);
      expect(backtickedTokens('none'), isEmpty);
      expect(backtickedTokens(''), isEmpty);
    });

    /// Requirement: doc/specs/architecture-guardrails.md FR-045, FR-046 -
    ///   empty, whitespace and the placeholders are refused, case-insensitive,
    ///   and real text that starts with one is not.
    /// Path: unhappy (boundary)
    test('isEmptyOrPlaceholder', () {
      for (final cell in ['', '  ', 'TODO', 'tbd', 'N/A', 'n/a', '-', ' - ']) {
        expect(isEmptyOrPlaceholder(cell), isTrue, reason: cell);
      }
      for (final cell in ['N/A here', '--', 'todo later', 'x']) {
        expect(isEmptyOrPlaceholder(cell), isFalse, reason: cell);
      }
    });
  });
}
