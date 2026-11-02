/// Themes ("editions") of Baulöwe, the property-trading game (KLD-060, id
/// `property`): square names, prices, rents and the two event card decks.
///
/// The rules are theme-independent ([PropertyGame]); a theme is plain,
/// JSON-serialisable data ([PropertyTheme.toJson] / [PropertyTheme.fromJson])
/// checked by [PropertyTheme.validate], so a later edition editor can let
/// families make their own and send it with the room config (see the card
/// `docs/tasks/KLD-060-property-game.md`, "Later: edition editor").
///
/// The board layout is fixed: every theme has the same 40 kinds of squares
/// in the same places ([propertyLayout], [propertyLayoutGroups]); a theme
/// fills in names and numbers. Texts are German first; the app will localise
/// the built-in themes per theme (UI step).
library;

import 'dart:convert';

import 'property_themes.dart';
import 'sha256.dart';

/// What a square does when a player lands on it.
enum PropertyKind {
  /// Square 0: players collect `PropertyGame.startSalary` when they pass or
  /// land on it.
  start,

  /// A street of one of the 8 colour groups: buy, build, rent.
  street,

  /// One of 4 station-like squares: rent by how many the owner has.
  station,

  /// One of 2 utility-like squares: rent is the dice total times 4 or 10.
  utility,

  /// Pay [PropertySquare.amount] to the bank.
  tax,

  /// Draw a card from the [PropertyDeck.surprise] deck.
  surprise,

  /// Draw a card from the [PropertyDeck.neighbourhood] deck.
  neighbourhood,

  /// The jail-like square: only visiting, or sitting out ("Pause").
  pause,

  /// Nothing happens.
  free,

  /// Go straight to the pause square.
  goToPause,
}

const _st = PropertyKind.street;

/// The fixed board layout: the kind of each square, index 0 = start, in the
/// direction of travel.
const List<PropertyKind> propertyLayout = [
  PropertyKind.start, _st, PropertyKind.neighbourhood, _st, PropertyKind.tax, //
  PropertyKind.station, _st, PropertyKind.surprise, _st, _st,
  PropertyKind.pause, _st, PropertyKind.utility, _st, _st,
  PropertyKind.station, _st, PropertyKind.neighbourhood, _st, _st,
  PropertyKind.free, _st, PropertyKind.surprise, _st, _st,
  PropertyKind.station, _st, _st, PropertyKind.utility, _st,
  PropertyKind.goToPause, _st, _st, PropertyKind.neighbourhood, _st,
  PropertyKind.station, PropertyKind.surprise, _st, PropertyKind.tax, _st,
];

/// Colour group (0–7) of each square of [propertyLayout]; -1 for non-streets.
const List<int> propertyLayoutGroups = [
  -1, 0, -1, 0, -1, -1, 1, -1, 1, 1, //
  -1, 2, -1, 2, 2, -1, 3, -1, 3, 3,
  -1, 4, -1, 4, 4, -1, 5, 5, -1, 5,
  -1, 6, 6, -1, 6, -1, -1, 7, -1, 7,
];

/// One of the 40 squares.
class PropertySquare {
  final int index;

  /// Display name (German for the built-in themes).
  final String name;
  final PropertyKind kind;

  /// Colour group 0–7 for streets, else -1.
  final int group;

  /// Purchase price (ownable squares), else 0.
  final int price;

  /// Cost of one house (streets), else 0. A hotel costs one more house.
  final int houseCost;

  /// Streets: rent with 0–4 houses and with a hotel (6 values). Stations:
  /// rent with 1–4 stations owned. Utilities: dice multiplier with 1 or 2
  /// owned.
  final List<int> rents;

  /// Tax squares: what to pay.
  final int amount;

  const PropertySquare(this.index, this.name, this.kind,
      {this.group = -1, this.price = 0, this.houseCost = 0, this.rents = const [], this.amount = 0});

  bool get isOwnable => kind == PropertyKind.street || kind == PropertyKind.station || kind == PropertyKind.utility;

  /// What the bank pays for a mortgage: half the price.
  int get mortgageValue => price ~/ 2;

