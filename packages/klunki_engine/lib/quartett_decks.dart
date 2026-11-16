part of 'quartett.dart';

/// One themed Quartett deck (KLD-069): 32 cards in 8 sets `A`–`H` of 4
/// (ids `A1`…`H4`), each card with a value for every stat of the deck.
///
/// [id] is stable (network config, preferences, l10n keys); [name] and
/// [setNames] are the engine's German texts for the CLI and the debug
/// console (the app localizes them by [id] and set letter). Card names of
/// the vehicle decks are real vehicle names and stay untranslated; the app
/// translates the animal names by deck and card id (KLD-128) and the type
/// word of three special vehicles (KLD-130). The engine's
/// German card name is gameplay data (compat fingerprint) and never depends
/// on the display language.
///
/// The vehicle values are plausible, rounded figures from general knowledge,
/// not verified data (`docs/tasks/KLD-069-quartett-decks.md`); the animal
/// motorcycle and special vehicle values are sourced (KLD-128, KLD-129,
/// KLD-130). See the comment above each deck. To add a deck: build it with [QuartettDeck.build], add it
/// to [QuartettDeck.all], then add its set names (and any new stat labels) to
/// the ARB files and a pictogram in the app.
class QuartettDeck {
  final String id;
  final String name;
  final List<QuartettStat> stats;
  final Map<String, String> setNames;
  final List<Card> cards;

  /// Gameplay revision of this deck (KLD-085): bump it whenever cards,
  /// stats (ids, order, [QuartettStat.higherWins]) or values change, not for
  /// labels, formats or photos. Two devices compare it to tell which one is
  /// older when their deck fingerprints differ ([contentFingerprint]); the
  /// fingerprint itself catches a forgotten bump.
  final int revision;
  final Map<String, Card> _byId;

  QuartettDeck._(this.id, this.name, this.stats, this.setNames, this.cards, this.revision)
      : _byId = {for (final c in cards) c.id: c};

  /// Builds a deck from rows `(id, name, values)`; `values` follow [stats].
  factory QuartettDeck.build({
    required String id,
    required String name,
    required List<QuartettStat> stats,
    required Map<String, String> setNames,
    required List<(String, String, List<num>)> rows,
    int revision = 1,
  }) {
    final cards = [
      for (final (cardId, cardName, values) in rows)
        Card(
          id: cardId,
          name: cardName,
          set: cardId[0],
          deck: id,
          stats: {for (var i = 0; i < stats.length && i < values.length; i++) stats[i].id: values[i]},
        ),
    ]..sort((a, b) => a.id.compareTo(b.id));
    return QuartettDeck._(id, name, List.unmodifiable(stats), Map.unmodifiable(setNames), List.unmodifiable(cards),
        revision);
  }

  /// Looks up a card by id; null if unknown.
  Card? cardById(String id) => _byId[id];

  QuartettStat? statById(String id) {
    for (final s in stats) {
      if (s.id == id) return s;
    }
    return null;
  }

  /// The cards of [set], sorted by id.
  List<Card> cardsOf(String set) => [for (final c in cards) if (c.set == set) c];

  /// Problems with this deck (empty = valid): 32 cards, ids `A1`…`H4`, 8 sets
  /// of 4 with a name each, every stat present on every card, unique stat ids.
  List<String> validate() {
    final problems = <String>[];
    if (cards.length != 32) problems.add('$id: ${cards.length} cards, expected 32');
    final ids = cards.map((c) => c.id).toSet();
    if (ids.length != cards.length) problems.add('$id: duplicate card ids');
    const letters = ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H'];
    if (setNames.keys.toSet().difference(letters.toSet()).isNotEmpty || setNames.length != 8) {
      problems.add('$id: set names must cover exactly A–H');
    }
    for (final l in letters) {
      for (var n = 1; n <= 4; n++) {
        if (!ids.contains('$l$n')) problems.add('$id: missing card $l$n');
      }
    }
    if (stats.map((s) => s.id).toSet().length != stats.length) problems.add('$id: duplicate stat ids');
    if (stats.length < 5 || stats.length > 6) problems.add('$id: ${stats.length} stats, expected 5–6');
    for (final s in stats) {
      if (s.isYear && s.unit.isNotEmpty) problems.add('$id: year stat ${s.id} has a unit');
    }
    for (final c in cards) {
      if (c.deck != id) problems.add('$id: card ${c.id} belongs to deck ${c.deck}');
      if (c.name.trim().isEmpty) problems.add('$id: card ${c.id} has no name');
      for (final s in stats) {
        final v = c.stats[s.id];
        if (v == null) {
          problems.add('$id: card ${c.id} lacks ${s.id}');
        } else if (v < 0 || !v.isFinite) {
          problems.add('$id: card ${c.id} has a bad ${s.id} ($v)');
        } else {
          final scaled = v * pow(10, s.decimals);
          if ((scaled - scaled.round()).abs() > 1e-6) {
            problems.add('$id: card ${c.id} ${s.id} = $v has more than ${s.decimals} decimals');
          }
          if (s.isYear && (v < 1800 || v > 2100)) problems.add('$id: card ${c.id} ${s.id} = $v is not a year');
        }
      }
      if (c.stats.length != stats.length) problems.add('$id: card ${c.id} has extra stats');
    }
    return problems;
  }

  /// Share of card pairs that tie on [stat] (0–1): how often a Trumpf pick
  /// on it would go to the pot.
  double tieRate(String stat) {
    var ties = 0, pairs = 0;
    for (var i = 0; i < cards.length; i++) {
      for (var j = i + 1; j < cards.length; j++) {
        pairs++;
        if (cards[i].stats[stat] == cards[j].stats[stat]) ties++;
      }
    }
    return pairs == 0 ? 0 : ties / pairs;
  }

  /// Id of the default deck, used when a config names none (pre-KLD-069).
  static const String defaultId = 'cars';

