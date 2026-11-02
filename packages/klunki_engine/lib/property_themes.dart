/// The built-in Baulöwe themes (KLD-060): Berlin (default) and the made-up
/// "Fantasiestadt". Same format as a custom edition ([PropertyTheme.toJson]).
///
/// Berlin: real streets and places (facts), grouped by district, cheap to
/// expensive. None of them is a street name of the original game's classic
/// German edition, and the list is our own selection, not a city edition's.
/// Group 3 gathers flea-market places, group 5 the Kollwitzkiez. Group 4
/// (Friedrichshain) nods to the club culture through the streets the
/// well-known clubs are on; club names (business names) were considered and
/// left out on purpose. Each group names its buildings (small → big): Laden →
/// Markthalle, Trödelstand → Flohmarkt, Imbiss → Club, Kindercafé → Spielplatz,
/// Galerie → Museum, else Haus → Hotel. The utilities are a waterworks and the TV tower by
/// place, no company names. Card texts: our own, kid-friendly, Berliner
/// Schnauze, no real people, companies or current controversies.
library;

import 'property_theme.dart';

const _houseCosts = [50, 50, 100, 100, 150, 150, 200, 200];

/// Squares for [names] (40, by position) with our own price ladder:
/// [prices] for the 22 streets in board order, stations 200, utilities 150,
/// taxes 200 (square 4) and 100 (square 38).
List<PropertySquare> _squares(List<String> names, List<int> prices) {
  assert(names.length == 40 && prices.length == 22);
  var street = 0;
  return [
    for (var i = 0; i < 40; i++)
      switch (propertyLayout[i]) {
        PropertyKind.street => PropertySquare(i, names[i], PropertyKind.street,
            group: propertyLayoutGroups[i],
            price: prices[street],
            houseCost: _houseCosts[propertyLayoutGroups[i]],
            rents: propertyStreetRents(prices[street++])),
        PropertyKind.station => PropertySquare(i, names[i], PropertyKind.station, price: 200, rents: const [25, 50, 100, 200]),
        PropertyKind.utility => PropertySquare(i, names[i], PropertyKind.utility, price: 150, rents: const [4, 10]),
        PropertyKind.tax => PropertySquare(i, names[i], PropertyKind.tax, amount: i == 4 ? 200 : 100),
        final k => PropertySquare(i, names[i], k),
      },
  ];
}

const _prices = [60, 70, 100, 100, 120, 140, 140, 160, 180, 180, 200, 220, 220, 240, 260, 260, 280, 300, 300, 320, 350, 400];

const _s = PropertyDeck.surprise;
const _n = PropertyDeck.neighbourhood;

PropertyCard _c(String id, PropertyDeck d, PropertyCardKind k, String text, [int v = 0, int v2 = 0]) =>
    PropertyCard(id, d, text, k, v, v2);

// Shortcuts for the card tables below.
const _adv = PropertyCardKind.advanceTo, _backTo = PropertyCardKind.backTo, _back = PropertyCardKind.back;
const _station = PropertyCardKind.nearestStation, _pause = PropertyCardKind.toPause;
const _get = PropertyCardKind.collect, _pay = PropertyCardKind.pay;
const _getEach = PropertyCardKind.collectEach, _payEach = PropertyCardKind.payEach;
const _repairs = PropertyCardKind.repairs, _free = PropertyCardKind.freeCard;