  /// What lifting the mortgage costs: the mortgage value plus 10 %, rounded up.
  int get unmortgageCost => (mortgageValue * 11 + 9) ~/ 10;

  /// JSON without the index and group (both follow from the position).
  Map<String, dynamic> toJson() => {
        'kind': kind.name,
        'name': name,
        if (price != 0) 'price': price,
        if (houseCost != 0) 'house': houseCost,
        if (rents.isNotEmpty) 'rents': List.of(rents),
        if (amount != 0) 'amount': amount,
      };

  /// Square [index] from [json]; throws [FormatException] for wrong types.
  factory PropertySquare.fromJson(int index, Object? json) {
    final m = _map(json, 'square $index');
    final kind = PropertyKind.values.where((k) => k.name == m['kind']).firstOrNull ??
        (throw FormatException('square $index: unknown kind ${m['kind']}'));
    return PropertySquare(index, _str(m, 'name', 'square $index'), kind,
        group: index >= 0 && index < propertyLayoutGroups.length ? propertyLayoutGroups[index] : -1,
        price: _int(m, 'price', 'square $index'),
        houseCost: _int(m, 'house', 'square $index'),
        rents: _ints(m, 'rents', 'square $index'),
        amount: _int(m, 'amount', 'square $index'));
  }
}

/// Our own rent table for a street of [price]: base rent = price / 12
/// (rounded, at least 2), then ×4, ×12, ×30, ×40 for 1–4 houses and ×50 for
/// a hotel. A helper for theme authors; a theme stores the explicit rents.
List<int> propertyStreetRents(int price) {
  final b = (price / 12).round().clamp(2, 1 << 30);
  return List.unmodifiable([b, b * 4, b * 12, b * 30, b * 40, b * 50]);
}

/// What a card does.
enum PropertyCardKind {
  /// Move forward to square [PropertyCard.value] (collect the start money
  /// when passing it).
  advanceTo,

  /// Move back to square [PropertyCard.value] (no start money).
  backTo,

  /// Move back [PropertyCard.value] squares.
  back,

  /// Move forward to the next station-like square.
  nearestStation,

  /// Go to the pause square.
  toPause,

  /// Collect [PropertyCard.value] from the bank.
  collect,

  /// Pay [PropertyCard.value] to the bank.
  pay,

  /// Collect [PropertyCard.value] from every other player.
  collectEach,

  /// Pay [PropertyCard.value] to every other player.
  payEach,

  /// Pay [PropertyCard.value] per house and [PropertyCard.value2] per hotel.
  repairs,

  /// Keep it: leave the pause for free later.
  freeCard,
}

/// The two decks (their titles come from the theme).
enum PropertyDeck {
  surprise,
  neighbourhood;

  static PropertyDeck? byName(Object? name) => values.where((d) => d.name == name).firstOrNull;
}

/// One event card. [id] is stable within its theme (UI texts, network
/// steps).
class PropertyCard {
  final String id;
  final PropertyDeck deck;

  /// Card text (German for the built-in themes).
  final String text;
  final PropertyCardKind kind;
  final int value;
  final int value2;
  const PropertyCard(this.id, this.deck, this.text, this.kind, [this.value = 0, this.value2 = 0]);

  Map<String, dynamic> toJson() => {
        'id': id,
        'kind': kind.name,
        'text': text,
        if (value != 0) 'value': value,
        if (value2 != 0) 'value2': value2,
      };

  factory PropertyCard.fromJson(PropertyDeck deck, Object? json) {
    final m = _map(json, 'card');
    final id = _str(m, 'id', 'card');
    final kind = PropertyCardKind.values.where((k) => k.name == m['kind']).firstOrNull ??
        (throw FormatException('card $id: unknown kind ${m['kind']}'));
    return PropertyCard(id, deck, _str(m, 'text', 'card $id'), kind, _int(m, 'value', 'card $id'),
        _int(m, 'value2', 'card $id'));
  }
}

/// One colour group's display data: its name and what its buildings are
/// called. The rules are the same for every group (4 small buildings, then
/// 1 big one; even building); only the words and icons change. Default:
/// "Haus" / "Hotel".
///
/// A pair must make sense on every square of its group, so a group is one
/// coherent area; [note] says why the pair fits (for theme authors and
/// reviewers, not shown in the game).
class PropertyGroup {
  final String name;
  final String small;
  final String smallPlural;
  final String big;
  final String bigPlural;