  static final QuartettDeck cars = _cars();
  static final QuartettDeck trains = _trains();
  static final QuartettDeck rockets = _rockets();
  static final QuartettDeck planes = _planes();
  static final QuartettDeck animals = _animals();
  static final QuartettDeck motorcycles = _motorcycles();
  static final QuartettDeck specialVehicles = _specialVehicles();

  /// Every deck, in picker order.
  static final List<QuartettDeck> all =
      List.unmodifiable([cars, trains, rockets, planes, animals, motorcycles, specialVehicles]);

  /// The deck with [id]; null if unknown. A null [id] is the default deck.
  static QuartettDeck? byId(String? id) {
    if (id == null) return cars;
    for (final d in all) {
      if (d.id == id) return d;
    }
    return null;
  }

  @override
  String toString() => 'QuartettDeck($id)';
}

// Stats shared by several decks use one id with one meaning (label, unit and
// direction), so the app needs one translation per id.
const _kmh = QuartettStat(id: 'kmh', label: 'Höchstgeschwindigkeit', unit: 'km/h');
const _lengthM = QuartettStat(id: 'lengthM', label: 'Länge', unit: 'm', decimals: 1);
// KLD-082: number built replaces the year stats ("older/newer" was a poor
// trump); the rockets got a success rate instead.
const _built = QuartettStat(id: 'built', label: 'Gebaut', unit: 'Stk.');

/// Cars: the original KLD-024 deck. Values: manufacturer figures as commonly
/// quoted, rounded; electric cars have 0 cm³ (shown as "–").
QuartettDeck _cars() => QuartettDeck.build(
      id: 'cars',
      name: 'Autos',
      stats: const [
        QuartettStat(id: 'ps', label: 'Leistung', unit: 'PS'),
        _kmh,
        QuartettStat(id: 'ccm', label: 'Hubraum', unit: 'cm³', zeroAsDash: true),
        QuartettStat(id: 'kg', label: 'Gewicht', unit: 'kg', higherWins: false),
        QuartettStat(id: 'sec0to100', label: '0–100 km/h', unit: 's', higherWins: false, decimals: 1, fixedDecimals: true),
      ],
      setNames: const {
        'A': 'Supersportwagen',
        'B': 'Hypercars',
        'C': 'Klassiker',
        'D': 'Muscle Cars',
        'E': 'Rallye-Legenden',
        'F': 'Gran Turismo',
        'G': 'Elektro',
        'H': 'Kleine Flitzer',
      },
      rows: const [
        ('A1', 'Porsche 911 Turbo S', [650, 330, 3745, 1640, 2.7]),
        ('A2', 'Ferrari F8 Tributo', [720, 340, 3902, 1435, 2.9]),
        ('A3', 'Lamborghini Huracán EVO', [640, 325, 5204, 1422, 2.9]),
        ('A4', 'McLaren 720S', [720, 341, 3994, 1419, 2.9]),
        ('B1', 'Bugatti Chiron', [1500, 420, 7993, 1995, 2.4]),
        ('B2', 'Koenigsegg Jesko', [1600, 480, 5065, 1420, 2.5]),
        ('B3', 'Pagani Huayra', [800, 383, 5980, 1350, 2.8]),
        ('B4', 'Rimac Nevera', [1914, 412, 0, 2300, 1.9]),
        ('C1', 'Mercedes 300 SL', [215, 260, 2996, 1295, 9.3]),
        ('C2', 'Jaguar E-Type', [269, 241, 3781, 1234, 7.0]),
        ('C3', 'Ferrari 250 GTO', [300, 280, 2953, 880, 6.1]),
        ('C4', 'Lamborghini Miura', [350, 280, 3929, 1180, 6.7]),
        ('D1', 'Ford Mustang Shelby GT500', [760, 290, 5163, 1916, 3.7]),
        ('D2', 'Dodge Challenger Hellcat', [717, 315, 6166, 2000, 3.6]),
        ('D3', 'Chevrolet Camaro ZL1', [659, 318, 6162, 1800, 4.0]),
        ('D4', 'Chevrolet Corvette Z06', [680, 315, 5500, 1600, 2.6]),
        ('E1', 'Lancia Delta Integrale', [215, 220, 1995, 1300, 5.7]),
        ('E2', 'Audi Sport quattro', [306, 250, 2133, 1300, 4.8]),
        ('E3', 'Subaru Impreza WRX STI', [300, 255, 2457, 1500, 5.2]),
        ('E4', 'Mitsubishi Lancer Evo IX', [280, 250, 1997, 1400, 4.8]),
        ('F1', 'Aston Martin DB11 V12', [608, 322, 5204, 1875, 3.9]),
        ('F2', 'Bentley Continental GT', [659, 335, 5950, 2244, 3.6]),
        ('F3', 'Mercedes-AMG GT R', [585, 318, 3982, 1630, 3.6]),
        ('F4', 'Nissan GT-R Nismo', [600, 315, 3799, 1725, 2.8]),
        ('G1', 'Tesla Model S Plaid', [1020, 322, 0, 2162, 2.1]),
        ('G2', 'Porsche Taycan Turbo S', [761, 260, 0, 2295, 2.8]),
        ('G3', 'Lucid Air Sapphire', [1234, 330, 0, 2375, 1.9]),
        ('G4', 'Audi e-tron GT', [646, 250, 0, 2350, 3.3]),
        ('H1', 'Mini Cooper S', [178, 235, 1998, 1265, 6.7]),
        ('H2', 'VW Polo GTI', [207, 238, 1984, 1355, 6.5]),
        ('H3', 'Toyota GR Yaris', [261, 230, 1618, 1280, 5.5]),
        ('H4', 'Abarth 595 Competizione', [180, 218, 1368, 1120, 7.3]),
      ],
    );

