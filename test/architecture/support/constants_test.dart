import 'dart:io';

import 'package:test/test.dart';

import 'constants.dart';
import 'package_root.dart';
import 'source_set.dart';

/// The text of the repository file at [path].
String readRepoFile(String path) =>
    File('${findPackageRoot().path}/$path').readAsStringSync();

/// The table row of [id] (`| FR-n | ...`) in [markdown].
///
/// Throws a [StateError] when the row is missing, so a renamed row fails the
/// self-test instead of passing vacuously.
String rowOf(String markdown, String id) => markdown
    .split('\n')
    .firstWhere(
      (line) => line.startsWith('| $id |'),
      orElse: () => throw StateError('no table row for $id'),
    );

/// The backticked tokens of [text].
Set<String> backticked(String text) => {
  for (final match in RegExp(r'`([^`]+)`').allMatches(text)) match.group(1)!,
};

/// The text of the level-2 section of [markdown] whose heading starts with
/// [heading] (for example `## 5.`), up to the next level-2 heading.
String sectionOf(String markdown, String heading) {
  final start = markdown.indexOf('\n$heading');
  if (start < 0) throw StateError('no section $heading');
  final next = markdown.indexOf('\n## ', start + 1);
  return markdown.substring(start, next < 0 ? markdown.length : next);
}

/// The pairs (key, value) of [sets] whose key or value is not backticked in
/// [section].
List<String> setValuesMissingFrom(
  Map<String, Set<String>> sets,
  String section,
) {
  final tokens = backticked(section);
  return [
    for (final MapEntry(:key, :value) in sets.entries) ...[
      if (!tokens.contains(key)) key,
      for (final v in value)
        if (!tokens.contains(v)) '$key=$v',
    ],
  ];
}

/// The backticked tokens of the first sentence of [cell] that are a path
/// ending in `/` (FR-079 (a)).
Set<String> coveredPathTokens(String firstSentence) => {
  for (final token in backticked(firstSentence))
    if (RegExp(r'^[A-Za-z0-9_.-]+(/[A-Za-z0-9_.-]+)*/$').hasMatch(token)) token,
};

/// The sentence of [row] that starts at [start], ending at the first full stop
/// followed by a space.
String sentenceFrom(String row, String start) {
  final from = row.indexOf(start);
  if (from < 0) throw StateError('no sentence starting $start');
  final end = RegExp(r'\.\s').firstMatch(row.substring(from));
  return end == null
      ? row.substring(from)
      : row.substring(from, from + end.start + 1);
}

const _guardrails = 'doc/specs/architecture-guardrails.md';
const _decisions = 'doc/specs/shared-types-and-ownership.md';