  /// Icon keys (`[a-z0-9-]`) of the small and the big building, e.g.
  /// `house` / `hotel`, `snack` / `club`; one per building kind so the pieces
  /// read clearly at small size. The app falls back to `house` / `hotel` for
  /// keys it does not know.
  final String smallIcon;
  final String bigIcon;

  /// Why the building pair fits every square of the group; may be empty.
  final String note;
  const PropertyGroup(this.name,
      {this.small = 'Haus',
      this.smallPlural = 'Häuser',
      this.big = 'Hotel',
      this.bigPlural = 'Hotels',
      this.smallIcon = 'house',
      this.bigIcon = 'hotel',
      this.note = ''});

  Map<String, dynamic> toJson() => {
        'name': name,
        'small': small,
        'smallPlural': smallPlural,
        'big': big,
        'bigPlural': bigPlural,
        'smallIcon': smallIcon,
        'bigIcon': bigIcon,
        if (note.isNotEmpty) 'note': note,
      };

  factory PropertyGroup.fromJson(Object? json) {
    final m = _map(json, 'group');
    final name = _str(m, 'name', 'group');
    return PropertyGroup(name,
        small: _str(m, 'small', 'group $name'),
        smallPlural: _str(m, 'smallPlural', 'group $name'),
        big: _str(m, 'big', 'group $name'),
        bigPlural: _str(m, 'bigPlural', 'group $name'),
        smallIcon: _str(m, 'smallIcon', 'group $name'),
        bigIcon: _str(m, 'bigIcon', 'group $name'),
        note: m['note'] == null ? '' : _str(m, 'note', 'group $name'));
  }
}

/// A theme (edition): names, numbers and cards for the fixed layout.
class PropertyTheme {
  /// Stable id (`[a-z0-9-]`, 1–32 chars), e.g. `berlin`.
  final String id;

  /// Gameplay revision: bump it whenever a number, card or name changes
  /// (like `QuartettDeck.revision`); it goes into the compat fingerprint
  /// once the game is registered, next to [contentHash].
  final int revision;

  /// Display title, e.g. "Berlin".
  final String title;

  /// Money unit for display, e.g. "Taler".
  final String currency;

  /// The 8 colour groups: names (Berlin: districts and themes) and
  /// building names.
  final List<PropertyGroup> colourGroups;

  /// The 40 squares, index = position.
  final List<PropertySquare> squares;

  /// Titles of the two decks.
  final Map<PropertyDeck, String> deckTitles;

  /// All cards of both decks, in the theme's (unshuffled) order.
  final List<PropertyCard> cards;

  /// Square indexes of each colour group, in board order.
  late final List<List<int>> groups = List.unmodifiable([
    for (var g = 0; g < 8; g++) List<int>.unmodifiable([for (final s in squares) if (s.group == g) s.index]),
  ]);

  PropertyTheme(
      {required this.id,
      required this.revision,
      required this.title,
      this.currency = 'Taler',
      required List<PropertyGroup> colourGroups,
      required List<PropertySquare> squares,
      required Map<PropertyDeck, String> deckTitles,
      required List<PropertyCard> cards})
      : colourGroups = List.unmodifiable(colourGroups),
        squares = List.unmodifiable(squares),
        deckTitles = Map.unmodifiable(deckTitles),
        cards = List.unmodifiable(cards);

  /// The built-in Berlin theme (the default).
  static PropertyTheme get berlin => berlinTheme;

  static const String defaultId = 'berlin';

  /// The themes that ship with the app.
  static List<PropertyTheme> get builtIn => [berlinTheme, fantasyTheme];

  /// The built-in theme [id] (null = [defaultId]); null if unknown.
  static PropertyTheme? byId(String? id) => builtIn.where((t) => t.id == (id ?? defaultId)).firstOrNull;

  /// The card [id], or null.
  PropertyCard? card(Object? id) => cards.where((c) => c.id == id).firstOrNull;