/// Trains. Approximate, unverified: rounded figures from general knowledge.
/// Top speed is the service maximum, except for the record vehicles named so
/// (TGV V150, Taurus, L0, Shanghai Transrapid: record or design speed).
/// Length and mass are for the whole unit as commonly built (loco only for
/// locomotives, steam locos with tender). Starting tractive effort of
/// multiple units is an estimate. "Gebaut" (KLD-082, approximate,
/// unverified): units built of the class (trainsets for multiple units,
/// locomotives of the class for locos, e.g. LNER A3 for the Flying Scotsman,
/// A4 for Mallard; 1 for one-offs like TGV V150 and 18 201; Fuxing CR400AF
/// and N700S still in production).
QuartettDeck _trains() => QuartettDeck.build(
      id: 'trains',
      name: 'Züge',
      revision: 2, // KLD-082: number built instead of the year stat
      stats: const [
        _kmh,
        QuartettStat(id: 'kw', label: 'Leistung', unit: 'kW'),
        _lengthM,
        QuartettStat(id: 'massT', label: 'Gewicht', unit: 't', higherWins: false),
        QuartettStat(id: 'tractiveKn', label: 'Anfahrzugkraft', unit: 'kN'),
        _built,
      ],
      setNames: const {
        'A': 'ICE',
        'B': 'Shinkansen',
        'C': 'TGV',
        'D': 'Europas Schnelle',
        'E': 'Asien & Amerika',
        'F': 'E-Loks',
        'G': 'Dampf-Legenden',
        'H': 'Güter-Riesen',
      },
      rows: const [
        ('A1', 'ICE 1', [280, 9600, 358, 849, 400, 60]),
        ('A2', 'ICE T', [230, 4000, 184.4, 368, 170, 71]),
        ('A3', 'ICE 3', [330, 8000, 200.8, 409, 300, 67]),
        ('A4', 'ICE 4', [265, 9900, 346, 670, 470, 137]),
        ('B1', 'Shinkansen 0', [220, 11840, 400.3, 970, 420, 250]),
        ('B2', 'Shinkansen 300', [270, 12000, 402.1, 711, 430, 69]),
        ('B3', 'Shinkansen N700S', [300, 17080, 404.7, 715, 520, 66]),
        ('B4', 'Shinkansen E5', [320, 9960, 253, 453, 330, 59]),
        ('C1', 'TGV Sud-Est', [260, 6450, 200.2, 385, 210, 109]),
        ('C2', 'TGV Atlantique', [300, 8800, 237.6, 444, 260, 105]),
        ('C3', 'TGV Duplex', [320, 8800, 200, 380, 220, 89]),
        ('C4', 'TGV V150', [575, 19600, 106, 268, 350, 1]),
        ('D1', 'Eurostar e320', [320, 16000, 400, 965, 380, 17]),
        ('D2', 'AVE S-103', [350, 8800, 200.3, 425, 283, 26]),
        ('D3', 'Frecciarossa 1000', [360, 9800, 202, 500, 370, 50]),
        ('D4', 'Talgo 350', [330, 8000, 200.5, 357, 240, 46]),
        ('E1', 'Fuxing CR400AF', [350, 10140, 209.1, 455, 360, 450]),
        ('E2', 'KTX-Sancheon', [305, 8800, 201, 403, 290, 24]),
        ('E3', 'Shanghai Transrapid', [431, 8000, 153, 300, 190, 3]),
        ('E4', 'Acela (Avelia Liberty)', [260, 9200, 210, 560, 340, 28]),
        ('F1', 'Baureihe 103', [200, 7440, 20.2, 114, 312, 149]),
        ('F2', 'Baureihe 101', [220, 6400, 19.1, 84, 300, 145]),
        ('F3', 'SBB Re 460', [230, 6100, 18.5, 83, 275, 119]),
        ('F4', 'Siemens Taurus ES64U4', [357, 6400, 19.6, 87, 300, 100]),
        ('G1', 'Flying Scotsman', [161, 1640, 21.3, 158, 146, 79]),
        ('G2', 'Mallard', [203, 1700, 21.6, 168, 158, 35]),
        ('G3', 'DR 18 201', [182, 1800, 25.6, 177, 142, 1]),
        ('G4', 'Big Boy', [130, 4700, 40.5, 548, 602, 25]),
        ('H1', 'SBB Krokodil', [65, 1650, 19.4, 128, 314, 51]),
        ('H2', 'EMD SD70ACe', [113, 3200, 22.6, 188, 850, 1500]),
        ('H3', 'GE AC6000CW', [120, 4500, 23.2, 192, 738, 317]),
        ('H4', 'Class 66', [121, 2385, 21.4, 126, 409, 480]),
      ],
    );

