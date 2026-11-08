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
  String get menuDebugConsole => 'Console de débogage';

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
  String get menuSectionNetwork => 'Jouer avec d’autres appareils';

  @override
  String get menuPlayOnOneDevice => 'Un appareil';

  @override
  String get menuPlayWithOthers => 'Avec d’autres';

  @override
  String get hotSeatPassDeviceHint =>
      'Passez-vous l’appareil – ce qui est caché reste secret.';

  @override
  String get roomStartSubtitle => 'Les autres entrent avec le code de salle';

  @override
  String get roomJoinSubtitle => 'Scanne ou saisis le code';

  @override
  String get roomAdvanced => 'Avancé';

  @override
  String get roomDirectWaitingHint =>
      'Les autres touchent « Rejoindre une salle » et scannent ce code QR. Les appareils du même Wi-Fi trouvent aussi la salle sous « Salles à proximité ».';

  @override
  String get roomViaRelay => 'Ouvrir la salle via un serveur';

  @override
  String get roomViaRelayHelper =>
      'Avec un code de salle, aussi pour les joueurs dans un navigateur. Il faut un serveur (par exemple un ordinateur qui exécute « klunki relay »). Désactivé, la salle tourne sur cet appareil et les appareils du même Wi-Fi la trouvent tout seuls.';

  @override
  String get roomTypeCode => 'Saisir le code de salle';

  @override
  String shellToMove(String player) {
    return 'À $player de jouer';
  }

  @override
  String shellHasWon(String player) {
    return '$player a gagné';
  }

  @override
  String get shellYourTurn => 'À toi de jouer';

  @override
  String shellWaitingFor(String player) {
    return 'On attend $player…';
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
  String get shellTakeBack => 'Reprendre';

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
    return 'Moulin ! Retire un pion à $player';
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
    return 'Pile adverse ($player)';
  }

  @override
  String quartettTrumpfYourCard(String player) {
    return 'Ta carte ($player)';
  }

  @override
  String get quartettTrumpfTie => 'Égalité – départage !';

  @override
  String quartettTrumpfWinsTrick(String player) {
    return '$player remporte la manche';
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
    return 'Les cartes vont au pot (maintenant $count), $player choisit encore';
  }

  @override
  String quartettTrumpfHintWaiting(String player) {
    return '$player choisit …';
  }

  @override
  String get quartettTrumpfLastTrick => 'Manche précédente';

  @override
  String quartettTrumpfGraceSeconds(int seconds) {
    return 'Suite dans $seconds s';
  }

  @override
  String quartettTrumpfQueuedPick(String player, String stat) {
    return '$player a choisi : $stat';
  }

  @override
  String quartettTrumpfNextPicker(String player) {
    return '$player choisit ensuite';
  }

  @override
  String quartettTrumpfPicksAgain(String player) {
    return '$player choisit encore';
  }

  @override
  String quartettTrumpfContinuePicker(String player) {
    return 'Continuer – $player choisit';
  }

  @override
  String get quartettTrumpfYouPickNext => 'Tu choisis ensuite';

  @override
  String quartettTrumpfTricksBehind(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'encore $count manches',
      many: 'encore $count de manches',
      one: 'encore $count manche',
    );
    return '$_temp0';
  }

  @override
  String quartettTrumpfHandoverReason(String player) {
    return '$player a remporté la manche';
  }

  @override
  String quartettTrumpfChooseOwn(int count) {
    return 'Il ne te reste que $count cartes – choisis-en une.';
  }

  @override
  String quartettTrumpfChooseDefend(String player, String stat) {
    return '$player joue $stat. Choisis ta carte.';
  }

  @override
  String get quartettTrumpfMoveChoose => 'choisit une carte';

  @override
  String quartettTrumpfHintDefending(String player) {
    return '$player choisit une carte …';
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
  String quartettSetsScore(String nameA, String nameB, int a, int b) {
    return 'Familles $nameA $a : $b $nameB';
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
  String get schiffeHintSetup => 'Touche la mer pour placer le navire.';

  @override
  String get schiffeHintAllSunk => 'Tous les navires sont coulés.';

  @override
  String schiffeHintWaiting(String player) {
    return 'On attend $player…';
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
    return '$ship sélectionné : glisse pour déplacer, touche encore pour tourner.';
  }

  @override
  String get schiffeHintReady =>
      'Flotte prête. Touche un navire pour le déplacer ou le tourner – ou « Terminé ».';

  @override
  String schiffeHintEarly(String player) {
    return 'Tu peux déjà placer tes navires. « Terminé » fonctionne quand $player aura fini.';
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
  String get schiffeHintSetupMore =>
      'Touche la mer pour le navire suivant. Touche un navire pour le déplacer ou le tourner.';

  @override
  String get schiffeCoachTap => 'Touche-le : déplacer ou tourner';

  @override
  String schiffeDoneLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'encore $count navires',
      one: 'encore 1 navire',
    );
    return '$_temp0';
  }

  @override
  String schiffePreviewSemantics(String ship, String orientation) {
    return 'Aperçu : $ship, $orientation. Touche pour le tourner.';
  }

  @override
  String schiffePreviewLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'encore $count de ce type',
      one: 'le dernier de ce type',
    );
    return '$_temp0';
  }

  @override
  String get schiffeInvalidTouch =>
      'Les navires ne doivent pas se toucher, même par un coin – laisse une case libre entre eux.';

  @override
  String get schiffeInvalidOffBoard => 'Ne rentre pas sur le plateau.';

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
  String get playerDefaultNameA => 'Anne';

  @override
  String get playerDefaultNameB => 'Hugo';

  @override
  String get hotSeatStartTitle => 'Qui joue ?';

  @override
  String get hotSeatStartPlay => 'Jouer';

  @override
  String get hotSeatNamesTitle => 'Noms des joueurs';

  @override
  String hotSeatNameLabel(int number) {
    return 'Joueur $number';
  }

  @override
  String get hotSeatStartsHint => 'commence';

  @override
  String get hotSeatNamesHelper => 'Laisse vide pour garder le nom par défaut.';

  @override
  String get pairingChooseGame => 'Choisis un jeu';

  @override
  String get roomStart => 'Ouvrir une salle';

  @override
  String roomStartFailed(String error) {
    return 'Impossible d’ouvrir la salle : $error';
  }

  @override
  String get pairingNotAdvertised =>
      'Pas visible automatiquement – les autres scannent le code QR.';

  @override
  String get pairingNoDiscoveryHost =>
      'Pas de recherche automatique sur cet appareil – les autres scannent le code QR.';

  @override
  String roomOfPlayer(String name, String game) {
    return 'Chez $name : $game';
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
  String get roomNearby => 'Salles à proximité';

  @override
  String get pairingNoDiscoveryJoin =>
      'La recherche automatique n’est pas disponible sur cet appareil. Scanne le code QR ou saisis l’adresse sous « Avancé ».';

  @override
  String get pairingBrowseFailed =>
      'Impossible de chercher sur le réseau. Scanne le code QR ou saisis l’adresse sous « Avancé ».';

  @override
  String get pairingSearching => 'Recherche de salles…';

  @override
  String get pairingOtherVersion => 'autre version de Klunki';

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
  String pairingStatus(String name, String peer) {
    return 'Toi : $name · Adversaire : $peer';
  }

  @override
  String netBarYou(String name) {
    return 'Toi : $name';
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
      'La reconnexion a échoué. L’autre appareil est-il encore dans la partie ?';

  @override
  String get pairingBrowserJoin =>
      'Rejoindre depuis un navigateur (saisir l’adresse ou coller le lien) :';

  @override
  String get pairingCopyLink => 'Copier le lien';

  @override
  String get pairingLinkCopied => 'Lien copié';

  @override
  String get webJoinHttpsWarning =>
      'Dans un navigateur en https, Klunki ne peut joindre que des serveurs sécurisés (wss://) – utilise l’app ou la version http locale.';

  @override
  String get webJoinAddressLabel => 'IP, IP:port, lien ws:// ou klunki://';

  @override
  String webJoinAddressHelper(int port) {
    return 'Le port est le port navigateur (WebSocket) de l’autre appareil ; $port par défaut.';
  }

  @override
  String get webJoinInvalidAddress =>
      'Adresse invalide. Exemple : 192.168.1.20, 192.168.1.20:4748 ou klunki://join?h=…';

  @override
  String get webJoinHints =>
      'Conseils : cet appareil est-il sur le même Wi-Fi que l’appareil de la salle ? Les réseaux invités bloquent souvent les connexions entre appareils. La page doit être ouverte en http://, pas en https://. L’autre appareil doit utiliser une version de Klunki compatible avec les navigateurs (elle affiche « Rejoindre depuis un navigateur »).';

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
    return 'Limite de manches atteinte, autant de cartes ($a:$b)';
  }

  @override
  String engineReasonQuartettTrickLimitMoreCards(int a, int b) {
    return 'Limite de manches atteinte, plus de cartes ($a:$b)';
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
    return 'Placement en cours : $player …';
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
    return 'On attend $player …';
  }

  @override
  String goMoveLimit(String moves) {
    return 'Encore $moves coups sans combat et c’est match nul.';
  }

  @override
  String get goArmyOwn => 'Ton armée';

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
    return 'Attaque par $player';
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
    return 'pièce cachée ($player)';
  }

  @override
  String goCellPiece(String piece, String player) {
    return '$piece ($player)';
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
  String get engineStatPs => 'Puis­sance';

  @override
  String get engineStatKmh => 'Vitesse max.';

  @override
  String get engineStatCcm => 'Cylin­drée';

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
  String get roomStartIntro =>
      'Les autres touchent « Rejoindre une salle » et saisissent le code de salle.';

  @override
  String get relayRoomCode => 'Code de salle';

  @override
  String get relayWaitingHint =>
      'Les autres touchent « Rejoindre une salle » et scannent le code QR ou saisissent le code de salle. Ou ils ouvrent le lien.';

  @override
  String relayInfo(String address) {
    return 'Serveur : $address';
  }

  @override
  String get roomCodeHelper =>
      '5 caractères – l’autre appareil affiche le code avec sa salle.';

  @override
  String get relayCodeInvalid =>
      'Code de salle invalide : 5 lettres ou chiffres (sans 0, O, 1, I, L).';

  @override
  String get roomJoin => 'Rejoindre une salle';

  @override
  String relayJoining(String code) {
    return 'Connexion à la salle $code…';
  }

  @override
  String get relayAddressLabel => 'Serveur';

  @override
  String get relayAddressHelper =>
      'Adresse du serveur, p. ex. 192.168.1.20:4749 (sur le Wi-Fi) ou wss://spiele.example (sur Internet)';

  @override
  String get relayAddressInvalid =>
      'Adresse de serveur invalide. Exemple : 192.168.1.20:4749';

  @override
  String relayErrorUnknownCode(String code) {
    return 'Aucune salle avec le code $code. Le code est-il juste, et la salle est-elle encore ouverte ?';
  }

  @override
  String relayErrorRoomFull(String code) {
    return 'La salle $code est déjà pleine : deux joueurs y jouent.';
  }

  @override
  String relayErrorHostAway(String code) {
    return 'L’appareil qui a ouvert la salle $code est injoignable pour le moment. Réessaie dans un instant.';
  }

  @override
  String get relayErrorRoomClosed =>
      'La salle a été fermée : la personne qui l’a ouverte est partie. La partie est terminée.';

  @override
  String get relayErrorExpired =>
      'La salle a expiré (10 minutes sans activité).';

  @override
  String relayErrorUnreachable(String address) {
    return 'Aucun serveur joignable à $address.';
  }

  @override
  String get relayErrorLost => 'La connexion au serveur a été perdue.';

  @override
  String get relayStartHint =>
      'Les salles avec code ont besoin d’un serveur. Lance-le sur un ordinateur du Wi-Fi et ouvre Klunki depuis son adresse :';

  @override
  String relayRoomLost(String reason) {
    return '$reason Ouvre une nouvelle salle.';
  }

  @override
  String relayFromLink(String address) {
    return 'Serveur du lien : $address';
  }

  @override
  String get relayLinkSaveDefault => 'Enregistrer par défaut';

  @override
  String get relayLinkUseSaved => 'Utiliser le serveur enregistré';

  @override
  String get relayLinkForeign =>
      'Attention : ce lien mène à un autre serveur, pas à celui de cette page. Ne rejoins que si tu fais confiance à l’expéditeur : un serveur étranger voit tous les coups.';

  @override
  String get pairingSeatTaken =>
      'Place occupée : quelqu’un joue déjà cette partie. Seul le joueur qui l’a rejointe en premier peut revenir.';

  @override
  String get qrScanButton => 'Scanner le QR code';

  @override
  String get qrScanHint =>
      'Pointe la caméra vers le code QR de l’autre appareil.';

  @override
  String get qrScanNotKlunki =>
      'Ce n’est pas un code Klunki. Scanne le code QR que l’autre appareil affiche avec sa salle.';

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
  String get relayChange => 'modifier';

  @override
  String get relayNotSet => 'Aucun serveur configuré – saisis une adresse';

  @override
  String relayUseDefault(String address) {
    return 'Par défaut : $address';
  }

  @override
  String get relaySave => 'Appliquer';

  @override
  String get relayClubCodeLabel => 'Code du club';

  @override
  String get relayClubCodeHelper =>
      'Enregistré seulement pour ce serveur. Le code du club n’est jamais mis dans les liens ni les QR codes des salles.';

  @override
  String get relayErrorClubMissing =>
      'Ce serveur demande un code du club. Demande à la personne qui gère le serveur.';

  @override
  String get relayErrorClubWrong =>
      'Ce serveur ne connaît pas ce code du club. Demande à la personne qui gère le serveur.';

  @override
  String get serverKindLan =>
      'Serveur sur le Wi-Fi (un ordinateur qui exécute « klunki relay »)';

  @override
  String get serverKindInternet => 'Serveur sur Internet';

  @override
  String get serverHelpLink => 'Comment ça marche ?';

  @override
  String get serverClubCodeRemove => 'Supprimer le code du club';

  @override
  String get serverClubCodeRetry => 'Essayer avec le code';

  @override
  String get helpTitle => 'Jouer ensemble, mode d’emploi';

  @override
  String get helpSectionRoomsTitle => 'Jouer avec d’autres';

  @override
  String get helpSectionRoomsBody =>
      'Une personne touche « Ouvrir une salle » et choisit un jeu. Klunki affiche alors un code de salle et un QR code.\n\nL’autre personne touche « Rejoindre une salle » et scanne le QR code ou saisit le code de salle. Et c’est parti.';

  @override
  String get helpSectionWifiTitle => 'Sur le même Wi-Fi';

  @override
  String get helpSectionWifiBody =>
      'L’un de vous a l’app ? Alors pas besoin de serveur sur le Wi-Fi : l’app est elle-même le serveur, aussi pour les joueurs dans un navigateur (QR code).\n\nLes appareils du même Wi-Fi se trouvent tout seuls.';

  @override
  String get helpSectionServerTitle => 'Quand faut-il un serveur ?';

  @override
  String get helpSectionServerBody =>
      'Seulement si tout le monde joue dans un navigateur ou si vous n’êtes pas sur le même Wi-Fi. Le serveur transmet les coups entre vos appareils.\n\nKlunki reconnaît à l’adresse de quel serveur il s’agit : « Serveur sur le Wi-Fi » ou « Serveur sur Internet ».';

  @override
  String get helpSectionOwnServerTitle => 'Votre propre serveur sur le Wi-Fi';

  @override
  String get helpSectionOwnServerBody =>
      'Vous pouvez aussi faire tourner votre propre serveur sur un ordinateur du Wi-Fi. Un programme prêt à l’emploi pour Mac, Windows et Linux est en préparation. Vous saisissez ensuite son adresse dans Klunki sous « Avancé » avec « modifier ».';

  @override
  String get helpSectionComingTitle => 'Bientôt plus simple (en préparation)';

  @override
  String get helpSectionComingBody =>
      'Ces façons d’avoir un serveur sont en préparation :\n• Serveur sur Internet pour un cercle d’amis (avec Cloudflare, gratuit)\n• Programme prêt à télécharger pour Mac, Windows et Linux\n• Docker pour NAS ou Raspberry Pi\n\nLes serveurs sur Internet sont le plus souvent protégés par un code du club.';

  @override
  String get helpSectionClubTitle => 'C’est quoi, un code du club ?';

  @override
  String get helpSectionClubBody =>
      'Un code du club, c’est comme une clé pour un serveur : seuls ceux qui le connaissent peuvent y ouvrir ou rejoindre des salles. Tu le reçois de la personne qui gère le serveur.\n\nKlunki ne le demande que si un serveur en a besoin, et le garde pour ce serveur.';

  @override
  String get helpSectionDataTitle => 'Que deviennent mes données ?';

  @override
  String get helpSectionDataBody =>
      'Le serveur ne fait que transmettre les coups et n’en garde rien durablement. Si vous jouez directement sur le même Wi-Fi, rien ne passe par un serveur extérieur.\n\nLe code du club reste sur ton appareil et n’est jamais mis dans les liens ni les QR codes des salles. Avec « modifier » à côté du serveur, tu peux le voir, le changer ou le supprimer.';

  @override
  String get joinDirectTitle => 'Se connecter directement à un appareil';

  @override
  String get joinDirectHelper =>
      'Pour un appareil sur lequel la salle tourne directement (appli ou terminal) : saisis son adresse (IP).';

  @override
  String get shellResign => 'Abandonner';

  @override
  String get shellResignTitle => 'Vraiment abandonner ?';

  @override
  String shellResignBody(String player) {
    return 'La partie se termine pour vous deux – $player gagne.';
  }

  @override
  String get shellLeaveTitle => 'Quitter la partie ?';

  @override
  String get shellLeaveBody =>
      'La connexion sera coupée et la partie se termine pour vous deux.';

  @override
  String get shellLeave => 'Quitter';

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
  String get quartettStatKw => 'Puis­sance';

  @override
  String get quartettStatLengthM => 'Lon­gueur';

  @override
  String get quartettStatMassT => 'Poids';

  @override
  String get quartettStatTractiveKn => 'Effort de trac­tion';

  @override
  String get quartettStatHeightM => 'Hauteur';

  @override
  String get quartettStatThrustKn => 'Pous­sée au décol­lage';

  @override
  String get quartettStatLeoT => 'Charge utile (LEO)';

  @override
  String get quartettStatLaunchMassT => 'Masse au lance­ment';

  @override
  String get quartettStatFlights => 'Lance­ments';

  @override
  String get quartettStatRangeKm => 'Auto­nomie';

  @override
  String get quartettStatWingspanM => 'Enver­gure';

  @override
  String get quartettStatMtowT => 'Masse max. au décol­lage';

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
  String get quartettStatBuilt => 'Cons­truits';

  @override
  String get quartettStatSuccessPct => 'Taux de réussite';

  @override
  String get quartettUnitBuilt => 'ex.';

  @override
  String quartettPhotoCredit(String author, String license) {
    return 'Photo : $author, $license';
  }

  @override
  String get quartettPhotoCreditTitle => 'Crédit photo';

  @override
  String get quartettPhotoCreditTooltip => 'Afficher le crédit photo';

  @override
  String get quartettPhotoModified => 'Réduite pour l’application.';

  @override
  String get quartettPhotoShareAlike =>
      'La version réduite est sous la même licence.';

  @override
  String get quartettPhotoLicense => 'Licence';

  @override
  String get quartettPhotoSource => 'Source';

  @override
  String get quartettPhotoClose => 'Fermer';

  @override
  String get quartettWikipediaRead => 'Lire sur Wikipédia';

  @override
  String get quartettImageCreditsTitle => 'Crédits photos';

  @override
  String get quartettImageCreditsIntro =>
      'Les photos proviennent de Wikimedia Commons et sont sous licences libres. Elles sont incluses dans l’application ; seuls les liens nécessitent Internet.';

  @override
  String get quartettLinkFailed => 'Le lien n’a pas pu être ouvert.';

  @override
  String relayLoopbackHint(String host, String example, String mdnsExample) {
    return 'Remarque : les autres appareils ne peuvent pas joindre « $host ». Ouvre la page via l’adresse Wi-Fi de cet ordinateur (p. ex. $example) ou son nom .local (p. ex. $mdnsExample) pour que le lien et le code QR fonctionnent sur les autres appareils.';
  }

  @override
  String relayLoopbackShort(String host) {
    return '« $host » ne fonctionne que sur cet appareil – les autres appareils ont besoin de l’adresse Wi-Fi ou du nom .local de cet ordinateur.';
  }

  @override
  String get loopbackHowTitle => 'Comment trouver l’adresse ?';

  @override
  String get loopbackHowMacSettings =>
      'Réglages Système › Wi-Fi › Détails… › Adresse IP. Ou dans le Terminal :';

  @override
  String get loopbackHowMacMdns =>
      'Le nom .local se trouve dans Réglages Système › Général › Partage (« Nom d’hôte local »).';

  @override
  String get loopbackHowWindowsSettings =>
      'Paramètres › Réseau et Internet › Wi-Fi › propriétés (adresse IPv4). Ou dans l’invite de commandes (cmd), « Adresse IPv4 » de la carte Wi-Fi :';

  @override
  String get loopbackHowWindowsMdns =>
      'Sous Windows 10/11, le nom .local est <nom de l’ordinateur>.local.';

  @override
  String get loopbackHowLinuxTerminal => 'Dans un terminal :';

  @override
  String get loopbackHowLinuxSettings =>
      'Ou Paramètres › Réseau › Wi-Fi › détails. Le nom .local est <nom d’hôte>.local si Avahi est actif.';

  @override
  String loopbackHowRelay(String command) {
    return 'Astuce : la console de « $command » affiche ces adresses au démarrage.';
  }

  @override
  String get loopbackHowCopy => 'Copier la commande';

  @override
  String get loopbackHowCopied => 'Commande copiée';

  @override
  String get goSetupInvalid =>
      'Seules tes quatre rangées du bas acceptent des pièces.';

  @override
  String get versionMismatchBoth =>
      'Les versions du jeu ne correspondent pas – mets à jour les deux applis (navigateur : recharge la page).';

  @override
  String get versionMismatchUpdateOther =>
      'Les versions du jeu ne correspondent pas : l’autre appareil a une version plus ancienne. Mets à jour l’appli sur cet appareil (navigateur : recharge la page).';

  @override
  String get versionMismatchUpdateThis =>
      'Les versions du jeu ne correspondent pas : cet appareil a une version plus ancienne. Mets à jour cette appli (navigateur : recharge la page).';

  @override
  String versionMismatchGuestRefused(String reason) {
    return 'Un appareil a voulu rejoindre la partie mais a été refusé : $reason';
  }

  @override
  String menuVersion(String version) {
    return 'Version $version';
  }

  @override
  String aboutBuildDetails(String build, String protocol, String games) {
    return 'Numéro de build $build · protocole $protocol · données de jeu $games';
  }

  @override
  String versionMismatchVersions(
    String nameA,
    String versionA,
    String nameB,
    String versionB,
  ) {
    return '$nameA a $versionA, $nameB a $versionB.';
  }

  @override
  String versionMismatchVersionsDevices(String versionA, String versionB) {
    return 'Cet appareil a $versionA, l\'autre appareil a $versionB.';
  }

  @override
  String get aboutTitle => 'À propos de Klunki';

  @override
  String get aboutPrivacy => 'Confidentialité';

  @override
  String get aboutImpressum => 'Mentions légales (Impressum)';

  @override
  String get aboutSupport => 'Assistance';

  @override
  String get aboutLicense =>
      'Klunki est un logiciel libre sous licence GNU AGPL 3.0.';

  @override
  String get aboutSourceCode => 'Code source';

  @override
  String get aboutLicenses => 'Licences open source';

  @override
  String get aboutOpenInBrowser => 'Ouvrir dans le navigateur';

  @override
  String get aboutPrivacyOffline =>
      'Cette version est enregistrée dans l’app pour être lue sans internet (en anglais). La page web fait foi :';

  @override
  String get menuGameChess => 'Échecs';

  @override
  String get menuDescChess =>
      'Le classique : mets le roi adverse échec et mat.';

  @override
  String get chessWhite => 'Blancs';

  @override
  String get chessBlack => 'Noirs';

  @override
  String get chessColorLabel => 'Ta couleur';

  @override
  String get chessColorRandom => 'Au hasard';

  @override
  String get chessColorHelper =>
      'Les Blancs commencent. « Au hasard » laisse le sort décider.';

  @override
  String get chessYouPlayWhite => 'Tu joues les Blancs.';

  @override
  String get chessYouPlayBlack => 'Tu joues les Noirs.';

  @override
  String get chessCheck => 'Échec !';

  @override
  String get chessHintSelect => 'Touche une pièce pour la déplacer.';

  @override
  String get chessHintTarget => 'Touche une case en surbrillance.';

  @override
  String get chessPromotionTitle => 'Promouvoir le pion en …';

  @override
  String get chessFlipBoard => 'Tourner l’échiquier';

  @override
  String get chessAutoFlip => 'Tourner l’échiquier vers le camp au trait';

  @override
  String chessSquareEmpty(String square) {
    return '$square : vide';
  }

  @override
  String chessSquarePiece(String square, String piece, String side) {
    return '$square : $piece ($side)';
  }

  @override
  String get chessPieceKing => 'Roi';

  @override
  String get chessPieceQueen => 'Dame';

  @override
  String get chessPieceRook => 'Tour';

  @override
  String get chessPieceBishop => 'Fou';

  @override
  String get chessPieceKnight => 'Cavalier';

  @override
  String get chessPiecePawn => 'Pion';

  @override
  String get chessOfferDraw => 'Proposer la nulle';

  @override
  String get chessOfferDrawTitle => 'Proposer la nulle ?';

  @override
  String chessOfferDrawBody(String player) {
    return '$player peut accepter ou refuser. Si elle est acceptée, la partie est nulle.';
  }

  @override
  String get chessOfferDrawConfirm => 'Proposer';

  @override
  String get chessDrawOfferTitle => 'Proposition de nulle';

  @override
  String chessDrawOfferBody(String player) {
    return '$player propose la nulle. Si tu acceptes, la partie est nulle.';
  }

  @override
  String get chessDrawAccept => 'Accepter';

  @override
  String get chessDrawDecline => 'Refuser';

  @override
  String chessHintDrawOffered(String player) {
    return 'Nulle proposée – $player décide.';
  }

  @override
  String chessHintDrawDeclined(String player) {
    return '$player refuse la nulle.';
  }

  @override
  String get chessMoveDrawOffer => 'Nulle proposée';

  @override
  String get chessMoveDrawDecline => 'Nulle refusée';

  @override
  String get chessMoveDrawAccept => 'Nulle acceptée';

  @override
  String get engineReasonChessDrawAgreed => 'Nulle par accord mutuel';

  @override
  String get engineReasonChessCheckmate => 'Échec et mat';

  @override
  String get engineReasonChessStalemate => 'Pat';

  @override
  String get engineReasonChessInsufficientMaterial =>
      'Matériel insuffisant pour mater';

  @override
  String engineReasonChessSeventyFiveMoves(int moves) {
    return '$moves coups sans prise ni coup de pion';
  }

  @override
  String engineReasonChessThreefoldRepetition(int times) {
    return 'Même position $times fois';
  }

  @override
  String get menuGameWordTiles => 'As des mots';

  @override
  String get menuDescWordTiles => 'Former des mots avec des lettres';

  @override
  String menuPreviewGame(String game) {
    return 'Aperçu : $game';
  }

  @override
  String get wordtilesPlay => 'Jouer';

  @override
  String get wordtilesRecall => 'Reprendre toutes les tuiles';

  @override
  String get wordtilesShuffle => 'Mélanger les tuiles';

  @override
  String get wordtilesExchange => 'Échanger';

  @override
  String wordtilesExchangeConfirm(int count) {
    return 'Échanger $count';
  }

  @override
  String get wordtilesPass => 'Passer';

  @override
  String get wordtilesZoomIn => 'Agrandir';

  @override
  String get wordtilesZoomOut => 'Plateau entier';

  @override
  String wordtilesBag(int count) {
    return 'Sac : $count tuiles';
  }

  @override
  String wordtilesScore(String player, int score) {
    String _temp0 = intl.Intl.pluralLogic(
      score,
      locale: localeName,
      other: '$score points',
      one: '$score point',
    );
    return '$player : $_temp0';
  }

  @override
  String get wordtilesHintPlace =>
      'Glisse des tuiles sur le plateau, ou touche une tuile puis une case.';

  @override
  String get wordtilesHintFirst =>
      'Le premier mot doit passer par l’étoile au centre.';

  @override
  String wordtilesHintZoom(String hint) {
    return '$hint Avec deux doigts, tu zoomes.';
  }

  @override
  String get wordtilesHintSelected => 'Touche une case libre.';

  @override
  String get wordtilesHintExchange =>
      'Choisis les tuiles à remettre dans le sac.';

  @override
  String get wordtilesHintAnswer => 'Accepte le mot ou conteste-le.';

  @override
  String wordtilesExchangeNotNow(int count) {
    return 'Échange possible seulement s’il reste au moins $count tuiles dans le sac.';
  }

  @override
  String wordtilesPreview(String words, int score) {
    String _temp0 = intl.Intl.pluralLogic(
      score,
      locale: localeName,
      other: '$score points',
      one: '$score point',
    );
    return '$words : $_temp0';
  }

  @override
  String wordtilesPreviewBingo(String words, int score, int bonus) {
    String _temp0 = intl.Intl.pluralLogic(
      score,
      locale: localeName,
      other: '$score points',
      one: '$score point',
    );
    return '$words : $_temp0 (dont $bonus de bonus pour toutes les tuiles)';
  }

  @override
  String get wordtilesErrorLine =>
      'Les tuiles doivent être sur une seule ligne ou colonne.';

  @override
  String get wordtilesErrorGap => 'Il reste une case vide entre les tuiles.';

  @override
  String get wordtilesErrorShort =>
      'Le premier mot doit avoir au moins deux lettres.';

  @override
  String get wordtilesErrorConnect =>
      'Les tuiles doivent toucher un mot du plateau.';

  @override
  String get wordtilesErrorUnknownWord =>
      'Un mot n’est pas dans le dictionnaire.';

  @override
  String get wordtilesErrorAnswerFirst =>
      'Accepte ou conteste d’abord le dernier mot.';

  @override
  String get wordtilesErrorOther => 'Tu ne peux pas poser les tuiles ainsi.';

  @override
  String wordtilesOpenPlacement(String player, String words, int score) {
    String _temp0 = intl.Intl.pluralLogic(
      score,
      locale: localeName,
      other: '$score points',
      one: '$score point',
    );
    return '$player a posé $words pour $_temp0.';
  }

  @override
  String get wordtilesAccept => 'Accepter';

  @override
  String get wordtilesChallenge => 'Contester';

  @override
  String get wordtilesChallengeTitle => 'Contester le mot ?';

  @override
  String wordtilesChallengeBodyFree(String player) {
    return 'Sans dictionnaire, ta contestation l’emporte : $player reprend ses tuiles et ne marque aucun point. Ensuite, c’est à toi.';
  }

  @override
  String get wordtilesChallengeBodyDict =>
      'Le dictionnaire tranche. Si le mot y figure, tu perds ton tour.';

  @override
  String wordtilesEndPending(String player) {
    return '$player a posé toutes ses tuiles. Si tu acceptes, la partie est finie.';
  }

  @override
  String wordtilesMovePlace(String words, int score) {
    String _temp0 = intl.Intl.pluralLogic(
      score,
      locale: localeName,
      other: '$score points',
      one: '$score point',
    );
    return '$words pour $_temp0';
  }

  @override
  String wordtilesMoveExchange(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tuiles échangées',
      many: '$count de tuiles échangées',
      one: '$count tuile échangée',
    );
    return '$_temp0';
  }

  @override
  String get wordtilesMovePass => 'a passé';

  @override
  String wordtilesMoveChallengeWithdrawn(String words) {
    return 'contesté : $words repris';
  }

  @override
  String get wordtilesMoveChallengeFailed =>
      'contesté, mais les mots sont valables';

  @override
  String get wordtilesMoveAccept => 'accepté';

  @override
  String get wordtilesBlankTitle => 'Quelle lettre pour le joker ?';

  @override
  String get wordtilesPremiumDoubleLetter => '2L';

  @override
  String get wordtilesPremiumTripleLetter => '3L';

  @override
  String get wordtilesPremiumDoubleWord => '2M';

  @override
  String get wordtilesPremiumTripleWord => '3M';

  @override
  String get wordtilesOptionTiles => 'Lettres';

  @override
  String get wordtilesOptionDictionary => 'Vérifier dans le dictionnaire';

  @override
  String get wordtilesOptionDictionaryOn =>
      'Chaque mot posé est vérifié. S’il n’y est pas, vous décidez ensemble : le reprendre ou l’accepter quand même.';

  @override
  String get wordtilesOptionDictionaryOff =>
      'Sans dictionnaire, vous jugez vous-mêmes : un mot peut être contesté.';

  @override
  String get wordtilesOptionsNext => 'Suivant';

  @override
  String get wordtilesDictLoading => 'Chargement du dictionnaire…';

  @override
  String get wordtilesDictLoadFailed =>
      'Impossible de charger le dictionnaire.';

  @override
  String get wordtilesUnknownTitle => 'Pas dans le dictionnaire';

  @override
  String wordtilesUnknownBody(String words, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '« $words » ne sont pas dans le dictionnaire.',
      one: '« $words » n’est pas dans le dictionnaire.',
    );
    return '$_temp0';
  }

  @override
  String get wordtilesUnknownAsk =>
      'Vous pouvez reprendre les lettres. Si vous êtes d’accord pour qu’il compte quand même, acceptez-le.';

  @override
  String get wordtilesUnknownWithdraw => 'Reprendre';

  @override
  String get wordtilesUnknownAllow => 'Accepter quand même';

  @override
  String wordtilesMovePlaceAllowed(String words, int score, String allowed) {
    String _temp0 = intl.Intl.pluralLogic(
      score,
      locale: localeName,
      other: '$score points',
      one: '$score point',
    );
    return '$words pour $_temp0 (accepté : $allowed)';
  }

  @override
  String get wordtilesBench => 'Banc d’essai';

  @override
  String get wordtilesBenchClear => 'Remettre toutes les lettres du banc';

  @override
  String get wordtilesBenchHint =>
      'Glisse des lettres ici pour essayer des mots.';

  @override
  String get wordtilesCoachBench1 =>
      'Le banc d’essai est ton brouillon : glisse des lettres ici et essaie des mots.';

  @override
  String get wordtilesCoachBench2 =>
      'Il compte seulement les points des lettres. Il ne vérifie pas si c’est un vrai mot.';

  @override
  String get wordtilesCoachBench3 =>
      'Ce bouton remet toutes les lettres en place. Personne d’autre ne voit ton banc.';

  @override
  String wordtilesCoachStep(int step, int count) {
    return '$step sur $count';
  }

  @override
  String get wordtilesCoachNext => 'Suivant';

  @override
  String get wordtilesCoachDone => 'Compris';

  @override
  String get wordtilesCoachSkip => 'Ignorer';

  @override
  String get wordtilesPassTitle => 'Passer ?';

  @override
  String wordtilesPassBody(int count, int limit) {
    return 'Ton tour se termine sans points. Tours sans points d’affilée : $count sur $limit. À $limit, la partie se termine.';
  }

  @override
  String get wordtilesBlankScore => 'Le joker vaut 0 point.';

  @override
  String get wordtilesHelp => 'Comment jouer';

  @override
  String get wordtilesHelpGoal =>
      'Posez des mots comme dans des mots croisés. Chaque lettre a des points (le petit chiffre). Le premier mot passe par l’étoile au milieu, chaque mot suivant s’y raccroche.';

  @override
  String get wordtilesHelpPremium => 'Cases bonus';

  @override
  String get wordtilesHelpDoubleLetter => 'Lettre compte double';

  @override
  String get wordtilesHelpTripleLetter => 'Lettre compte triple';

  @override
  String get wordtilesHelpDoubleWord => 'Mot entier compte double';

  @override
  String get wordtilesHelpTripleWord => 'Mot entier compte triple';

  @override
  String get wordtilesHelpPremiumOnce =>
      'Les cases bonus ne comptent qu’au tour où une lettre y est posée.';

  @override
  String wordtilesHelpBingo(int count, int bonus) {
    return 'Les $count lettres posées en un seul tour : $bonus points en plus.';
  }

  @override
  String get wordtilesHelpBlank =>
      'Le joker (lettre blanche) devient la lettre de ton choix mais vaut 0 point. Il affiche un petit 0.';

  @override
  String wordtilesHelpSwap(int count) {
    return 'Échanger : remettre des lettres dans le sac et en piocher de nouvelles. Possible seulement tant qu’il reste au moins $count lettres dans le sac ; cela prend le tour.';
  }

  @override
  String wordtilesHelpPass(int limit) {
    return 'Passer : tu sautes un tour. Après $limit tours d’affilée sans points, la partie se termine.';
  }

  @override
  String get wordtilesHelpDictionary =>
      'Avec « Vérifier dans le dictionnaire », chaque mot est vérifié à la pose. S’il manque, reprenez les lettres ou acceptez-le ensemble : « Accepter quand même ». Les mots acceptés figurent dans l’historique.';

  @override
  String get wordtilesHelpChallenge =>
      'Sans dictionnaire, le dernier mot peut être contesté : les lettres sont reprises et ne rapportent rien.';

  @override
  String get wordtilesHelpBench =>
      'Sur le banc d’essai, tu essaies des mots. Il n’affiche que les points des lettres, pas si c’est un mot.';

  @override
  String get wordtilesHelpZoom =>
      'Avec deux doigts, tu zoomes sur le plateau et tu le déplaces. Fais glisser une tuile que tu viens de poser pour la déplacer ; un toucher la reprend.';

  @override
  String get wordtilesHelpEnd =>
      'La partie se termine quand le sac est vide et que quelqu’un a posé toutes ses lettres. Les points des lettres restantes sont retirés ; qui a fini les reçoit en plus.';

  @override
  String wordtilesResultRack(String points) {
    return 'Lettres restantes : $points';
  }

  @override
  String wordtilesResultBestWord(String word, String player, int score) {
    String _temp0 = intl.Intl.pluralLogic(
      score,
      locale: localeName,
      other: '$score points',
      one: '$score point',
    );
    return 'Meilleur mot : $word ($player, $_temp0)';
  }

  @override
  String wordtilesResultAllowed(String words) {
    return 'Acceptés quand même : $words';
  }

  @override
  String engineReasonWordtilesPlayedOut(int a, int b) {
    return 'Toutes les tuiles posées, score final $a : $b';
  }

  @override
  String engineReasonWordtilesScoreless(int turns, int a, int b) {
    return '$turns tours sans points, score final $a : $b';
  }

  @override
  String get webBetaBadge => 'Bêta';

  @override
  String get aboutWebBeta =>
      'Version web bêta – les parties sur plusieurs appareils se jouent dans l\'app.';

  @override
  String get networkUnavailableWeb =>
      'Pas encore disponible dans le navigateur – avec l\'app, vous pouvez jouer sur plusieurs appareils.';

  @override
  String get appBetaTeaser => 'Bêta de l\'app en préparation.';

  @override
  String get appBetaIos => 'Essayer l\'app pour iPhone et iPad';

  @override
  String get appBetaAndroid => 'Obtenir l\'app Android';

  @override
  String wordtilesOptionsSummaryDict(String language) {
    return '$language · avec dictionnaire';
  }

  @override
  String wordtilesOptionsSummaryFree(String language) {
    return '$language · sans dictionnaire';
  }

  @override
  String wordtilesOpenPlacementJoker(String player, String words, int score) {
    String _temp0 = intl.Intl.pluralLogic(
      score,
      locale: localeName,
      other: '$score points',
      one: '$score point',
    );
    return '$player a posé $words pour $_temp0 (joker échangé).';
  }

  @override
  String get wordtilesOptionJoker => 'Échanger le joker';

  @override
  String get wordtilesOptionJokerExplain =>
      'Règle maison : si tu as la lettre que remplace un joker sur le plateau, tu peux la poser à sa place et prendre le joker. Ensuite, tu poses encore des lettres dans le même tour.';

  @override
  String wordtilesOptionsSummaryJoker(String summary) {
    return '$summary · échange du joker';
  }

  @override
  String get wordtilesHintJoker =>
      'Glisse la bonne lettre sur un joker du plateau pour prendre le joker.';

  @override
  String get wordtilesJokerStaged =>
      'Joker pris. Pose maintenant des lettres, sinon l’échange ne compte pas.';

  @override
  String wordtilesMoveJoker(String move) {
    return '$move (joker échangé)';
  }

  @override
  String get wordtilesHelpJoker =>
      'Échanger le joker (règle maison) : si tu as la lettre que remplace un joker sur le plateau, glisse-la sur le joker. Le joker rejoint tes lettres, et tu poses encore des lettres dans le même tour (le joker peut en faire partie). Sans pose, l’échange ne compte pas. L’ancien mot et ses points restent.';

  @override
  String get wordtilesHelpJokerOn => 'Activée dans cette partie.';

  @override
  String get wordtilesHelpJokerOff =>
      'Désactivée dans cette partie. Vous pouvez l’activer avant une partie.';

  @override
  String wordtilesUnknownAskNet(String player) {
    return 'Tu peux reprendre les lettres ou demander à $player si le mot compte quand même.';
  }

  @override
  String wordtilesUnknownDeclinedBefore(String player) {
    return '$player a déjà refusé. Reprends les lettres.';
  }

  @override
  String get wordtilesAllowTitle => 'Accepter quand même ?';

  @override
  String wordtilesAllowBody(String player, String words) {
    return '$player voudrait faire accepter « $words » – d’accord ?';
  }

  @override
  String get wordtilesAllowAccept => 'Accepter';

  @override
  String get wordtilesAllowDecline => 'Refuser';

  @override
  String wordtilesAllowDeciding(String player) {
    return '$player décide…';
  }

  @override
  String get wordtilesAllowYouDecide => 'À toi de décider';

  @override
  String wordtilesAllowLine(String player, String words, int score) {
    String _temp0 = intl.Intl.pluralLogic(
      score,
      locale: localeName,
      other: '$score points',
      one: '$score point',
    );
    return '$player voudrait faire accepter « $words » ($_temp0).';
  }

  @override
  String wordtilesAllowDeclined(String player, String words) {
    return '$player refuse « $words ».';
  }

  @override
  String wordtilesMoveAllowRequest(String words, int score) {
    String _temp0 = intl.Intl.pluralLogic(
      score,
      locale: localeName,
      other: '$score points',
      one: '$score point',
    );
    return 'demande d’accepter $words ($_temp0)';
  }

  @override
  String wordtilesMoveAllowAccept(String words, int score) {
    String _temp0 = intl.Intl.pluralLogic(
      score,
      locale: localeName,
      other: '$score points',
      one: '$score point',
    );
    return 'd’accord : $words compte ($_temp0)';
  }

  @override
  String wordtilesMoveAllowDecline(String words) {
    return 'refusé : $words';
  }

  @override
  String get menuGameMaexchen => 'Mia';

  @override
  String get menuDescMaexchen => 'Lancer les dés, bluffer, démasquer';

  @override
  String get engineReasonMaexchenNoLives => 'Plus aucune vie';

  @override
  String get maexchenOptionLives => 'Vies au départ';

  @override
  String get maexchenOptionDouble => 'Mia double';

  @override
  String get maexchenOptionDoubleExplain =>
      'Tout ce qui touche au Mia compte double : douter d’un vrai Mia ou être pris avec un faux coûte 2 vies.';

  @override
  String get maexchenOptionsNext => 'Suivant';

  @override
  String get maexchenRoll => 'Lancer';

  @override
  String get maexchenPeek => 'Regarder';

  @override
  String get maexchenCover => 'Couvrir';

  @override
  String get maexchenPickTitle => 'Qu’annonces-tu ?';

  @override
  String maexchenAnnounce(String value) {
    return 'Annoncer $value';
  }

  @override
  String get maexchenOrder =>
      'Du plus petit au plus grand : 31, 32 … 65, puis les doubles 11 … 66, puis Mia (21).';

  @override
  String get maexchenBelieve => 'Croire';

  @override
  String get maexchenDoubt => 'Douter';

  @override
  String get maexchenGiveUp => 'Céder une vie';

  @override
  String maexchenAnnounced(String player, String value) {
    return '$player annonce $value';
  }

  @override
  String get maexchenNewRound => 'Nouvelle manche : toute valeur est permise';

  @override
  String get maexchenHintRoll =>
      'Touche Lancer, puis regarde sous le gobelet en cachette.';

  @override
  String maexchenHintBelieved(String value) {
    return 'Tu crois au $value. Lance et annonce plus que $value.';
  }

  @override
  String get maexchenHintAnnounceFirst =>
      'Regarde en cachette et annonce une valeur. Bluffer est permis !';

  @override
  String maexchenHintAnnounceHigher(String value) {
    return 'Annonce plus que $value. Bluffer est permis !';
  }

  @override
  String maexchenHintRespond(String player, String value) {
    return '$player annonce $value. Tu y crois ?';
  }

  @override
  String maexchenHintRespondMaexchen(String player) {
    return '$player annonce Mia ! Rien ne bat ça : douter ou céder une vie ?';
  }

  @override
  String maexchenUnderCup(String value) {
    return 'Sous le gobelet : $value';
  }

  @override
  String maexchenVerdictBluff(String player) {
    return 'Bluff ! $player perd une vie.';
  }

  @override
  String maexchenVerdictTrue(String player) {
    return 'C’était vrai ! $player perd une vie.';
  }

  @override
  String maexchenVerdictTrueTwo(String player) {
    return 'Un vrai Mia ! $player perd 2 vies.';
  }

  @override
  String maexchenVerdictBluffTwo(String player) {
    return 'Un faux Mia ! $player perd 2 vies.';
  }

  @override
  String maexchenVerdictGaveUp(String player) {
    return '$player cède une vie. Le gobelet reste fermé.';
  }

  @override
  String maexchenLivesOf(String player, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count vies',
      one: '1 vie',
    );
    return '$player : $_temp0';
  }

  @override
  String maexchenRoundLabel(int round) {
    return 'Manche $round';
  }

  @override
  String get maexchenMoveRoll => 'lance les dés';

  @override
  String maexchenMoveAnnounce(String value) {
    return 'annonce $value';
  }

  @override
  String get maexchenMoveBelieve => 'y croit';

  @override
  String get maexchenMoveDoubt => 'doute';

  @override
  String get maexchenMoveGiveUp => 'cède une vie';

  @override
  String get maexchenMaexchenName => 'Mia';

  @override
  String get maexchenMaexchenCall => 'Mia !';

  @override
  String get maexchenAnnouncedLabel => 'Annoncé';
}
