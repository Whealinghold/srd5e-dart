import 'package:srd5e/src/content/domain/tool_proficiency.dart';
import 'package:test/test.dart';

import '../../support/argument_error_matcher.dart';
import '../../support/operator_equals.dart';

/// Exhaustive over the sealed family with no default branch (FR-119).
String _describe(ToolProficiency proficiency) => switch (proficiency) {
  SpecificToolProficiency() => 'specific',
  ChoiceToolProficiency() => 'choice',
};

void main() {
  /// Requirement: doc/specs/content-schema-and-decoder.md FR-119 -
  ///   SpecificToolProficiency names one tool (SRD 5.2.1, "Parts of
  ///   a Background: Tool Proficiency", p. 83).
  /// Path: happy
  group('SpecificToolProficiency', () {
    /// Requirement: doc/specs/content-schema-and-decoder.md FR-119 - a name
    ///   per FR-027 (SRD 5.2.1, "Parts of a Background: Tool Proficiency",
    ///   p. 83).
    /// Path: happy
    test('accepts a printed tool name with its typographic apostrophe', () {
      expect(SpecificToolProficiency('Thieves’ Tools').name, 'Thieves’ Tools');
    });

    /// Requirement: doc/specs/content-schema-and-decoder.md FR-119 - the
    ///   name must be non-empty with no leading or trailing whitespace.
    /// Path: unhappy (invalid input)
    test('rejects an empty or padded name', () {
      expect(
        () => SpecificToolProficiency(''),
        throwsArgumentErrorFor('name', ''),
      );
      expect(
        () => SpecificToolProficiency(' Thieves’ Tools'),
        throwsArgumentErrorFor('name', ' Thieves’ Tools'),
      );
      expect(
        () => SpecificToolProficiency('Thieves’ Tools '),
        throwsArgumentErrorFor('name', 'Thieves’ Tools '),
      );
    });
  });

  /// Requirement: doc/specs/content-schema-and-decoder.md FR-119 -
  ///   ChoiceToolProficiency names a category to choose from (SRD
  ///   5.2.1, "Soldier", p. 83).
  /// Path: happy
  group('ChoiceToolProficiency', () {
    /// Requirement: doc/specs/content-schema-and-decoder.md FR-119 - a
    ///   non-blank category, such as Gaming Set (SRD 5.2.1, "Soldier",
    ///   p. 83).
    /// Path: happy
    test('accepts a printed category', () {
      expect(ChoiceToolProficiency('Gaming Set').category, 'Gaming Set');
    });

    /// Requirement: doc/specs/content-schema-and-decoder.md FR-119 - the
    ///   category must be non-blank.
    /// Path: unhappy (invalid input)
    test('rejects a blank category', () {
      expect(
        () => ChoiceToolProficiency(''),
        throwsArgumentErrorFor('category', ''),
      );
      expect(
        () => ChoiceToolProficiency('  '),
        throwsArgumentErrorFor('category', '  '),
      );
    });
  });

  /// Requirement: doc/specs/content-schema-and-decoder.md FR-119 - the
  ///   family is sealed with exactly the two variants, and a switch is
  ///   exhaustive without a default.
  /// Path: happy
  test('a switch over every variant selects its case', () {
    expect(
      [
        _describe(SpecificToolProficiency('Thieves’ Tools')),
        _describe(ChoiceToolProficiency('Gaming Set')),
      ],
      ['specific', 'choice'],
    );
  });

  /// Requirement: doc/specs/content-schema-and-decoder.md FR-119 - value
  ///   equality within each variant.
  /// Path: happy
  test('variants compare within their own type', () {
    expect(
      operatorEquals(
        SpecificToolProficiency('Thieves’ Tools'),
        SpecificToolProficiency('Thieves’ Tools'),
      ),
      isTrue,
    );
    expect(
      operatorEquals(
        ChoiceToolProficiency('Gaming Set'),
        ChoiceToolProficiency('Gaming Set'),
      ),
      isTrue,
    );
    expect(
      operatorEquals(
        SpecificToolProficiency('Thieves’ Tools'),
        ChoiceToolProficiency('Thieves’ Tools'),
      ),
      isFalse,
    );
  });

  /// Requirement: doc/specs/content-schema-and-decoder.md FR-119 - the
  ///   variants are value objects; hashCode and toString are part of their
  ///   value semantics.
  /// Path: happy
  test('tool proficiencies hash by value and print their parts', () {
    final specific = SpecificToolProficiency('Thieves’ Tools');
    expect(
      specific.hashCode,
      SpecificToolProficiency('Thieves’ Tools').hashCode,
    );
    expect(specific.toString(), 'SpecificToolProficiency(Thieves’ Tools)');

    final choice = ChoiceToolProficiency('Gaming Set');
    expect(choice.hashCode, ChoiceToolProficiency('Gaming Set').hashCode);
    expect(choice.toString(), 'ChoiceToolProficiency(Gaming Set)');
  });
}