/// Rockets (launch vehicles). Approximate, unverified: height, liftoff
/// thrust, payload to low Earth orbit and launch mass for the most common or
/// most powerful configuration, rounded. Launches are approximate counts as
/// of about 2025 (the family where noted on the card name); a flight number
/// replaces the brief's "stages" stat, which ties too often (most rockets
/// have 2 or 3 stages).
///
/// "Erfolgsquote" (KLD-082, approximate, unverified): fully successful
/// launches / launches in %, one decimal, as of about 2025. Partial failures
/// count as failures (Saturn V: Apollo 6; Delta IV Heavy: demo flight;
/// Ariane 6: first flight); for the reusable set B a lost booster on a
/// planned landing counts as a partial failure too (Falcon 9, Falcon Heavy
/// center cores, New Glenn NG-1). Energija: the Polyus flight is counted as
/// a failure (its payload did not reach orbit). Few flights, so the rate
/// says little: SLS (1), New Glenn (2), Energija (2), N1 (4), Vega C (4),
/// Ariane 6 (5), H3, Epsilon and Firefly Alpha (6 each), LVM3 (7).
QuartettDeck _rockets() => QuartettDeck.build(
      id: 'rockets',
      name: 'Raketen',
      revision: 2, // KLD-082: flights and success rate instead of the year stats
      stats: const [
        QuartettStat(id: 'heightM', label: 'Höhe', unit: 'm', decimals: 1),
        QuartettStat(id: 'thrustKn', label: 'Startschub', unit: 'kN'),
        QuartettStat(id: 'leoT', label: 'Nutzlast (LEO)', unit: 't', decimals: 2),
        QuartettStat(id: 'launchMassT', label: 'Startmasse', unit: 't'),
        QuartettStat(id: 'flights', label: 'Starts', unit: ''),
        QuartettStat(id: 'successPct', label: 'Erfolgsquote', unit: '%', decimals: 1),
      ],
      setNames: const {
        'A': 'Mondraketen',
        'B': 'Wiederverwendbar',
        'C': 'Europa',
        'D': 'USA-Klassiker',
        'E': 'Russland',
        'F': 'China',
        'G': 'Japan & Indien',
        'H': 'Kleine Träger',
      },
      rows: const [
        ('A1', 'Saturn V', [110.6, 35100, 140, 2970, 13, 92.3]),
        ('A2', 'Saturn IB', [68.1, 7100, 21, 590, 9, 100]),
        ('A3', 'SLS Block 1', [98.1, 39100, 95, 2610, 1, 100]),
        ('A4', 'N1', [105.3, 45400, 95.5, 2750, 4, 0]),
        ('B1', 'Falcon 9', [70, 7600, 22.8, 549, 550, 97.5]),
        ('B2', 'Falcon Heavy', [70, 22800, 63.8, 1420, 11, 72.7]),
        ('B3', 'Starship', [121, 74400, 150, 5000, 11, 45.5]),
        ('B4', 'New Glenn', [98, 17100, 45, 1500, 2, 50]),
        ('C1', 'Ariane 5', [53, 13000, 21.5, 780, 117, 95.7]),
        ('C2', 'Ariane 6 (A64)', [63, 15400, 21.6, 860, 5, 80]),
        ('C3', 'Vega C', [35, 4500, 3.3, 210, 4, 75]),
        ('C4', 'Ariane 4', [58.7, 5400, 7.6, 470, 116, 97.4]),
        ('D1', 'Atlas V', [58.3, 8000, 18.8, 590, 100, 99]),
        ('D2', 'Delta IV Heavy', [72, 9400, 28.8, 733, 16, 93.8]),
        ('D3', 'Space Shuttle', [56.1, 30200, 27.5, 2030, 135, 98.5]),
        ('D4', 'Titan IV B', [44, 15200, 21.7, 940, 39, 89.7]),
        ('E1', 'Sojus-U', [51.1, 4000, 6.9, 313, 786, 97.2]),
        ('E2', 'Proton-M', [58.2, 10000, 23, 705, 115, 90.4]),
        ('E3', 'Angara A5', [55.4, 9600, 24.5, 773, 8, 87.5]),
        ('E4', 'Energija', [58.8, 34800, 100, 2400, 2, 50]),
        ('F1', 'Langer Marsch 5', [57, 10600, 25, 870, 14, 92.9]),
        ('F2', 'Langer Marsch 2F', [62, 6000, 8.4, 480, 23, 100]),
        ('F3', 'Langer Marsch 3B', [56.3, 5900, 11.5, 456, 100, 95]),
        ('F4', 'Langer Marsch 2C', [43, 2960, 3.9, 233, 70, 98.6]),
        ('G1', 'H3', [63, 7000, 6.5, 575, 6, 83.3]),
        ('G2', 'H-IIB', [56.6, 10000, 19, 531, 9, 100]),
        ('G3', 'PSLV', [44, 4800, 3.8, 320, 60, 93.3]),
        ('G4', 'LVM3', [43.4, 9000, 10, 640, 7, 100]),
        ('H1', 'Electron', [18, 190, 0.3, 13, 70, 94.3]),
        ('H2', 'Pegasus XL', [17.6, 726, 0.45, 23, 45, 93.3]),
        ('H3', 'Firefly Alpha', [29.8, 736, 1, 54, 6, 33.3]),
        ('H4', 'Epsilon', [26, 2350, 1.5, 95, 6, 83.3]),
      ],
    );

