# Dice, Rolls and the DiceRoller Port

| | |
|---|---|
| Status | implemented |
| Context | `shared_kernel`, `shared_ports` |
| Roadmap phase | 0 |
| Depends on | `errors-and-results.md` |

## 1. Purpose and scope

Placement: dice types and roll results in `shared_kernel` (`shared-types-and-ownership.md` FR-001); `DiceRoller` and its failure contract in `shared_ports`; `SeededDiceRoller` in `shared_ports/adapters/` (FR-037 there); doubles in `lib/src/testing/` (FR-038 there). Type phase 0 (FR-014 there). Roadmap: [../roadmap.md](../roadmap.md).

Defines the vocabulary every rule needs to talk about dice (a die, a die
expression such as `2d8 + 2`, the result of rolling one), the `DiceRoller`
driven port through which all randomness enters the package and its failure
contract, the test doubles in `testing.dart`, and one generic bundled adapter
(`SeededDiceRoller`) so the port has a real implementation and the contract
suite has more than one subject. The domain never rolls: use cases obtain a
`RollResult` through the port and hand it to pure domain code
(`doc/rules/architecture.md` §3, "Purity").

**Out of scope:**

- **A "Rolling Dice" section.** SRD 5.2.1 has none (contents page, p. 2, and
  Rules Glossary, pp. 176-191, searched); everything below comes from where the
  SRD *uses* dice (section 2).
- **Notation the PDF never defines:** keep-highest or drop-lowest, exploding or
  rerolled dice, `d%`, `d66`. The SRD prints `1d3` (pp. 200, 215; `Nd3` appears
  on other pages too), so `d3` is a named constant (FR-001); `d2`, `d7`, `d30`
  are not printed. FR-017 to FR-029 are the minimal reading of the single-term
  forms printed (`d20`, `1d4`, `2d8 + 2`, `D12`, `1d20 − 1`, `1d100`).
- **Multiplied dice** (`1d4 × 10 minutes`, p. 120; `6d6 × 10 feet`, p. 192): a
  consumer multiplies `total` itself; `tryParse` rejects it as `malformed`.
- **Rules that consume dice**, owned elsewhere: Advantage and Disadvantage, D20
  Tests and natural 1 / 20, Critical Hit triggering, the "0 damage but not
  negative" clamp ("Damage Rolls", p. 16), Heroic Inspiration, Hit Point
  maximum, ability score generation.
- **Types owned elsewhere** (`shared-types-and-ownership.md` FR-001, FR-002,
  FR-010): `D20Roll` and the rest of `d20_test`, `RollMode`, `Modifier`,
  `Ability`, `AbilityScore`, `DomainEvent`, the Heroic Inspiration state.
- Multi-term expressions (`1d6 + 2d4`), dice as modifiers, rerolling policy,
  statistical quality of `SeededDiceRoller`, asynchronous or I/O-backed rollers
  (consumer adapters meeting this contract).

## 2. Source

SRD 5.2.1, printed page numbers (PDF page index equals printed number).

- "D20 Tests", p. 6: "Roll 1d20 ... roll two d20s ... the higher one ... the
  lower one". Source of `d20` and `1d20`.
- "Advantage/Disadvantage", "Roll Two D20s", p. 8: an 18 and a 3; the 3 with
  Disadvantage, the 18 with Advantage. Source of "highest" and "lowest".
- "Round Down" sidebar, p. 5: round down when dividing or multiplying leaves a
  fraction.
- "Damage Rolls", p. 16: "You roll the damage dice, add any modifiers".
- "Critical Hits", p. 16: "Roll the attack's damage dice twice, add them
  together ... roll 2d4 for the damage rather than 1d4".
- "Random Generation", p. 21: "Roll four d6s and record the total of the
  highest three dice." (prints "four d6s", not `4d6`).
- "Rogue Features", p. 62: `4d6` (also pp. 46, 107).
- "Traps" (Poisoned Darts), p. 200: "struck by 1d3 darts"; "Magic Items A-Z",
  Cloak of Invisibility, p. 215: "regains 1d3 expended charges". Source of `d3`.
- Multiplied forms, pp. 120 and 192. "Trinkets", p. 26: the `1d100` table (row
  labels such as `01`). "Barbarian", Core Barbarian Traits, p. 28: "D12 per
  Barbarian level".
- "Stat Block Overview", "Hit Points" and Hit Dice by Size, p. 255: d4, d6, d8,
  d10, d12, d20 and per-die averages (2½, 3½, 4½, 5½, 6½, 10½); "roll the die
  expression in parentheses"; "2d8 + 2 Hit Points (average 11)". No maximum and
  no face range is given.
- "Damage Notation", p. 257: "4 (1d4 + 2) damage"; only the spaced `+` form.
- "Deck of Illusions", p. 217: "1d20 − 1" with U+2212. The SRD prints negative
  modifiers with U+2212 (pp. 217, 239, 302) and once with U+2013 (p. 356); never an
  ASCII hyphen. "Stat Block" HP, p. 302: "HP 7 (3d6 − 3)".
- The face range of a die (1 to its sides) is a package-design reading of "Roll
  1d20" (p. 6).

## 3. Vocabulary

| SRD term | Type | Notes |
|---|---|---|
| die / dice (d3 ... d100) | `Die` | Number of sides. Printed: d3, d4, d6, d8, d10, d12, d20, d100; not d7 or d30. |
| die expression | `DiceExpression` | Count of identical dice plus a flat modifier. SRD says "die expression" (pp. 255, 257); the binding name is `DiceExpression` (`shared-types-and-ownership.md` FR-001). No type `Dice`. |
| roll (noun) | `DieRoll` | One die and the face it showed. |
| the roll made for an expression | `RollResult` | The expression, every `DieRoll`, and the totals. |
| "roll the damage dice twice" | `DiceExpression.doubleDice()` | Doubles the count only; the modifier is "added as normal" (p. 16). |
| "the highest three dice", "the higher", "the lower" | `RollResult.sumOfHighest`, `sumOfLowest` | pp. 6, 8, 21. |
| "average" | `DiceExpression.average` | Rounded down (p. 5). |

`DiceExpression.modifier` is a plain `int` (the flat term printed in the
expression), not the kernel `Modifier` (a roll-time bonus). Exported names are
the single list in FR-067.

## 4. Requirements

Stable ids. Never renumber; new requirements get new ids.

Package-design limits: `Die.maxSides` = 1000, `DiceExpression.maxCount` = 1000,
`DiceExpression.maxModifier` = 1000000. "Rejected" for a constructor means
`ArgumentError`.

### 4.1 Die