  Map<String, dynamic> toJson() => {
        'format': 1,
        'id': id,
        'revision': revision,
        'title': title,
        'currency': currency,
        'groups': [for (final g in colourGroups) g.toJson()],
        'squares': [for (final s in squares) s.toJson()],
        'decks': {
          for (final d in PropertyDeck.values)
            d.name: {
              'title': deckTitles[d],
              'cards': [for (final c in cards) if (c.deck == d) c.toJson()],
            },
        },
      };

  /// A theme from [json] (as [toJson] writes it). Throws [FormatException]
  /// for a wrong shape or type; the content is checked by [validate].
  factory PropertyTheme.fromJson(Object? json) {
    final m = _map(json, 'theme');
    if (m['format'] != 1) throw FormatException('theme: unknown format ${m['format']}');
    final squares = m['squares'];
    if (squares is! List) throw const FormatException('theme: squares must be a list');
    final groups = m['groups'];
    if (groups is! List) throw const FormatException('theme: groups must be a list');
    final decks = _map(m['decks'], 'decks');
    final titles = <PropertyDeck, String>{};
    final cards = <PropertyCard>[];
    for (final d in PropertyDeck.values) {
      final deck = _map(decks[d.name], 'deck ${d.name}');
      titles[d] = _str(deck, 'title', 'deck ${d.name}');
      final list = deck['cards'];
      if (list is! List) throw FormatException('deck ${d.name}: cards must be a list');
      cards.addAll([for (final c in list) PropertyCard.fromJson(d, c)]);
    }
    return PropertyTheme(
        id: _str(m, 'id', 'theme'),
        revision: _int(m, 'revision', 'theme'),
        title: _str(m, 'title', 'theme'),
        currency: m['currency'] == null ? 'Taler' : _str(m, 'currency', 'theme'),
        colourGroups: [for (final g in groups) PropertyGroup.fromJson(g)],
        squares: [for (var i = 0; i < squares.length; i++) PropertySquare.fromJson(i, squares[i])],
        deckTitles: titles,
        cards: cards);
  }

  /// Text limits (characters) for names and card texts.
  static const int maxNameLength = 30;
  static const int maxCardTextLength = 200;