void main() {
  /// Requirement: doc/specs/architecture-guardrails.md FR-009 - the named
  ///   constants are the only exemptions, and hold the values the specs name.
  /// Path: happy
  group('constants hold the specified values', () {
    /// Requirement: doc/specs/architecture-guardrails.md FR-013 and FR-014 -
    ///   the platform entry-point set is empty today.
    /// Path: happy
    test('platform entry points are empty', () {
      expect(platformEntryPoints, isEmpty);
    });

    /// Requirement: doc/specs/architecture-guardrails.md FR-026 - the exempt
    ///   paths are the rule files and the pubspec repository line.
    /// Path: happy
    test('consumer scan exempt paths', () {
      expect(consumerScanExemptFiles, {'AGENTS.md', 'CLAUDE.md'});
      expect(consumerScanExemptLineFile, 'pubspec.yaml');
      expect(
        consumerScanExemptLine.hasMatch(
          'repository: https://github.com/example/srd5e-dart',
        ),
        isTrue,
      );
    });

    /// Requirement: doc/specs/architecture-guardrails.md FR-026 - only the
    ///   `repository:` line is exempt, not other lines of the pubspec.
    /// Path: unhappy (boundary)
    test('consumer scan exempt line is only the repository line', () {
      expect(consumerScanExemptLine.hasMatch('homepage: x'), isFalse);
      expect(consumerScanExemptLine.hasMatch('  repository: x'), isFalse);
    });

    /// Requirement: doc/specs/architecture-guardrails.md FR-032 - the SDK
    ///   package and library denylist.
    /// Path: happy
    test('SDK denylist', () {
      expect(sdkPackagePrefixes, [
        'opentelemetry',
        'dart_opentelemetry',
        'sentry',
        'logging',
        'logger',
        'datadog',
        'bugsnag',
        'newrelic',
        'firebase_crashlytics',
      ]);
      expect(sdkLibraries, {'dart:developer'});
    });

    /// Requirement: doc/specs/architecture-guardrails.md FR-083 - the
    ///   dependency allowlist is `collection` and `meta`.
    /// Path: happy
    test('dependency allowlist', () {
      expect(dependencyAllowlist, {'collection', 'meta'});
    });

    /// Requirement: doc/specs/architecture-guardrails.md FR-077 - the generic
    ///   variant names.
    /// Path: happy
    test('generic variant names', () {
      expect(genericVariantNames, {
        'Applied',
        'Rejected',
        'Succeeded',
        'ContentMissing',
        'Found',
        'NotFound',
      });
    });

    /// Requirement: doc/specs/architecture-guardrails.md FR-081 - the double
    ///   prefixes.
    /// Path: happy
    test('double prefixes', () {
      expect(doublePrefixes, [
        'Fake',
        'Recording',
        'Fixed',
        'Scripted',
        'Stub',
        'Spy',
        'Mock',
      ]);
    });

    /// Requirement: doc/specs/architecture-guardrails.md FR-082 - the port
    ///   handles.
    /// Path: happy
    test('port handles', () {
      expect(portHandles, {'Span', 'Counter', 'Histogram', 'Gauge'});
    });

    /// Requirement: doc/specs/architecture-guardrails.md FR-036 and FR-085 -
    ///   the reserved attribute key and the shared value sets.
    /// Path: happy
    test('reserved key and shared attribute value sets', () {
      expect(reservedAttributeKeys, {'error.type'});
      expect(exceptionTypeAttributeKey, 'error.type');
      expect(sharedAttributeValueSets, {
        'srd5e.outcome': {'success', 'failure'},
        'srd5e.d20_test.kind': {'ability_check', 'saving_throw', 'attack_roll'},
        'srd5e.d20_test.roll_mode': {'normal', 'advantage', 'disadvantage'},
        'srd5e.d20_test.critical_hit': {'true', 'false'},
      });
    });

    /// Requirement: doc/specs/architecture-guardrails.md FR-085 - the sets
    ///   are closed: the reserved key has no fixed set here.
    /// Path: unhappy (boundary)
    test('the exception type key has no fixed value set', () {
      expect(
        sharedAttributeValueSets.containsKey(exceptionTypeAttributeKey),
        isFalse,
      );
    });

    /// Requirement: doc/specs/architecture-guardrails.md FR-079, FR-098,
    ///   FR-096 and FR-099 - notice paths, leaf contexts, placeholder and
    ///   data spec names.
    /// Path: happy
    test('notice, leaf, placeholder and data spec constants', () {
      expect(noticeCoveredPaths, {
        'data/',
        'lib/src/content/data/',
        'test/fixtures/srd/',
      });
      expect(leafContexts, {'toolbox'});
      expect(placeholderSpecNames, {'x', 'y', 'z'});
      expect(dataSpecs, {
        'content-thin-slice',
        'content-species-backgrounds-feats',
        'content-equipment',
        'content-spells',
        'content-monsters',
        'content-classes',
        'content-magic-items',
      });
    });

    /// Requirement: doc/specs/architecture-guardrails.md FR-102 and FR-101 -
    ///   the index path and the rank-90 threshold.
    /// Path: happy
    test('documentation index path and rank threshold', () {
      expect(documentationIndexPath, 'doc/documentation_index.md');
      expect(highRankThreshold, 90);
    });

    /// Requirement: doc/specs/architecture-guardrails.md FR-002 - the excluded
    ///   paths are the SourceSet loader's own sets, not a copy.
    /// Path: happy
    test('excluded paths are the SourceSet sets', () {
      expect(
        identical(excludedDirectories, SourceSet.excludedDirectories),
        isTrue,
      );
      expect(identical(excludedFiles, SourceSet.excludedFiles), isTrue);
    });
  });

  /// Requirement: doc/specs/architecture-guardrails.md FR-068 and FR-069 -
  ///   every denylist entry is assembled from fragments and matches in each
  ///   form of FR-025.
  /// Path: happy
  group('denylist entries', () {
    final lists = <String, List<DeniedName>>{
      'consumer': consumerDenylist,
      'trademark': trademarkDenylist,
      'affiliate': affiliateDenylist,
    };

    /// Requirement: per case
    /// Path: per case
    for (final MapEntry(key: listName, value: entries) in lists.entries) {
      for (var i = 0; i < entries.length; i++) {
        final entry = entries[i];
        final label = '$listName entry ${i + 1}';
        final forms = <String, String>{
          'comment': '// note: ${entry.name}\n',
          'string': "final s = '${entry.name}';",
          'path': 'lib/src/${entry.name}/x.dart',
          'upper case': entry.name.toUpperCase(),
          'hyphen separators': entry.spelled('-'),
          'underscore separators': entry.spelled('_'),
          'space separators': entry.spelled(' '),
        };
        for (final MapEntry(key: form, value: text) in forms.entries) {
          test('$label matches in the $form form [happy]', () {
            expect(entry.appearsIn(text), isTrue);
          });
        }

        test('$label is not matched by its first fragment alone '
            '[unhappy (boundary)]', () {
          expect(entry.appearsIn(entry.fragments.first), isFalse);
        });

        test('$label has more than one fragment [unhappy (boundary)]', () {
          expect(entry.fragments.length, greaterThan(1));
        });
      }
    }

    /// Requirement: doc/specs/architecture-guardrails.md FR-025 - text with no
    ///   denylist name yields no hit, and the bare licensor name is on no
    ///   list.
    /// Path: unhappy (false positive)
    test('unrelated text and the bare licensor name match nothing', () {
      const text = 'The SRD 5.2.1 is licensed by Wizards of the Coast LLC.';

      expect(deniedNamesIn(text, allDeniedNames), isEmpty);
    });

    /// Requirement: doc/specs/architecture-guardrails.md FR-025 - the scan
    ///   returns every entry it finds, in list order.
    /// Path: unhappy (multiple violations)
    test('deniedNamesIn returns every matching entry in list order', () {
      final text =
          '${trademarkDenylist[1].name} then ${trademarkDenylist[0].name}';

      expect(deniedNamesIn(text, trademarkDenylist), [
        trademarkDenylist[0],
        trademarkDenylist[1],
      ]);
    });

    /// Requirement: doc/specs/architecture-guardrails.md FR-025 - ignoring
    ///   `-`, `_` and spaces, case-insensitively.
    /// Path: unhappy (boundary)
    test('normaliseName lower-cases and drops hyphen, underscore, space', () {
      expect(normaliseName('A-b_C d\te\nF'), 'abcdef');
    });
  });

  /// Requirement: doc/specs/architecture-guardrails.md FR-068 - the denylist
  ///   source and its test hold no name in plain text, in any list.
  /// Path: unhappy (invalid input)
  group(
    'plain-text scan of the denylist source',
    timeout: const Timeout(Duration(seconds: 10)),
    () {
      for (final path in const [
        'test/architecture/support/constants.dart',
        'test/architecture/support/constants_test.dart',
      ]) {
        /// Requirement: doc/specs/architecture-guardrails.md FR-068 - no list
        ///   entry appears in the file.
        /// Path: unhappy (invalid input)
        test('$path names no denylist entry', () {
          final text = readRepoFile(path);

          expect(deniedNamesIn(text, allDeniedNames), isEmpty);
        });
      }

      /// Requirement: doc/specs/architecture-guardrails.md FR-068 - the scan
      ///   itself can fail: a file that spells an entry is caught.
      /// Path: unhappy (failure)
      test('a file that spells an entry in plain text is detected', () {
        final spelled = 'const x = "${consumerDenylist.first.name}";';

        expect(deniedNamesIn(spelled, allDeniedNames), isNotEmpty);
      });
    },
  );

  /// Requirement: doc/specs/architecture-guardrails.md FR-025 and FR-026 -
  ///   the consumer denylist names the subject that AGENTS.md states and the
  ///   hosting organisation of the pubspec repository URL.
  /// Path: happy
  group(
    'consumer denylist matches its sources',
    timeout: const Timeout(Duration(seconds: 10)),
    () {
      /// Requirement: doc/specs/architecture-guardrails.md FR-026 - AGENTS.md
      ///   "Hard constraints" names every consumer entry.
      /// Path: unhappy (state error)
      test('AGENTS.md names every consumer entry', () {
        final agents = readRepoFile('AGENTS.md');

        for (final entry in consumerDenylist) {
          expect(entry.appearsIn(agents), isTrue, reason: entry.normalised);
        }
      });

      /// Requirement: doc/specs/architecture-guardrails.md FR-026 - the
      ///   pubspec `repository:` line is the one place the name appears, and
      ///   it carries the hosting organisation.
      /// Path: unhappy (state error)
      test('the pubspec repository line carries the organisation', () {
        final line = readRepoFile(
          'pubspec.yaml',
        ).split('\n').firstWhere(consumerScanExemptLine.hasMatch);

        expect(deniedNamesIn(line, consumerDenylist), isNotEmpty);
      });

      /// Requirement: doc/specs/architecture-guardrails.md FR-026 - no other
      ///   pubspec line names a consumer.
      /// Path: unhappy (invalid input)
      test('no other pubspec line names a consumer', () {
        final others = readRepoFile('pubspec.yaml')
            .split('\n')
            .where((l) => !consumerScanExemptLine.hasMatch(l))
            .join('\n');

        expect(deniedNamesIn(others, consumerDenylist), isEmpty);
      });
    },
  );

  /// Requirement: doc/specs/architecture-guardrails.md FR-009 - constants that
  ///   copy a decision fail a self-test when the source text drifts.
  /// Path: unhappy (state error)
  group(
    'constants against their source text',
    timeout: const Timeout(Duration(seconds: 10)),
    () {
      late String guardrails;
      late String decisions;
      late String observability;
      late String architecture;
      late String agents;

      setUpAll(() {
        guardrails = readRepoFile(_guardrails);
        decisions = readRepoFile(_decisions);
        observability = readRepoFile('doc/rules/observability.md');
        architecture = readRepoFile('doc/rules/architecture.md');
        agents = readRepoFile('AGENTS.md');
      });

      /// Requirement: doc/specs/architecture-guardrails.md FR-079 - the
      ///   notice paths equal the covered-path tokens of the first sentence
      ///   of the FR-033 row of shared-types-and-ownership.md.
      /// Path: unhappy (state error)
      test('noticeCoveredPaths equals the FR-033 row sentence', () {
        final sentence = sentenceFrom(
          rowOf(decisions, 'FR-033'),
          '`NOTICE.md` covers exactly:',
        );

        expect(coveredPathTokens(sentence), noticeCoveredPaths);
      });

      /// Requirement: doc/specs/architecture-guardrails.md FR-079 - tokens
      ///   after the first sentence (the `doc/research/` note) are not in
      ///   the set, and the sentence ends at a full stop and a space.
      /// Path: unhappy (boundary)
      test('the FR-079 sentence rule ignores later sentences', () {
        const row =
            '| FR-033 | `NOTICE.md` covers exactly: `a/`, `b/c/`. '
            'Notes in `doc/research/` are not distributed. | x | happy |';

        final sentence = sentenceFrom(row, '`NOTICE.md` covers exactly:');

        expect(coveredPathTokens(sentence), {'a/', 'b/c/'});
      });

      /// Requirement: doc/specs/architecture-guardrails.md FR-079 - a source
      ///   row that adds a path makes the comparison unequal (the drift is
      ///   detectable).
      /// Path: unhappy (failure)
      test('an added source path would differ from the constant', () {
        const row =
            '| FR-033 | `NOTICE.md` covers exactly: `data/`, '
            '`lib/src/content/data/`, `test/fixtures/srd/`, `docs/`. | x |';

        final sentence = sentenceFrom(row, '`NOTICE.md` covers exactly:');

        expect(coveredPathTokens(sentence), isNot(noticeCoveredPaths));
      });

      /// Requirement: doc/specs/architecture-guardrails.md FR-085 - every set
      ///   value is backticked in observability.md section 5.
      /// Path: unhappy (state error)
      test(
        'shared attribute value sets appear in observability.md section 5',
        () {
          final section = sectionOf(observability, '## 5.');

          expect(
            setValuesMissingFrom(sharedAttributeValueSets, section),
            isEmpty,
          );
        },
      );

      /// Requirement: doc/specs/architecture-guardrails.md FR-085 - the
      ///   self-test fails when one value is deleted from a copy of the
      ///   section.
      /// Path: unhappy (failure)
      test('a value deleted from section 5 is reported', () {
        final section = sectionOf(
          observability,
          '## 5.',
        ).replaceAll('`failure`', 'x');

        expect(setValuesMissingFrom(sharedAttributeValueSets, section), [
          'srd5e.outcome=failure',
        ]);
      });

      /// Requirement: doc/specs/architecture-guardrails.md FR-085 - the
      ///   reserved key `error.type` is backticked in section 5.
      /// Path: unhappy (state error)
      test('the reserved attribute key appears in section 5', () {
        final tokens = backticked(sectionOf(observability, '## 5.'));

        expect(tokens, containsAll(reservedAttributeKeys));
      });

      /// Requirement: doc/specs/architecture-guardrails.md FR-098 - the
      ///   FR-045 row of shared-types-and-ownership.md still names each leaf
      ///   context in backticks.
      /// Path: unhappy (state error)
      test('leaf contexts appear in the decisions FR-045 row', () {
        final tokens = backticked(rowOf(decisions, 'FR-045'));

        expect(tokens, containsAll(leafContexts));
      });

      /// Requirement: doc/specs/architecture-guardrails.md FR-099 - the FR-047
      ///   row names each data spec, the schema and the source port in
      ///   backticks, and the FR-067 row names `content-classes-data`.
      /// Path: unhappy (state error)
      test('data specs appear in the decisions FR-047 and FR-067 rows', () {
        final fr47 = backticked(rowOf(decisions, 'FR-047'));
        final fr67 = backticked(rowOf(decisions, 'FR-067'));

        expect(
          fr47,
          containsAll({
            ...dataSpecs,
            'content-schema-and-decoder',
            'content-source-port',
          }),
        );
        expect(fr67, contains('content-classes-data'));
      });

      /// Requirement: doc/specs/architecture-guardrails.md FR-101 - the
      ///   rank table puts `architecture-guardrails` at the rank-90
      ///   threshold.
      /// Path: unhappy (state error)
      test('the rank table has this spec at the threshold', () {
        final row = RegExp(r'^\| (\d+) \| (.*) \|$', multiLine: true)
            .allMatches(decisions)
            .firstWhere(
              (m) =>
                  backticked(m.group(2)!).contains('architecture-guardrails'),
            );

        expect(int.parse(row.group(1)!), highRankThreshold);
      });

      /// Requirement: doc/specs/architecture-guardrails.md FR-096 - the
      ///   placeholder names are not real specs, so the exemption cannot hide
      ///   a citation of one.
      /// Path: unhappy (rule interaction)
      test('no spec file has a placeholder name', () {
        for (final name in placeholderSpecNames) {
          expect(
            File('${findPackageRoot().path}/doc/specs/$name.md').existsSync(),
            isFalse,
            reason: name,
          );
        }
      });

      /// Requirement: doc/specs/architecture-guardrails.md FR-102 - the
      ///   documentation index exists at the constant's path.
      /// Path: unhappy (missing content)
      test('the documentation index exists', () {
        expect(
          File(
            '${findPackageRoot().path}/$documentationIndexPath',
          ).existsSync(),
          isTrue,
        );
      });

      /// Requirement: doc/specs/architecture-guardrails.md FR-077 - the
      ///   generic variant names are backticked in architecture.md section 9.
      /// Path: unhappy (state error)
      test('generic variant names appear in architecture.md', () {
        final tokens = backticked(sectionOf(architecture, '## 9.'));

        expect(tokens, containsAll(genericVariantNames));
      });

      /// Requirement: doc/specs/architecture-guardrails.md FR-081 and FR-082 -
      ///   the double prefixes and port handles are backticked in their own
      ///   spec rows.
      /// Path: unhappy (state error)
      test('double prefixes and port handles appear in their spec rows', () {
        final fr81 = backticked(rowOf(guardrails, 'FR-081'));
        final fr82 = rowOf(guardrails, 'FR-082');
        final handles = RegExp(
          r'`\{([^}]*)\}`',
        ).firstMatch(fr82)!.group(1)!.split(',').map((s) => s.trim()).toSet();

        expect(fr81, containsAll(doublePrefixes));
        expect(handles, portHandles);
      });

      /// Requirement: doc/specs/architecture-guardrails.md FR-032 - the SDK
      ///   packages and `dart:developer` are backticked in the FR-032 row.
      /// Path: unhappy (state error)
      test('SDK denylist appears in the FR-032 row', () {
        final tokens = backticked(rowOf(guardrails, 'FR-032'));

        expect(tokens, containsAll(sdkPackagePrefixes));
        expect(tokens, containsAll(sdkLibraries));
      });

      /// Requirement: doc/specs/architecture-guardrails.md FR-083 - AGENTS.md
      ///   allows only `collection` and `meta` as runtime dependencies.
      /// Path: unhappy (state error)
      test('dependency allowlist appears in AGENTS.md', () {
        final hardConstraints = sectionOf(agents, '## Hard constraints');

        expect(backticked(hardConstraints), containsAll(dependencyAllowlist));
      });

      /// Requirement: doc/specs/architecture-guardrails.md FR-002 - the
      ///   excluded directories and files are backticked in the FR-002 row.
      /// Path: unhappy (state error)
      test('excluded paths appear in the FR-002 row', () {
        final tokens = backticked(rowOf(guardrails, 'FR-002'));

        expect(
          tokens,
          containsAll({for (final d in excludedDirectories) '$d/'}),
        );
        expect(tokens, containsAll(excludedFiles));
      });

      /// Requirement: doc/specs/architecture-guardrails.md FR-026 - the
      ///   exempt files are named in the FR-026 row.
      /// Path: unhappy (state error)
      test('consumer scan exempt files appear in the FR-026 row', () {
        final tokens = backticked(rowOf(guardrails, 'FR-026'));

        expect(tokens, containsAll(consumerScanExemptFiles));
        expect(tokens, contains(consumerScanExemptLineFile));
      });
    },
  );
}