| Id | Requirement | Source | Path |
|---|---|---|---|
| FR-001 | `Die` MUST provide named constants `d3`, `d4`, `d6`, `d8`, `d10`, `d12`, `d20`, `d100` with 3, 4, 6, 8, 10, 12, 20, 100 sides. | SRD 5.2.1, "Traps" (Poisoned Darts), p. 200, and "Magic Items A-Z" (Cloak of Invisibility), p. 215 (`1d3`, examples); "Hit Points" (Hit Dice by Size), p. 255; "Trinkets", p. 26 | happy |
| FR-002 | `Die(sides)` MUST accept any integer from 2 to `maxSides` inclusive, so content and house rules can express a die the SRD does not print (d2, d7, d30). 2 and 1000 are accepted. | n/a (package design; `architecture.md` §3, "Optional rules") | unhappy (boundary) |
| FR-003 | `Die(sides)` MUST be rejected for sides below 2 (1, 0, negative) with an `ArgumentError` carrying `name` (`sides`) and `invalidValue`. | n/a (package design; a one-sided die cannot be rolled meaningfully) | unhappy (invalid input) |
| FR-004 | `Die(sides)` MUST be rejected for sides above `maxSides` (1001). | n/a (package design; keeps arithmetic within safe integers on every platform) | unhappy (boundary) |
| FR-005 | Two `Die` values with the same sides MUST be equal with equal hash codes; different sides MUST be unequal. | n/a (value object, `architecture.md` §3) | happy |

### 4.2 DiceExpression