/// Planes. Approximate, unverified: maximum (or maximum cruise) speed,
/// range, length, wingspan and maximum take-off mass as commonly quoted,
/// rounded; record aircraft show their record range. "Gebaut" (KLD-082,
/// approximate, unverified): aircraft built of the type as named on the
/// card (A320neo family, all 737 MAX, DC-3 including the military C-47,
/// Wright Flyer I-III, Solar Impulse 1 and 2); one-offs have 1.
QuartettDeck _planes() => QuartettDeck.build(
      id: 'planes',
      name: 'Flugzeuge',
      revision: 2, // KLD-082: number built instead of the year stat
      stats: const [
        _kmh,
        QuartettStat(id: 'rangeKm', label: 'Reichweite', unit: 'km', decimals: 1),
        _lengthM,
        QuartettStat(id: 'wingspanM', label: 'Spannweite', unit: 'm', decimals: 2),
        QuartettStat(id: 'mtowT', label: 'Startgewicht', unit: 't', decimals: 2),
        _built,
      ],
      setNames: const {
        'A': 'Großraumjets',
        'B': 'Mittelstrecke',
        'C': 'Überschall',
        'D': 'Propeller-Klassiker',
        'E': 'Frachtriesen',
        'F': 'Business & Sport',
        'G': 'Pioniere',
        'H': 'Rekord-Exoten',
      },
      rows: const [
        ('A1', 'Airbus A380-800', [1020, 15000, 72.7, 79.8, 575, 251]),
        ('A2', 'Boeing 747-8I', [988, 14320, 76.3, 68.4, 448, 48]),
        ('A3', 'Boeing 777-300ER', [950, 13650, 73.9, 64.8, 351, 840]),
        ('A4', 'Airbus A350-900', [945, 15370, 66.8, 64.75, 283, 600]),
        ('B1', 'Airbus A320neo', [871, 6300, 37.6, 35.8, 79, 4000]),
        ('B2', 'Boeing 737 MAX 8', [839, 6570, 39.5, 35.9, 82.6, 1900]),
        ('B3', 'Airbus A220-300', [870, 6300, 38.7, 35.1, 70.9, 300]),
        ('B4', 'Embraer E195-E2', [868, 4800, 41.5, 35.12, 61.5, 50]),
        ('C1', 'Concorde', [2179, 7222, 61.7, 25.6, 185, 20]),
        ('C2', 'Tupolew Tu-144', [2500, 6500, 65.7, 28.8, 207, 16]),
        ('C3', 'Lockheed SR-71', [3540, 5400, 32.7, 16.9, 78, 32]),
        ('C4', 'North American X-15', [7274, 450, 15.5, 6.8, 15.4, 3]),
        ('D1', 'Douglas DC-3', [370, 2400, 19.7, 29, 12.7, 16000]),
        ('D2', 'Junkers Ju 52/3m', [265, 1000, 18.9, 29.25, 10.5, 4800]),
        ('D3', 'Lockheed Super Constellation', [607, 8700, 34.6, 38.5, 63, 579]),
        ('D4', 'De Havilland Dash 8-400', [667, 2040, 32.8, 28.4, 30.5, 640]),
        ('E1', 'Antonow An-225', [850, 15400, 84, 88.4, 640, 1]),
        ('E2', 'Antonow An-124', [865, 4800, 69.1, 73.3, 405, 55]),
        ('E3', 'Boeing 747 Dreamlifter', [878, 7800, 71.7, 64.4, 364, 4]),
        ('E4', 'Airbus Beluga XL', [760, 4000, 63.1, 60.3, 227, 6]),
        ('F1', 'Cessna 172', [302, 1289, 8.3, 11, 1.1, 45000]),
        ('F2', 'Learjet 75', [860, 3780, 17.7, 15.5, 9.8, 250]),
        ('F3', 'Gulfstream G650', [982, 13000, 30.4, 30.36, 45.2, 500]),
        ('F4', 'Pilatus PC-12', [528, 3400, 14.4, 16.3, 4.7, 2000]),
        ('G1', 'Wright Flyer', [48, 0.3, 6.4, 12.3, 0.34, 3]),
        ('G2', 'Blériot XI', [75, 100, 7.6, 7.8, 0.23, 800]),
        ('G3', 'Spirit of St. Louis', [214, 6600, 8.4, 14, 2.3, 1]),
        ('G4', 'Junkers F 13', [170, 1400, 9.6, 17.8, 1.7, 322]),
        ('H1', 'Solar Impulse 2', [140, 8924, 22.4, 71.9, 2.3, 2]),
        ('H2', 'Hughes H-4 Hercules', [351, 4800, 66.6, 97.5, 180, 1]),
        ('H3', 'Stratolaunch Roc', [304, 3700, 72.5, 117, 590, 1]),
        ('H4', 'Rutan Voyager', [196, 42212, 8.9, 33.8, 4.4, 1]),
      ],
    );

