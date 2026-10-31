// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'Klunki';

  @override
  String get menuLanguage => 'Langue';

  @override
  String get languagePickerTitle => 'Choisir la langue';

  @override
  String get languageSystem => 'Système';

  @override
  String get menuChooseGame => 'Choisis un jeu';

  @override
  String get menuPassDevice => 'Passe l’appareil';

  @override
  String get menuDebugConsole => 'Console de débogage';

  @override
  String get menuPlayOverWifi => 'Jouer en Wi-Fi';

  @override
  String get menuGameConnect4 => 'Quatre en ligne';

  @override
  String get menuGameMuehle => 'Jeu du moulin';

  @override
  String get menuGameQuartettTrumpf => 'Quartett (Atouts)';

  @override
  String get menuGameQuartettSets => 'Quartett (Familles)';

  @override
  String get menuGameSchiffe => 'Bataille navale';

  @override
  String get menuDescConnect4 =>
      'Quatre en ligne – horizontale, verticale ou diagonale.';

  @override
  String get menuDescMuehle =>
      'Forme des lignes de trois et capture les pions adverses.';

  @override
  String get menuDescQuartettTrumpf =>
      'Comparez les valeurs – la meilleure remporte les deux cartes.';

  @override
  String get menuDescQuartettSets =>
      'Demande des cartes et réunis des familles complètes de quatre.';

  @override
  String get menuDescSchiffe => 'Cachez vos flottes et tirez à tour de rôle.';

  @override
  String get menuSectionHotSeat => 'À deux sur un appareil';

  @override
  String get menuSectionNetwork => 'Avec deux appareils';

  @override
  String get menuNetworkSubtitle => 'Héberger ou rejoindre une partie';

  @override
  String get menuHiddenInfo =>
      'Cartes ou flotte secrètes – passez-vous l\'appareil';

  @override
  String shellToMove(String player) {
    return 'Au tour de $player';
  }

  @override
  String shellHasWon(String player) {
    return '$player a gagné';
  }

  @override
  String shellYourTurn(String mark) {
    return 'À toi de jouer ($mark)';
  }

  @override
  String shellWaitingFor(String player) {
    return 'En attente de $player…';
  }

  @override
  String get shellYouHaveWon => 'Tu as gagné';

  @override
  String get shellDraw => 'Match nul';

  @override
  String shellWins(String player) {
    return '$player gagne !';
  }

  @override
  String get shellYouWin => 'Tu gagnes !';

  @override
  String get shellMenu => 'Menu';

  @override
  String get shellPlayAgain => 'Rejouer';

  @override
  String get shellUndo => 'Annuler le coup';

  @override
  String get shellNewGame => 'Nouvelle partie';

  @override
  String get shellNewGameTitle => 'Nouvelle partie ?';

  @override
  String get shellNewGameBody => 'La partie en cours sera abandonnée.';

  @override
  String get shellCancel => 'Annuler';

  @override
  String get shellRestart => 'Recommencer';

  @override
  String get shellMoves => 'Coups';

  @override
  String get shellNoMoves => 'Aucun coup pour l’instant.';

  @override
  String shellHistoryEntry(String player, String move) {
    return '$player : $move';
  }

  @override
  String shellHandoverPass(String player) {
    return 'Passe l’appareil à $player';
  }

  @override
  String shellHandoverContinue(String player) {
    return 'Je suis $player – continuer';
  }

  @override
  String connect4Column(int column) {
    return 'Colonne $column';
  }

  @override
  String get connect4HintTapColumn => 'Touche une colonne';

  @override
  String get muehlePhasePlacing => 'Pose';

  @override
  String get muehlePhaseMoving => 'Déplacement';

  @override
  String get muehlePhaseFlying => 'Saut';

  @override
  String muehleMovePlace(int point) {
    return 'pose sur $point';
  }

  @override
  String muehleMoveRemove(int point) {
    return 'retire le pion sur $point';
  }

  @override
  String muehleMoveMove(int from, int to) {
    return 'déplace $from→$to';
  }

  @override
  String muehleMoveFly(int from, int to) {
    return 'saute $from→$to';
  }

  @override
  String muehleHintRemove(String player) {
    return 'Moulin ! Retire un pion de $player';
  }

  @override
  String get muehleHintPlace => 'Pose un pion';

  @override
  String get muehleHintTarget =>
      'Choisis une case (ou touche à nouveau le pion pour le désélectionner)';

  @override
  String get muehleHintSelectFly => 'Choisis un pion à faire sauter';

  @override
  String get muehleHintSelectMove => 'Choisis un pion à déplacer';

  @override
  String muehlePointEmpty(int point) {
    return 'Point $point, vide';
  }

  @override
  String muehlePointOwned(int point, String player) {
    return 'Point $point, $player';
  }

  @override
  String muehleCounts(int hand, int board) {
    return 'Main : $hand · Plateau : $board';
  }

  @override
  String muehleCaptured(int count) {
    return 'Pris : $count';
  }

  @override
  String get quartettNoGame => 'Pas une partie de Quartett';

  @override
  String get quartettContinue => 'Continuer';

  @override
  String get quartettHigherWins => 'le plus haut gagne';

  @override
  String get quartettLowerWins => 'le plus bas gagne';

  @override
  String get quartettCardBack => 'QUARTETT';

  @override
  String quartettCards(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count cartes',
      many: '$count de cartes',
      one: '$count carte',
    );
    return '$_temp0';
  }

  @override
  String quartettPlayerCards(String player, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count cartes',
      many: '$count de cartes',
      one: '$count carte',
    );
    return '$player : $_temp0';
  }

  @override
  String quartettTrumpfMovePick(String stat) {
    return 'choisit $stat';
  }

  @override
  String get quartettTrumpfHintPick => 'Choisis une valeur de ta carte';

  @override
  String quartettTrumpfPot(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count cartes',
      many: '$count de cartes',
      one: '$count carte',
    );
    return 'Pot : $_temp0';
  }

  @override
  String quartettTrumpfOpponentStack(String player) {
    return 'Pile de $player';
  }

  @override
  String quartettTrumpfYourCard(String player) {
    return 'Ta carte ($player)';
  }

  @override
  String get quartettTrumpfTie => 'Égalité – les cartes vont au pot';

  @override
  String quartettTrumpfWinsTrick(String player) {
    return '$player remporte le pli';
  }

  @override
  String get quartettTrumpfOutcomeWin => 'gagne';

  @override
  String get quartettTrumpfOutcomeLose => 'perd';

  @override
  String get quartettTrumpfOutcomeTie => 'égalité';

  @override
  String quartettTrumpfSideOutcome(String player, String outcome) {
    return '$player – $outcome';
  }

  @override
  String quartettTrumpfPicked(String player, String stat) {
    return '$player choisit $stat';
  }

  @override
  String quartettTrumpfPotAgain(int count, String player) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count cartes',
      many: '$count de cartes',
      one: '$count carte',
    );
    return 'Dans le pot : $_temp0 – $player choisit encore';
  }

  @override
  String get quartettSetsHit => 'Touché';

  @override
  String get quartettSetsMiss => 'Pioche';

  @override
  String quartettSetsMoveAsk(String card, String result) {
    return 'demande $card : $result';
  }

  @override
  String quartettSetsMoveAskQuartet(String card, String result, String set) {
    return 'demande $card : $result – famille $set';
  }

  @override
  String quartettSetsHintContinue(String player) {
    return 'Touche « Continuer » et passe l’appareil à $player';
  }

  @override
  String get quartettSetsHintAsk =>
      'Touche une carte manquante pour la demander';

  @override
  String get quartettSetsNoQuartet => 'pas encore de famille';

  @override
  String quartettSetsStock(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count cartes',
      many: '$count de cartes',
      one: '$count carte',
    );
    return 'Pioche : $_temp0';
  }

  @override
  String quartettSetsScore(int a, int b) {
    return 'Familles X $a : $b O';
  }

  @override
  String quartettSetsOtherAsked(String player, String card, String result) {
    return '$player demande $card : $result';
  }

  @override
  String quartettSetsHitGives(String player, String card) {
    return 'Touché ! $player te donne $card';
  }

  @override
  String get quartettSetsMissDraw => 'Pioche – tu tires une carte';

  @override
  String get quartettSetsMissEmpty => 'Pioche – la pioche est vide';

  @override
  String get quartettSetsAskAgain => 'Tu peux redemander.';

  @override
  String quartettSetsNotHeld(String player, String card) {
    return '$player n’a pas $card.';
  }

  @override
  String quartettSetsQuartetLaid(String set) {
    return 'Famille complète ! $set posée';
  }

  @override
  String get quartettSetsDrawn => 'Tiré :';

  @override
  String quartettSetsYourCards(String player, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count cartes',
      many: '$count de cartes',
      one: '$count carte',
    );
    return 'Tes cartes ($player) : $_temp0';
  }

  @override
  String quartettSetsProgress(int have, int missing) {
    return '$have/4 – manque : $missing';
  }

  @override
  String get quartettSetsAskSlot => 'demander';

  @override
  String get quartettSetsMissingSlot => 'manque';

  @override
  String get schiffeHintSetup =>
      'Placement : touche la mer (ou glisse et relâche) pour placer le navire. Les navires ne doivent pas se toucher.';

  @override
  String get schiffeHintAllSunk => 'Tous les navires sont coulés.';

  @override
  String schiffeHintWaiting(String player) {
    return 'En attente de $player…';
  }

  @override
  String get schiffeHintExtraShot =>
      'Touché ! Encore – touche une case de la mer adverse.';

  @override
  String get schiffeHintFire =>
      'Touche une case inconnue de la mer adverse pour tirer.';

  @override
  String get schiffeLookWater => 'eau';

  @override
  String get schiffeLookShip => 'navire';

  @override
  String get schiffeLookMiss => 'raté';

  @override
  String get schiffeLookShipHit => 'navire touché';

  @override
  String get schiffeLookHit => 'touché';

  @override
  String get schiffeLookSunk => 'coulé';

  @override
  String get schiffeLookUnknown => 'inconnu';

  @override
  String schiffeCellLabel(String cell, String state) {
    return '$cell $state';
  }

  @override
  String get schiffeFleetComplete => 'Flotte complète';

  @override
  String schiffeShipWithLength(String ship, int length) {
    return '$ship ($length)';
  }

  @override
  String schiffeShipPlaced(String ship, int length) {
    return '$ship ($length) · placé';
  }

  @override
  String get schiffeHorizontal => 'Horizontal';

  @override
  String get schiffeVertical => 'Vertical';

  @override
  String get schiffeRandom => 'Au hasard';

  @override
  String get schiffeFleet => 'Flotte';

  @override
  String schiffeExtraShotSunk(String ship) {
    return '$ship coulé – touché ! Encore';
  }

  @override
  String get schiffeExtraShot => 'Touché ! Encore';

  @override
  String schiffeRemaining(int own, String player, int opponent) {
    return 'Ta flotte : $own · Adversaire ($player) : $opponent navires restants';
  }

  @override
  String schiffeIncoming(String player, String cell, String result) {
    return '$player a tiré en dernier sur $cell : $result';
  }

  @override
  String get schiffeTargetSection => 'Adversaire';

  @override
  String get schiffeOwnSection => 'Ta mer';

  @override
  String get schiffeMovePlace => 'place un navire';

  @override
  String schiffeMoveAutoplace(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'place $count navires au hasard',
      many: 'place $count de navires au hasard',
      one: 'place $count navire au hasard',
    );
    return '$_temp0';
  }

  @override
  String schiffeMoveFire(String cell, String result) {
    return 'tire sur $cell : $result';
  }

  @override
  String get schiffeRotate => 'Tourner';

  @override
  String schiffeRotateSemantics(String orientation) {
    return 'Tourner, actuellement $orientation';
  }

  @override
  String get schiffeRemove => 'Retirer';

  @override
  String get schiffeRemoveTooltip => 'Retour au port';

  @override
  String get schiffeReset => 'Réinitialiser';

  @override
  String get schiffeDone => 'Terminé';

  @override
  String schiffeSetupCount(int placed, int total, String player) {
    return '$placed navires sur $total placés · $player place';
  }

  @override
  String schiffeHintSelected(String ship) {
    return '$ship sélectionné : touche une case ou fais glisser le navire pour le déplacer. Touche-le encore ou « Tourner » pour le pivoter.';
  }

  @override
  String get schiffeHintReady =>
      'Flotte prête. Touche un navire pour le modifier – ou « Terminé ».';

  @override
  String schiffeHintEarly(String player) {
    return 'Tu peux déjà placer tes navires. « Terminé » fonctionne dès que $player a fini.';
  }

  @override
  String get schiffeInvalidPlace =>
      'Ça ne rentre pas : les navires doivent être entièrement sur la mer et ne pas se toucher.';

  @override
  String get schiffeInvalidRotate =>
      'Impossible de tourner ici – pas assez de place.';

  @override
  String get schiffeSubmitFailed =>
      'Le placement n’a pas été accepté. Touche à nouveau « Terminé ».';

  @override
  String get schiffeSelected => 'sélectionné';

  @override
  String get schiffeHarbour => 'Port';

  @override
  String schiffeShipSunk(String ship) {
    return '$ship coulé';
  }

  @override
  String get debugConsoleTitle => 'Console de débogage';

  @override
  String get debugUndo => 'undo';

  @override
  String get debugMenu => 'Jeu / démo';

  @override
  String debugNewGame(String game) {
    return 'Nouveau : $game';
  }

  @override
  String get debugLegalMoves => 'Coups légaux';

  @override
  String get debugAutoPlay => 'Jouer jusqu’au bout (au hasard)';

  @override
  String get debugDemo => 'Démo : tous les jeux';

  @override
  String get pairingTitle => 'Jouer en Wi-Fi';

  @override
  String get pairingDeviceNameHelper =>
      'C’est ainsi que l’autre joueur te voit';

  @override
  String get playerNameTitle => 'Comment tu t’appelles ?';

  @override
  String get playerNameLabel => 'Ton nom';

  @override
  String playerLabel(String name, String mark) {
    return '$name ($mark)';
  }

  @override
  String get hotSeatNamesTitle => 'Noms des joueurs';

  @override
  String hotSeatNameLabel(String mark) {
    return 'Joueur $mark';
  }

  @override
  String get hotSeatNamesHelper =>
      'Facultatif – laisse vide pour afficher seulement X et O.';

  @override
  String get pairingModeHost => 'Héberger';

  @override
  String get pairingModeJoin => 'Rejoindre';

  @override
  String get pairingChooseGame => 'Choisis un jeu';

  @override
  String get pairingHostGame => 'Héberger la partie';

  @override
  String pairingHostStartFailed(String error) {
    return 'Impossible de lancer la partie : $error';
  }

  @override
  String get pairingNotAdvertised =>
      'Pas visible automatiquement – l’autre joueur saisit l’adresse.';

  @override
  String get pairingNoDiscoveryHost =>
      'Pas de recherche automatique sur cet appareil – l’autre joueur saisit l’adresse.';

  @override
  String pairingHosting(String name, String game) {
    return '$name héberge $game';
  }

  @override
  String pairingNoAddress(int port) {
    return 'Aucune adresse Wi-Fi trouvée. L’appareil est-il connecté au Wi-Fi ? Port : $port';
  }

  @override
  String get pairingAddresses => 'Adresses (à saisir) :';

  @override
  String get pairingProbablyWifi => 'probablement le Wi-Fi';

  @override
  String get pairingWaitingForGuest => 'En attente de l’autre joueur…';

  @override
  String get pairingCancel => 'Annuler';

  @override
  String get pairingGamesOnNetwork => 'Parties sur le réseau';

  @override
  String get pairingNoDiscoveryJoin =>
      'La recherche automatique n’est pas disponible sur cet appareil. Saisis l’adresse ci-dessous.';

  @override
  String get pairingBrowseFailed =>
      'Impossible de chercher sur le réseau. Saisis l’adresse ci-dessous.';

  @override
  String get pairingSearching => 'Recherche de parties…';

  @override
  String get pairingOtherVersion => 'autre version de Klunki';

  @override
  String get pairingOrEnterAddress => 'Ou saisis une adresse';

  @override
  String get pairingManualLabel => 'IP, IP:port ou lien klunki://';

  @override
  String get pairingInvalidAddress =>
      'Adresse invalide. Exemple : 192.168.1.20 ou 192.168.1.20:4747';

  @override
  String get pairingConnect => 'Connecter';

  @override
  String pairingConnecting(String host) {
    return 'Connexion à $host…';
  }

  @override
  String get pairingTimeout => 'Délai dépassé';

  @override
  String pairingJoinFailed(String host, String error) {
    return 'Échec de la connexion à $host ($error).';
  }

  @override
  String get pairingJoinHints =>
      'Conseils : les deux appareils sont-ils sur le même Wi-Fi ? Les réseaux invités bloquent souvent les connexions entre appareils. iOS : « Réseau local » est-il autorisé pour Klunki (Réglages › Confidentialité) ?';

  @override
  String pairingStatus(String name, String mark, String peer, String peerMark) {
    return 'Toi ($name, $mark) · Adversaire : $peer ($peerMark)';
  }

  @override
  String netBarYou(String name) {
    return 'Toi ($name)';
  }

  @override
  String netBarOpponent(String peer) {
    return 'Adversaire : $peer';
  }

  @override
  String get pairingOpponent => 'Adversaire';

  @override
  String pairingPeerLeft(String peer) {
    return '$peer a quitté la partie';
  }

  @override
  String pairingPeerLost(String peer) {
    return 'Connexion avec $peer perdue';
  }

  @override
  String pairingWaitForRejoin(String reason) {
    return '$reason. En attente de son retour…';
  }

  @override
  String get pairingReconnecting => 'Reconnexion…';

  @override
  String get pairingReconnect => 'Se reconnecter';

  @override
  String get networkVerificationFailed =>
      'Le déroulement de la partie n\'a pas pu être confirmé';

  @override
  String get pairingReconnectFailed =>
      'Échec de la reconnexion. L’hôte est-il encore dans la partie ?';

  @override
  String get pairingBrowserJoin =>
      'Rejoindre depuis un navigateur (saisir l’adresse ou coller le lien) :';

  @override
  String get pairingCopyLink => 'Copier le lien';

  @override
  String get pairingLinkCopied => 'Lien copié';

  @override
  String get webJoinIntro =>
      'Rejoins dans le navigateur une partie hébergée par un iPhone, un iPad, un appareil Android ou le terminal (klunki host). L’hôte affiche l’adresse et le lien sous « Rejoindre depuis un navigateur ».';

  @override
  String get webJoinHttpsWarning =>
      'Cette page est ouverte en https. Depuis là, les navigateurs bloquent les connexions ws:// vers le réseau local. Ouvre Klunki en http://.';

  @override
  String get webJoinAddressLabel => 'IP, IP:port, lien ws:// ou klunki://';

  @override
  String webJoinAddressHelper(int port) {
    return 'Le port est le port navigateur (WebSocket) de l’hôte ; sans port : $port.';
  }

  @override
  String get webJoinInvalidAddress =>
      'Adresse invalide. Exemple : 192.168.1.20, 192.168.1.20:4748 ou klunki://join?h=…';

  @override
  String get webJoinHints =>
      'Conseils : cet appareil est-il sur le même Wi-Fi que l’hôte ? Les réseaux invités bloquent souvent les connexions entre appareils. La page doit être ouverte en http://, pas en https://. L’hôte doit utiliser une version de Klunki compatible avec les navigateurs (elle affiche « Rejoindre depuis un navigateur »).';

  @override
  String get engineReasonConnect4FourInARow => 'Quatre alignés';

  @override
  String get engineReasonConnect4BoardFull => 'Plateau plein';

  @override
  String get engineReasonMuehleFewerThanThree =>
      'L’adversaire a moins de 3 pions';

  @override
  String get engineReasonMuehleBlocked => 'L’adversaire ne peut plus bouger';

  @override
  String engineReasonMuehleNoRemovalLimit(int moves) {
    return '$moves coups sans prise';
  }

  @override
  String get engineReasonQuartettBothStacksEmpty => 'Les deux piles sont vides';

  @override
  String get engineReasonQuartettAllCards => 'L’adversaire n’a plus de cartes';

  @override
  String engineReasonQuartettTrickLimitEqual(int a, int b) {
    return 'Limite de plis atteinte, autant de cartes ($a:$b)';
  }

  @override
  String engineReasonQuartettTrickLimitMoreCards(int a, int b) {
    return 'Limite de plis atteinte, plus de cartes ($a:$b)';
  }

  @override
  String engineReasonQuartettAllQuartetsEqual(int a, int b) {
    return 'Toutes les familles posées, $a:$b';
  }

  @override
  String engineReasonQuartettMostQuartets(int a, int b) {
    return 'Plus de familles ($a:$b)';
  }

  @override
  String get engineReasonSchiffeAllSunk => 'Tous les navires coulés';

  @override
  String get engineReasonGostrategyFlagCaptured => 'Drapeau capturé';

  @override
  String get engineReasonGostrategyNoMoves =>
      'L’adversaire n’a plus aucun coup';

  @override
  String get engineReasonGostrategyBothBlocked => 'Aucun camp ne peut jouer';

  @override
  String engineReasonGostrategyMoveLimit(int moves) {
    return '$moves coups sans combat';
  }

  @override
  String get menuGameGoStrategy => 'GoStrategy';

  @override
  String get menuDescGoStrategy =>
      'Armées cachées – trouve et prends le drapeau adverse.';

  @override
  String get goPieceMarshal => 'Maréchal';

  @override
  String get goPieceGeneral => 'Général';

  @override
  String get goPieceColonel => 'Colonel';

  @override
  String get goPieceMajor => 'Commandant';

  @override
  String get goPieceCaptain => 'Capitaine';

  @override
  String get goPieceLieutenant => 'Lieutenant';

  @override
  String get goPieceSergeant => 'Sergent';

  @override
  String get goPieceMiner => 'Démineur';

  @override
  String get goPieceScout => 'Éclaireur';

  @override
  String get goPieceSpy => 'Espion';

  @override
  String get goPieceBomb => 'Bombe';

  @override
  String get goPieceFlag => 'Drapeau';

  @override
  String goPieceRank(String piece, String rank) {
    return '$piece ($rank)';
  }

  @override
  String goSetupTitle(String player) {
    return 'Place ton armée ($player)';
  }

  @override
  String get goSetupHint =>
      'Touche deux pièces ou fais-en glisser une sur une autre case de tes quatre rangées pour les échanger. Puis « Terminé ».';

  @override
  String goSetupSelected(String piece) {
    return '$piece choisi – touche une autre case de tes quatre rangées pour échanger.';
  }

  @override
  String get goSetupShuffle => 'Mélanger';

  @override
  String get goSetupDone => 'Terminé';

  @override
  String goSetupFirst(String player) {
    return '$player se place en premier – tu peux déjà préparer.';
  }

  @override
  String goWaitingSetup(String player) {
    return 'En attente du placement de $player …';
  }

  @override
  String get goLegendTitle => 'Pièces';

  @override
  String get goLegendRules =>
      'Le rang le plus élevé gagne ; à égalité, les deux tombent. L’espion bat le maréchal s’il attaque. Seuls les démineurs désamorcent les bombes. Les éclaireurs avancent en ligne droite aussi loin qu’ils veulent. Les bombes et le drapeau ne bougent pas.';

  @override
  String get goHintSelect => 'Touche une de tes pièces, puis une case marquée.';

  @override
  String goHintSelected(String piece) {
    return '$piece – touche une case marquée.';
  }

  @override
  String goHintNoTargets(String piece) {
    return '$piece ne peut pas bouger pour l’instant.';
  }

  @override
  String goHintWaiting(String player) {
    return 'En attente de $player …';
  }

  @override
  String goMoveLimit(String moves) {
    return 'Encore $moves coups sans combat et c’est match nul.';
  }

  @override
  String goArmyOwn(String mark) {
    return 'Ton armée ($mark)';
  }

  @override
  String goArmyEnemy(String player) {
    return 'Adversaire – $player';
  }

  @override
  String goArmyLeft(String left, String total) {
    return '$left sur $total restantes';
  }

  @override
  String goFightBy(String player) {
    return 'Attaque de $player';
  }

  @override
  String goFightBeats(String winner, String loser) {
    return '$winner bat $loser';
  }

  @override
  String get goFightBoth => 'Les deux tombent';

  @override
  String goFightDefused(String piece) {
    return '$piece désamorce la bombe';
  }

  @override
  String goFightBomb(String piece) {
    return '$piece saute sur une bombe';
  }

  @override
  String get goFightFlag => 'Drapeau pris !';

  @override
  String get goMoveSetup => 'place son armée';

  @override
  String goMoveStep(String from, String to) {
    return 'joue $from–$to';
  }

  @override
  String goMoveAttack(String from, String to, String result) {
    return 'attaque ($from–$to) – $result';
  }

  @override
  String goCellLabel(String cell, String content) {
    return '$cell – $content';
  }

  @override
  String get goCellFree => 'libre';

  @override
  String get goCellLake => 'lac';

  @override
  String goCellHidden(String player) {
    return 'pièce cachée de $player';
  }

  @override
  String goCellPiece(String piece, String player) {
    return '$piece de $player';
  }

  @override
  String goCellMoved(String content) {
    return '$content, déplacée';
  }

  @override
  String gameNotInApp(String game) {
    return '$game n’est pas encore disponible dans l’application.';
  }

  @override
  String get engineSetA => 'Supersportives';

  @override
  String get engineSetB => 'Hypersportives';

  @override
  String get engineSetC => 'Classiques';

  @override
  String get engineSetD => 'Muscle cars';

  @override
  String get engineSetE => 'Légendes du rallye';

  @override
  String get engineSetF => 'Grand tourisme';

  @override
  String get engineSetG => 'Électriques';

  @override
  String get engineSetH => 'Petites bombes';

  @override
  String get engineStatPs => 'Puissance';

  @override
  String get engineStatKmh => 'Vitesse max.';

  @override
  String get engineStatCcm => 'Cylindrée';

  @override
  String get engineStatKg => 'Poids';

  @override
  String get engineStatSec0to100 => '0–100 km/h';

  @override
  String get engineUnitPs => 'ch';

  @override
  String get engineUnitKmh => 'km/h';

  @override
  String get engineUnitCcm => 'cm³';

  @override
  String get engineUnitKg => 'kg';

  @override
  String get engineUnitSec => 's';

  @override
  String get engineShip5 => 'Cuirassé';

  @override
  String get engineShip4 => 'Croiseur';

  @override
  String get engineShip3 => 'Contre-torpilleur';

  @override
  String get engineShip2 => 'Sous-marin';

  @override
  String get engineShipOther => 'Navire';

  @override
  String get relayHostIntro =>
      'Un second navigateur sur le même Wi-Fi rejoint la partie avec le code de salle.';

  @override
  String get relayRoomCode => 'Code de salle';

  @override
  String get relayWaitingHint =>
      'Ouvre le lien sur le second appareil ou scanne le code QR. Ou ouvre Klunki dessus et saisis le code de salle.';

  @override
  String relayInfo(String address) {
    return 'Relais : $address';
  }

  @override
  String get relayJoinTitle => 'Rejoindre avec un code de salle';

  @override
  String get relayCodeHelper =>
      '5 caractères. Le navigateur qui héberge la partie affiche le code.';

  @override
  String get relayCodeInvalid =>
      'Code de salle invalide : 5 lettres ou chiffres (sans 0, O, 1, I, L).';

  @override
  String get relayJoin => 'Rejoindre la salle';

  @override
  String relayJoining(String code) {
    return 'Connexion à la salle $code…';
  }

  @override
  String get relayAddressLabel => 'Adresse du relais';

  @override
  String get relayAddressHelper =>
      'Ordinateur du Wi-Fi qui exécute « klunki relay », p. ex. 192.168.1.20:4749';

  @override
  String get relayAddressAdvanced => 'Avancé : adresse du relais';

  @override
  String get relayAddressInvalid =>
      'Adresse de relais invalide. Exemple : 192.168.1.20:4749';

  @override
  String relayErrorUnknownCode(String code) {
    return 'Aucune salle avec le code $code. Le code est-il juste, et l’hôte attend-il encore ?';
  }

  @override
  String relayErrorRoomFull(String code) {
    return 'La salle $code est déjà pleine : deux joueurs y jouent.';
  }

  @override
  String get relayErrorHostLeft =>
      'L’hôte a quitté la salle. La partie est terminée.';

  @override
  String get relayErrorExpired =>
      'La salle a expiré (10 minutes sans activité).';

  @override
  String relayErrorUnreachable(String address) {
    return 'Aucun relais joignable à $address.';
  }

  @override
  String get relayErrorLost => 'La connexion au relais a été perdue.';

  @override
  String get relayStartHint =>
      'Navigateur contre navigateur nécessite un relais. Lance-le sur un ordinateur du Wi-Fi et ouvre Klunki depuis son adresse :';

  @override
  String relayRoomLost(String reason) {
    return '$reason Lance une nouvelle partie.';
  }

  @override
  String relayFromLink(String address) {
    return 'Relais du lien : $address';
  }

  @override
  String get relayLinkSaveDefault => 'Enregistrer par défaut';

  @override
  String get relayLinkUseSaved => 'Utiliser le relais enregistré';

  @override
  String get relayLinkForeign =>
      'Attention : ce lien mène à un autre relais, pas au serveur de cette page. Ne rejoins que si tu fais confiance à l’expéditeur : un relais étranger voit tous les coups.';

  @override
  String get pairingSeatTaken =>
      'Place occupée : quelqu’un joue déjà cette partie. Seul le joueur qui l’a rejointe en premier peut revenir.';

  @override
  String get webJoinDirectTitle =>
      'Ou se connecter à un appareil hôte (appli ou terminal)';

  @override
  String get qrScanButton => 'Scanner le QR code';

  @override
  String get qrScanHint => 'Pointe la caméra vers le QR code de l\'hôte.';

  @override
  String get qrScanNotKlunki =>
      'Ce n\'est pas un code Klunki. Scanne le QR code que le jeu affiche quand il héberge une partie.';

  @override
  String get qrScanTorchOn => 'Allumer la lumière';

  @override
  String get qrScanTorchOff => 'Éteindre la lumière';

  @override
  String get qrScanPermissionDenied =>
      'Klunki n\'a pas le droit d\'utiliser la caméra.';

  @override
  String get qrScanPermissionHint =>
      'Tu peux autoriser l\'accès à la caméra pour Klunki dans les réglages de l\'appareil.';

  @override
  String get qrScanUnavailable => 'La caméra n\'est pas disponible.';

  @override
  String get qrScanTypeInstead => 'Saisir le code';

  @override
  String get relayGroupTitle => 'Jouer via le relais (code de salle)';

  @override
  String get relayChange => 'modifier';

  @override
  String get relayNotSet => 'Aucun relais configuré – saisis une adresse';

  @override
  String relayUseDefault(String address) {
    return 'Par défaut : $address';
  }

  @override
  String get relaySave => 'Appliquer';

  @override
  String get relayJoinIntro =>
      'Le code de salle vient d’un navigateur qui a choisi « Héberger la partie ».';

  @override
  String get joinDirectTitle => 'Se connecter directement à un appareil';

  @override
  String get joinDirectHelper =>
      'Pour un téléphone, une tablette ou un terminal qui héberge lui-même : saisis l’adresse de l’appareil (IP).';

  @override
  String get shellResign => 'Abandonner';

  @override
  String get shellResignTitle => 'Vraiment abandonner ?';

  @override
  String shellResignBody(String player) {
    return 'La partie se termine maintenant et $player gagne.';
  }

  @override
  String get shellResignWho =>
      'Qui abandonne ? La partie se termine maintenant et l’autre camp gagne.';

  @override
  String shellResignPlayer(String player) {
    return '$player abandonne';
  }

  @override
  String engineReasonCommonResigned(String player) {
    return '$player a abandonné';
  }

  @override
  String get engineReasonCommonYouResigned => 'Tu as abandonné';

  @override
  String get quartettDeckCars => 'Voitures';

  @override
  String get quartettDeckTrains => 'Trains';

  @override
  String get quartettDeckRockets => 'Fusées';

  @override
  String get quartettDeckPlanes => 'Avions';

  @override
  String get quartettSetTrainsA => 'ICE';

  @override
  String get quartettSetTrainsB => 'Shinkansen';

  @override
  String get quartettSetTrainsC => 'TGV';

  @override
  String get quartettSetTrainsD => 'Les rapides d\'Europe';

  @override
  String get quartettSetTrainsE => 'Asie & Amérique';

  @override
  String get quartettSetTrainsF => 'Locomotives électriques';

  @override
  String get quartettSetTrainsG => 'Légendes de la vapeur';

  @override
  String get quartettSetTrainsH => 'Géants du fret';

  @override
  String get quartettSetRocketsA => 'Fusées lunaires';

  @override
  String get quartettSetRocketsB => 'Réutilisables';

  @override
  String get quartettSetRocketsC => 'Europe';

  @override
  String get quartettSetRocketsD => 'Classiques américains';

  @override
  String get quartettSetRocketsE => 'Russie';

  @override
  String get quartettSetRocketsF => 'Chine';

  @override
  String get quartettSetRocketsG => 'Japon & Inde';

  @override
  String get quartettSetRocketsH => 'Petits lanceurs';

  @override
  String get quartettSetPlanesA => 'Gros-porteurs';

  @override
  String get quartettSetPlanesB => 'Moyen-courriers';

  @override
  String get quartettSetPlanesC => 'Supersoniques';

  @override
  String get quartettSetPlanesD => 'Classiques à hélice';

  @override
  String get quartettSetPlanesE => 'Géants du cargo';

  @override
  String get quartettSetPlanesF => 'Affaires & loisirs';

  @override
  String get quartettSetPlanesG => 'Pionniers';

  @override
  String get quartettSetPlanesH => 'Records insolites';

  @override
  String get quartettStatKw => 'Puissance';

  @override
  String get quartettStatLengthM => 'Longueur';

  @override
  String get quartettStatMassT => 'Poids';

  @override
  String get quartettStatTractiveKn => 'Effort de traction';

  @override
  String get quartettStatInService => 'En service depuis';

  @override
  String get quartettStatHeightM => 'Hauteur';

  @override
  String get quartettStatThrustKn => 'Poussée au décollage';

  @override
  String get quartettStatLeoT => 'Charge utile (LEO)';

  @override
  String get quartettStatLaunchMassT => 'Masse au lancement';

  @override
  String get quartettStatFlights => 'Lancements';

  @override
  String get quartettStatFirstFlight => 'Premier vol';

  @override
  String get quartettStatRangeKm => 'Autonomie';

  @override
  String get quartettStatWingspanM => 'Envergure';

  @override
  String get quartettStatMtowT => 'Masse max. au décollage';

  @override
  String get quartettDeckPickerTitle => 'Choisir un jeu de cartes';

  @override
  String get quartettDeckLabel => 'Jeu de cartes';

  @override
  String quartettDeckSets(int sets) {
    return '$sets familles de 4 cartes';
  }

  @override
  String get quartettDeckPlay => 'Jouer';

  @override
  String get quartettGalleryOpen => 'Voir les cartes';

  @override
  String get quartettGalleryTitle => 'Cartes du Quartett';

  @override
  String quartettGalleryCardOf(int index, int total) {
    return 'Carte $index sur $total';
  }

  @override
  String get quartettGalleryPrevious => 'Carte précédente';

  @override
  String get quartettGalleryNext => 'Carte suivante';

  @override
  String get quartettGalleryTopMenu => 'Top 5 par valeur';

  @override
  String quartettGalleryTopTitle(String stat) {
    return 'Top 5 : $stat';
  }

  @override
  String quartettCardSemantics(String id, String name, String set) {
    return 'Carte $id : $name, famille $set';
  }

  @override
  String get goSetupInvalid =>
      'Seules tes quatre rangées du bas acceptent des pièces.';
}