  /// Everything wrong with this theme, in English, or an empty list. Checks
  /// the layout, groups, prices and rents for sanity, the card actions and
  /// their numbers, unique card ids and text lengths. [PropertyGame] refuses
  /// a theme with problems.
  List<String> validate() {
    final p = <String>[];
    bool text(String what, String s, int max) {
      final n = s.trim().runes.length;
      if (n == 0 || n > max) p.add('$what: text must have 1–$max characters');
      return n > 0 && n <= max;
    }

    if (!RegExp(r'^[a-z0-9-]{1,32}$').hasMatch(id)) p.add('id must be 1–32 of a-z, 0-9, -');
    if (revision < 1) p.add('revision must be at least 1');
    text('title', title, maxNameLength);
    text('currency', currency, 12);
    if (colourGroups.length != 8) p.add('there must be 8 groups');
    for (final g in colourGroups) {
      for (final t in [g.name, g.small, g.smallPlural, g.big, g.bigPlural]) {
        text('group "${g.name}"', t, maxNameLength);
      }
      for (final icon in [g.smallIcon, g.bigIcon]) {
        if (!RegExp(r'^[a-z0-9-]{1,24}$').hasMatch(icon)) p.add('group "${g.name}": icon must be 1–24 of a-z, 0-9, -');
      }
      if (g.note.runes.length > maxCardTextLength) p.add('group "${g.name}": note too long');
    }
    if (squares.length != propertyLayout.length) {
      p.add('there must be ${propertyLayout.length} squares');
      return p;
    }
    for (final s in squares) {
      final at = 'square ${s.index} (${s.name})';
      text(at, s.name, maxNameLength);
      if (s.kind != propertyLayout[s.index]) p.add('$at: must be a ${propertyLayout[s.index].name}');
      bool range(String what, int v, int lo, int hi) {
        if (v < lo || v > hi) p.add('$at: $what must be $lo–$hi');
        return v >= lo && v <= hi;
      }

      bool rising(List<int> r, int count, {bool strict = true}) {
        if (r.length != count) {
          p.add('$at: needs $count rents');
          return false;
        }
        for (var k = 1; k < r.length; k++) {
          if (strict ? r[k] <= r[k - 1] : r[k] < r[k - 1]) {
            p.add('$at: rents must rise');
            return false;
          }
        }
        return true;
      }

      switch (s.kind) {
        case PropertyKind.street:
          range('price', s.price, 10, 2000);
          range('house cost', s.houseCost, 10, 1000);
          if (rising(s.rents, 6)) {
            range('rent', s.rents.first, 1, 1000);
            range('hotel rent', s.rents.last, 1, 10000);
          }
        case PropertyKind.station:
          range('price', s.price, 10, 2000);
          if (rising(s.rents, 4, strict: false)) range('rent', s.rents.last, 1, 2000);
        case PropertyKind.utility:
          range('price', s.price, 10, 2000);
          if (rising(s.rents, 2, strict: false)) range('dice multiplier', s.rents.last, 1, 50);
        case PropertyKind.tax:
          range('amount', s.amount, 1, 2000);
        default:
          if (s.price != 0 || s.houseCost != 0 || s.rents.isNotEmpty || s.amount != 0) {
            p.add('$at: has no price, rent or amount');
          }
      }
    }
    for (final d in PropertyDeck.values) {
      text('deck ${d.name} title', deckTitles[d] ?? '', maxNameLength);
      final deck = [for (final c in cards) if (c.deck == d) c];
      final keep = deck.where((c) => c.kind == PropertyCardKind.freeCard).length;
      if (deck.length < 8 || deck.length > 40) p.add('deck ${d.name}: needs 8–40 cards');
      if (keep > 2) p.add('deck ${d.name}: at most 2 free cards');
    }
    final ids = <String>{};
    for (final c in cards) {
      final at = 'card ${c.id}';
      if (!RegExp(r'^[A-Za-z0-9_-]{1,16}$').hasMatch(c.id)) p.add('$at: id must be 1–16 of A-Z, a-z, 0-9, _, -');
      if (!ids.add(c.id)) p.add('$at: id used twice');
      text(at, c.text, maxCardTextLength);
      void range(String what, int v, int lo, int hi) {
        if (v < lo || v > hi) p.add('$at: $what must be $lo–$hi');
      }

      switch (c.kind) {
        case PropertyCardKind.advanceTo || PropertyCardKind.backTo:
          range('target square', c.value, 0, propertyLayout.length - 1);
        case PropertyCardKind.back:
          range('steps', c.value, 1, 12);
        case PropertyCardKind.collect || PropertyCardKind.pay || PropertyCardKind.collectEach || PropertyCardKind.payEach:
          range('amount', c.value, 1, 1000);
        case PropertyCardKind.repairs:
          range('per house', c.value, 0, 500);
          range('per hotel', c.value2, 1, 2000);
        case PropertyCardKind.nearestStation || PropertyCardKind.toPause || PropertyCardKind.freeCard:
          if (c.value != 0 || c.value2 != 0) p.add('$at: takes no number');
      }
      if (c.kind != PropertyCardKind.repairs && c.value2 != 0) p.add('$at: takes no second number');
    }
    return p;
  }

  /// SHA-256 (hex, 32 chars) of [toJson]: identifies the exact content, for
  /// the compat check of built-in themes and the room check of custom ones.
  String get contentHash => sha256Hex('klunki-property-theme-v1\n${jsonEncode(toJson())}').substring(0, 32);
}

Map<String, dynamic> _map(Object? json, String what) {
  if (json is! Map) throw FormatException('$what: must be an object');
  return json.cast<String, dynamic>();
}

String _str(Map<String, dynamic> m, String key, String what) {
  final v = m[key];
  if (v is! String) throw FormatException('$what: $key must be text');
  return v;
}

int _int(Map<String, dynamic> m, String key, String what) {
  final v = m[key] ?? 0;
  if (v is! int) throw FormatException('$what: $key must be a whole number');
  return v;
}

List<int> _ints(Map<String, dynamic> m, String key, String what) {
  final v = m[key] ?? const [];
  if (v is! List || v.any((e) => e is! int)) throw FormatException('$what: $key must be whole numbers');
  return List<int>.unmodifiable(v.cast<int>());
}
