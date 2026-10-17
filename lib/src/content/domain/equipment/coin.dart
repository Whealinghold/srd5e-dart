/// One of the five coins ("Coins", SRD 5.2.1, p. 89), in printed order
/// (FR-009, FR-098).
///
/// The wire spelling is the printed abbreviation. [copperValue] is the Coin
/// Values table row: the worth of one coin in Copper Pieces.
enum Coin {
  /// Copper Piece, worth 1 Copper Piece.
  cp('CP', 1),

  /// Silver Piece, worth 10 Copper Pieces.
  sp('SP', 10),

  /// Electrum Piece, worth 50 Copper Pieces.
  ep('EP', 50),

  /// Gold Piece, worth 100 Copper Pieces.
  gp('GP', 100),

  /// Platinum Piece, worth 1,000 Copper Pieces.
  pp('PP', 1000);

  const Coin(this.jsonValue, this.copperValue);

  /// The printed abbreviation used in JSON.
  final String jsonValue;

  /// The worth of one coin of this denomination in Copper Pieces
  /// ("Coin Values", SRD 5.2.1, p. 89).
  final int copperValue;

  /// The member whose [jsonValue] is [value], or null for a non-member: the
  /// decoder turns a non-member into `invalidValue` (FR-105, FR-080).
  static Coin? fromJson(String value) => switch (value) {
    'CP' => cp,
    'SP' => sp,
    'EP' => ep,
    'GP' => gp,
    'PP' => pp,
    _ => null,
  };
}
