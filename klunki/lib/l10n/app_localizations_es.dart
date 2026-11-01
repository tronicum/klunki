// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'Klunki';

  @override
  String get menuLanguage => 'Idioma';

  @override
  String get languagePickerTitle => 'Elegir idioma';

  @override
  String get languageSystem => 'Sistema';

  @override
  String get menuChooseGame => 'Elige un juego';

  @override
  String get menuPassDevice => 'Pasa el dispositivo';

  @override
  String get menuDebugConsole => 'Consola de depuración';

  @override
  String get menuPlayOverWifi => 'Jugar por wifi';

  @override
  String get menuGameConnect4 => 'Cuatro en raya';

  @override
  String get menuGameMuehle => 'Juego del molino';

  @override
  String get menuGameQuartettTrumpf => 'Quartett (Triunfos)';

  @override
  String get menuGameQuartettSets => 'Quartett (Familias)';

  @override
  String get menuGameSchiffe => 'Hundir la flota';

  @override
  String get menuDescConnect4 =>
      'Cuatro en línea: horizontal, vertical o diagonal.';

  @override
  String get menuDescMuehle =>
      'Forma líneas de tres y captura las fichas rivales.';

  @override
  String get menuDescQuartettTrumpf =>
      'Comparad valores: el mejor gana ambas cartas.';

  @override
  String get menuDescQuartettSets =>
      'Pide cartas y reúne grupos completos de cuatro.';

  @override
  String get menuDescSchiffe =>
      'Esconded vuestras flotas y disparad por turnos.';

  @override
  String get menuSectionHotSeat => 'Dos jugadores, un dispositivo';

  @override
  String get menuSectionNetwork => 'Con dos dispositivos';

  @override
  String get menuNetworkSubtitle => 'Crear o unirse a una partida';

  @override
  String get menuHiddenInfo =>
      'Cartas o flota secretas: os pasáis el dispositivo';

  @override
  String shellToMove(String player) {
    return 'Turno de $player';
  }

  @override
  String shellHasWon(String player) {
    return '$player ha ganado';
  }

  @override
  String shellYourTurn(String mark) {
    return 'Te toca ($mark)';
  }

  @override
  String shellWaitingFor(String player) {
    return 'Esperando a $player…';
  }

  @override
  String get shellYouHaveWon => 'Has ganado';

  @override
  String get shellDraw => 'Empate';

  @override
  String shellWins(String player) {
    return '¡$player gana!';
  }

  @override
  String get shellYouWin => '¡Ganas tú!';

  @override
  String get shellMenu => 'Menú';

  @override
  String get shellPlayAgain => 'Otra vez';

  @override
  String get shellUndo => 'Deshacer jugada';

  @override
  String get shellNewGame => 'Nueva partida';

  @override
  String get shellNewGameTitle => '¿Nueva partida?';

  @override
  String get shellNewGameBody => 'La partida en curso se abandonará.';

  @override
  String get shellCancel => 'Cancelar';

  @override
  String get shellRestart => 'Reiniciar';

  @override
  String get shellMoves => 'Jugadas';

  @override
  String get shellNoMoves => 'Aún no hay jugadas.';

  @override
  String shellHistoryEntry(String player, String move) {
    return '$player: $move';
  }

  @override
  String shellHandoverPass(String player) {
    return 'Pasa el dispositivo a $player';
  }

  @override
  String shellHandoverContinue(String player) {
    return 'Soy $player – seguir';
  }

  @override
  String connect4Column(int column) {
    return 'Columna $column';
  }

  @override
  String get connect4HintTapColumn => 'Toca una columna';

  @override
  String get muehlePhasePlacing => 'Colocar';

  @override
  String get muehlePhaseMoving => 'Mover';

  @override
  String get muehlePhaseFlying => 'Saltar';

  @override
  String muehleMovePlace(int point) {
    return 'coloca en $point';
  }

  @override
  String muehleMoveRemove(int point) {
    return 'quita la ficha de $point';
  }

  @override
  String muehleMoveMove(int from, int to) {
    return 'mueve $from→$to';
  }

  @override
  String muehleMoveFly(int from, int to) {
    return 'salta $from→$to';
  }

  @override
  String muehleHintRemove(String player) {
    return '¡Molino! Quita una ficha de $player';
  }

  @override
  String get muehleHintPlace => 'Coloca una ficha';

  @override
  String get muehleHintTarget =>
      'Elige un destino (o toca la ficha otra vez para soltarla)';

  @override
  String get muehleHintSelectFly => 'Elige una ficha para saltar';

  @override
  String get muehleHintSelectMove => 'Elige una ficha para mover';

  @override
  String muehlePointEmpty(int point) {
    return 'Punto $point, vacío';
  }

  @override
  String muehlePointOwned(int point, String player) {
    return 'Punto $point, $player';
  }

  @override
  String muehleCounts(int hand, int board) {
    return 'Mano: $hand · Tablero: $board';
  }

  @override
  String muehleCaptured(int count) {
    return 'Capturadas: $count';
  }

  @override
  String get quartettNoGame => 'No es una partida de Quartett';

  @override
  String get quartettContinue => 'Seguir';

  @override
  String get quartettHigherWins => 'gana el mayor';

  @override
  String get quartettLowerWins => 'gana el menor';

  @override
  String get quartettCardBack => 'QUARTETT';

  @override
  String quartettCards(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count cartas',
      many: '$count de cartas',
      one: '$count carta',
    );
    return '$_temp0';
  }

  @override
  String quartettPlayerCards(String player, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count cartas',
      many: '$count de cartas',
      one: '$count carta',
    );
    return '$player: $_temp0';
  }

  @override
  String quartettTrumpfMovePick(String stat) {
    return 'elige $stat';
  }

  @override
  String get quartettTrumpfHintPick => 'Elige un dato de tu carta';

  @override
  String quartettTrumpfPot(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count cartas',
      many: '$count de cartas',
      one: '$count carta',
    );
    return 'Bote: $_temp0';
  }

  @override
  String quartettTrumpfOpponentStack(String player) {
    return 'Mazo de $player';
  }

  @override
  String quartettTrumpfYourCard(String player) {
    return 'Tu carta ($player)';
  }

  @override
  String get quartettTrumpfTie => 'Empate – ¡desempate!';

  @override
  String quartettTrumpfWinsTrick(String player) {
    return '$player gana la ronda';
  }

  @override
  String get quartettTrumpfOutcomeWin => 'gana';

  @override
  String get quartettTrumpfOutcomeLose => 'pierde';

  @override
  String get quartettTrumpfOutcomeTie => 'empate';

  @override
  String quartettTrumpfSideOutcome(String player, String outcome) {
    return '$player – $outcome';
  }

  @override
  String quartettTrumpfPicked(String player, String stat) {
    return '$player elige $stat';
  }

  @override
  String quartettTrumpfPotAgain(int count, String player) {
    return 'Las cartas van al bote (ahora $count), $player vuelve a elegir';
  }

  @override
  String quartettTrumpfHintWaiting(String player) {
    return '$player está eligiendo …';
  }

  @override
  String get quartettTrumpfLastTrick => 'Ronda anterior';

  @override
  String quartettTrumpfGraceSeconds(int seconds) {
    return 'Sigue en $seconds s';
  }

  @override
  String quartettTrumpfQueuedPick(String player, String stat) {
    return '$player ha elegido: $stat';
  }

  @override
  String quartettTrumpfNextPicker(String player) {
    return '$player elige a continuación';
  }

  @override
  String quartettTrumpfPicksAgain(String player) {
    return '$player vuelve a elegir';
  }

  @override
  String quartettTrumpfContinuePicker(String player) {
    return 'Seguir – elige $player';
  }

  @override
  String quartettTrumpfYouPickNext(String player) {
    return 'Eliges tú a continuación ($player)';
  }

  @override
  String quartettTrumpfTricksBehind(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'quedan $count rondas',
      many: 'quedan $count de rondas',
      one: 'queda $count ronda',
    );
    return '$_temp0';
  }

  @override
  String quartettTrumpfHandoverReason(String player) {
    return '$player ganó la ronda';
  }

  @override
  String get quartettSetsHit => 'Acierto';

  @override
  String get quartettSetsMiss => 'Nada';

  @override
  String quartettSetsMoveAsk(String card, String result) {
    return 'pide $card: $result';
  }

  @override
  String quartettSetsMoveAskQuartet(String card, String result, String set) {
    return 'pide $card: $result – familia $set';
  }

  @override
  String quartettSetsHintContinue(String player) {
    return 'Toca «Seguir» y pasa el dispositivo a $player';
  }

  @override
  String get quartettSetsHintAsk => 'Toca una carta que falte para pedirla';

  @override
  String get quartettSetsNoQuartet => 'aún sin familia';

  @override
  String quartettSetsStock(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count cartas',
      many: '$count de cartas',
      one: '$count carta',
    );
    return 'Mazo: $_temp0';
  }

  @override
  String quartettSetsScore(int a, int b) {
    return 'Familias X $a : $b O';
  }

  @override
  String quartettSetsOtherAsked(String player, String card, String result) {
    return '$player pide $card: $result';
  }

  @override
  String quartettSetsHitGives(String player, String card) {
    return '¡Acierto! $player te da $card';
  }

  @override
  String get quartettSetsMissDraw => 'Nada – robas una carta';

  @override
  String get quartettSetsMissEmpty => 'Nada – el mazo está vacío';

  @override
  String get quartettSetsAskAgain => 'Puedes volver a pedir.';

  @override
  String quartettSetsNotHeld(String player, String card) {
    return '$player no tiene $card.';
  }

  @override
  String quartettSetsQuartetLaid(String set) {
    return '¡Familia completa! $set bajada';
  }

  @override
  String get quartettSetsDrawn => 'Robada:';

  @override
  String quartettSetsYourCards(String player, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count cartas',
      many: '$count de cartas',
      one: '$count carta',
    );
    return 'Tus cartas ($player): $_temp0';
  }

  @override
  String quartettSetsProgress(int have, int missing) {
    return '$have/4 – faltan: $missing';
  }

  @override
  String get quartettSetsAskSlot => 'pedir';

  @override
  String get quartettSetsMissingSlot => 'falta';

  @override
  String get schiffeHintSetup =>
      'Colocación: toca el mar (o arrastra y suelta) para colocar el barco. Los barcos no pueden tocarse.';

  @override
  String get schiffeHintAllSunk => 'Todos los barcos hundidos.';

  @override
  String schiffeHintWaiting(String player) {
    return 'Esperando a $player…';
  }

  @override
  String get schiffeHintExtraShot =>
      '¡Tocado! Otra vez – toca una casilla del mar rival.';

  @override
  String get schiffeHintFire =>
      'Toca una casilla desconocida del mar rival para disparar.';

  @override
  String get schiffeLookWater => 'agua';

  @override
  String get schiffeLookShip => 'barco';

  @override
  String get schiffeLookMiss => 'fallo';

  @override
  String get schiffeLookShipHit => 'barco tocado';

  @override
  String get schiffeLookHit => 'tocado';

  @override
  String get schiffeLookSunk => 'hundido';

  @override
  String get schiffeLookUnknown => 'desconocido';

  @override
  String schiffeCellLabel(String cell, String state) {
    return '$cell $state';
  }

  @override
  String get schiffeFleetComplete => 'Flota completa';

  @override
  String schiffeShipWithLength(String ship, int length) {
    return '$ship ($length)';
  }

  @override
  String schiffeShipPlaced(String ship, int length) {
    return '$ship ($length) · colocado';
  }

  @override
  String get schiffeHorizontal => 'Horizontal';

  @override
  String get schiffeVertical => 'Vertical';

  @override
  String get schiffeRandom => 'Al azar';

  @override
  String get schiffeFleet => 'Flota';

  @override
  String schiffeExtraShotSunk(String ship) {
    return '$ship hundido – ¡tocado! Otra vez';
  }

  @override
  String get schiffeExtraShot => '¡Tocado! Otra vez';

  @override
  String schiffeRemaining(int own, String player, int opponent) {
    return 'Tu flota: $own · Rival ($player): quedan $opponent barcos';
  }

  @override
  String schiffeIncoming(String player, String cell, String result) {
    return 'Último disparo de $player en $cell: $result';
  }

  @override
  String get schiffeTargetSection => 'Rival';

  @override
  String get schiffeOwnSection => 'Tu mar';

  @override
  String get schiffeMovePlace => 'coloca un barco';

  @override
  String schiffeMoveAutoplace(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'coloca $count barcos al azar',
      many: 'coloca $count de barcos al azar',
      one: 'coloca $count barco al azar',
    );
    return '$_temp0';
  }

  @override
  String schiffeMoveFire(String cell, String result) {
    return 'dispara a $cell: $result';
  }

  @override
  String get schiffeRotate => 'Girar';

  @override
  String schiffeRotateSemantics(String orientation) {
    return 'Girar, ahora $orientation';
  }

  @override
  String get schiffeRemove => 'Quitar';

  @override
  String get schiffeRemoveTooltip => 'Volver al puerto';

  @override
  String get schiffeReset => 'Reiniciar';

  @override
  String get schiffeDone => 'Listo';

  @override
  String schiffeSetupCount(int placed, int total, String player) {
    return '$placed de $total barcos colocados · coloca $player';
  }

  @override
  String schiffeHintSelected(String ship) {
    return '$ship seleccionado: toca una casilla o arrastra el barco para moverlo. Tócalo otra vez o «Girar» para girarlo.';
  }

  @override
  String get schiffeHintReady =>
      'Flota lista. Toca un barco para cambiarlo, o «Listo».';

  @override
  String schiffeHintEarly(String player) {
    return 'Ya puedes colocar tus barcos. «Listo» funciona en cuanto $player termine.';
  }

  @override
  String get schiffeInvalidPlace =>
      'No cabe ahí: los barcos deben estar del todo en el mar y no pueden tocarse.';

  @override
  String get schiffeInvalidRotate => 'Aquí no se puede girar: no hay sitio.';

  @override
  String get schiffeSubmitFailed =>
      'No se aceptó la colocación. Toca «Listo» otra vez.';

  @override
  String get schiffeSelected => 'seleccionado';

  @override
  String get schiffeHarbour => 'Puerto';

  @override
  String schiffeShipSunk(String ship) {
    return '$ship hundido';
  }

  @override
  String get debugConsoleTitle => 'Consola de depuración';

  @override
  String get debugUndo => 'undo';

  @override
  String get debugMenu => 'Juego / demo';

  @override
  String debugNewGame(String game) {
    return 'Nuevo: $game';
  }

  @override
  String get debugLegalMoves => 'Jugadas legales';

  @override
  String get debugAutoPlay => 'Jugar hasta el final (al azar)';

  @override
  String get debugDemo => 'Demo: todos los juegos';

  @override
  String get pairingTitle => 'Jugar por wifi';

  @override
  String get pairingDeviceNameHelper => 'Así te ve el otro jugador';

  @override
  String get playerNameTitle => '¿Cómo te llamas?';

  @override
  String get playerNameLabel => 'Tu nombre';

  @override
  String playerLabel(String name, String mark) {
    return '$name ($mark)';
  }

  @override
  String get hotSeatNamesTitle => 'Nombres de los jugadores';

  @override
  String hotSeatNameLabel(String mark) {
    return 'Jugador $mark';
  }

  @override
  String get hotSeatNamesHelper =>
      'Opcional: déjalo vacío para mostrar solo X y O.';

  @override
  String get pairingModeHost => 'Crear';

  @override
  String get pairingModeJoin => 'Unirse';

  @override
  String get pairingChooseGame => 'Elige un juego';

  @override
  String get pairingHostGame => 'Crear partida';

  @override
  String pairingHostStartFailed(String error) {
    return 'No se pudo iniciar la partida: $error';
  }

  @override
  String get pairingNotAdvertised =>
      'No visible automáticamente – el otro jugador introduce la dirección.';

  @override
  String get pairingNoDiscoveryHost =>
      'Sin búsqueda automática en este dispositivo – el otro jugador introduce la dirección.';

  @override
  String pairingHosting(String name, String game) {
    return '$name ofrece $game';
  }

  @override
  String pairingNoAddress(int port) {
    return 'No se encontró ninguna dirección wifi. ¿Está el dispositivo conectado al wifi? Puerto: $port';
  }

  @override
  String get pairingAddresses => 'Direcciones (para escribir):';

  @override
  String get pairingProbablyWifi => 'probablemente wifi';

  @override
  String get pairingWaitingForGuest => 'Esperando al otro jugador…';

  @override
  String get pairingCancel => 'Cancelar';

  @override
  String get pairingGamesOnNetwork => 'Partidas en la red';

  @override
  String get pairingNoDiscoveryJoin =>
      'La búsqueda automática no está disponible en este dispositivo. Introduce la dirección abajo.';

  @override
  String get pairingBrowseFailed =>
      'No se puede buscar en la red. Introduce la dirección abajo.';

  @override
  String get pairingSearching => 'Buscando partidas…';

  @override
  String get pairingOtherVersion => 'otra versión de Klunki';

  @override
  String get pairingOrEnterAddress => 'O introduce una dirección';

  @override
  String get pairingManualLabel => 'IP, IP:puerto o enlace klunki://';

  @override
  String get pairingInvalidAddress =>
      'Dirección no válida. Ejemplo: 192.168.1.20 o 192.168.1.20:4747';

  @override
  String get pairingConnect => 'Conectar';

  @override
  String pairingConnecting(String host) {
    return 'Conectando con $host…';
  }

  @override
  String get pairingTimeout => 'Tiempo agotado';

  @override
  String pairingJoinFailed(String host, String error) {
    return 'Error al conectar con $host ($error).';
  }

  @override
  String get pairingJoinHints =>
      'Consejos: ¿están ambos dispositivos en el mismo wifi? Las redes de invitados suelen bloquear las conexiones entre dispositivos. iOS: ¿está permitida la «Red local» para Klunki (Ajustes › Privacidad)?';

  @override
  String pairingStatus(String name, String mark, String peer, String peerMark) {
    return 'Tú ($name, $mark) · Rival: $peer ($peerMark)';
  }

  @override
  String netBarYou(String name) {
    return 'Tú ($name)';
  }

  @override
  String netBarOpponent(String peer) {
    return 'Rival: $peer';
  }

  @override
  String get pairingOpponent => 'Rival';

  @override
  String pairingPeerLeft(String peer) {
    return '$peer ha salido de la partida';
  }

  @override
  String pairingPeerLost(String peer) {
    return 'Se perdió la conexión con $peer';
  }

  @override
  String pairingWaitForRejoin(String reason) {
    return '$reason. Esperando a que vuelva…';
  }

  @override
  String get pairingReconnecting => 'Reconectando…';

  @override
  String get pairingReconnect => 'Reconectar';

  @override
  String get networkVerificationFailed =>
      'No se pudo confirmar el desarrollo de la partida';

  @override
  String get pairingReconnectFailed =>
      'Error al reconectar. ¿Sigue el anfitrión en la partida?';

  @override
  String get pairingBrowserJoin =>
      'Unirse desde un navegador (escribe la dirección o pega el enlace):';

  @override
  String get pairingCopyLink => 'Copiar enlace';

  @override
  String get pairingLinkCopied => 'Enlace copiado';

  @override
  String get webJoinIntro =>
      'Únete desde el navegador a una partida alojada en un iPhone, iPad, dispositivo Android o en la terminal (klunki host). El anfitrión muestra la dirección y el enlace en «Unirse desde un navegador».';

  @override
  String get webJoinHttpsWarning =>
      'En un navegador con https, Klunki solo puede conectar con relés seguros (wss://): usa la app o la versión http local.';

  @override
  String get webJoinAddressLabel => 'IP, IP:puerto, enlace ws:// o klunki://';

  @override
  String webJoinAddressHelper(int port) {
    return 'El puerto es el puerto de navegador (WebSocket) del anfitrión; sin puerto: $port.';
  }

  @override
  String get webJoinInvalidAddress =>
      'Dirección no válida. Ejemplo: 192.168.1.20, 192.168.1.20:4748 o klunki://join?h=…';

  @override
  String get webJoinHints =>
      'Consejos: ¿está este dispositivo en el mismo wifi que el anfitrión? Las redes de invitados suelen bloquear las conexiones entre dispositivos. La página debe abrirse con http://, no con https://. El anfitrión debe usar una versión de Klunki compatible con navegadores (muestra «Unirse desde un navegador»).';

  @override
  String get engineReasonConnect4FourInARow => 'Cuatro en raya';

  @override
  String get engineReasonConnect4BoardFull => 'Tablero lleno';

  @override
  String get engineReasonMuehleFewerThanThree =>
      'El rival tiene menos de 3 fichas';

  @override
  String get engineReasonMuehleBlocked => 'El rival no puede mover';

  @override
  String engineReasonMuehleNoRemovalLimit(int moves) {
    return '$moves jugadas sin captura';
  }

  @override
  String get engineReasonQuartettBothStacksEmpty => 'Ambos mazos vacíos';

  @override
  String get engineReasonQuartettAllCards => 'Al rival no le quedan cartas';

  @override
  String engineReasonQuartettTrickLimitEqual(int a, int b) {
    return 'Límite de rondas, mismas cartas ($a:$b)';
  }

  @override
  String engineReasonQuartettTrickLimitMoreCards(int a, int b) {
    return 'Límite de rondas, más cartas ($a:$b)';
  }

  @override
  String engineReasonQuartettAllQuartetsEqual(int a, int b) {
    return 'Todas las familias bajadas, $a:$b';
  }

  @override
  String engineReasonQuartettMostQuartets(int a, int b) {
    return 'Más familias ($a:$b)';
  }

  @override
  String get engineReasonSchiffeAllSunk => 'Todos los barcos hundidos';

  @override
  String get engineReasonGostrategyFlagCaptured => 'Bandera capturada';

  @override
  String get engineReasonGostrategyNoMoves => 'El rival no tiene movimientos';

  @override
  String get engineReasonGostrategyBothBlocked => 'Ningún bando puede mover';

  @override
  String engineReasonGostrategyMoveLimit(int moves) {
    return '$moves jugadas sin combate';
  }

  @override
  String get menuGameGoStrategy => 'GoStrategy';

  @override
  String get menuDescGoStrategy =>
      'Ejércitos ocultos: encuentra y captura la bandera rival.';

  @override
  String get goPieceMarshal => 'Mariscal';

  @override
  String get goPieceGeneral => 'General';

  @override
  String get goPieceColonel => 'Coronel';

  @override
  String get goPieceMajor => 'Comandante';

  @override
  String get goPieceCaptain => 'Capitán';

  @override
  String get goPieceLieutenant => 'Teniente';

  @override
  String get goPieceSergeant => 'Sargento';

  @override
  String get goPieceMiner => 'Minero';

  @override
  String get goPieceScout => 'Explorador';

  @override
  String get goPieceSpy => 'Espía';

  @override
  String get goPieceBomb => 'Bomba';

  @override
  String get goPieceFlag => 'Bandera';

  @override
  String goPieceRank(String piece, String rank) {
    return '$piece ($rank)';
  }

  @override
  String goSetupTitle(String player) {
    return 'Coloca tu ejército ($player)';
  }

  @override
  String get goSetupHint =>
      'Toca dos piezas o arrastra una a otra casilla de tus cuatro filas para intercambiarlas. Luego «Listo».';

  @override
  String goSetupSelected(String piece) {
    return '$piece elegido: toca otra casilla de tus cuatro filas para intercambiar.';
  }

  @override
  String get goSetupShuffle => 'Mezclar';

  @override
  String get goSetupDone => 'Listo';

  @override
  String goSetupFirst(String player) {
    return '$player coloca primero; mientras tanto puedes preparar.';
  }

  @override
  String goWaitingSetup(String player) {
    return 'Esperando a que $player coloque …';
  }

  @override
  String get goLegendTitle => 'Piezas';

  @override
  String get goLegendRules =>
      'Gana el rango mayor; con rangos iguales caen los dos. El espía vence al mariscal si ataca. Solo los mineros desactivan bombas. Los exploradores avanzan en línea recta lo que quieran. Las bombas y la bandera no se mueven.';

  @override
  String get goHintSelect =>
      'Toca una de tus piezas y luego una casilla marcada.';

  @override
  String goHintSelected(String piece) {
    return '$piece: toca una casilla marcada.';
  }

  @override
  String goHintNoTargets(String piece) {
    return '$piece no puede moverse ahora.';
  }

  @override
  String goHintWaiting(String player) {
    return 'Esperando a $player …';
  }

  @override
  String goMoveLimit(String moves) {
    return '$moves jugadas más sin combate y será empate.';
  }

  @override
  String goArmyOwn(String mark) {
    return 'Tu ejército ($mark)';
  }

  @override
  String goArmyEnemy(String player) {
    return 'Rival: $player';
  }

  @override
  String goArmyLeft(String left, String total) {
    return 'quedan $left de $total';
  }

  @override
  String goFightBy(String player) {
    return 'Ataque de $player';
  }

  @override
  String goFightBeats(String winner, String loser) {
    return '$winner vence a $loser';
  }

  @override
  String get goFightBoth => 'Caen los dos';

  @override
  String goFightDefused(String piece) {
    return '$piece desactiva la bomba';
  }

  @override
  String goFightBomb(String piece) {
    return '$piece pisa una bomba';
  }

  @override
  String get goFightFlag => '¡Bandera capturada!';

  @override
  String get goMoveSetup => 'coloca su ejército';

  @override
  String goMoveStep(String from, String to) {
    return 'mueve $from–$to';
  }

  @override
  String goMoveAttack(String from, String to, String result) {
    return 'ataca ($from–$to): $result';
  }

  @override
  String goCellLabel(String cell, String content) {
    return '$cell: $content';
  }

  @override
  String get goCellFree => 'libre';

  @override
  String get goCellLake => 'lago';

  @override
  String goCellHidden(String player) {
    return 'pieza oculta de $player';
  }

  @override
  String goCellPiece(String piece, String player) {
    return '$piece de $player';
  }

  @override
  String goCellMoved(String content) {
    return '$content, movida';
  }

  @override
  String gameNotInApp(String game) {
    return '$game aún no está disponible en la app.';
  }

  @override
  String get engineSetA => 'Superdeportivos';

  @override
  String get engineSetB => 'Hiperdeportivos';

  @override
  String get engineSetC => 'Clásicos';

  @override
  String get engineSetD => 'Muscle cars';

  @override
  String get engineSetE => 'Leyendas del rally';

  @override
  String get engineSetF => 'Gran turismo';

  @override
  String get engineSetG => 'Eléctricos';

  @override
  String get engineSetH => 'Pequeños bólidos';

  @override
  String get engineStatPs => 'Poten­cia';

  @override
  String get engineStatKmh => 'Velocidad máx.';

  @override
  String get engineStatCcm => 'Cilin­drada';

  @override
  String get engineStatKg => 'Peso';

  @override
  String get engineStatSec0to100 => '0–100 km/h';

  @override
  String get engineUnitPs => 'CV';

  @override
  String get engineUnitKmh => 'km/h';

  @override
  String get engineUnitCcm => 'cm³';

  @override
  String get engineUnitKg => 'kg';

  @override
  String get engineUnitSec => 's';

  @override
  String get engineShip5 => 'Acorazado';

  @override
  String get engineShip4 => 'Crucero';

  @override
  String get engineShip3 => 'Destructor';

  @override
  String get engineShip2 => 'Submarino';

  @override
  String get engineShipOther => 'Barco';

  @override
  String get relayHostIntro =>
      'Un segundo navegador en la misma red wifi se une con el código de sala.';

  @override
  String get relayRoomCode => 'Código de sala';

  @override
  String get relayWaitingHint =>
      'Abre el enlace en el segundo dispositivo o escanea el código QR. O abre Klunki allí e introduce el código de sala.';

  @override
  String relayInfo(String address) {
    return 'Relé: $address';
  }

  @override
  String get relayJoinTitle => 'Unirse con un código de sala';

  @override
  String get relayCodeHelper =>
      '5 caracteres. El navegador que crea la partida muestra el código.';

  @override
  String get relayCodeInvalid =>
      'Código de sala no válido: 5 letras o cifras (sin 0, O, 1, I, L).';

  @override
  String get relayJoin => 'Entrar en la sala';

  @override
  String relayJoining(String code) {
    return 'Entrando en la sala $code…';
  }

  @override
  String get relayAddressLabel => 'Dirección del relé';

  @override
  String get relayAddressHelper =>
      'Ordenador de la red wifi que ejecuta «klunki relay», p. ej. 192.168.1.20:4749';

  @override
  String get relayAddressAdvanced => 'Avanzado: dirección del relé';

  @override
  String get relayAddressInvalid =>
      'Dirección de relé no válida. Ejemplo: 192.168.1.20:4749';

  @override
  String relayErrorUnknownCode(String code) {
    return 'No hay ninguna sala con el código $code. ¿Es correcto el código y sigue esperando el anfitrión?';
  }

  @override
  String relayErrorRoomFull(String code) {
    return 'La sala $code ya está llena: allí ya juegan dos.';
  }

  @override
  String get relayErrorHostLeft =>
      'El anfitrión ha salido de la sala. La partida ha terminado.';

  @override
  String get relayErrorExpired =>
      'La sala ha caducado (10 minutos sin actividad).';

  @override
  String relayErrorUnreachable(String address) {
    return 'No hay ningún relé accesible en $address.';
  }

  @override
  String get relayErrorLost => 'Se ha perdido la conexión con el relé.';

  @override
  String get relayStartHint =>
      'Navegador contra navegador necesita un relé. Inícialo en un ordenador de la red wifi y abre Klunki desde su dirección:';

  @override
  String relayRoomLost(String reason) {
    return '$reason Empieza una partida nueva.';
  }

  @override
  String relayFromLink(String address) {
    return 'Relay del enlace: $address';
  }

  @override
  String get relayLinkSaveDefault => 'Guardar como predeterminado';

  @override
  String get relayLinkUseSaved => 'Usar el relay guardado';

  @override
  String get relayLinkForeign =>
      'Atención: este enlace lleva a otro relay, no al servidor de esta página. Únete solo si confías en quien lo envió: un relay ajeno ve todas las jugadas.';

  @override
  String get pairingSeatTaken =>
      'Plaza ocupada: alguien ya está jugando esta partida. Solo quien se unió primero puede volver a entrar.';

  @override
  String get webJoinDirectTitle =>
      'O conectar con un dispositivo anfitrión (app o terminal)';

  @override
  String get qrScanButton => 'Escanear código QR';

  @override
  String get qrScanHint => 'Apunta la cámara al código QR del anfitrión.';

  @override
  String get qrScanNotKlunki =>
      'No es un código de Klunki. Escanea el código QR que muestra el juego al crear una partida.';

  @override
  String get qrScanTorchOn => 'Encender la luz';

  @override
  String get qrScanTorchOff => 'Apagar la luz';

  @override
  String get qrScanPermissionDenied =>
      'Klunki no tiene permiso para usar la cámara.';

  @override
  String get qrScanPermissionHint =>
      'Puedes permitir el acceso a la cámara para Klunki en los ajustes del dispositivo.';

  @override
  String get qrScanUnavailable => 'La cámara no está disponible.';

  @override
  String get qrScanTypeInstead => 'Escribir el código';

  @override
  String get relayGroupTitle => 'Jugar mediante relé (código de sala)';

  @override
  String get relayChange => 'cambiar';

  @override
  String get relayNotSet =>
      'No hay ningún relé configurado: introduce una dirección';

  @override
  String relayUseDefault(String address) {
    return 'Predeterminado: $address';
  }

  @override
  String get relaySave => 'Aplicar';

  @override
  String get relayJoinIntro =>
      'El código de sala viene de un navegador que eligió «Crear partida».';

  @override
  String get joinDirectTitle => 'Conectar directamente con un dispositivo';

  @override
  String get joinDirectHelper =>
      'Para un móvil, tableta o terminal que aloja la partida: introduce la dirección del dispositivo (IP).';

  @override
  String get shellResign => 'Rendirse';

  @override
  String get shellResignTitle => '¿Seguro que quieres rendirte?';

  @override
  String shellResignBody(String player) {
    return 'La partida termina ahora y gana $player.';
  }

  @override
  String get shellResignWho =>
      '¿Quién se rinde? La partida termina ahora y gana el otro lado.';

  @override
  String shellResignPlayer(String player) {
    return '$player se rinde';
  }

  @override
  String engineReasonCommonResigned(String player) {
    return '$player se ha rendido';
  }

  @override
  String get engineReasonCommonYouResigned => 'Te has rendido';

  @override
  String get quartettDeckCars => 'Coches';

  @override
  String get quartettDeckTrains => 'Trenes';

  @override
  String get quartettDeckRockets => 'Cohetes';

  @override
  String get quartettDeckPlanes => 'Aviones';

  @override
  String get quartettSetTrainsA => 'ICE';

  @override
  String get quartettSetTrainsB => 'Shinkansen';

  @override
  String get quartettSetTrainsC => 'TGV';

  @override
  String get quartettSetTrainsD => 'Los rápidos de Europa';

  @override
  String get quartettSetTrainsE => 'Asia y América';

  @override
  String get quartettSetTrainsF => 'Locomotoras eléctricas';

  @override
  String get quartettSetTrainsG => 'Leyendas del vapor';

  @override
  String get quartettSetTrainsH => 'Gigantes de carga';

  @override
  String get quartettSetRocketsA => 'Cohetes lunares';

  @override
  String get quartettSetRocketsB => 'Reutilizables';

  @override
  String get quartettSetRocketsC => 'Europa';

  @override
  String get quartettSetRocketsD => 'Clásicos de EE. UU.';

  @override
  String get quartettSetRocketsE => 'Rusia';

  @override
  String get quartettSetRocketsF => 'China';

  @override
  String get quartettSetRocketsG => 'Japón e India';

  @override
  String get quartettSetRocketsH => 'Lanzadores pequeños';

  @override
  String get quartettSetPlanesA => 'Fuselaje ancho';

  @override
  String get quartettSetPlanesB => 'Medio radio';

  @override
  String get quartettSetPlanesC => 'Supersónicos';

  @override
  String get quartettSetPlanesD => 'Clásicos de hélice';

  @override
  String get quartettSetPlanesE => 'Gigantes del aire';

  @override
  String get quartettSetPlanesF => 'Negocios y deporte';

  @override
  String get quartettSetPlanesG => 'Pioneros';

  @override
  String get quartettSetPlanesH => 'Rarezas récord';

  @override
  String get quartettStatKw => 'Poten­cia';

  @override
  String get quartettStatLengthM => 'Longitud';

  @override
  String get quartettStatMassT => 'Peso';

  @override
  String get quartettStatTractiveKn => 'Esfuerzo de trac­ción';

  @override
  String get quartettStatHeightM => 'Altura';

  @override
  String get quartettStatThrustKn => 'Empuje al despe­gue';

  @override
  String get quartettStatLeoT => 'Carga útil (LEO)';

  @override
  String get quartettStatLaunchMassT => 'Masa al lanza­miento';

  @override
  String get quartettStatFlights => 'Lanza­mientos';

  @override
  String get quartettStatRangeKm => 'Alcance';

  @override
  String get quartettStatWingspanM => 'Enver­gadura';

  @override
  String get quartettStatMtowT => 'Peso al despe­gue';

  @override
  String get quartettDeckPickerTitle => 'Elige una baraja';

  @override
  String get quartettDeckLabel => 'Baraja';

  @override
  String quartettDeckSets(int sets) {
    return '$sets grupos de 4 cartas';
  }

  @override
  String get quartettDeckPlay => 'Jugar';

  @override
  String get quartettGalleryOpen => 'Ver las cartas';

  @override
  String get quartettGalleryTitle => 'Cartas del Quartett';

  @override
  String quartettGalleryCardOf(int index, int total) {
    return 'Carta $index de $total';
  }

  @override
  String get quartettGalleryPrevious => 'Carta anterior';

  @override
  String get quartettGalleryNext => 'Carta siguiente';

  @override
  String get quartettGalleryTopMenu => 'Top 5 por valor';

  @override
  String quartettGalleryTopTitle(String stat) {
    return 'Los 5 mejores: $stat';
  }

  @override
  String quartettCardSemantics(String id, String name, String set) {
    return 'Carta $id: $name, grupo $set';
  }

  @override
  String get quartettStatBuilt => 'Fabri­cados';

  @override
  String get quartettStatSuccessPct => 'Tasa de éxito';

  @override
  String get quartettUnitBuilt => 'uds.';

  @override
  String quartettPhotoCredit(String author, String license) {
    return 'Foto: $author, $license';
  }

  @override
  String get quartettPhotoCreditTitle => 'Crédito de la imagen';

  @override
  String get quartettPhotoCreditTooltip => 'Mostrar crédito de la imagen';

  @override
  String get quartettPhotoModified => 'Reducida para la app.';

  @override
  String get quartettPhotoShareAlike =>
      'La versión reducida tiene la misma licencia.';

  @override
  String get quartettPhotoLicense => 'Licencia';

  @override
  String get quartettPhotoSource => 'Fuente';

  @override
  String get quartettPhotoClose => 'Cerrar';

  @override
  String get quartettWikipediaRead => 'Leer en Wikipedia';

  @override
  String get quartettImageCreditsTitle => 'Créditos de las imágenes';

  @override
  String get quartettImageCreditsIntro =>
      'Las fotos proceden de Wikimedia Commons y tienen licencias libres. Están incluidas en la app; solo los enlaces necesitan internet.';

  @override
  String get quartettLinkFailed => 'No se pudo abrir el enlace.';

  @override
  String relayLoopbackHint(String host, String example, String mdnsExample) {
    return 'Nota: otros dispositivos no pueden acceder a «$host». Abre la página con la dirección wifi de este ordenador (p. ej. $example) o su nombre .local (p. ej. $mdnsExample) para que el enlace y el código QR funcionen en otros dispositivos.';
  }

  @override
  String relayLoopbackShort(String host) {
    return '«$host» solo funciona en este dispositivo: los demás necesitan la dirección wifi o el nombre .local de este ordenador.';
  }

  @override
  String get loopbackHowTitle => '¿Cómo encuentro la dirección?';

  @override
  String get loopbackHowMacSettings =>
      'Ajustes del Sistema › Wi-Fi › Detalles… › Dirección IP. O en Terminal:';

  @override
  String get loopbackHowMacMdns =>
      'El nombre .local está en Ajustes del Sistema › General › Compartir («Nombre de host local»).';

  @override
  String get loopbackHowWindowsSettings =>
      'Configuración › Red e Internet › Wi-Fi › propiedades (dirección IPv4). O en el símbolo del sistema (cmd), «Dirección IPv4» del adaptador wifi:';

  @override
  String get loopbackHowWindowsMdns =>
      'En Windows 10/11 el nombre .local es <nombre del equipo>.local.';

  @override
  String get loopbackHowLinuxTerminal => 'En un terminal:';

  @override
  String get loopbackHowLinuxSettings =>
      'O Configuración › Red › Wi-Fi › detalles. El nombre .local es <nombre de host>.local si Avahi está activo.';

  @override
  String loopbackHowRelay(String command) {
    return 'Consejo: la consola de «$command» muestra estas direcciones al arrancar.';
  }

  @override
  String get loopbackHowCopy => 'Copiar comando';

  @override
  String get loopbackHowCopied => 'Comando copiado';

  @override
  String get goSetupInvalid => 'Solo tus cuatro filas de abajo admiten piezas.';

  @override
  String get versionMismatchBoth =>
      'Las versiones del juego no coinciden: actualiza las dos apps (navegador: recarga la página).';

  @override
  String get versionMismatchUpdateOther =>
      'Las versiones del juego no coinciden: el otro dispositivo tiene una versión más antigua. Actualiza allí la app (navegador: recarga la página).';

  @override
  String get versionMismatchUpdateThis =>
      'Las versiones del juego no coinciden: este dispositivo tiene una versión más antigua. Actualiza esta app (navegador: recarga la página).';

  @override
  String versionMismatchGuestRefused(String reason) {
    return 'Un dispositivo intentó unirse, pero fue rechazado: $reason';
  }

  @override
  String menuVersion(String version) {
    return 'Versión $version';
  }

  @override
  String get menuGameChess => 'Ajedrez';

  @override
  String get menuDescChess => 'El clásico: da jaque mate al rey rival.';

  @override
  String get chessWhite => 'Blancas';

  @override
  String get chessBlack => 'Negras';

  @override
  String get chessCheck => '¡Jaque!';

  @override
  String get chessHintSelect => 'Toca una pieza para moverla.';

  @override
  String get chessHintTarget => 'Toca una casilla marcada.';

  @override
  String get chessPromotionTitle => 'Coronar el peón como …';

  @override
  String get chessFlipBoard => 'Girar el tablero';

  @override
  String get chessAutoFlip => 'Girar el tablero hacia el bando que mueve';

  @override
  String chessSquareEmpty(String square) {
    return '$square: vacía';
  }

  @override
  String chessSquarePiece(String square, String piece, String side) {
    return '$square: $piece ($side)';
  }

  @override
  String get chessPieceKing => 'Rey';

  @override
  String get chessPieceQueen => 'Dama';

  @override
  String get chessPieceRook => 'Torre';

  @override
  String get chessPieceBishop => 'Alfil';

  @override
  String get chessPieceKnight => 'Caballo';

  @override
  String get chessPiecePawn => 'Peón';

  @override
  String get engineReasonChessCheckmate => 'Jaque mate';

  @override
  String get engineReasonChessStalemate => 'Ahogado';

  @override
  String get engineReasonChessInsufficientMaterial =>
      'Material insuficiente para dar mate';

  @override
  String engineReasonChessSeventyFiveMoves(int moves) {
    return '$moves jugadas sin captura ni movimiento de peón';
  }

  @override
  String engineReasonChessThreefoldRepetition(int times) {
    return 'Misma posición $times veces';
  }
}