/// Animals (KLD-128). Unlike the vehicle decks the values are sourced, and
/// cautious where the sources disagree; the task card
/// `docs/tasks/KLD-128-quartett-animals.md` has the table with a source per
/// value.
///
/// * Gewicht: mean adult body mass of both sexes from AnAge (Human Ageing
///   Genomic Resources, genomics.senescence.info/species/entry.php?species=
///   Genus_species). Black mamba: AnAge's 30.8 kg is a data error; the
///   measured mean of seven snakes, 1.0 kg (Branch, Haagner & Shine 1995, in
///   en.wikipedia.org/wiki/Black_mamba), is used instead.
/// * Länge: head to tail tip, mean of both sexes (standing height for the
///   apes, ostrich and penguin, shell length for the tortoise), from Animal
///   Diversity Web (animaldiversity.org/accounts/Genus_species/), the
///   Smithsonian National Zoo or Wikipedia with a primary source. Elephant
///   8.0 m counts trunk and tail (de.wikipedia "Afrikanischer Elefant").
///   Black mamba 2.5: ADW, average length 2.2–2.7 m.
/// * Höchstgeschwindigkeit: the highest value a reliable source gives as
///   measured or as a firm figure; for a span without a measurement the
///   cautious lower end. Measured or from a reference book: cheetah 104
///   (Sharp 1997), lion 74 (GPS collars, 2018), tiger 56 (Schaller 1967),
///   leopard 58 (Sunquist & Sunquist), polar bear 40, brown bear 48
///   (Yellowstone), elephant 24, giraffe 60 (Schaller 1976), hippo 30, rhino
///   40, blue whale 48 (ADW), bowhead 23 (Ford & Reeves 2008, satellite
///   tags), orca 56 and bottlenose dolphin 35 (Fish & Fisher), great white 24,
///   ostrich 70 (Davies 2002), peregrine 290 (ADW, dive), emperor penguin 20
///   (ADW), saltwater crocodile 29 (NT Government), Komodo dragon 20 (Burnie
///   & Wilson 2001), black mamba 22.5 (22.53 km/h, Spawls, Howell, Drewes &
///   Ashe 2017, A Field Guide to the Reptiles of East Africa, 2nd ed.; in
///   en.wikipedia.org/wiki/Fastest_animals). Popular figures only, cautious
///   lower end: giant panda 32, sun bear 30, gorilla 32, orangutan 5,
///   chimpanzee 35, gibbon 55, tiger shark 32 (ADW data field), blue shark 39
///   (ReefQuest), mako 50, wandering albatross 135 (Barwell 2013), Aldabra
///   giant tortoise 0.3. One decimal for the tortoise and the mamba; every
///   other value is whole.
/// * Lebenserwartung: typical lifespan of an adult, in the wild where known
///   (ADW, Smithsonian, Wikipedia with a primary source), else in human care
///   (sun bear 20; black mamba 10: ADW, mean of females in captivity 10.1
///   years, Max Planck Institute for Demographic Research). Spans are
///   averaged. Bowhead whale and Aldabra tortoise 100 are cautious lower
///   bounds ("over 100" at NOAA and the Smithsonian).
/// * Tragzeit / Brutzeit: mating to birth for mammals and live-bearing sharks,
///   incubation of the egg for birds and egg-laying reptiles (AnAge; ADW or
///   Wikipedia where AnAge has none); months × 30.4, rounded to 5 days.
///   Black mamba 85: AnAge 85, ADW 80–90.
QuartettDeck _animals() => QuartettDeck.build(
      id: 'animals',
      name: 'Tiere',
      stats: const [
        // Not `kg` of the cars: that one wins low.
        QuartettStat(id: 'weightKg', label: 'Gewicht', unit: 'kg', decimals: 1),
        _lengthM,
        // The same stat as _kmh (id, label, unit, direction) with one decimal,
        // for the tortoise (0.3 km/h) and the mamba (22.5 km/h).
        QuartettStat(id: 'kmh', label: 'Höchstgeschwindigkeit', unit: 'km/h', decimals: 1),
        QuartettStat(id: 'lifeYears', label: 'Lebenserwartung', unit: 'Jahre'),
        QuartettStat(id: 'gestationD', label: 'Tragzeit / Brutzeit', unit: 'Tage'),
      ],
      setNames: const {
        'A': 'Raubkatzen',
        'B': 'Bären',
        'C': 'Affen',
        'D': 'Savanne',
        'E': 'Wale & Delfine',
        'F': 'Haie',
        'G': 'Vögel',
        'H': 'Reptilien',
      },
      rows: const [
        ('A1', 'Gepard', [54, 2.0, 104, 9, 88]),
        ('A2', 'Löwe', [175, 2.7, 74, 14, 109]),
        ('A3', 'Tiger', [120, 3.0, 56, 9, 105]),
        ('A4', 'Leopard', [54, 2.2, 58, 15, 97]),
        ('B1', 'Eisbär', [475, 2.1, 40, 28, 245]),
        ('B2', 'Braunbär', [278, 2.0, 48, 25, 225]),
        ('B3', 'Großer Panda', [118, 1.6, 32, 13, 130]),
        ('B4', 'Malaienbär', [46, 1.4, 30, 20, 95]),
        ('C1', 'Gorilla', [140, 1.5, 32, 38, 256]),
        ('C2', 'Orang-Utan', [64, 1.3, 5, 40, 249]),
        ('C3', 'Schimpanse', [45, 1.5, 35, 33, 229]),
        ('C4', 'Weißhandgibbon', [6.8, 0.5, 55, 30, 217]),
        ('D1', 'Afrikanischer Elefant', [4800, 8.0, 24, 65, 670]),
        ('D2', 'Giraffe', [800, 5.2, 60, 13, 457]),
        ('D3', 'Flusspferd', [3750, 3.6, 30, 45, 234]),
        ('D4', 'Breitmaulnashorn', [2175, 4.2, 40, 41, 515]),
        ('E1', 'Blauwal', [136000, 26.0, 48, 85, 350]),
        ('E2', 'Grönlandwal', [100000, 16.0, 23, 100, 396]),
        ('E3', 'Orca', [3988, 7.5, 56, 50, 435]),
        ('E4', 'Großer Tümmler', [200, 3.1, 35, 25, 365]),
        ('F1', 'Weißer Hai', [1870, 4.2, 24, 30, 365]),
        ('F2', 'Tigerhai', [444, 3.8, 32, 27, 440]),
        ('F3', 'Blauhai', [113, 2.5, 39, 16, 320]),
        ('F4', 'Kurzflossen-Mako', [278, 3.5, 50, 31, 500]),
        ('G1', 'Strauß', [111, 2.1, 70, 35, 40]),
        ('G2', 'Wanderfalke', [0.8, 0.5, 290, 13, 30]),
        ('G3', 'Kaiserpinguin', [30, 1.2, 20, 20, 65]),
        ('G4', 'Wanderalbatros', [7.0, 1.2, 135, 35, 78]),
        ('H1', 'Leistenkrokodil', [200, 3.6, 29, 70, 90]),
        ('H2', 'Komodowaran', [87, 2.4, 20, 30, 230]),
        ('H3', 'Aldabra-Riesenschildkröte', [117, 1.1, 0.3, 100, 240]),
        ('H4', 'Schwarze Mamba', [1.0, 2.5, 22.5, 10, 85]),
      ],
    );