/// Berlin, the first local theme.
final PropertyTheme berlinTheme = PropertyTheme(
  id: 'berlin',
  revision: 1,
  title: 'Berlin',
  colourGroups: const [
    PropertyGroup('Köpenick', note: 'Old town and the road out to the lakes: homes and guest houses fit both.'),
    PropertyGroup('Wedding', note: 'Busy residential streets and a square: houses and hotels fit all three.'),
    PropertyGroup('Neukölln',
        small: 'Laden',
        smallPlural: 'Läden',
        big: 'Markthalle',
        bigPlural: 'Markthallen',
        smallIcon: 'shop',
        bigIcon: 'market-hall',
        note: 'Shopping streets and a village square with markets: shops and a market hall fit each.'),
    PropertyGroup('Flohmärkte',
        small: 'Trödelstand',
        smallPlural: 'Trödelstände',
        big: 'Flohmarkt',
        bigPlural: 'Flohmärkte',
        smallIcon: 'stall',
        bigIcon: 'flea-market',
        note: 'All three are squares or parks with a weekend flea market.'),
    PropertyGroup('Friedrichshain',
        small: 'Imbiss',
        smallPlural: 'Imbisse',
        big: 'Club',
        bigPlural: 'Clubs',
        smallIcon: 'snack',
        bigIcon: 'club',
        note: 'The streets of the well-known dance clubs (no club names): a snack bar and a club fit each.'),
    PropertyGroup('Prenzlauer Berg',
        small: 'Kindercafé',
        smallPlural: 'Kindercafés',
        big: 'Spielplatz',
        bigPlural: 'Spielplätze',
        smallIcon: 'cafe',
        bigIcon: 'playground',
        note: "The family-rich Kollwitzkiez and its avenues: children's cafés and playgrounds line all three."),
    PropertyGroup('Charlottenburg', note: 'Elegant avenue, square and lakeside: fine houses and hotels fit all three.'),
    PropertyGroup('Mitte',
        small: 'Galerie',
        smallPlural: 'Galerien',
        big: 'Museum',
        bigPlural: 'Museen',
        smallIcon: 'gallery',
        bigIcon: 'museum',
        note: 'The museum island and the grand avenue next to it: galleries and museums fit both.'),
  ],

  deckTitles: const {_s: 'Spree-Post', _n: 'Kiez-Karte'},
  squares: _squares(const [
    'Start', 'Alt-Köpenick', 'Kiez-Karte', 'Müggelheimer Straße', 'Bürgeramt-Gebühr', //
    'Südkreuz', 'Osloer Straße', 'Spree-Post', 'Leopoldplatz', 'Müllerstraße',
    'Ersatzverkehr', 'Richardplatz', 'Wasserwerk Friedrichshagen', 'Weserstraße', 'Sonnenallee',
    'Westkreuz', 'Arkonaplatz', 'Kiez-Karte', 'Boxhagener Platz', 'Mauerpark',
    'Späti-Pause', 'Revaler Straße', 'Spree-Post', 'Alt-Stralau', 'Am Wriezener Bahnhof',
    'Hauptbahnhof', 'Kollwitzplatz', 'Kastanienallee', 'Fernsehturm', 'Schönhauser Allee',
    'Weichenstörung!', 'Olivaer Platz', 'Lietzensee', 'Kiez-Karte', 'Kurfürstendamm',
    'Ostkreuz', 'Spree-Post', 'Museumsinsel', 'Fahrradreparatur', 'Unter den Linden',
  ], _prices),
  cards: [
    _c('s01', _s, _adv, 'Ab zum Start! Nimm die S-Bahn – heute fährt sie sogar pünktlich.', 0),
    _c('s02', _s, _adv, 'Sonntag ist Karaoke im Mauerpark: Fahr hin und sing mit!', 19),
    _c('s03', _s, _adv, 'Heute wird getanzt! Fahr zur Revaler Straße.', 21),
    _c('s04', _s, _adv, 'Einmal Unter den Linden flanieren, bitte!', 39),
    _c('s05', _s, _station, 'Steig in die Ringbahn: Fahr zum nächsten Bahnhof.'),
    _c('s06', _s, _adv, 'Fahr zum Südkreuz. Umsteigen, bitte!', 5),
    _c('s07', _s, _back, 'Falsche Richtung: Innenring statt Außenring! Geh 3 Felder zurück.', 3),
    _c('s08', _s, _pause, 'Weichenstörung! Ab in den Ersatzverkehr. Du kommst nicht am Start vorbei.'),
    _c('s09', _s, _free,
        'Freifahrtschein: Damit verlässt du den Ersatzverkehr sofort. Behalte ihn, bis du ihn brauchst.'),
    _c('s10', _s, _get, 'Dein Waffelstand beim Kiezfest ist ausverkauft: 50 Taler.', 50),
    _c('s11', _s, _get, 'Du gewinnst das Seifenkistenrennen am Kreuzberg: 100 Taler.', 100),
    _c('s12', _s, _pay, 'Currywurst mit Pommes Schranke für alle am Tisch: zahle 15 Taler.', 15),
    _c('s13', _s, _payEach, 'Du gibst ein Eis an der Spree aus: zahle allen anderen je 25 Taler.', 25),
    _c('s14', _s, _repairs, 'Frühjahrsputz im Kiez: zahle 25 Taler pro Haus und 100 Taler pro Hotel.', 25, 100),
    _c('s15', _s, _pay, 'Dein Fahrrad hat einen Platten: zahle 20 Taler.', 20),
    _c('s16', _s, _get, 'Erster Preis beim Sandburgen-Wettbewerb am Wannsee: 150 Taler.', 150),
    _c('n01', _n, _adv, 'Ab zum Start! Der Bus wartet heute ausnahmsweise auf dich.', 0),
    _c('n02', _n, _getEach, 'Du hast Geburtstag! Alle singen für dich und schenken dir je 10 Taler.', 10),
    _c('n03', _n, _get, 'Flohmarkt im Kiez: Du verkaufst alte Spielsachen für 50 Taler.', 50),
    _c('n04', _n, _pay, 'Zu viele Pfannkuchen genascht – ab zum Zahnarzt: zahle 50 Taler.', 50),
    _c('n05', _n, _free,
        'Freifahrtschein: Damit verlässt du den Ersatzverkehr sofort. Behalte ihn, bis du ihn brauchst.'),
    _c('n06', _n, _pause, 'Signalstörung! Ab in den Ersatzverkehr. Du kommst nicht am Start vorbei.'),
    _c('n07', _n, _get, 'Dein Sparschwein ist voll: 100 Taler.', 100),
    _c('n08', _n, _get, 'Kiek mal: Das Fundbüro gibt dir deinen Schlüssel und 20 Taler zurück.', 20),
    _c('n09', _n, _payEach, 'Hoffest bei dir: zahle allen anderen je 10 Taler für Brause und Schrippen.', 10),
    _c('n10', _n, _pay, 'Der Hamster muss zum Tierarzt: zahle 40 Taler.', 40),
    _c('n11', _n, _back, 'Lange an der Tür angestanden und doch nicht reingekommen. Geh 3 Felder zurück.', 3),
    _c('n12', _n, _repairs, 'Sturm über der Spree: zahle 40 Taler pro Haus und 115 Taler pro Hotel.', 40, 115),
    _c('n13', _n, _get, 'Zinsen vom Sparbuch: 25 Taler.', 25),
    _c('n14', _n, _get, 'Du findest einen Goldtaler im Sandkasten am Lietzensee: 200 Taler.', 200),
    _c('n15', _n, _backTo, 'Mütze im Bus vergessen! Geh zurück nach Alt-Köpenick.', 1),
    _c('n16', _n, _pay, 'Det Buch kam zu spät zur Bücherei zurück: zahle 10 Taler.', 10),
  ],
);

