/// The FR-078 telemetry pin over the real slice
/// (doc/specs/content-thin-slice.md FR-078): loading the three embedded
/// slice documents through `LoadContentSet`, one call per document, with a
/// recording `Observability` and the real decoder. The per-kind counts
/// lapse with the bulk data (thin-slice section 1, "Lifecycle"); until
/// then they are asserted here.
library;

import 'package:srd5e/adapters.dart';
import 'package:srd5e/src/content/application/content_signals.dart';
import 'package:srd5e/src/content/application/load_content_set.dart';
import 'package:srd5e/src/content/data/class_wizard.dart' show classWizardJson;
import 'package:srd5e/src/content/data/species.dart' show speciesJson;
import 'package:srd5e/src/content/data/spells.dart' show spellsJson;
import 'package:srd5e/src/shared_ports/signals.dart';
import 'package:srd5e/testing.dart';
import 'package:test/test.dart';

void main() {
  /// Requirement: doc/specs/content-thin-slice.md FR-078 - three calls,
  ///   one per document, add across the calls 4 entries_loaded for
  ///   species, 1 for character_class and 12 for spell (nothing for other
  ///   kinds), add nothing to decode_errors, and add three loads with
  ///   outcome success, one per call; each call is a separate top-level
  ///   call, no use case calling another
  ///   (content-schema-and-decoder.md FR-079 to FR-082).
  /// Path: happy
  test('three loads of the slice documents record the slice counts', () {
    const decoder = JsonContentSetDecoder();
    final recorded = RecordingObservability();
    final useCase = LoadContentSet(
      decoder,
      observability: recorded.observability,
    );
    final documents = [
      ('species.json', speciesJson),
      ('class_wizard.json', classWizardJson),
      ('spells.json', spellsJson),
    ];

    for (final (name, text) in documents) {
      final result = useCase.call(LoadContentSetCommand(text));
      expect(result, isA<LoadContentSetLoaded>(), reason: '$name loads');
    }

    // entries_loaded: 4 species, 1 character_class, 12 spell. Only these
    // three keys appear, so no other kind gains a record, not even add(0)
    // (content-schema-and-decoder.md FR-081).
    final entriesByKind = <String, int>{};
    for (final measurement in recorded.meter.measurementsNamed(
      ContentSignals.entriesLoadedMetric,
    )) {
      final kind = measurement.attributes[ContentSignals.kindAttribute];
      expect(kind, isA<String>(), reason: 'every add carries the kind');
      final key = kind! as String;
      entriesByKind[key] =
          (entriesByKind[key] ?? 0) + (measurement.value as int);
    }
    expect(entriesByKind, {'species': 4, 'character_class': 1, 'spell': 12});

    // decode_errors: zero problems across the three documents (FR-078).
    expect(
      recorded.meter.measurementsNamed(ContentSignals.decodeErrorsMetric),
      isEmpty,
    );

    // loads: three increments, one per call, each outcome success
    // (FR-080).
    final loads = recorded.meter.measurementsNamed(ContentSignals.loadsMetric);
    expect(loads, hasLength(3));
    for (final load in loads) {
      expect(
        load.attributes[AttributeKeys.outcome],
        ContentSignals.outcomeSuccessValue,
      );
      expect(load.attributes.containsKey(AttributeKeys.errorType), isFalse);
    }

    // Nothing is logged for either outcome (content-schema-and-decoder.md
    // FR-083).
    expect(recorded.logger.records, isEmpty);
  });
}