/// Motorcycles (KLD-129). Stand 2025/2026: prices and the classics' values
/// are from 2025/2026 and age with every model year. Real model names, not
/// translated (like the cars). Values are manufacturer figures, directly or
/// as quoted by a press database (motorradundreisen.de, motorradonline.de,
/// 1000ps.com, motofichas.com, cyclenews.com, bikez.net), or estimates; the
/// task card `docs/tasks/KLD-129-quartett-motorcycles.md` has the source of
/// every value.
///
/// * Leistung (PS): peak power, also for the electric bikes (Zero SR/F 83 kW
///   → 113, LiveWire One 75 kW → 102 converted). BMW R 32: 8.5 PS, shown as 9
///   (whole numbers, the maintainer's decision).
/// * Höchstgeschwindigkeit: manufacturer figure where given (Africa Twin,
///   Hayabusa (limited), R 32, Beta Alp, WR125R, Super Cub, Zero, Can-Am,
///   LiveWire, Ninja e-1), else press values; Ninja H2R 400 is the unofficial
///   record, Husqvarna 701 Enduro 165 an estimate (nowhere published).
/// * Drehmoment (Nm): manufacturer or press figures; R 32 19 and Black Shadow
///   71 are estimates from kW and engine speed.
/// * Gewicht (kg, lower wins, the cars' `kg`): ready to ride with a (nearly)
///   full tank; Panigale V4 S 199 (187 without fuel + 17 L), Multistrada V4 S
///   246 (231 + 90 % of 22 L), 701 Enduro 162 (152 + tank) estimated; Beta Alp
///   150 (1000ps.com, ready to ride; Beta: 140 dry).
/// * Reichweite (km): petrol bikes tank (L) × 100 / consumption (L/100 km,
///   type approval WMTC, Euro 5/5+, mostly via a database quoting the
///   factory), rounded to 5 km; the Ninja H2R (no type approval) with the
///   road H2's 8.5 L. Electric bikes the manufacturer's range: Can-Am Pulse
///   130 and Ninja e-1 70 (72) WMTC, Zero SR/F 190 (188, highway), LiveWire
///   One 155 (153, combined). Classics: consumption from period tests or user
///   databases, estimates (R 32 ~3.5 L, CB750 34.3 US mpg, Z1 ~6.5 L, Black
///   Shadow "about 50 mpg").
/// * Wert (€): German list price (UVP) of the named model year without
///   on-road costs where that can be told (Super Meteor, Vespa, Ninja e-1,
///   WR125R and Beta only known with them), rounded to 100 €. Classics:
///   typical collector value from auction results, rounded to 1000 €, always
///   an estimate (R 32 150,000: Bonhams Paris 2023 143,750 €, Mecum 2026 about
///   180,000 €; CB750 Four 12,000, die-cast K0; Z1 18,000; Black Shadow
///   65,000; USD → EUR 0.86, GBP → EUR 1.17).
QuartettDeck _motorcycles() => QuartettDeck.build(
      id: 'motorcycles',
      name: 'Motorräder',
      stats: const [
        QuartettStat(id: 'ps', label: 'Leistung', unit: 'PS'),
        _kmh,
        QuartettStat(id: 'nm', label: 'Drehmoment', unit: 'Nm'),
        // The cars' weight: lower wins.
        QuartettStat(id: 'kg', label: 'Gewicht', unit: 'kg', higherWins: false),
        // Not the planes' `rangeKm` (one decimal, thousands of km).
        QuartettStat(id: 'rangeKmBike', label: 'Reichweite', unit: 'km'),
        QuartettStat(id: 'valueEur', label: 'Wert', unit: '€'),
      ],
      setNames: const {
        'A': 'Supersportler',
        'B': 'Naked Bikes',
        'C': 'Reiseenduros',
        'D': 'Cruiser',
        'E': 'Klassiker',
        'F': 'Gelände',
        'G': 'Roller',
        'H': 'Elektro',
      },
      rows: const [
        ('A1', 'Ducati Panigale V4 S', [216, 299, 121, 199, 260, 34800]),
        ('A2', 'BMW M 1000 RR', [218, 314, 113, 194, 255, 36300]),
        ('A3', 'Suzuki Hayabusa', [190, 299, 150, 264, 300, 19400]),
        ('A4', 'Kawasaki Ninja H2R', [310, 400, 165, 216, 200, 58000]),
        ('B1', 'KTM 1390 Super Duke R Evo', [190, 250, 145, 212, 295, 23000]),
        ('B2', 'Yamaha MT-09', [119, 215, 93, 193, 280, 11000]),
        ('B3', 'Triumph Speed Triple 1200 RS', [183, 245, 128, 199, 280, 20000]),
        ('B4', 'Aprilia Tuono V4 Factory', [180, 270, 121, 211, 250, 21000]),
        ('C1', 'BMW R 1300 GS', [145, 225, 149, 237, 395, 19900]),
        ('C2', 'Honda Africa Twin', [102, 199, 112, 231, 385, 16400]),
        ('C3', 'Ducati Multistrada V4 S', [170, 240, 124, 246, 365, 25300]),
        ('C4', 'Harley-Davidson Pan America 1250 Special', [152, 220, 125, 258, 385, 20900]),
        ('D1', 'Harley-Davidson Fat Boy 117', [105, 190, 168, 315, 345, 27700]),
        ('D2', 'Indian Chief Dark Horse', [88, 174, 156, 304, 280, 19400]),
        ('D3', 'Triumph Rocket 3 Storm R', [182, 222, 225, 317, 275, 26200]),
        ('D4', 'Royal Enfield Super Meteor 650', [47, 160, 52, 241, 365, 8100]),
        ('E1', 'BMW R 32', [9, 95, 19, 122, 400, 150000]),
        ('E2', 'Honda CB750 Four', [67, 200, 60, 233, 260, 12000]),
        ('E3', 'Kawasaki Z1', [82, 210, 74, 246, 275, 18000]),
        ('E4', 'Vincent Black Shadow', [56, 201, 71, 227, 285, 65000]),
        ('F1', 'Husqvarna 701 Enduro', [79, 165, 73, 162, 310, 12500]),
        ('F2', 'Suzuki DR-Z4S', [38, 139, 37, 151, 250, 9000]),
        ('F3', 'Beta Alp 4.0', [35, 135, 28, 150, 315, 6100]),
        ('F4', 'Yamaha WR125R', [15, 104, 11, 138, 350, 5000]),
        ('G1', 'Vespa GTS 310', [25, 127, 29, 163, 265, 7300]),
        ('G2', 'Honda Super Cub C125', [10, 95, 10, 111, 245, 4200]),
        ('G3', 'Yamaha TMAX 560 Tech MAX', [48, 165, 55, 221, 315, 16100]),
        ('G4', 'Kymco AK 575 Premium', [52, 160, 55, 238, 345, 12300]),
        ('H1', 'Zero SR/F', [113, 200, 190, 227, 190, 23000]),
        ('H2', 'Can-Am Pulse', [47, 129, 72, 177, 130, 12900]),
        ('H3', 'LiveWire One', [102, 177, 114, 255, 155, 14800]),
        ('H4', 'Kawasaki Ninja e-1', [12, 99, 40, 140, 70, 6600]),
      ],
    );