/// A made-up town with kid-friendly fantasy names, for families outside
/// Berlin and for tests.
final PropertyTheme fantasyTheme = PropertyTheme(
  id: 'fantasie',
  revision: 1,
  title: 'Fantasiestadt',
  colourGroups: const [
    PropertyGroup('Braun'), PropertyGroup('Hellblau'), PropertyGroup('Rosa'), PropertyGroup('Orange'), //
    PropertyGroup('Rot'), PropertyGroup('Gelb'), PropertyGroup('Grün'), PropertyGroup('Dunkelblau'),
  ],
  deckTitles: const {_s: 'Überraschung', _n: 'Nachbarschaft'},
  squares: _squares(const [
    'Start', 'Schneckenweg', 'Nachbarschaft', 'Pfützengasse', 'Stadtkasse', //
    'Seilbahn', 'Kastanienweg', 'Überraschung', 'Murmelgasse', 'Drachenwiese',
    'Auszeit', 'Bücherplatz', 'Windrad', 'Malerweg', 'Zirkusplatz',
    'Fähre', 'Ponyhof', 'Nachbarschaft', 'Heuweg', 'Kürbisfeld',
    'Picknickwiese', 'Leuchtturmweg', 'Überraschung', 'Muschelstrand', 'Möwenkai',
    'Bimmelbahn', 'Sternwarte', 'Kometenweg', 'Wasserturm', 'Mondplatz',
    'Ab in die Auszeit!', 'Erfinderstraße', 'Raketenplatz', 'Nachbarschaft', 'Roboterweg',
    'Luftschiff', 'Überraschung', 'Regenbogenbrücke', 'Fahrradreparatur', 'Schatzinsel',
  ], _prices),
  cards: [
    _c('s01', _s, _adv, 'Ab zum Start! Du bekommst das Startgeld.', 0),
    _c('s02', _s, _adv, 'Ausflug zur Sternwarte.', 26),
    _c('s03', _s, _adv, 'Sandburgen bauen am Muschelstrand.', 23),
    _c('s04', _s, _adv, 'Schatzsuche! Fahr zur Schatzinsel.', 39),
    _c('s05', _s, _station, 'Steig in die nächste Bahn: Fahr zur nächsten Linie.'),
    _c('s06', _s, _adv, 'Fahr mit der Seilbahn.', 5),
    _c('s07', _s, _back, 'Du hast etwas vergessen: Geh 3 Felder zurück.', 3),
    _c('s08', _s, _pause, 'Ab in die Auszeit! Du kommst nicht am Start vorbei.'),
    _c('s09', _s, _free, 'Freikarte: Damit verlässt du die Auszeit sofort. Behalte sie, bis du sie brauchst.'),
    _c('s10', _s, _get, 'Du findest 50 Taler am Wegrand.', 50),
    _c('s11', _s, _get, 'Dein Kuchen gewinnt beim Backwettbewerb: 100 Taler.', 100),
    _c('s12', _s, _pay, 'Die Fahrradklingel ist kaputt: zahle 15 Taler.', 15),
    _c('s13', _s, _payEach, 'Du gibst ein Eis aus: zahle allen anderen je 25 Taler.', 25),
    _c('s14', _s, _repairs, 'Frühjahrsputz: zahle 25 Taler pro Haus und 100 Taler pro Hotel.', 25, 100),
    _c('s15', _s, _pay, 'Das Bobbycar stand im Weg: zahle 20 Taler.', 20),
    _c('s16', _s, _get, 'Erster Preis beim Malwettbewerb: 150 Taler.', 150),
    _c('n01', _n, _adv, 'Ab zum Start! Du bekommst das Startgeld.', 0),
    _c('n02', _n, _getEach, 'Du hast Geburtstag: Alle anderen schenken dir je 10 Taler.', 10),
    _c('n03', _n, _get, 'Flohmarkt: Du verkaufst alte Spielsachen für 50 Taler.', 50),
    _c('n04', _n, _pay, 'Besuch beim Zahnarzt: zahle 50 Taler.', 50),
    _c('n05', _n, _free, 'Freikarte: Damit verlässt du die Auszeit sofort. Behalte sie, bis du sie brauchst.'),
    _c('n06', _n, _pause, 'Ab in die Auszeit! Du kommst nicht am Start vorbei.'),
    _c('n07', _n, _get, 'Das Sparschwein ist voll: 100 Taler.', 100),
    _c('n08', _n, _get, 'Das Fundbüro gibt dir 20 Taler zurück.', 20),
    _c('n09', _n, _payEach, 'Gartenfest bei dir: zahle allen anderen je 10 Taler.', 10),
    _c('n10', _n, _pay, 'Der Hamster muss zum Tierarzt: zahle 40 Taler.', 40),
    _c('n11', _n, _get, 'Zweiter Preis beim Kürbiswettbewerb: 10 Taler.', 10),
    _c('n12', _n, _repairs, 'Sturm im Viertel: zahle 40 Taler pro Haus und 115 Taler pro Hotel.', 40, 115),
    _c('n13', _n, _get, 'Zinsen vom Sparbuch: 25 Taler.', 25),
    _c('n14', _n, _get, 'Du findest einen Goldtaler im Sandkasten: 200 Taler.', 200),
    _c('n15', _n, _backTo, 'Du hast deine Mütze verloren: Geh zurück zum Schneckenweg.', 1),
    _c('n16', _n, _pay, 'Das Buch kam zu spät zur Bücherei zurück: zahle 10 Taler.', 10),
  ],
);