| Id | Requirement | Source | Path |
|---|---|---|---|
| FR-006 | `DiceExpression(count, die, modifier: 0)` MUST accept a count from 1 to `maxCount` and expose `count`, `die` and `modifier` unchanged. `1d20` and `2d8 + 2` are valid. | SRD 5.2.1, "D20 Tests", p. 6; "Hit Points", p. 255 | happy |
| FR-007 | `DiceExpression` MUST be rejected for a count below 1 (0, negative) with an `ArgumentError` carrying `name` (`count`) and `invalidValue`. | n/a (package design; a roll has at least one die) | unhappy (boundary) |
| FR-008 | `DiceExpression` MUST be rejected for a count above `maxCount` (1001); 1000 is accepted. | n/a (package design; bounds the work a roller may be asked to do) | unhappy (boundary) |
| FR-009 | `DiceExpression` MUST be rejected for a modifier whose magnitude exceeds `maxModifier` (1000001 and -1000001); 1000000 and -1000000 are accepted. | n/a (package design) | unhappy (boundary) |
| FR-010 | `DiceExpression.minimum` MUST equal `count + modifier` (every die shows 1). See the case table. | n/a (package design; follows from "Roll 1d20", SRD 5.2.1 p. 6; the SRD does not state a die's face range) | happy |
| FR-011 | `DiceExpression.maximum` MUST equal `count * sides + modifier` (every die shows its highest face). | n/a (package design; the SRD states no maximum, p. 255 gives only per-die averages) | happy |
| FR-012 | `DiceExpression.average` MUST equal `count * (sides + 1) / 2 + modifier` rounded down (towards negative infinity). See the case table. | SRD 5.2.1, "Hit Points" and Hit Dice by Size, p. 255; "Damage Notation", p. 257; "Round Down", p. 5 | happy |
| FR-013 | Two `DiceExpression` values with equal count, die and modifier MUST be equal with equal hash codes; any differing field makes them unequal. | n/a (value object) | happy |
| FR-014 | `doubleDice()` MUST return an expression with the count doubled and the same die and modifier. `1d4` gives `2d4`; `1d4 + 3` gives `2d4 + 3`. | SRD 5.2.1, "Critical Hits", p. 16 | happy |
| FR-015 | `doubleDice()` on a count above `maxCount / 2` (501) MUST be rejected with `ArgumentError` carrying `name` (`count`, naming the expression's own count, since `doubleDice()` takes no argument) and `invalidValue` (the expression's count); 500 gives 1000. A caller avoids it by checking `canDoubleDice` (FR-069). | n/a (package design; same limit as FR-008) | unhappy (boundary) |
| FR-016 | `doubleDice()` MUST NOT alter the expression it is called on. | n/a (immutability, `architecture.md` §3) | unhappy (immutability) |

Case table for FR-010, FR-011, FR-012 (one table-driven test per row):

| Label | Expression | minimum | maximum | average | Source | Path |
|---|---|---|---|---|---|---|
| one d20 | `1d20` | 1 | 20 | 10 (10½ rounded down) | p. 255 (d20 average 10½); p. 5 | happy |
| one d4 plus 2 | `1d4 + 2` | 3 | 6 | 4 (4½ rounded down) | p. 257 prints "4 (1d4 + 2)" | happy |
| two d8 plus 2 | `2d8 + 2` | 4 | 18 | 11 | p. 255 | happy |
| two d4 | `2d4` | 2 | 8 | 5 (2½ per die, twice) | p. 255 | happy |
| one d6 | `1d6` | 1 | 6 | 3 (3½ rounded down) | p. 255 | happy |
| four d6 | `4d6` | 4 | 24 | 14 (exact) | n/a (arithmetic; `4d6` printed on p. 62; p. 21 says "four d6s") | happy |
| one d100 | `1d100` | 1 | 100 | 50 (50½ rounded down) | p. 26 | happy |
| negative modifier (printed) | `3d6 - 3` | 0 | 15 | 7 (10½ - 3 = 7½ rounded down) | p. 302 prints "HP 7 (3d6 − 3)"; rounding p. 5 | happy |
| negative modifier, negative average | `1d4 - 5` | -4 | -1 | -3 (-2½ rounded down) | n/a (package design; rounding per p. 5) | unhappy (boundary) |
| largest allowed | `1000d1000 + 1000000` | 1001000 | 2000000 | 1500500 (500500 + 1000000) | n/a (limits) | unhappy (boundary) |
| smallest allowed | `1d2 - 1000000` | -999999 | -999998 | -999999 (1½ - 1000000 = -999998½ rounded down) | n/a (limits) | unhappy (boundary) |

### 4.3 Parsing and notation

`DiceExpression.tryParse(String)` is the non-throwing factory for untrusted
text (`architecture.md` §6). It returns `ParsedDiceExpression(expression)` or
`RejectedDiceExpression(reason)` (sealed `DiceExpressionParse`).
`DiceExpressionRejection`: `empty`, `malformed`, `countOutOfRange`,
`sidesOutOfRange`, `modifierOutOfRange`. One reason per parse; count is checked
before sides, sides before modifier (a factory, not a decoder, so
`errors-and-results.md` FR-035 permits one reason; its FR-023 is for decoders).

| Id | Requirement | Source | Path |
|---|---|---|---|
| FR-017 | `tryParse` MUST read the count as optional: `d20` is `1d20`. | SRD 5.2.1, "D20 Tests", p. 6 | happy |
| FR-018 | `tryParse` MUST accept `<count>d<sides>` for ASCII-digit counts and sides, for example `1d4`, `2d8`, `4d6`, `1d100`. | SRD 5.2.1, pp. 16 (`2d4`, `1d4`), 26 (`1d100`), 62 (`4d6`) | happy |
| FR-019 | `tryParse` MUST accept an upper-case `D` as the die letter (`D12`). | SRD 5.2.1, "Barbarian", p. 28 | happy |
| FR-020 | `tryParse` MUST accept an optional modifier `+<n>` or `-<n>` (ASCII `-`), written either with no spaces (`1d4+2`) or with exactly one space on each side of the sign (`2d8 + 2`, `1d4 - 5`). Asymmetric spacing (`1d4 +2`, `1d4+ 2`) and runs of more than one space (`1d4  +  2`) are `malformed`. `1d20+0`, `1d20-0` and `1d20 + 0` parse to `1d20` with modifier 0. | SRD 5.2.1, "Damage Notation", p. 257; "Hit Points", p. 255 (spaced `+` form only); unspaced, ASCII-minus and zero forms are n/a (package design) | happy |
| FR-021 | `tryParse` MUST accept the Unicode minus sign U+2212 as the modifier sign (`1d20 − 1`, `1d20−1`), under the same spacing rule as FR-020. | SRD 5.2.1, "Deck of Illusions", p. 217 | happy |
| FR-022 | `tryParse("")` MUST return `RejectedDiceExpression(empty)`. (In the tables below, `Rejected(x)` and a bare reason `x` are shorthand for `RejectedDiceExpression(x)`; the generic name `Rejected` is not exported, FR-085.) | n/a (invalid input) | unhappy (invalid input) |
| FR-023 | `tryParse` MUST return `Rejected(malformed)` for text that is not of the form in FR-017 to FR-021. See the case table. | n/a (invalid input) | unhappy (invalid input) |
| FR-024 | `tryParse` MUST return `Rejected(countOutOfRange)` for a syntactically valid count below 1 or above `maxCount` (`0d6`, `1001d6`). | n/a (limits, FR-007, FR-008) | unhappy (boundary) |
| FR-025 | `tryParse` MUST return `Rejected(sidesOutOfRange)` for sides below 2 or above `maxSides` (`1d1`, `1d0`, `1d1001`). | n/a (limits, FR-003, FR-004) | unhappy (boundary) |
| FR-026 | `tryParse` MUST return `Rejected(modifierOutOfRange)` for a modifier magnitude above `maxModifier` (`1d6+1000001`, `1d6-1000001`). | n/a (limits, FR-009) | unhappy (boundary) |
| FR-027 | `tryParse` MUST classify numbers too large to represent as an integer (`99999999999999999999d6`, `1d99999999999999999999`, `1d6+99999999999999999999`) as the matching out-of-range reason and MUST NOT throw. | n/a (invalid input) | unhappy (invalid input) |
| FR-028 | `tryParse` MUST reject surrounding whitespace, whitespace-only input (`"   "`; only the zero-length string is `empty`), whitespace inside the count or sides, the en dash U+2013 and every other non-ASCII sign or digit as `malformed`. | n/a (package design: callers trim deliberately, a lenient parse hides malformed content; spaces around the sign are accepted because the SRD prints them; the en dash is rejected, section 9) | unhappy (invalid input) |
| FR-029 | `tryParse` MUST NOT throw for any input string, including very long strings and strings with control characters. | `architecture.md` §6 (untrusted input is a result) | unhappy (invalid input) |
| FR-081 | `tryParse` MUST accept leading zeros in the count, sides and modifier digits (`01d6`, `1d006`, `1d6+007`) and read them as decimal; the value is judged after the zeros are stripped, so `0000000000000000000001d6` is `1d6` and `00d6` is `countOutOfRange`. `notation` (FR-030) never prints leading zeros. | n/a (package design; the SRD's trinket table prints `01`, p. 26, as a row label, not a die expression) | unhappy (boundary) |
| FR-030 | `DiceExpression.notation` MUST return the canonical machine form: the count always present, lower-case `d`, no spaces, ASCII sign, modifier omitted when 0 (`1d20`, `2d8+2`, `1d4-5`). It is an identifier for content and logs, not display text. `tryParse(notation)` MUST return an expression equal to the original for every valid expression. | n/a (package design; `architecture.md` §6) | happy |

Case table for FR-017 to FR-021 (accepted input):

| Label | Input | Parsed | Source | Path |
|---|---|---|---|---|
| count omitted or one | `d20`; `1d20` | `1d20` | p. 6 | happy |
| upper-case D | `D12` | `1d12` | p. 28 | happy |
| several dice; percentile-sized die | `4d6`; `1d100` | same | pp. 62, 26 | happy |
| spaced plus | `2d8 + 2`; `1d4 + 2` | same | pp. 255, 257 | happy |
| unspaced plus | `1d4+2` | `1d4 + 2` | n/a (package design) | happy |
| spaced minus | `1d4 - 5` | `1d4 - 5` | n/a (package design; ASCII hyphen, the SRD prints only U+2212) | happy |
| Unicode minus | `1d20 − 1`; `1d20−1` | `1d20 - 1` | p. 217 | happy |
| zero modifier | `1d20+0`; `1d20-0`; `1d20 + 0` | `1d20`, modifier 0 | n/a (package design; follows from "Roll 1d20", p. 6) | unhappy (boundary) |
| leading zeros (FR-081) | `01d6`; `1d006`; `1d6+007`; `0000000000000000000001d6` | `1d6`; `1d6`; `1d6 + 7`; `1d6` | n/a (package design) | unhappy (boundary) |
| d3 | `1d3` | `1d3` | pp. 200, 215 (examples) | happy |
| every limit | `1000d1000+1000000` | `1000d1000 + 1000000` | n/a (limits) | unhappy (boundary) |

Case table for FR-022 to FR-028 (rejected input; every listed input is its own
test case, all path unhappy):

| Reason | Inputs | Kind |
|---|---|---|
| `empty` | `` (zero-length string only) | invalid input |
| `malformed` | `d`; `2d`; `2x6`; `1d6+`; `1d6++1`; `1d6 + + 1`; `d+2`; `2 d6`; `2d 6`; `1.5d6`; `1d6+1.5`; `-1d6`; `+1d6` | invalid input |
| `malformed` (whitespace) | `   ` (three spaces; not `empty`); ` 1d20`; `1d20 `; `1d6\n`; `1d4 +2`; `1d4+ 2`; `1d4  +  2`; `1d20 −1`; `1d20− 1` (U+2212, asymmetric spacing) | invalid input |
| `malformed` (characters) | `1d20 – 1` (en dash U+2013, section 9); `１d20` (full-width 1) | invalid input |
| `malformed` (out of scope, section 1) | `1d4 × 10` (multiplied); `1d6+2d4` (two terms) | invalid input |
| `countOutOfRange` | `0d6`; `00d6`; `1001d6`; `0d0` (count is checked first); `99999999999999999999d6` | boundary (overflow row: invalid input) |
| `sidesOutOfRange` | `1d0`; `1d1`; `1d1001`; `1d99999999999999999999` | boundary (overflow row: invalid input) |
| `modifierOutOfRange` | `1d6+1000001`; `1d6-1000001`; `1d6+99999999999999999999` | boundary (overflow row: invalid input) |

### 4.4 DieRoll and RollResult

| Id | Requirement | Source | Path |
|---|---|---|---|
| FR-031 | `DieRoll(die, value)` MUST accept a value from 1 to `die.sides` inclusive (1 and `sides` are accepted). | n/a (package design; follows from "Roll 1d20", SRD 5.2.1 p. 6; the SRD does not state a die's face range) | unhappy (boundary) |
| FR-032 | `DieRoll(die, value)` MUST be rejected for a value of 0, a negative value, or `sides + 1`, with an `ArgumentError` carrying `name` (`value`) and `invalidValue`. | n/a (invalid input; a die cannot show a face it does not have) | unhappy (invalid input) |
| FR-033 | `RollResult(expression, rolls)` MUST accept exactly `expression.count` rolls, each of `expression.die`, and expose `expression`, `rolls` (in the order given) and `modifier`. | SRD 5.2.1, "Damage Rolls", p. 16 | happy |
| FR-034 | `RollResult` MUST be rejected when the number of rolls differs from `expression.count` (none, one fewer, one more), with an `ArgumentError` carrying `name` (`rolls`) and `invalidValue`. | n/a (invariant) | unhappy (invalid input) |
| FR-035 | `RollResult` MUST be rejected when any roll is of a different die than `expression.die`, with an `ArgumentError` carrying `name` (`rolls`) and `invalidValue`. | n/a (invariant) | unhappy (invalid input) |
| FR-036 | `RollResult.diceTotal` MUST be the sum of the face values and `total` MUST be `diceTotal + modifier`. See the case table. | SRD 5.2.1, "Damage Rolls", p. 16; "D20 Tests", p. 6 | happy |
| FR-037 | A result with every die at 1 MUST have `total == expression.minimum`, and with every die at its highest face `total == expression.maximum`. | n/a (package design; consistency of FR-010, FR-011 and FR-036) | unhappy (boundary) |
| FR-038 | `total` MAY be negative or zero (`1d4 - 5` rolling 1 gives -4). `RollResult` MUST NOT clamp it; the damage clamp belongs to the rules that apply it. | SRD 5.2.1, "Damage Rolls", p. 16 | unhappy (boundary) |
| FR-039 | `RollResult.rolls` MUST be an unmodifiable view; mutating it throws `UnsupportedError`. | n/a (`architecture.md` §4, Handoffs) | unhappy (immutability) |
| FR-040 | `RollResult` MUST copy the list it is given; mutating the original list afterwards MUST NOT change the result. | n/a (immutability) | unhappy (immutability) |
| FR-041 | `sumOfHighest(n)` MUST return the sum of the `n` highest face values, ignoring the modifier. Ties count normally; roll order does not matter. `rolls` MUST be left unchanged in order and content (no in-place sort). See the case table. | SRD 5.2.1, "Random Generation", p. 21; "Roll Two D20s", p. 8 | happy |
| FR-042 | `sumOfLowest(n)` MUST return the sum of the `n` lowest face values, ignoring the modifier. `rolls` MUST be left unchanged. | SRD 5.2.1, "D20 Tests", p. 6 ("the lower one"); "Roll Two D20s", p. 8 | happy |
| FR-043 | `sumOfHighest(n)` and `sumOfLowest(n)` MUST be rejected with `ArgumentError` (carrying `name` and `invalidValue`) for `n` below 1 or above `expression.count`. With `n == count` they MUST equal `diceTotal`. | n/a (invalid input) | unhappy (boundary) |
| FR-044 | Two `RollResult` values with equal expression and equal rolls in the same order MUST be equal with equal hash codes. | n/a (value object) | happy |

Case table for FR-036 and FR-038:

| Label | Expression | Faces | diceTotal | total | Source | Path |
|---|---|---|---|---|---|---|
| two d8 plus 2 | `2d8 + 2` | 3, 6 | 9 | 11 | p. 255 | happy |
| natural 20 | `1d20` | 20 | 20 | 20 | p. 6 | happy |
| natural 1 | `1d20` | 1 | 1 | 1 | p. 6 | unhappy (boundary) |
| d4 plus 2 high | `1d4 + 2` | 4 | 4 | 6 | p. 257 | happy |
| four d6 | `4d6` | 6, 5, 4, 1 | 16 | 16 | n/a (arithmetic; p. 21 "four d6s") | happy |
| negative total | `1d4 - 5` | 1 | 1 | -4 | p. 16 | unhappy (boundary) |
| zero total | `1d4 - 3` | 3 | 3 | 0 | p. 16 | unhappy (boundary) |

Case table for FR-041, FR-042, FR-043:

| Label | Expression | Faces | Call | Result | Source | Path |
|---|---|---|---|---|---|---|
| keep the higher of two d20s | `2d20` | 18, 3 | `sumOfHighest(1)` | 18 | p. 8 | happy |
| keep the lower of two d20s | `2d20` | 18, 3 | `sumOfLowest(1)` | 3 | p. 8 | happy |
| highest three of four d6 | `4d6` | 6, 5, 4, 1 | `sumOfHighest(3)` | 15 | p. 21 | happy |
| order does not matter | `4d6` | 1, 4, 6, 5 | `sumOfHighest(3)` | 15 | p. 21 | happy |
| all dice equal | `4d6` | 1, 1, 1, 1 | `sumOfHighest(3)` | 3 | p. 21 | unhappy (boundary) |
| ties at the cut | `4d6` | 3, 3, 3, 2 | `sumOfHighest(3)` | 9 | p. 21 | unhappy (boundary) |
| two lowest | `4d6` | 6, 1, 6, 1 | `sumOfLowest(2)` | 2 | n/a (package design; p. 6 and p. 8 only cover the lower of two d20s) | happy |
| modifier ignored | `2d20 + 5` | 18, 3 | `sumOfHighest(1)` | 18 | p. 8 | unhappy (rule interaction) |
| n equals count | `4d6` | 6, 5, 4, 1 | `sumOfHighest(4)` | 16 (`diceTotal`) | p. 21 | unhappy (boundary) |
| n is zero | `4d6` | 6, 5, 4, 1 | `sumOfHighest(0)` | `ArgumentError` | n/a | unhappy (boundary) |
| n above count | `4d6` | 6, 5, 4, 1 | `sumOfLowest(5)` | `ArgumentError` | n/a | unhappy (boundary) |
| n negative | `4d6` | 6, 5, 4, 1 | `sumOfLowest(-1)` | `ArgumentError` | n/a | unhappy (invalid input) |

### 4.4a Non-throwing construction and doubling (added ids)

Each `tryCreate` returns one of four sealed bases (`DieCreation`,
`DiceExpressionCreation`, `DieRollCreation`, `RollResultCreation`) with a
`Created<X>(value)` and a `Rejected<X>(reason)` variant carrying one typed
reason (`errors-and-results.md` FR-035). Variants are prefixed with their type
and never use the generic names `Created` or `Rejected` (FR-085). Each MUST fail
if and only if the matching constructor throws `ArgumentError`, and MUST NOT
throw for any input (`errors-and-results.md` FR-025, FR-026). Reasons are
checked in argument order.

| Id | Requirement | Source | Path |
|---|---|---|---|
| FR-069 | `DiceExpression.canDoubleDice` MUST be `true` exactly when `count * 2 <= maxCount` (500 true, 501 false), and `doubleDice()` MUST throw only when it is `false`. | n/a (package design; lets a caller handle content near the limit without knowing the private limit) | unhappy (boundary) |
| FR-070 | `Die.tryCreate(sides)` MUST return `CreatedDie` for 2 to `maxSides` and `RejectedDie(DieRejection.sidesOutOfRange)` otherwise (1, 0, negative, 1001, `int` extremes). | n/a (`architecture.md` §6) | unhappy (boundary) |
| FR-071 | `DiceExpression.tryCreate(count, die, modifier: 0)` MUST return `CreatedDiceExpression` for every argument set the constructor accepts, and otherwise `RejectedDiceExpressionInput` with `DiceExpressionRejection.countOutOfRange` or `modifierOutOfRange` (count checked first). It never returns `empty`, `malformed` or `sidesOutOfRange` (a `Die` is already valid). | n/a (`architecture.md` §6) | unhappy (boundary) |
| FR-072 | `DieRoll.tryCreate(die, value)` MUST return `CreatedDieRoll` for 1 to `die.sides` and `RejectedDieRoll(DieRollRejection.valueOutOfRange)` otherwise. | n/a (`architecture.md` §6; physical dice entered by a host) | unhappy (boundary) |
| FR-073 | `RollResult.tryCreate(expression, rolls)` MUST return `CreatedRollResult` for every input the constructor accepts, `RejectedRollResult(RollResultRejection.rollCountMismatch)` for a wrong number of rolls, and `RejectedRollResult(RollResultRejection.dieMismatch)` for a roll of another die (count checked first). It MUST copy the list (FR-040) and not mutate it. | n/a (`architecture.md` §6) | unhappy (invalid input) |
| FR-074 | Property: for a table of argument sets (valid, each boundary, each invalid kind), `tryCreate` returns a `Rejected` variant if and only if the corresponding constructor throws `ArgumentError`. | n/a (`errors-and-results.md` FR-026) | unhappy (rule conflict) |
| FR-075 | The `Rejected` variants MUST carry only the typed reason (no display text) and the sealed result classes MUST have only `final` direct subtypes. | n/a (`errors-and-results.md` FR-018, FR-020) | unhappy (invalid input) |
| FR-076 | `lib/srd5e.dart` MUST export every name in the FR-067 export list, including the four creation bases, all eight `Created*`/`Rejected*` variants and the three new rejection enums (`DieRejection`, `DieRollRejection`, `RollResultRejection`); FR-067 is the single list. | n/a (`architecture.md` §7) | happy |
| FR-077 | Every `ArgumentError` thrown by a constructor, `doubleDice`, `sumOfHighest`, `sumOfLowest`, `FixedDiceRoller` or `SeededDiceRoller` argument check in this spec MUST carry the argument `name` and the `invalidValue`. Names: `Die` `sides`; `DiceExpression` `count` or `modifier`; `doubleDice` `count` (the expression's count, FR-015); `DieRoll` `value`; `RollResult` `rolls`; `sumOfHighest`/`sumOfLowest` `n`; `FixedDiceRoller.roll` `values`, with `invalidValue` the offending value (FR-057). Tests assert type, `name` and `invalidValue`, never the message. | n/a (`errors-and-results.md` FR-027) | unhappy (invalid input) |
| FR-085 | No generic variant name (`Created`, `Rejected`, `Parsed`, `Applied`, `Succeeded`) is exported from any barrel by this spec. Every sealed result variant here is prefixed with its type or operation (`ParsedDiceExpression`, `RejectedDiceExpression`, `CreatedDie`, `RejectedDieRoll`, ...). Any shared failure detail would be a value object held as a field, not a shared variant. | `shared-types-and-ownership.md` FR-017, FR-018 | unhappy (name collision) |
| FR-086 | `DiceRollerException.errorType` MUST equal `'dice_roller_exception'` (the snake_case of the subtype name) and is the value of `error.type` wherever a use case records this failure. This replaces the earlier `'dice_roller'`; `errors-and-results.md` holds the registry of constants and lists this one. | `shared-types-and-ownership.md` FR-041 | unhappy (failure) |
| FR-087 | The dice types and the roller emit no log, span or metric, and no type in this spec takes an `Observability` argument. The d20 test's signals are owned by `resolve-d20-test-use-case.md`; this spec only supplies the `error.type` value (FR-086). | `shared-types-and-ownership.md` FR-040, FR-043 | happy |

### 4.5 DiceRoller port and its failure contract

| Id | Requirement | Source | Path |
|---|---|---|---|
| FR-045 | `DiceRoller` MUST be an abstract interface class in `shared_ports` with the single synchronous method `RollResult roll(DiceExpression expression)`. It MUST NOT return a `Future`, `FutureOr`, `null` or a sealed absence type. | n/a (`architecture.md` §4: computational ports are synchronous; rolling has no expected-absence outcome) | happy |
| FR-046 | Every implementation MUST return a `RollResult` whose `expression` equals the requested expression (same count, die and modifier). | n/a (port contract) | happy |
| FR-047 | Every implementation MUST roll exactly `expression.count` dice, each within 1 to `sides`, so `total` lies between `expression.minimum` and `expression.maximum`. | n/a (package design; follows from FR-031 and FR-033; SRD 5.2.1 p. 16 says only "roll the damage dice") | happy |
| FR-048 | An adapter whose backend can fail MUST wrap that failure with `wrapPortFailure` (`errors-and-results.md` FR-032) so a backend `Exception` surfaces as `DiceRollerException` with reason `unavailable`, the requested expression, and the original exception as `cause` (and its stack trace as `causeStackTrace`). It MUST NOT return a partial or default result, and MUST NOT leak the raw backend exception. An `Error` from the backend propagates unchanged (`errors-and-results.md` FR-011). | n/a (`architecture.md` §4, failure contract; `errors-and-results.md` FR-009, FR-032) | unhappy (failure) |
| FR-049 | `DiceRollerException` MUST be a `final` subtype of `Srd5eException` (an `abstract base class` in `lib/src/shared_ports/errors/` (FR-055 of `shared-types-and-ownership.md`), not `sealed`, so it may be extended from `shared_ports/dice_roller/`; `errors-and-results.md` §"Types"). It MUST be `const`-constructible and carry `expression`, `reason` (a `DiceRollerFailureReason`: `unavailable` or `invalidResult`; permitted by `errors-and-results.md` OQ-6), `cause` and `causeStackTrace` (unchanged instances), and return the constant `errorType == 'dice_roller_exception'` (FR-086). It carries data, not display text. | n/a (`architecture.md` §6; `errors-and-results.md` FR-002, FR-005) | unhappy (failure) |
| FR-050 | The extension `DiceRollerChecked` on `DiceRoller` provides `rollChecked(expression)`, which MUST return the roller's result when `result.expression == expression`. | n/a (port contract, FR-046) | happy |
| FR-051 | `rollChecked` MUST throw `DiceRollerException` with reason `invalidResult` and the requested expression when the roller returns a result for a different expression. One case per differing field: count, die, modifier. | n/a (testing.md §4, "collaborator returns invalid data") | unhappy (failure) |
| FR-052 | `rollChecked` MUST let a `DiceRollerException` thrown by the roller propagate unchanged (the same instance, not wrapped again). | `observability.md` §7 (recorded once, by the use case) | unhappy (failure) |
| FR-053 | `rollChecked` MUST NOT catch an `Error` thrown by the roller (`StateError`, `ArgumentError`); it propagates. | `architecture.md` §6 ("Never catch `Error`") | unhappy (state error) |

Application code that needs a roll calls `rollChecked`. Reroll-style rules (a
second roll of a single die, "Heroic Inspiration", p. 8) are further calls to
the same port, one die at a time; the reroll and replace-a-die operations live
on `D20Roll` (`shared-types-and-ownership.md` FR-002, FR-010).

### 4.6 Test doubles (`testing.dart`)

The doubles live in `lib/src/testing/`, exported only by `lib/testing.dart`
(`shared-types-and-ownership.md` FR-038); they depend only on the port, the
kernel and context barrels.

| Id | Requirement | Source | Path |
|---|---|---|---|
| FR-054 | `FixedDiceRoller(values)` MUST build each `RollResult` from the next unused values in order, across dice and across calls (`[18, 3]` serves one `2d20`, or two `1d20` calls). The supply is finite: a call needing more dice than remain (FR-056) consumes nothing and is not recorded in `requests`; likewise a call that fails FR-057. | n/a (package design; testing.md §4, determinism) | happy |
| FR-055 | `FixedDiceRoller.minimum()` MUST roll 1 on every die and `FixedDiceRoller.maximum()` MUST roll each die's highest face, for any expression. | n/a (testing.md §4, "results for fixed rolls, including extremes") | unhappy (boundary) |
| FR-056 | `FixedDiceRoller` MUST throw `StateError` when asked for more dice than it has values (a test set-up bug, not a port failure). | n/a (`architecture.md` §6, programmer error) | unhappy (state error) |
| FR-057 | `FixedDiceRoller` MUST throw `ArgumentError` (`name: 'values'`, `invalidValue`: the offending value) when the next value is outside 1 to the requested die's sides (for example 21 for a d20). | n/a (invalid input) | unhappy (invalid input) |
| FR-058 | `FixedDiceRoller.requests` MUST list the requested expressions in call order as an unmodifiable view, and `remaining` MUST report the number of unused values. | n/a (testing.md §6, specific assertions) | happy |
| FR-082 | `FixedDiceRoller` MUST copy the `values` it is given; mutating the original list after construction MUST NOT change later rolls. `FixedDiceRoller(const [])` is valid: it serves nothing, so any `roll` throws `StateError` (FR-056) and `remaining` is 0. The constructor does not validate the values; `roll` validates each value it consumes (FR-057). | n/a (package design; immutability) | unhappy (immutability) |
| FR-083 | For `FixedDiceRoller.minimum()` and `FixedDiceRoller.maximum()`, supply is unbounded: `remaining` MUST return `null` (type `int?`), they never throw `StateError`, and `requests` MUST still list every expression in call order. | n/a (package design) | unhappy (boundary) |
| FR-059 | `CallbackDiceRoller(callback)` MUST return whatever the callback returns and let anything it throws propagate unchanged, so tests can simulate `DiceRollerException` and wrong results. | n/a (testing.md §4, "collaborator failure") | unhappy (failure) |

### 4.7 Bundled adapter (`adapters.dart`)

`SeededDiceRoller` lives in `lib/src/shared_ports/adapters/` and depends only on
`shared_kernel` and the port (`shared-types-and-ownership.md` FR-037). Its
constructor takes a `Random` and nothing else; there is no `fromSeed` factory,
so a consumer or test passes `Random(7)` itself, which keeps
`observability-ports.md` FR-053 true without an exemption.

| Id | Requirement | Source | Path |
|---|---|---|---|
| FR-060 | `SeededDiceRoller(random)` MUST return a result satisfying FR-046 and FR-047 for every valid expression, including `1000d1000`. | n/a (port contract) | happy |
| FR-084 | `SeededDiceRoller` MUST call `random.nextInt` inside `wrapPortFailure` so a `Random` that throws an `Exception` yields `DiceRollerException(unavailable)` with that exception as `cause` (FR-048), and a `Random` that throws an `Error` propagates it unchanged. | n/a (`errors-and-results.md` FR-032) | unhappy (failure of collaborator) |
| FR-061 | `SeededDiceRoller` MUST call `random.nextInt(sides)` exactly once per die, in order, and map the returned `v` to the face `v + 1`. A `Random` returning 0 yields face 1; one returning `sides - 1` yields the highest face. | n/a (package design) | unhappy (boundary) |
| FR-062 | Two `SeededDiceRoller(Random(7))` instances (the test builds both `Random`s) MUST give identical results for the same sequence of expressions. Tests MUST NOT pin concrete dice values, only equality between runs. | n/a (testing.md §4, determinism) | happy |
| FR-063 | `SeededDiceRoller(Random(7))` MUST give the same faces for one `2d6` call as for two successive `1d6` calls on an equal `Random(7)` (the sequence advances per die, in order). | n/a (package design) | happy |
| FR-064 | `SeededDiceRoller` MUST use only the `Random` it was given. The adapter file `lib/src/shared_ports/adapters/seeded_dice_roller.dart` MUST contain no `Random(` call of any kind (seeded or not), so an unseeded roller is always the consumer's explicit choice. | n/a (`architecture.md` §3, no hidden non-determinism) | unhappy (determinism) |

### 4.8 Boundaries and entry points

| Id | Requirement | Source | Path |
|---|---|---|---|
| FR-065 | The import-direction checks of `architecture-guardrails.md` apply to the dice files and are not restated here: FR-023 (the `shared_kernel/dice/` files import nothing else in the package), FR-017 and FR-024 (the port, adapter and exception files under `shared_ports/`), and FR-075 (the doubles in `lib/src/testing/`). This spec adds only: "imports" in those checks means package imports; `dart:math` in the adapter file is not a package import. | n/a (`architecture-guardrails.md`; `architecture.md` §1, §9) | unhappy (state error) |
| FR-066 | The dice files under `lib/src/shared_kernel/dice/` and `lib/src/shared_ports/` contain no `Random(`, `DateTime.now(` or `Stopwatch(` call. Two existing checks cover this and neither is restated here: `observability-ports.md` FR-053 scans every file under `lib/src/shared_ports/` (adapters included), and `architecture.md` §9 scans `domain/` and `application/` only, so it does not reach the kernel or port files. The kernel dice files (`shared_kernel/dice/`) are not scanned by either check; this spec adds one architecture test over `lib/src/shared_kernel/dice/` for the same patterns. Only `seeded_dice_roller.dart` may import `dart:math` (for the `Random` type). | n/a (`architecture.md` §3, §9) | unhappy (determinism) |
| FR-067 | This change creates `lib/adapters.dart` and `lib/testing.dart` (both "planned" in `AGENTS.md`) and updates the `AGENTS.md` directory structure. `lib/srd5e.dart` MUST export exactly this list (the single export list for this spec; a sealed class's direct subtypes are exported with it, `release-0-1-0.md` FR-013): `Die`, `DiceExpression`, `DieRoll`, `RollResult`; the parse result `DiceExpressionParse`, `ParsedDiceExpression`, `RejectedDiceExpression`; the creation bases `DieCreation`, `DiceExpressionCreation`, `DieRollCreation`, `RollResultCreation`; their variants `CreatedDie`, `RejectedDie`, `CreatedDiceExpression`, `RejectedDiceExpressionInput`, `CreatedDieRoll`, `RejectedDieRoll`, `CreatedRollResult`, `RejectedRollResult`; the rejection enums `DiceExpressionRejection`, `DieRejection`, `DieRollRejection`, `RollResultRejection`; `DiceRoller`, the extension `DiceRollerChecked`, `DiceRollerException` and its `DiceRollerFailureReason` enum (the export is assigned here by `errors-and-results.md` FR-033; `Srd5eException` itself is exported by that spec). `lib/adapters.dart` MUST export `SeededDiceRoller` (from `shared_ports/adapters/`; only `lib/adapters.dart` imports adapter folders, `shared-types-and-ownership.md` FR-037) and nothing else from this spec, so it exports only symbols defined under an `adapters/` folder (`release-0-1-0.md` FR-010). `lib/testing.dart` MUST export `FixedDiceRoller` and `CallbackDiceRoller` from `lib/src/testing/`; nothing else imports `lib/src/testing/` (FR-038). Each exported member MUST have a dartdoc comment. | n/a (`architecture.md` §7) | happy |
| FR-068 | The public entry points expose a working roller and result: importing only `srd5e.dart` and `testing.dart`, a `FixedDiceRoller` serving `[18, 3]` for `2d20` MUST yield a `RollResult` through `rollChecked`. Entry-point wiring smoke test; the selection arithmetic is proven by FR-041 and FR-042. | SRD 5.2.1, "Roll Two D20s", p. 8 | happy |

### 4.9 Withdrawn ids

| Id | Status |
|---|---|
| FR-078 | Withdrawn: never issued (reserved, MUST NOT be reused) |
| FR-079 | Withdrawn: never issued (reserved, MUST NOT be reused) |
| FR-080 | Withdrawn: never issued (reserved, MUST NOT be reused) |

## 5. Model

- **Value objects** (immutable, `const` where possible, compared by value):
  `Die`, `DiceExpression`, `DieRoll`, `RollResult`, living in
  `lib/src/shared_kernel/dice/`. No entities, aggregates, events or services.
  Invariants are enforced in constructors (FR-002 to FR-009, FR-031 to FR-035,
  FR-039, FR-040).
- **Failures:** constructors and `n`-argument methods throw `ArgumentError`;
  untrusted text goes through `tryParse`, untrusted numbers through `tryCreate`
  (FR-070 to FR-073), `canDoubleDice` (FR-069) guards `doubleDice`; a port
  infrastructure failure is `DiceRollerException`, never a result.
- The domain cannot depend on `shared_ports` (`architecture.md` §1): a use case
  calls the port and passes the `RollResult` to the domain as a value.

## 6. Interface

- **Use cases:** none; other specs' use cases take a `DiceRoller` through their
  constructor (`architecture.md` §4).
- **Port `DiceRoller`:** `RollResult roll(DiceExpression)`, synchronous. A
  roller backed by I/O is outside the contract: a consumer resolves the roll
  first, validates host-supplied faces with `DieRoll.tryCreate` and
  `RollResult.tryCreate`, and serves the result through its own adapter.
- **Failure contract:** no expected-absence outcome, so no sealed result.
  `DiceRollerException(unavailable)` (FR-048) for infrastructure failure;
  `DiceRollerException(invalidResult)` from `rollChecked` (FR-051).
  `ArgumentError` and `StateError` are never wrapped.
- **Contract suite:** `test/contract/dice_roller_contract.dart` asserts FR-045
  to FR-048 against `FixedDiceRoller`, `SeededDiceRoller` (over `Random(7)` built
  by the test) and a `CallbackDiceRoller` wrapping `SeededDiceRoller`; it is not
  exported (`shared-types-and-ownership.md` FR-039). For FR-048 the harness takes
  a `failingVariant` factory (for `SeededDiceRoller`, a `Random` whose `nextInt`
  throws a `FormatException`) and asserts `DiceRollerException(unavailable)`, the
  identical `cause`, `causeStackTrace`, `errorType` and no raw leak.
- **File layout:** port, extension and `DiceRollerException` in
  `lib/src/shared_ports/dice_roller/` (extending the non-sealed `Srd5eException`
  from `lib/src/shared_ports/errors/`); adapter in
  `lib/src/shared_ports/adapters/seeded_dice_roller.dart` (`architecture-guardrails.md`
  FR-017, `release-0-1-0.md` FR-010); doubles in `lib/src/testing/`.

## 7. Observability

**Silent by design:** value objects and an in-memory port emit nothing (FR-087).

| Signal | Type | Attributes | Emitted by | Cardinality |
|---|---|---|---|---|
| none | n/a | n/a | n/a | n/a |

Signals owned by this spec: none. The shared `error.type` constant
is FR-086; the use case that lets the failure leave srd5e records it once
(`observability.md` §7; `shared-types-and-ownership.md` FR-040, FR-041; for
example `resolve-d20-test-use-case.md`). The seven questions (`observability.md`
§2):

1. **What can go wrong?** A roller cannot roll (`unavailable`); an adapter
   returns a result for another expression (`invalidResult`); untrusted dice
   text is malformed (`RejectedDiceExpression`); an invalid argument (a bug).
2. **How would an operator know?** The use case's span error status, exception
   record and error counter with `error.type=dice_roller_exception`. The port and
   adapter neither log nor count, so nothing is counted twice. A rejected parse
   is a result; the consumer that parsed decides whether to count it.
3. **What is needed to diagnose it?** `DiceRollerException` carries the
   expression (canonical `notation`, FR-030), the reason and the cause. The
   expression is never a metric or span attribute (unbounded cardinality).
4. **What should be counted or timed?** Roll throughput and latency belong to
   the rolling use case; a port-level counter would duplicate it.
5. **Is existing instrumentation still correct?** None exists yet (phase 0).
6. **What should a consumer alert on?** A non-zero rate of
   `error.type=dice_roller_exception` in the use cases' error counters; reasons
   are told apart from the span's exception record (no `reason` attribute).
7. **Is anything now noisy?** No; `SeededDiceRoller` stays silent per roll (hot
   loop, `observability.md` §7).

## 8. Test plan

Doubles: `FixedDiceRoller` and `CallbackDiceRoller` (section 4.6), tested by
FR-054 to FR-059. Mutation testing (`testing.md` §8): `mutate4dart` on
`lib/src/shared_kernel` and `lib/src/shared_ports` (`rollChecked`),
`--diff-base main`, threshold 80; FR-012 rounding and the limits (FR-002 to
FR-009, FR-015) get one case on each side of every limit. SHOULD for the
adapter and doubles.

| Ids | Level | Notes |
|---|---|---|
| FR-001 to FR-005 | unit | `test/shared_kernel/dice/die_test.dart`; constants' sides; boundary table 1, 2, 1000, 1001, 0, negative; equality and hash code. |
| FR-006 to FR-016, FR-069 | unit | `dice_expression_test.dart`; limit tables; FR-010 to FR-012 table-driven, one test per row of the first case table (includes the negative-average rounding row); equality; `doubleDice` limit at 501, `canDoubleDice` at 500 and 501, original unchanged. |
| FR-017 to FR-030, FR-081 | unit | `dice_expression_parse_test.dart`; table-driven over the accepted and rejected tables, asserting the exact `DiceExpressionRejection`; FR-081 rows plus `00d6`; FR-029 a fixed list of hostile strings (very long, control characters, lone surrogates) asserting a result variant and no throw (a seeded generated loop is allowed, never an unseeded `Random`); FR-030 canonical output table plus round trip over every accepted row. |
| FR-031 to FR-044 | unit | `die_roll_test.dart` boundary values; `roll_result_test.dart`: count and die mismatch; totals table (extremes via `minimum` and `maximum`); `UnsupportedError` on mutation and source list edited after construction; selection table including `ArgumentError` rows, asserting `rolls` unchanged in order and content after each call; equality. |
| FR-045 to FR-048 | contract | `dice_roller_contract.dart` run against every implementation (section 6); FR-045 is a compile-time typed assignment; FR-048 through `failingVariant` on `SeededDiceRoller` over a throwing `Random`, asserting typed exception, `cause`, `causeStackTrace`, no raw leak. |
| FR-049, FR-086 | unit | `test/shared_ports/dice_roller/dice_roller_exception_test.dart`: fields, `cause` and `causeStackTrace` identity, `errorType == 'dice_roller_exception'`, `Srd5eException` subtype, exhaustive `switch` over `reason`. |
| FR-050 to FR-053 | application (port helper, with double) | `roll_checked_test.dart` (imports a double, `testing.md` §3), using `CallbackDiceRoller` to return a wrong result (one case per differing field), throw a `DiceRollerException` (same instance), throw a `StateError`. |
| FR-054 to FR-059, FR-082, FR-083 | unit | `test/testing/fixed_dice_roller_test.dart`; FR-058: `requests` order and `UnsupportedError` on mutation, `remaining` counts down after each roll; empty list, defensive copy, atomic failure (nothing consumed or recorded), `remaining == null` for `minimum()`/`maximum()`; `callback_dice_roller_test.dart` for FR-059. |
| FR-070 to FR-077 | unit | `tryCreate` tables, one case each side of every limit; the iff property (FR-074) as a table over valid and invalid argument sets; `name` and `invalidValue` asserted on every `ArgumentError`; FR-076 in the public-surface test. |
| FR-060, FR-084 | contract | `seeded_dice_roller_test.dart`; also a `1000d1000` call; FR-084 through the failing variant plus an `Error`-throwing `Random` that must propagate. |
| FR-061 to FR-063 | contract | Fake `Random` recording `nextInt` bounds and returning scripted values (bound, count, order, `+ 1` mapping at both extremes); FR-062/FR-063 compare two instances over equal `Random(7)` built by the test, never pinning concrete values. |
| FR-064 | contract, architecture | Fake `Random` records every call, so only the injected instance is used; the adapter file contains no `Random(` call (`observability-ports.md` FR-053 scan). |
| FR-065, FR-066 | architecture | Guardrails cover import direction and `shared_ports/` banned calls; one added test over `lib/src/shared_kernel/dice/` (no `Random(`, `DateTime.now(`, `Stopwatch(`) with a fixture row proving it flags each pattern. |
| FR-067, FR-085, FR-087 | architecture (FR-087 also unit) | Public-surface test imports only the three entry points (doubles via `lib/testing.dart` only, FR-038 there) and references each exported name; `public_member_api_docs` covers dartdoc; barrel scan for generic variant names (`shared-types-and-ownership.md` FR-017); FR-087: no dice type takes an `Observability` argument (public-surface test), and a scan of `lib/src/shared_kernel/dice/` and `lib/src/shared_ports/dice_roller/` finds no logger, tracer or meter call (shares the FR-066 fixture-backed test). Every FR appears above; none is left uncovered. `AGENTS.md` updated in the same change. |
| FR-068 | scenario | `test/scenarios/dice_scenario_test.dart`, public API only; a wiring smoke test, not repeating FR-041/FR-042. |

Deliberately not covered: FR-065 - a pointer row; the import-direction checks it names (architecture-guardrails.md FR-023, FR-017, FR-024 and FR-075) are owned by that spec and not yet implemented, so the dice files get them when those checks land (deferred to those check ids).
Deliberately not covered: FR-078 - withdrawn, never issued; the id is reserved and has no behaviour to test.
Deliberately not covered: FR-079 - withdrawn, never issued; the id is reserved and has no behaviour to test.
Deliberately not covered: FR-080 - withdrawn, never issued; the id is reserved and has no behaviour to test.

## 9. Open questions and decisions

Settled (not repeated): name `DiceExpression`, `modifier` as `int`, `SeededDiceRoller`
and the adapter and double placement (`shared-types-and-ownership.md` FR-001,
FR-037, FR-038); one parse reason (`errors-and-results.md` FR-035); `error.type`
registration (FR-086); other choices are FR-002, FR-030, FR-064, FR-069.

| Question | Recommendation | Status |
|---|---|---|
| The SRD has no "Rolling Dice" section. Is resting on the usages in section 2 acceptable? | Yes: the only reading compliant with "if it is not in that PDF, it does not go in". Anything else (keep-highest, `d%`, multiple terms) stays out until a rule needs it. | decided |
| Limits `maxSides` 1000, `maxCount` 1000, `maxModifier` 1000000. | Keep: safe integer arithmetic on web targets and a bound on roller work, not an SRD rule. Raising later is non-breaking, lowering breaking. | decided |
| Accept the en dash U+2013 as a minus (the SRD prints it once, `1d4 – 1`, p. 356, against U+2212 everywhere else)? (FR-028) | Reject as `malformed`: one printed instance is a typographic inconsistency, not a notation; a parser that accepted every dash look-alike would hide bad content. Revisit if content needs it (FR-021 extension is non-breaking). | decided |
| `average` rounds negative values by floor. The SRD's "Round Down" (p. 5) gives no negative example. | Floor towards negative infinity, pinned by the `1d4 - 5` row; revisit only if a rule needs truncation. Package-design decision (interpretation: "Round Down" says to round down a fraction, which for a negative value is towards negative infinity). | decided |

## 10. Changelog impact

Under `Unreleased` / **Added**: dice value objects (`Die`, `DiceExpression`,
`DieRoll`, `RollResult`), `DiceExpression.tryParse`, the `DiceRoller` port with
`DiceRollerException` (`errorType` `dice_roller_exception`) and `rollChecked`,
`SeededDiceRoller` (`adapters.dart`), and `FixedDiceRoller` /
`CallbackDiceRoller` (`testing.dart`). Not **BREAKING**: first code under
`lib/src/`, no earlier release exists.