/// Special vehicles, "Sonderfahrzeuge" (KLD-130). Stand 2025/2026. Real
/// model names, not translated (like the cars); only the three rescue cards
/// without a telling model name carry a type word, which the app translates
/// (E1 "Rettungswagen Sprinter", E2 "Notarztwagen Kodiaq", E4 "Seenotretter
/// Hermann Marwede"). No military vehicles. Values are manufacturer figures
/// (directly or via a database or dealer quoting the data sheet), press or
/// database values, or estimates; the task card
/// `docs/tasks/KLD-130-quartett-special-vehicles.md` has the source of every
/// value.
///
/// * Leistung (PS): peak power, kW × 1.36 (also the electric drives); the
///   crane's carrier engine only (LTM 11200), the H135 both engines' take-off
///   power, the rescue cruiser all three engines.
/// * Höchstgeschwindigkeit: no fire engine, box ambulance or heavy-haulage
///   tractor has a published top speed. Five values are estimates: M32L-AS
///   100 (tender spec, fire engines are exempt from the 90 km/h limiter), M64L
///   90 and FH16 90 (the legal limiter), Rosenbauer RT 105 (the US sister
///   model RTX), Sprinter ambulance 130 (a placeholder). SPMT 5 loaded;
///   rescue cruiser 25 kn → 46; Mototok 1.05 m/s → 4.
/// * Gewicht (t, lower wins like the trains): permissible gross weight for
///   registered vehicles; loaded gross weight for dump trucks and the SPMT
///   (two 6-axle modules with payload, an estimate, 715); operating weight for
///   machines without a load (excavator, dozer, crane, tug, robot); maximum
///   take-off weight for the helicopter; displacement for the ship.
/// * Länge (m): in driving or transport position, without attachments (the
///   combine without its header, the LTM 11200 without the boom that travels
///   separately).
/// * Höhe (m, two decimals: with one, the 4 m legal height limit gives 4 %
///   ties): in driving position; eEconic as a chassis with cab, without the
///   refuse body (2.85); the rescue cruiser's 17 measured on a side view
///   (waterline to mast top, ±2 m), an estimate.
QuartettDeck _specialVehicles() => QuartettDeck.build(
      id: 'special',
      name: 'Sonderfahrzeuge',
      stats: const [
        // The cars' and motorcycles' power.
        QuartettStat(id: 'ps', label: 'Leistung', unit: 'PS'),
        _kmh,
        // The trains' weight (lower wins), here with one decimal.
        QuartettStat(id: 'massT', label: 'Gewicht', unit: 't', higherWins: false, decimals: 1),
        _lengthM,
        // The rockets' height, here with two decimals.
        QuartettStat(id: 'heightM', label: 'Höhe', unit: 'm', decimals: 2),
      ],
      setNames: const {
        'A': 'Feuerwehr',
        'B': 'Baustelle',
        'C': 'Kräne',
        'D': 'Landwirtschaft',
        'E': 'Rettung',
        'F': 'Flughafen',
        'G': 'Stadtreinigung',
        'H': 'Schwertransport',
      },
      rows: const [
        ('A1', 'Magirus M32L-AS', [299, 100, 16.0, 10.2, 3.30]),
        ('A2', 'Magirus M64L', [422, 90, 32.0, 12.0, 3.92]),
        ('A3', 'Rosenbauer RT', [490, 105, 18.0, 7.6, 2.90]),
        ('A4', 'Magirus Wolf R1', [20, 15, 0.9, 1.5, 1.30]),
        ('B1', 'Caterpillar 320', [175, 6, 22.6, 9.5, 2.96]),
        ('B2', 'JCB 3CX', [75, 40, 8.2, 5.6, 3.61]),
        ('B3', 'Caterpillar D11', [862, 12, 106.8, 10.5, 4.72]),
        ('B4', 'Volvo A60H', [639, 55, 98.8, 12.2, 3.85]),
        ('C1', 'Liebherr LTM 11200-9.1', [687, 75, 108.0, 19.9, 4.00]),
        ('C2', 'Liebherr LTM 1090-4.2', [449, 85, 48.0, 13.4, 4.00]),
        ('C3', 'Tadano GR-1000XL-4', [284, 35, 53.2, 14.4, 3.81]),
        ('C4', 'Liebherr MK 140', [544, 80, 60.0, 16.0, 4.00]),
        ('D1', 'Fendt 1052 Vario', [520, 60, 18.0, 6.4, 3.55]),
        ('D2', 'John Deere 9RX 830', [842, 40, 38.1, 8.9, 3.77]),
        ('D3', 'Claas Lexion 8900', [790, 40, 22.4, 9.4, 4.00]),
        ('D4', 'Fendt 211 Vario', [114, 40, 7.5, 4.1, 2.62]),
        ('E1', 'Rettungswagen Sprinter', [190, 130, 5.0, 6.5, 2.98]),
        ('E2', 'Notarztwagen Kodiaq', [193, 220, 2.3, 4.8, 1.68]),
        ('E3', 'Airbus H135', [1284, 255, 3.0, 12.3, 3.90]),
        ('E4', 'Seenotretter Hermann Marwede', [9250, 46, 404.0, 46.0, 17.00]),
        ('F1', 'Rosenbauer Panther 8×8', [1450, 135, 52.0, 12.0, 4.00]),
        ('F2', 'Goldhofer AST-1X', [707, 32, 31.0, 9.5, 2.21]),
        ('F3', 'e.COBUS 3000', [218, 50, 20.4, 13.9, 3.10]),
        ('F4', 'Mototok Twin 7500', [7, 4, 2.1, 2.6, 0.32]),
        ('G1', 'Mercedes-Benz eEconic', [544, 89, 27.0, 8.5, 2.85]),
        ('G2', 'Bucher CityCat 5006', [160, 80, 10.4, 5.0, 2.50]),
        ('G3', 'Mercedes-Benz Unimog U 530', [299, 90, 16.5, 5.3, 2.92]),
        ('G4', 'Goupil G4', [14, 50, 2.1, 3.6, 1.89]),
        ('H1', 'Volvo FH16 780', [780, 90, 35.0, 7.4, 3.79]),
        ('H2', 'Caterpillar 797F', [4057, 68, 623.7, 15.1, 7.71]),
        ('H3', 'BelAZ 75710', [4660, 64, 810.0, 20.6, 8.16]),
        ('H4', 'Scheuerle SPMT', [245, 5, 715.0, 16.8, 1.50]),
      ],
    );
