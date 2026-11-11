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
  String get appSubtitle => 'colección de juegos';

  @override
  String get menuLanguage => 'Idioma';

  @override
  String get languagePickerTitle => 'Elegir idioma';

  @override
  String get languageSystem => 'Sistema';

  @override
  String get menuChooseGame => 'Elige un juego';

  @override
  String get menuDebugConsole => 'Consola de depuración';

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
  String get menuSectionNetwork => 'Jugar con otros dispositivos';

  @override
  String get menuPlayOnOneDevice => 'Un dispositivo';

  @override
  String get menuPlayWithOthers => 'Con otros';

  @override
  String get hotSeatPassDeviceHint =>
      'Os pasáis el dispositivo: lo oculto sigue siendo secreto.';

  @override
  String get roomStartSubtitle => 'Los demás entran con el código de sala';

  @override
  String get roomJoinSubtitle => 'Escanea o escribe el código';

  @override
  String get roomAdvanced => 'Avanzado';

  @override
  String get roomDirectWaitingHint =>
      'Los demás tocan «Entrar en una sala» y escanean este código QR. Los dispositivos de la misma wifi también encuentran la sala en «Salas cercanas».';

  @override
  String get roomViaRelay => 'Abrir la sala a través de un servidor';

  @override
  String get roomViaRelayHelper =>
      'Con código de sala, también para quien juega en el navegador. Necesita un servidor (por ejemplo, un ordenador con «klunki relay» en marcha). Desactivado, la sala funciona en este dispositivo y los dispositivos de la misma wifi la encuentran solos.';

  @override
  String get roomTypeCode => 'Escribir el código de sala';

  @override
  String shellToMove(String player) {
    return 'Turno de $player';
  }

  @override
  String shellHasWon(String player) {
    return '$player ha ganado';
  }

  @override
  String get shellYourTurn => 'Te toca';

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
  String get shellTakeBack => 'Deshacer';

  @override
  String get undoAllowedSetting => 'Permitir deshacer jugadas';

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
  String get quartettTrumpfYouPickNext => 'Eliges tú a continuación';

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
  String quartettTrumpfChooseOwn(int count) {
    return 'Solo te quedan $count cartas: elige una.';
  }

  @override
  String quartettTrumpfChooseDefend(String player, String stat) {
    return '$player juega $stat. Elige tu carta.';
  }

  @override
  String get quartettTrumpfMoveChoose => 'elige una carta';

  @override
  String quartettTrumpfHintDefending(String player) {
    return '$player está eligiendo una carta …';
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
  String quartettSetsScore(String nameA, String nameB, int a, int b) {
    return 'Familias $nameA $a : $b $nameB';
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
  String get schiffeHintSetup => 'Toca el mar para colocar el barco.';

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
    return '$ship seleccionado: arrastra para mover, toca otra vez para girar.';
  }

  @override
  String get schiffeHintReady =>
      'Flota lista. Toca un barco para moverlo o girarlo, o «Listo».';

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
  String get schiffeHintSetupMore =>
      'Toca el mar para el siguiente barco. Toca un barco para moverlo o girarlo.';

  @override
  String get schiffeCoachTap => 'Tócalo: mover o girar';

  @override
  String schiffeDoneLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'faltan $count barcos',
      one: 'falta 1 barco',
    );
    return '$_temp0';
  }

  @override
  String schiffePreviewSemantics(String ship, String orientation) {
    return 'Vista previa: $ship, $orientation. Toca para girarlo.';
  }

  @override
  String schiffePreviewLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'quedan $count de este tipo',
      one: 'el último de este tipo',
    );
    return '$_temp0';
  }

  @override
  String get schiffeInvalidTouch =>
      'Los barcos no pueden tocarse, ni siquiera por las esquinas: deja una casilla libre entre ellos.';

  @override
  String get schiffeInvalidOffBoard => 'No cabe en el tablero.';

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
  String get playerDefaultNameA => 'Ana';

  @override
  String get playerDefaultNameB => 'Beto';

  @override
  String get hotSeatStartTitle => '¿Quién juega?';

  @override
  String get hotSeatStartPlay => 'Jugar';

  @override
  String get hotSeatNamesTitle => 'Nombres de los jugadores';

  @override
  String hotSeatNameLabel(int number) {
    return 'Jugador $number';
  }

  @override
  String get hotSeatStartsHint => 'empieza';

  @override
  String get hotSeatNamesHelper =>
      'Déjalo vacío para usar el nombre predeterminado.';

  @override
  String get pairingChooseGame => 'Elige un juego';

  @override
  String get roomStart => 'Abrir una sala';

  @override
  String roomStartFailed(String error) {
    return 'No se pudo abrir la sala: $error';
  }

  @override
  String get pairingNotAdvertised =>
      'No visible automáticamente: los demás escanean el código QR.';

  @override
  String get pairingNoDiscoveryHost =>
      'Sin búsqueda automática en este dispositivo: los demás escanean el código QR.';

  @override
  String roomOfPlayer(String name, String game) {
    return 'Sala de $name: $game';
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
  String get roomNearby => 'Salas cercanas';

  @override
  String get pairingNoDiscoveryJoin =>
      'La búsqueda automática no está disponible en este dispositivo. Escanea el código QR o introduce la dirección en «Avanzado».';

  @override
  String get pairingBrowseFailed =>
      'No se puede buscar en la red. Escanea el código QR o introduce la dirección en «Avanzado».';

  @override
  String get pairingSearching => 'Buscando salas…';

  @override
  String get pairingOtherVersion => 'otra versión de Klunki';

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
  String pairingStatus(String name, String peer) {
    return 'Tú: $name · Rival: $peer';
  }

  @override
  String netBarYou(String name) {
    return 'Tú: $name';
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
      'No se pudo volver a conectar. ¿Sigue el otro dispositivo en la partida?';

  @override
  String get pairingBrowserJoin =>
      'Unirse desde un navegador (escribe la dirección o pega el enlace):';

  @override
  String get pairingCopyLink => 'Copiar enlace';

  @override
  String get pairingLinkCopied => 'Enlace copiado';

  @override
  String get webJoinHttpsWarning =>
      'En un navegador con https, Klunki solo puede conectar con servidores seguros (wss://): usa la app o la versión http local.';

  @override
  String get webJoinAddressLabel => 'IP, IP:puerto, enlace ws:// o klunki://';

  @override
  String webJoinAddressHelper(int port) {
    return 'El puerto es el puerto de navegador (WebSocket) del otro dispositivo; $port si no se indica.';
  }

  @override
  String get webJoinInvalidAddress =>
      'Dirección no válida. Ejemplo: 192.168.1.20, 192.168.1.20:4748 o klunki://join?h=…';

  @override
  String get webJoinHints =>
      'Consejos: ¿está este dispositivo en el mismo wifi que el dispositivo de la sala? Las redes de invitados suelen bloquear las conexiones entre dispositivos. La página debe abrirse con http://, no con https://. El otro dispositivo debe usar una versión de Klunki compatible con navegadores (muestra «Unirse desde un navegador»).';

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
  String get goArmyOwn => 'Tu ejército';

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
  String get roomStartIntro =>
      'Los demás tocan «Entrar en una sala» e introducen el código de sala.';

  @override
  String get relayRoomCode => 'Código de sala';

  @override
  String get relayWaitingHint =>
      'Los demás tocan «Entrar en una sala» y escanean el código QR o introducen el código de sala. O abren el enlace.';

  @override
  String relayInfo(String address) {
    return 'Servidor: $address';
  }

  @override
  String get roomCodeHelper =>
      '5 caracteres: el otro dispositivo muestra el código junto a su sala.';

  @override
  String get relayCodeInvalid =>
      'Código de sala no válido: 5 letras o cifras (sin 0, O, 1, I, L).';

  @override
  String get roomJoin => 'Entrar en una sala';

  @override
  String relayJoining(String code) {
    return 'Entrando en la sala $code…';
  }

  @override
  String get relayAddressLabel => 'Servidor';

  @override
  String get relayAddressHelper =>
      'Dirección del servidor, p. ej. 192.168.1.20:4749 (en la wifi) o wss://spiele.example (en internet)';

  @override
  String get relayAddressInvalid =>
      'Dirección de servidor no válida. Ejemplo: 192.168.1.20:4749';

  @override
  String relayErrorUnknownCode(String code) {
    return 'No hay ninguna sala con el código $code. ¿Es correcto el código y sigue abierta la sala?';
  }

  @override
  String relayErrorRoomFull(String code) {
    return 'La sala $code ya está llena: allí ya juegan dos.';
  }

  @override
  String relayErrorHostAway(String code) {
    return 'El dispositivo que abrió la sala $code no está disponible ahora. Prueba otra vez en un momento.';
  }

  @override
  String get relayErrorRoomClosed =>
      'La sala se ha cerrado: quien la abrió se ha ido. La partida ha terminado.';

  @override
  String get relayErrorExpired =>
      'La sala ha caducado (10 minutos sin actividad).';

  @override
  String relayErrorUnreachable(String address) {
    return 'No hay ningún servidor accesible en $address.';
  }

  @override
  String get relayErrorLost => 'Se ha perdido la conexión con el servidor.';

  @override
  String get relayStartHint =>
      'Las salas con código necesitan un servidor. Inícialo en un ordenador de la red wifi y abre Klunki desde su dirección:';

  @override
  String relayRoomLost(String reason) {
    return '$reason Abre una sala nueva.';
  }

  @override
  String relayFromLink(String address) {
    return 'Servidor del enlace: $address';
  }

  @override
  String get relayLinkSaveDefault => 'Guardar como predeterminado';

  @override
  String get relayLinkUseSaved => 'Usar el servidor guardado';

  @override
  String get relayLinkForeign =>
      'Atención: este enlace lleva a otro servidor, no al de esta página. Únete solo si confías en quien lo envió: un servidor ajeno ve todas las jugadas.';

  @override
  String get pairingSeatTaken =>
      'Plaza ocupada: alguien ya está jugando esta partida. Solo quien se unió primero puede volver a entrar.';

  @override
  String get qrScanButton => 'Escanear código QR';

  @override
  String get qrScanHint =>
      'Apunta la cámara al código QR del otro dispositivo.';

  @override
  String get qrScanNotKlunki =>
      'No es un código de Klunki. Escanea el código QR que muestra el otro dispositivo junto a su sala.';

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
  String get relayChange => 'cambiar';

  @override
  String get relayNotSet =>
      'No hay ningún servidor configurado: introduce una dirección';

  @override
  String relayUseDefault(String address) {
    return 'Predeterminado: $address';
  }

  @override
  String get relaySave => 'Aplicar';

  @override
  String get relayClubCodeLabel => 'Código del club';

  @override
  String get relayClubCodeHelper =>
      'Se guarda solo para este servidor. El código del club nunca va en los enlaces ni en los códigos QR de las salas.';

  @override
  String get relayErrorClubMissing =>
      'Este servidor necesita un código del club. Pregunta a la persona que gestiona el servidor.';

  @override
  String get relayErrorClubWrong =>
      'Este servidor no conoce ese código del club. Pregunta a la persona que gestiona el servidor.';

  @override
  String get serverKindLan =>
      'Servidor en la wifi (un ordenador con «klunki relay» en marcha)';

  @override
  String get serverKindInternet => 'Servidor en internet';

  @override
  String get serverHelpLink => '¿Cómo funciona?';

  @override
  String get serverClubCodeRemove => 'Quitar el código del club';

  @override
  String get serverClubCodeRetry => 'Probar con el código';

  @override
  String get helpTitle => 'Cómo jugar juntos';

  @override
  String get helpSectionRoomsTitle => 'Jugar con otros';

  @override
  String get helpSectionRoomsBody =>
      'Una persona toca «Abrir una sala» y elige un juego. Klunki muestra entonces un código de sala y un código QR.\n\nLa otra persona toca «Entrar en una sala» y escanea el código QR o escribe el código de sala. Y a jugar.';

  @override
  String get helpSectionWifiTitle => 'En la misma wifi';

  @override
  String get helpSectionWifiBody =>
      '¿Alguien tiene la app? Entonces en la wifi no hace falta servidor: la app es el servidor, también para quien juega en el navegador (código QR).\n\nLos dispositivos de la misma wifi se encuentran solos.';

  @override
  String get helpSectionServerTitle => '¿Cuándo hace falta un servidor?';

  @override
  String get helpSectionServerBody =>
      'Solo si todos juegan en el navegador o si no estáis en la misma wifi. El servidor pasa las jugadas entre vuestros dispositivos.\n\nKlunki reconoce por la dirección qué servidor es: «Servidor en la wifi» o «Servidor en internet».';

  @override
  String get helpSectionOwnServerTitle => 'Servidor propio en la wifi';

  @override
  String get helpSectionOwnServerBody =>
      'También podéis tener vuestro propio servidor en un ordenador de la wifi. Está en preparación un programa listo para Mac, Windows y Linux. Después escribid su dirección en Klunki en «Avanzado» con «cambiar».';

  @override
  String get helpSectionComingTitle => 'Pronto más fácil (en preparación)';

  @override
  String get helpSectionComingBody =>
      'Estas formas de tener un servidor están en preparación:\n• Servidor en internet para grupos de amigos (con Cloudflare, gratis)\n• Programa listo para descargar para Mac, Windows y Linux\n• Docker para NAS o Raspberry Pi\n\nLos servidores en internet suelen estar protegidos con un código del club.';

  @override
  String get helpSectionClubTitle => '¿Qué es un código del club?';

  @override
  String get helpSectionClubBody =>
      'Un código del club es como una llave para un servidor: solo quien lo conoce puede abrir salas o entrar en ellas. Te lo da la persona que gestiona el servidor.\n\nKlunki solo lo pide cuando un servidor lo necesita, y lo recuerda para ese servidor.';

  @override
  String get helpSectionDataTitle => '¿Qué pasa con mis datos?';

  @override
  String get helpSectionDataBody =>
      'El servidor solo pasa las jugadas y no guarda nada de forma duradera. Si jugáis directamente en la misma wifi, nada pasa por un servidor ajeno.\n\nEl código del club se queda en tu dispositivo y nunca va en los enlaces ni en los códigos QR de las salas. Con «cambiar» junto al servidor puedes verlo, cambiarlo o quitarlo.';

  @override
  String get joinDirectTitle => 'Conectar directamente con un dispositivo';

  @override
  String get joinDirectHelper =>
      'Para un dispositivo en el que la sala funciona directamente (app o terminal): introduce su dirección (IP).';

  @override
  String get shellResign => 'Rendirse';

  @override
  String get shellResignTitle => '¿Seguro que quieres rendirte?';

  @override
  String shellResignBody(String player) {
    return 'La partida termina para los dos: gana $player.';
  }

  @override
  String get shellLeaveTitle => '¿Salir de la partida?';

  @override
  String get shellLeaveBody =>
      'Se cortará la conexión y la partida terminará para los dos.';

  @override
  String get shellLeave => 'Salir';

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
  String aboutBuildDetails(String build, String protocol, String games) {
    return 'Número de compilación $build · protocolo $protocol · datos de juego $games';
  }

  @override
  String versionMismatchVersions(
    String nameA,
    String versionA,
    String nameB,
    String versionB,
  ) {
    return '$nameA tiene $versionA, $nameB tiene $versionB.';
  }

  @override
  String versionMismatchVersionsDevices(String versionA, String versionB) {
    return 'Este dispositivo tiene $versionA, el otro dispositivo tiene $versionB.';
  }

  @override
  String get aboutTitle => 'Acerca de Klunki';

  @override
  String get aboutPrivacy => 'Privacidad';

  @override
  String get aboutImpressum => 'Aviso legal (Impressum)';

  @override
  String get aboutSupport => 'Soporte';

  @override
  String get aboutLicense => 'Klunki es software libre bajo la GNU AGPL 3.0.';

  @override
  String get aboutSourceCode => 'Código fuente';

  @override
  String get aboutLicenses => 'Licencias de código abierto';

  @override
  String get aboutOpenInBrowser => 'Abrir en el navegador';

  @override
  String get aboutPrivacyOffline =>
      'Esta versión está guardada en la app para leerla sin internet (en inglés). La página web es la que vale:';

  @override
  String get menuGameChess => 'Ajedrez';

  @override
  String get menuDescChess => 'El clásico: da jaque mate al rey rival.';

  @override
  String get chessWhite => 'Blancas';

  @override
  String get chessBlack => 'Negras';

  @override
  String get chessColorLabel => 'Tu color';

  @override
  String get chessColorRandom => 'Al azar';

  @override
  String get chessColorHelper =>
      'Empiezan las blancas. «Al azar» deja que decida la suerte.';

  @override
  String get chessYouPlayWhite => 'Juegas con blancas.';

  @override
  String get chessYouPlayBlack => 'Juegas con negras.';

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
  String get chessOfferDraw => 'Ofrecer tablas';

  @override
  String get chessOfferDrawTitle => '¿Ofrecer tablas?';

  @override
  String chessOfferDrawBody(String player) {
    return '$player puede aceptar o rechazar. Si se aceptan, la partida termina en tablas.';
  }

  @override
  String get chessOfferDrawConfirm => 'Ofrecer';

  @override
  String get chessDrawOfferTitle => 'Oferta de tablas';

  @override
  String chessDrawOfferBody(String player) {
    return '$player ofrece tablas. Si aceptas, la partida termina en tablas.';
  }

  @override
  String get chessDrawAccept => 'Aceptar';

  @override
  String get chessDrawDecline => 'Rechazar';

  @override
  String chessHintDrawOffered(String player) {
    return 'Tablas ofrecidas: decide $player.';
  }

  @override
  String chessHintDrawDeclined(String player) {
    return '$player rechaza las tablas.';
  }

  @override
  String get chessMoveDrawOffer => 'Tablas ofrecidas';

  @override
  String get chessMoveDrawDecline => 'Tablas rechazadas';

  @override
  String get chessMoveDrawAccept => 'Tablas aceptadas';

  @override
  String get engineReasonChessDrawAgreed => 'Tablas por acuerdo';

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

  @override
  String get menuGameWordTiles => 'Palabrista';

  @override
  String get menuDescWordTiles => 'Forma palabras con letras';

  @override
  String menuPreviewGame(String game) {
    return 'Vista previa: $game';
  }

  @override
  String get wordtilesPlay => 'Jugar';

  @override
  String get wordtilesRecall => 'Recuperar todas las fichas';

  @override
  String get wordtilesShuffle => 'Mezclar fichas';

  @override
  String get wordtilesExchange => 'Cambiar';

  @override
  String wordtilesExchangeConfirm(int count) {
    return 'Cambiar $count';
  }

  @override
  String get wordtilesPass => 'Pasar';

  @override
  String get wordtilesZoomIn => 'Ampliar';

  @override
  String get wordtilesZoomOut => 'Tablero completo';

  @override
  String wordtilesBag(int count) {
    return 'Bolsa: $count fichas';
  }

  @override
  String wordtilesScore(String player, int score) {
    String _temp0 = intl.Intl.pluralLogic(
      score,
      locale: localeName,
      other: '$score puntos',
      one: '$score punto',
    );
    return '$player: $_temp0';
  }

  @override
  String get wordtilesHintPlace =>
      'Arrastra fichas al tablero o toca una ficha y luego una casilla.';

  @override
  String get wordtilesHintFirst =>
      'La primera palabra debe pasar por la estrella del centro.';

  @override
  String wordtilesHintZoom(String hint) {
    return '$hint Con dos dedos haces zoom.';
  }

  @override
  String get wordtilesHintSelected => 'Toca una casilla libre.';

  @override
  String get wordtilesHintExchange =>
      'Elige las fichas que vuelven a la bolsa.';

  @override
  String get wordtilesHintAnswer => 'Acepta la palabra o impúgnala.';

  @override
  String wordtilesExchangeNotNow(int count) {
    return 'Solo puedes cambiar si quedan al menos $count fichas en la bolsa.';
  }

  @override
  String wordtilesPreview(String words, int score) {
    String _temp0 = intl.Intl.pluralLogic(
      score,
      locale: localeName,
      other: '$score puntos',
      one: '$score punto',
    );
    return '$words: $_temp0';
  }

  @override
  String wordtilesPreviewBingo(String words, int score, int bonus) {
    String _temp0 = intl.Intl.pluralLogic(
      score,
      locale: localeName,
      other: '$score puntos',
      one: '$score punto',
    );
    return '$words: $_temp0 (con $bonus de bonificación por todas las fichas)';
  }

  @override
  String get wordtilesErrorLine =>
      'Las fichas deben estar en una sola fila o columna.';

  @override
  String get wordtilesErrorGap => 'Queda una casilla vacía entre las fichas.';

  @override
  String get wordtilesErrorShort =>
      'La primera palabra necesita al menos dos letras.';

  @override
  String get wordtilesErrorConnect =>
      'Las fichas deben tocar una palabra del tablero.';

  @override
  String get wordtilesErrorUnknownWord =>
      'Una palabra no está en el diccionario.';

  @override
  String get wordtilesErrorAnswerFirst =>
      'Primero acepta o impugna la última palabra.';

  @override
  String get wordtilesErrorOther => 'No puedes colocar las fichas así.';

  @override
  String wordtilesOpenPlacement(String player, String words, int score) {
    String _temp0 = intl.Intl.pluralLogic(
      score,
      locale: localeName,
      other: '$score puntos',
      one: '$score punto',
    );
    return '$player colocó $words por $_temp0.';
  }

  @override
  String get wordtilesAccept => 'Aceptar';

  @override
  String get wordtilesChallenge => 'Impugnar';

  @override
  String get wordtilesChallengeTitle => '¿Impugnar la palabra?';

  @override
  String wordtilesChallengeBodyFree(String player) {
    return 'Sin diccionario, tu objeción decide: $player retira las fichas y no suma puntos. Luego te toca a ti.';
  }

  @override
  String get wordtilesChallengeBodyDict =>
      'Decide el diccionario. Si la palabra está, pierdes tu turno.';

  @override
  String wordtilesEndPending(String player) {
    return '$player ha colocado todas sus fichas. Si aceptas, termina la partida.';
  }

  @override
  String wordtilesMovePlace(String words, int score) {
    String _temp0 = intl.Intl.pluralLogic(
      score,
      locale: localeName,
      other: '$score puntos',
      one: '$score punto',
    );
    return '$words por $_temp0';
  }

  @override
  String wordtilesMoveExchange(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count fichas cambiadas',
      one: '1 ficha cambiada',
    );
    return '$_temp0';
  }

  @override
  String get wordtilesMovePass => 'pasó';

  @override
  String wordtilesMoveChallengeWithdrawn(String words) {
    return 'impugnó: $words retirado';
  }

  @override
  String get wordtilesMoveChallengeFailed => 'impugnó, pero las palabras valen';

  @override
  String get wordtilesMoveAccept => 'aceptó';

  @override
  String get wordtilesBlankTitle => '¿Qué letra es el comodín?';

  @override
  String get wordtilesPremiumDoubleLetter => '2L';

  @override
  String get wordtilesPremiumTripleLetter => '3L';

  @override
  String get wordtilesPremiumDoubleWord => '2P';

  @override
  String get wordtilesPremiumTripleWord => '3P';

  @override
  String get wordtilesOptionTiles => 'Letras';

  @override
  String get wordtilesOptionDictionary => 'Comprobar en el diccionario';

  @override
  String get wordtilesOptionDictionaryOn =>
      'Cada palabra colocada se busca. Si falta alguna, decidís juntos: retirarla o permitirla igualmente.';

  @override
  String get wordtilesOptionDictionaryOff =>
      'Sin diccionario juzgáis vosotros: se puede dudar de una palabra.';

  @override
  String get wordtilesOptionsNext => 'Siguiente';

  @override
  String get wordtilesDictLoading => 'Cargando el diccionario…';

  @override
  String get wordtilesDictLoadFailed => 'No se pudo cargar el diccionario.';

  @override
  String get wordtilesUnknownTitle => 'No está en el diccionario';

  @override
  String wordtilesUnknownBody(String words, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '«$words» no están en el diccionario.',
      one: '«$words» no está en el diccionario.',
    );
    return '$_temp0';
  }

  @override
  String get wordtilesUnknownAsk =>
      'Podéis retirar las fichas. Si estáis de acuerdo en que cuenta igualmente, permitidlo.';

  @override
  String get wordtilesUnknownWithdraw => 'Retirar';

  @override
  String get wordtilesUnknownAllow => 'Permitir igualmente';

  @override
  String wordtilesMovePlaceAllowed(String words, int score, String allowed) {
    String _temp0 = intl.Intl.pluralLogic(
      score,
      locale: localeName,
      other: '$score puntos',
      one: '$score punto',
    );
    return '$words por $_temp0 (permitido: $allowed)';
  }

  @override
  String get wordtilesBench => 'Banquito';

  @override
  String get wordtilesBenchClear => 'Devolver todas las fichas del banquito';

  @override
  String get wordtilesBenchHint => 'Arrastra fichas aquí para probar palabras.';

  @override
  String get wordtilesCoachBench1 =>
      'El banquito es tu borrador: arrastra fichas aquí y prueba palabras.';

  @override
  String get wordtilesCoachBench2 =>
      'Solo suma los puntos de las letras. No comprueba si es una palabra de verdad.';

  @override
  String get wordtilesCoachBench3 =>
      'Con este botón devuelves todas las fichas. Nadie más ve tu banquito.';

  @override
  String wordtilesCoachStep(int step, int count) {
    return '$step de $count';
  }

  @override
  String get wordtilesCoachNext => 'Siguiente';

  @override
  String get wordtilesCoachDone => 'Entendido';

  @override
  String get wordtilesCoachSkip => 'Saltar';

  @override
  String get wordtilesPassTitle => '¿Pasar?';

  @override
  String wordtilesPassBody(int count, int limit) {
    return 'Tu turno termina sin puntos. Turnos seguidos sin puntos: $count de $limit. Con $limit termina la partida.';
  }

  @override
  String get wordtilesBlankScore => 'El comodín vale 0 puntos.';

  @override
  String get wordtilesHelpGoal =>
      'Colocad palabras como en un crucigrama. Cada letra tiene puntos (el número pequeño). La primera palabra pasa por la estrella del centro y cada una siguiente se conecta.';

  @override
  String get wordtilesHelpPremium => 'Casillas de bonificación';

  @override
  String get wordtilesHelpDoubleLetter => 'La letra cuenta doble';

  @override
  String get wordtilesHelpTripleLetter => 'La letra cuenta triple';

  @override
  String get wordtilesHelpDoubleWord => 'La palabra entera cuenta doble';

  @override
  String get wordtilesHelpTripleWord => 'La palabra entera cuenta triple';

  @override
  String get wordtilesHelpPremiumOnce =>
      'Las casillas de bonificación solo cuentan en el turno en que se coloca una ficha encima.';

  @override
  String wordtilesHelpBingo(int count, int bonus) {
    return 'Las $count fichas colocadas en un turno: $bonus puntos extra.';
  }

  @override
  String get wordtilesHelpBlank =>
      'El comodín (ficha en blanco) se convierte en la letra que elijas, pero vale 0 puntos. Muestra un pequeño 0.';

  @override
  String wordtilesHelpSwap(int count) {
    return 'Cambiar: devolver fichas a la bolsa y sacar otras. Solo mientras queden al menos $count fichas en la bolsa, y gasta el turno.';
  }

  @override
  String wordtilesHelpPass(int limit) {
    return 'Pasar: te saltas un turno. Tras $limit turnos seguidos sin puntos termina la partida.';
  }

  @override
  String get wordtilesHelpDictionary =>
      'Con «Comprobar en el diccionario» cada palabra se busca al colocarla. Si falta, retirad las fichas o permitidla juntos: «Permitir igualmente». Las palabras permitidas aparecen en el historial.';

  @override
  String get wordtilesHelpChallenge =>
      'Sin diccionario se puede dudar de la última palabra: las fichas vuelven y no puntúan.';

  @override
  String get wordtilesHelpBench =>
      'En el banquito pruebas palabras. Solo muestra los puntos de las letras, no si es una palabra.';

  @override
  String get wordtilesHelpZoom =>
      'Con dos dedos haces zoom en el tablero y lo mueves. Arrastra una ficha que acabas de colocar para moverla; un toque la devuelve.';

  @override
  String get wordtilesHelpEnd =>
      'La partida termina cuando la bolsa está vacía y alguien ha colocado todas sus fichas. Los puntos de las fichas que quedan se restan; quien terminó los suma.';

  @override
  String get wordtilesHelpEndNoRest =>
      'La partida termina cuando la bolsa está vacía y alguien ha colocado todas sus fichas. Las fichas que quedan no cuentan.';

  @override
  String wordtilesResultRack(String points) {
    return 'Fichas restantes: $points';
  }

  @override
  String wordtilesResultBestWord(String word, String player, int score) {
    String _temp0 = intl.Intl.pluralLogic(
      score,
      locale: localeName,
      other: '$score puntos',
      one: '$score punto',
    );
    return 'Mejor palabra: $word ($player, $_temp0)';
  }

  @override
  String wordtilesResultAllowed(String words) {
    return 'Permitidas igualmente: $words';
  }

  @override
  String engineReasonWordtilesPlayedOut(int a, int b) {
    return 'Todas las fichas colocadas, resultado final $a : $b';
  }

  @override
  String engineReasonWordtilesScoreless(int turns, int a, int b) {
    return '$turns turnos sin puntos, resultado final $a : $b';
  }

  @override
  String get engineReasonWordtilesPlayedOutSeats =>
      'Todas las fichas colocadas';

  @override
  String engineReasonWordtilesScorelessSeats(int turns) {
    return '$turns turnos sin puntos';
  }

  @override
  String get webBetaBadge => 'Beta';

  @override
  String get aboutWebBeta =>
      'Beta web: las partidas en varios dispositivos están en la app.';

  @override
  String get networkUnavailableWeb =>
      'Aún no está disponible en el navegador: con la app se puede jugar en varios dispositivos.';

  @override
  String get appBetaTeaser => 'Beta de la app en preparación.';

  @override
  String get appBetaIos => 'Probar la app para iPhone y iPad';

  @override
  String get appBetaAndroid => 'Descargar la app para Android';

  @override
  String wordtilesOptionsSummaryDict(String language) {
    return '$language · con diccionario';
  }

  @override
  String wordtilesOptionsSummaryFree(String language) {
    return '$language · sin diccionario';
  }

  @override
  String wordtilesOpenPlacementJoker(String player, String words, int score) {
    String _temp0 = intl.Intl.pluralLogic(
      score,
      locale: localeName,
      other: '$score puntos',
      one: '$score punto',
    );
    return '$player colocó $words por $_temp0 (comodín cambiado).';
  }

  @override
  String get wordtilesOptionJoker => 'Cambiar el comodín';

  @override
  String get wordtilesOptionJokerExplain =>
      'Variante de regla: si tienes la letra que representa un comodín del tablero, puedes ponerla en su lugar y llevarte el comodín. Después colocas fichas en el mismo turno.';

  @override
  String get wordtilesOptionRest => 'Restar las fichas sobrantes';

  @override
  String get wordtilesOptionRestExplain =>
      'Variante: al final, cada uno pierde los puntos de las fichas que le quedan; quien colocó todas sus fichas los suma. Desactivado: solo cuentan las palabras colocadas.';

  @override
  String wordtilesOptionsSummaryJoker(String summary) {
    return '$summary · cambiar el comodín';
  }

  @override
  String wordtilesOptionsSummaryNoRest(String summary) {
    return '$summary · sin restar sobrantes';
  }

  @override
  String get wordtilesHintJoker =>
      'Arrastra la letra que corresponde a un comodín del tablero para llevarte el comodín.';

  @override
  String get wordtilesJokerStaged =>
      'Comodín tomado. Ahora coloca fichas, o el cambio no cuenta.';

  @override
  String wordtilesMoveJoker(String move) {
    return '$move (comodín cambiado)';
  }

  @override
  String wordtilesUnknownAskNet(String player) {
    return 'Puedes retirar las fichas o preguntar a $player si cuenta igualmente.';
  }

  @override
  String wordtilesUnknownDeclinedBefore(String player) {
    return '$player ya lo rechazó. Retira las fichas.';
  }

  @override
  String get wordtilesAllowTitle => '¿Permitir igualmente?';

  @override
  String wordtilesAllowBody(String player, String words) {
    return '$player quiere permitir «$words». ¿De acuerdo?';
  }

  @override
  String get wordtilesAllowAccept => 'Aceptar';

  @override
  String get wordtilesAllowDecline => 'Rechazar';

  @override
  String wordtilesAllowDeciding(String player) {
    return 'Decide $player…';
  }

  @override
  String get wordtilesAllowYouDecide => 'Te toca decidir';

  @override
  String wordtilesAllowLine(String player, String words, int score) {
    String _temp0 = intl.Intl.pluralLogic(
      score,
      locale: localeName,
      other: '$score puntos',
      one: '$score punto',
    );
    return '$player quiere permitir «$words» ($_temp0).';
  }

  @override
  String wordtilesAllowDeclined(String player, String words) {
    return '$player rechaza «$words».';
  }

  @override
  String wordtilesMoveAllowRequest(String words, int score) {
    String _temp0 = intl.Intl.pluralLogic(
      score,
      locale: localeName,
      other: '$score puntos',
      one: '$score punto',
    );
    return 'pide permitir $words ($_temp0)';
  }

  @override
  String wordtilesMoveAllowAccept(String words, int score) {
    String _temp0 = intl.Intl.pluralLogic(
      score,
      locale: localeName,
      other: '$score puntos',
      one: '$score punto',
    );
    return 'de acuerdo: $words cuenta ($_temp0)';
  }

  @override
  String wordtilesMoveAllowDecline(String words) {
    return 'rechazado: $words';
  }

  @override
  String get menuGameMauMau => 'Mau-Mau';

  @override
  String get menuDescMauMau =>
      'Echa cartas que encajen hasta quedarte sin ninguna';

  @override
  String get engineReasonMaumauEmptyHand => 'Todas las cartas echadas';

  @override
  String get maumauSuitClubs => 'tréboles';

  @override
  String get maumauSuitSpades => 'picas';

  @override
  String get maumauSuitHearts => 'corazones';

  @override
  String get maumauSuitDiamonds => 'diamantes';

  @override
  String get maumauRankJack => 'jota';

  @override
  String get maumauRankQueen => 'reina';

  @override
  String get maumauRankKing => 'rey';

  @override
  String get maumauRankAce => 'as';

  @override
  String get maumauRankLetterJack => 'J';

  @override
  String get maumauRankLetterQueen => 'Q';

  @override
  String get maumauRankLetterKing => 'K';

  @override
  String get maumauRankLetterAce => 'A';

  @override
  String maumauCardName(String suit, String rank) {
    return '$rank de $suit';
  }

  @override
  String get maumauOptionsIntro => '¿Con qué reglas queréis jugar?';

  @override
  String get maumauOptionsNext => 'Siguiente';

  @override
  String get maumauOptionSeven => '7: robar dos';

  @override
  String get maumauOptionSevenExplain =>
      'Tras un 7, la otra persona roba 2 cartas.';

  @override
  String get maumauOptionStack => '7 sobre 7';

  @override
  String get maumauOptionStackExplain =>
      'Quien tenga un 7 lo pone encima. Entonces la otra persona roba 4 cartas.';

  @override
  String get maumauOptionEight => '8: pierde turno';

  @override
  String get maumauOptionEightExplain =>
      'Tras un 8, la otra persona pierde el turno.';

  @override
  String get maumauOptionJackInfo =>
      'Jota: encaja casi siempre. Quien la echa pide un palo.';

  @override
  String get maumauOptionJackOnJack => 'Jota sobre jota';

  @override
  String get maumauOptionJackOnJackExplain =>
      'Una jota también puede ir sobre otra jota.';

  @override
  String get maumauOptionAce => 'As: repetir';

  @override
  String get maumauOptionAceExplain =>
      'Quien echa un as vuelve a jugar enseguida.';

  @override
  String get maumauOptionMau => 'Decir «¡Mau!»';

  @override
  String get maumauOptionMauExplain =>
      'Con la penúltima carta, pulsa antes «¡Mau!». Si se te olvida, robas una carta de castigo.';

  @override
  String maumauOpponentCards(String player, int count) {
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
  String maumauYourCards(int count) {
    return 'Tus cartas ($count)';
  }

  @override
  String maumauStock(int count) {
    return 'Mazo: $count';
  }

  @override
  String maumauStockLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count cartas',
      many: '$count de cartas',
      one: '$count carta',
    );
    return 'Mazo para robar, $_temp0';
  }

  @override
  String get maumauDiscard => 'Descartes';

  @override
  String maumauWish(String suit) {
    return 'Palo pedido: $suit';
  }

  @override
  String get maumauDraw => 'Robar carta';

  @override
  String maumauDrawPenalty(int count) {
    return 'Robar $count cartas';
  }

  @override
  String get maumauKeep => 'Quedármela';

  @override
  String get maumauPass => 'Pasar';

  @override
  String get maumauMauButton => '¡Mau!';

  @override
  String get maumauContinue => 'Seguir';

  @override
  String get maumauPickSuitTitle => '¿Qué palo pides?';

  @override
  String get maumauDrewNoFit => 'Has robado esta carta. No encaja.';

  @override
  String maumauDrewPenalty(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count cartas',
      many: '$count de cartas',
      one: '$count carta',
    );
    return 'Has robado $_temp0. Nuevas en tu mano:';
  }

  @override
  String get maumauHintPlay => 'Echa una carta que encaje o roba una.';

  @override
  String maumauHintWish(String suit) {
    return 'Se pide $suit. Echa una carta de ese palo o roba.';
  }

  @override
  String maumauHintPenalty(int count) {
    return 'Tienes que robar $count cartas.';
  }

  @override
  String maumauHintPenaltyStack(int count) {
    return 'Echa un 7 o roba $count cartas.';
  }

  @override
  String get maumauHintDrawn => 'La carta robada encaja. Échala o quédatela.';

  @override
  String get maumauHintPass => 'No queda nada para robar. Tienes que pasar.';

  @override
  String get maumauHintMau =>
      'Penúltima carta: primero pulsa «¡Mau!», luego échala.';

  @override
  String maumauLastPlayed(String player, String card) {
    return '$player ha echado $card.';
  }

  @override
  String maumauLastPlayedWish(String player, String card, String suit) {
    return '$player ha echado $card y pide $suit.';
  }

  @override
  String maumauLastDrew(String player, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count cartas',
      many: '$count de cartas',
      one: 'una carta',
    );
    return '$player ha robado $_temp0.';
  }

  @override
  String maumauLastDrewPenalty(String player, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count cartas de castigo',
      many: '$count de cartas de castigo',
      one: 'una carta de castigo',
    );
    return '$player ha robado $_temp0.';
  }

  @override
  String maumauLastKept(String player) {
    return '$player ha robado una carta y se la ha quedado.';
  }

  @override
  String maumauLastPassed(String player) {
    return '$player ha pasado.';
  }

  @override
  String maumauExtraMau(String player) {
    return '$player dice «¡Mau!».';
  }

  @override
  String maumauExtraForgotMau(String player) {
    return '$player ha olvidado «¡Mau!» y roba una carta de castigo.';
  }

  @override
  String maumauExtraPenalty(String player, int count) {
    return '$player tiene que robar $count cartas.';
  }

  @override
  String get coachNext => 'Siguiente';

  @override
  String get coachDone => '¡A jugar!';

  @override
  String get coachSkip => 'Saltar';

  @override
  String get maumauCoachPlay =>
      'Toca una carta que encaje para echarla. Las que encajan están más arriba y tienen marco.';

  @override
  String get maumauCoachDraw =>
      '¿No encaja ninguna? Toca el mazo para robar una carta.';

  @override
  String get maumauCoachWin => 'Gana quien se quede antes sin cartas.';

  @override
  String get maumauCoachWinMau =>
      'Gana quien se quede antes sin cartas. Antes de la penúltima carta, pulsa «¡Mau!».';

  @override
  String maumauChainBadge(String sum, int count) {
    return 'Robar $sum = $count cartas';
  }

  @override
  String maumauExtraPenaltyStacked(String player, int count) {
    return 'Los 7 se suman: $player tiene que robar ahora $count cartas.';
  }

  @override
  String maumauExtraAgain(String player) {
    return '$player pierde el turno.';
  }

  @override
  String maumauExtraAce(String player) {
    return '$player vuelve a jugar enseguida.';
  }

  @override
  String get maumauExtraReshuffled =>
      'Los descartes se han barajado como nuevo mazo.';

  @override
  String maumauMovePlay(String card) {
    return 'echa $card';
  }

  @override
  String maumauMovePlayWish(String card, String suit) {
    return 'echa $card, pide $suit';
  }

  @override
  String maumauMoveDraw(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count cartas',
      many: '$count de cartas',
      one: 'una carta',
    );
    return 'roba $_temp0';
  }

  @override
  String get maumauMovePass => 'pasa';

  @override
  String get maumauMoveKeep => 'se queda la carta robada';

  @override
  String get menuGameMaexchen => 'Mia';

  @override
  String get menuDescMaexchen => 'Tirar los dados, farolear, descubrir';

  @override
  String get engineReasonMaexchenNoLives => 'No quedan vidas';

  @override
  String get maexchenOptionLives => 'Vidas al empezar';

  @override
  String get maexchenOptionDouble => 'Mia doble';

  @override
  String get maexchenOptionDoubleExplain =>
      'Todo lo de Mia cuenta doble: dudar de una Mia verdadera o que te pillen con una falsa cuesta 2 vidas.';

  @override
  String get maexchenOptionsNext => 'Siguiente';

  @override
  String get maexchenRoll => 'Tirar';

  @override
  String get maexchenPeek => 'Mirar';

  @override
  String get maexchenCover => 'Tapar';

  @override
  String get maexchenPickTitle => '¿Qué anuncias?';

  @override
  String maexchenAnnounce(String value) {
    return 'Anunciar $value';
  }

  @override
  String get maexchenOrder =>
      'De menor a mayor: 31, 32 … 65, luego dobles 11 … 66, luego Mia (21).';

  @override
  String get maexchenBelieve => 'Creer';

  @override
  String get maexchenDoubt => 'Dudar';

  @override
  String get maexchenGiveUp => 'Ceder una vida';

  @override
  String maexchenAnnounced(String player, String value) {
    return '$player anuncia $value';
  }

  @override
  String get maexchenNewRound => 'Nueva ronda: vale cualquier valor';

  @override
  String get maexchenHintRoll =>
      'Toca Tirar y luego mira bajo el cubilete a escondidas.';

  @override
  String maexchenHintBelieved(String value) {
    return 'Crees el $value. Tira y anuncia más que $value.';
  }

  @override
  String get maexchenHintAnnounceFirst =>
      'Mira a escondidas y anuncia un valor. ¡Se vale farolear!';

  @override
  String maexchenHintAnnounceHigher(String value) {
    return 'Anuncia más que $value. ¡Se vale farolear!';
  }

  @override
  String maexchenHintRespond(String player, String value) {
    return '$player anuncia $value. ¿Te lo crees?';
  }

  @override
  String maexchenHintRespondMaexchen(String player) {
    return '$player anuncia Mia. Nada la supera: ¿dudar o ceder una vida?';
  }

  @override
  String maexchenUnderCup(String value) {
    return 'Bajo el cubilete: $value';
  }

  @override
  String maexchenVerdictBluff(String player) {
    return '¡Farol! $player pierde una vida.';
  }

  @override
  String maexchenVerdictTrue(String player) {
    return '¡Era verdad! $player pierde una vida.';
  }

  @override
  String maexchenVerdictTrueTwo(String player) {
    return '¡Una Mia de verdad! $player pierde 2 vidas.';
  }

  @override
  String maexchenVerdictBluffTwo(String player) {
    return '¡Una Mia falsa! $player pierde 2 vidas.';
  }

  @override
  String maexchenVerdictGaveUp(String player) {
    return '$player cede una vida. El cubilete sigue tapado.';
  }

  @override
  String maexchenLivesOf(String player, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count vidas',
      one: '1 vida',
    );
    return '$player: $_temp0';
  }

  @override
  String maexchenRoundLabel(int round) {
    return 'Ronda $round';
  }

  @override
  String get maexchenMoveRoll => 'tira los dados';

  @override
  String maexchenMoveAnnounce(String value) {
    return 'anuncia $value';
  }

  @override
  String get maexchenMoveBelieve => 'se lo cree';

  @override
  String get maexchenMoveDoubt => 'duda';

  @override
  String get maexchenMoveGiveUp => 'cede una vida';

  @override
  String get maexchenMaexchenName => 'Mia';

  @override
  String get maexchenMaexchenCall => '¡Mia!';

  @override
  String get maexchenAnnouncedLabel => 'Anunciado';

  @override
  String get maexchenPickFirst => 'Elige un número';

  @override
  String get maexchenShakeHint => 'o agita el móvil';

  @override
  String get shakeToRollSetting => 'Agitar para tirar';

  @override
  String get shakeToRollExplain =>
      'Agita el móvil como un cubilete en lugar de tocar Tirar.';

  @override
  String get confirmMoveSetting => 'Confirmar jugada';

  @override
  String get confirmMoveHelper =>
      'Una jugada solo cuenta después de tocar «Mover».';

  @override
  String get confirmMoveCommit => 'Mover';

  @override
  String get confirmMoveBack => 'Otra jugada';

  @override
  String get confirmMoveHint =>
      '¿Es la jugada correcta? Toca «Mover» u «Otra jugada».';

  @override
  String get confirmMoveOn => 'Confirmar jugada: activado.';

  @override
  String get confirmMoveOff => 'Confirmar jugada: desactivado.';

  @override
  String get rulesButton => 'Reglas';

  @override
  String get menuCards => 'Cartas';

  @override
  String rulesTitle(String game) {
    return 'Reglas: $game';
  }

  @override
  String playerCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count jugadores',
      one: '1 jugador',
    );
    return '$_temp0';
  }

  @override
  String playerCountRange(int min, int max) {
    return 'De $min a $max jugadores';
  }

  @override
  String get rulesGoal => 'Objetivo';

  @override
  String get rulesTurn => 'Cómo es un turno';

  @override
  String get rulesSpecial => 'Reglas';

  @override
  String get rulesHouse => 'Variantes de reglas';

  @override
  String get rulesHouseInGame => 'Variantes de reglas en esta partida';

  @override
  String get rulesHouseMenuNote =>
      'Esto es lo que se propone. Antes de la partida podéis cambiar las variantes de reglas.';

  @override
  String get rulesNewHere => '¿Primera vez? Así se juega';

  @override
  String get rulesCoachHere => 'Aquí encuentras todas las reglas.';

  @override
  String get rulesConnect4Goal =>
      'Pon 4 de tus fichas en línea: en horizontal, en vertical o en diagonal.';

  @override
  String get rulesConnect4Turn =>
      'Toca una columna. Tu ficha cae hasta el hueco libre más bajo.\nLuego le toca al rival.\nEmpieza el Jugador 1.';

  @override
  String get rulesConnect4Special =>
      'El tablero tiene 7 columnas y 6 filas.\nEn una columna llena ya no cabe ninguna ficha.\nSi el tablero se llena y nadie tiene 4 en línea, es empate.';

  @override
  String get rulesMuehleGoal =>
      'Quítale fichas al rival hasta que solo le queden 2. O bloquea sus fichas para que ya no pueda mover.';

  @override
  String get rulesMuehleTurn =>
      'Cada jugador tiene 9 fichas. Empieza el Jugador 1.\nPrimero colocáis por turnos una ficha en un punto libre.\nCuando todas las fichas están colocadas, deslizas una ficha por una línea hasta el punto libre de al lado.\nSi solo te quedan 3 fichas, puedes saltar: a cualquier punto libre.';

  @override
  String get rulesMuehleMill =>
      '3 fichas en una línea forman un molino. Entonces le quitas una ficha al rival.';

  @override
  String get rulesMuehleSpecial =>
      'Las fichas de un molino están protegidas. Solo si todas las fichas del rival están en molinos puedes quitar una de ellas.\nSi abres un molino y lo vuelves a cerrar, cuenta otra vez.\n50 jugadas seguidas sin quitar ninguna ficha (contando las de los dos): empate.';

  @override
  String get rulesTrumpfGoal =>
      'Gana todas las cartas. Quien se queda sin cartas pierde.';

  @override
  String get rulesTrumpfTurn =>
      'Cada jugador recibe 16 cartas en un mazo boca abajo. Siempre se juega la carta de arriba.\nQuien tiene el turno elige un dato de su carta, por ejemplo la velocidad.\nEl mejor valor gana la ronda. Casi siempre es mejor el más alto, en algunos datos el más bajo. Lo pone en la carta.\nQuien gana la ronda pone las dos cartas debajo de su mazo y elige a continuación.\nEl Jugador 1 elige primero.';

  @override
  String get rulesTrumpfSpecial =>
      'Mismo valor: ¡desempate! Las dos cartas van al bote y quien eligió vuelve a elegir. Quien gana la ronda siguiente se lleva también todo el bote.\nTras 200 rondas gana quien tiene más cartas. Con las mismas cartas es empate.\nSi los dos mazos se quedan vacíos, también es empate.';

  @override
  String get rulesTrumpfPickLow => 'Con 3 cartas o menos: elegir';

  @override
  String get rulesTrumpfPickLowText =>
      'Si solo te quedan 2 o 3 cartas, las ves todas y eliges cuál juegas. Quien elige el dato escoge primero la carta y luego el dato. El rival escoge su carta cuando ya conoce el dato.';

  @override
  String get rulesSetsGoal =>
      'Reúne familias: las 4 cartas de un grupo. Quien tiene más familias al final gana.';

  @override
  String get rulesSetsTurn =>
      'Cada jugador recibe 8 cartas. Las otras 16 quedan boca abajo como mazo.\nPídele al rival una carta que te falte. Ya tienes que tener una carta de ese grupo.\nSi el rival tiene la carta, te la da y puedes volver a pedir.\nSi no la tiene: ¡nada! Robas una carta del mazo y le toca al rival.\nEl Jugador 1 pide primero.';

  @override
  String get rulesSetsSpecial =>
      'Si tienes las 4 cartas de un grupo, bajas la familia enseguida.\nSi robas del mazo la carta que pediste, igualmente le toca al rival.\nSi no te quedan cartas, robas una del mazo.\nCuando las 8 familias están bajadas, se acaba la partida. Con 4 a 4 es empate.';

  @override
  String get rulesSchiffeGoal =>
      'Hunde todos los barcos del rival antes de que hunda los tuyos.';

  @override
  String get rulesSchiffeTurn =>
      'Primero cada jugador coloca su flota en secreto en su mar de 10 por 10 casillas. Empieza el Jugador 1.\nLuego disparáis por turnos: toca una casilla del mar del rival.\nA cada casilla disparas solo una vez.';

  @override
  String get rulesSchiffeMiss => 'Agua: fallo. Ahora le toca al rival.';

  @override
  String get rulesSchiffeHit => '¡Tocado! Puedes volver a disparar.';

  @override
  String get rulesSchiffeSunk =>
      'Hundido: todas las casillas del barco están tocadas. Te enteras de qué barco era.';

  @override
  String get rulesSchiffeFleet => 'La flota';

  @override
  String rulesSchiffeShip(int count, String ship, int length) {
    return '$count × $ship ($length casillas)';
  }

  @override
  String get rulesSchiffeSpecial =>
      'Los barcos van rectos: en horizontal o en vertical.\nLos barcos no pueden tocarse, ni siquiera por las esquinas.';

  @override
  String get rulesGoGoal =>
      'Captura la bandera del rival. También ganas si el rival ya no puede mover.';

  @override
  String get rulesGoTurn =>
      'Primero cada jugador coloca en secreto sus 40 piezas en sus 4 filas. El rango de una pieza solo lo ve quien la tiene.\nEl Jugador 1 coloca primero y mueve primero.\nEn tu turno mueves una pieza 1 casilla hacia delante, hacia atrás, a la izquierda o a la derecha. Nunca en diagonal.\nNinguna pieza puede entrar en los dos lagos del centro.';

  @override
  String get rulesGoFightTitle => '¿Quién gana a quién?';

  @override
  String get rulesGoFight =>
      'Si mueves a una casilla con una pieza del rival, las dos piezas luchan. Después los dos jugadores ven qué piezas eran.\nGana el rango más alto. La pieza que pierde queda fuera.\nMismo rango: las dos quedan fuera.';

  @override
  String get rulesGoPieces => 'Las piezas';

  @override
  String rulesGoRank(int rank) {
    return 'Rango $rank';
  }

  @override
  String rulesGoCount(int count) {
    return '$count ×';
  }

  @override
  String get rulesGoMarshal =>
      'La pieza más fuerte. Solo pierde contra el espía, si es el espía quien ataca.';

  @override
  String get rulesGoScout =>
      'Avanza en línea recta tantas casillas libres como quiera y al final puede atacar. Si avanza más de 1 casilla, los dos jugadores ven que es un explorador.';

  @override
  String get rulesGoMiner => 'Desactiva bombas: si ataca una, ocupa su lugar.';

  @override
  String get rulesGoSpy =>
      'La pieza más débil. Pero si el espía ataca al mariscal, gana el espía.';

  @override
  String get rulesGoBomb =>
      'Nunca se mueve. Quien la ataca queda fuera y la bomba se queda. Solo el minero la desactiva.';

  @override
  String get rulesGoFlag => 'Nunca se mueve. Quien la ataca gana la partida.';

  @override
  String get rulesGoSpecial =>
      'Una pieza puede ir y volver entre las mismas dos casillas como mucho 3 veces seguidas.\nCuando una pieza se ha movido, el rival lo sabe: no es una bomba ni la bandera.\n200 jugadas seguidas sin combate: empate. También si nadie puede mover.';

  @override
  String get rulesGoZoom =>
      'Con dos dedos haces zoom en el tablero y lo mueves. La lupa amplía la pieza elegida; tócala otra vez para ver todo el tablero.';

  @override
  String get rulesChessGoal =>
      'Dale jaque mate al rey del rival: está atacado y ya no puede escapar.';

  @override
  String get rulesChessTurn =>
      'Empiezan las blancas; luego movéis por turnos.\nToca una de tus piezas y luego una casilla. Si allí hay una pieza del rival, la capturas.\nSolo el caballo puede saltar por encima de otras piezas.';

  @override
  String get rulesChessPieces => 'Cómo se mueven las piezas';

  @override
  String get rulesChessKing => '1 casilla en cualquier dirección.';

  @override
  String get rulesChessQueen =>
      'Las casillas que quiera, en recto o en diagonal.';

  @override
  String get rulesChessRook => 'Las casillas que quiera, en recto.';

  @override
  String get rulesChessBishop => 'Las casillas que quiera, en diagonal.';

  @override
  String get rulesChessKnight =>
      'Como una L: 2 casillas en recto y luego 1 hacia un lado. Salta por encima de las piezas.';

  @override
  String get rulesChessPawn =>
      '1 casilla hacia delante; en su primer movimiento también 2. Captura 1 casilla en diagonal hacia delante.';

  @override
  String get rulesChessSpecial =>
      'Jaque: tu rey está atacado. Tienes que salvarlo enseguida. No vale una jugada que deje a tu rey en jaque.\nJaque mate: el rey está en jaque y no se puede salvar. Quien da jaque mate gana.\nEnroque: el rey y la torre aún no se han movido y entre ellos todo está libre. El rey va 2 casillas hacia la torre y la torre salta a su lado. No vale si el rey está en jaque o si tendría que pasar por una casilla atacada.\nAl paso: si un peón avanza 2 casillas y queda al lado de tu peón, puedes capturarlo en diagonal justo en tu siguiente jugada, como si hubiera avanzado solo 1 casilla.\nCoronación: cuando un peón llega a la última fila, se convierte en dama, torre, alfil o caballo. Tú eliges.';

  @override
  String get rulesChessDrawTitle => 'Tablas (empate)';

  @override
  String get rulesChessDraw =>
      'Ahogado: quien tiene el turno no puede mover, pero no está en jaque.\nQuedan muy pocas piezas para dar jaque mate.\nLa misma posición aparece por 3.ª vez.\n75 jugadas de cada jugador sin capturas y sin mover ningún peón.\nTablas por acuerdo: quien tiene el turno puede ofrecer tablas. El rival acepta o rechaza.';

  @override
  String get rulesWordtilesWin => 'Quien tiene más puntos al final gana.';

  @override
  String get rulesWordtilesTurn =>
      'Tienes 7 fichas en tu atril.\nColoca de 1 a 7 fichas en una fila o una columna, sin huecos.\nTe llevas los puntos de todas las palabras nuevas, también de las que se cruzan con ellas.\nLuego sacas fichas de la bolsa hasta volver a tener 7.';

  @override
  String get rulesWordtilesChallengeAfter =>
      'Después, quien impugnó juega su turno normal.';

  @override
  String get rulesWordtilesPlayers =>
      'De dos a cuatro en un dispositivo: jugáis por turnos. En una sala jugáis dos.';

  @override
  String get rulesWordtilesChallengeNext =>
      'Solo puede impugnar quien juega a continuación.';

  @override
  String get rulesWordtilesScoreless =>
      'Si la partida termina porque nadie consigue más puntos, cada jugador pierde los puntos de las fichas que le quedan.';

  @override
  String get rulesWordtilesNoRestTitle => 'Sin restar sobrantes';

  @override
  String get rulesWordtilesNoRest =>
      'Al final no se resta ni se suma nada: solo cuentan las palabras colocadas.';

  @override
  String get rulesMaumauGoal => 'Quédate sin cartas antes que el rival.';

  @override
  String get rulesMaumauTurn =>
      'Hay 32 cartas. Cada jugador recibe 5 y una queda boca arriba en el centro. Empieza el Jugador 1.\nEcha encima una carta del mismo palo o del mismo valor, por ejemplo corazones sobre corazones o 9 sobre 9.\nSi no encaja ninguna carta o no quieres echar ninguna, robas 1 carta. Si encaja, puedes echarla o quedártela. Si no encaja, le toca al rival.\nCuando el mazo se acaba, las cartas echadas se barajan y forman un mazo nuevo.';

  @override
  String get rulesMaumauJack =>
      'Jota: encaja sobre cualquier carta menos sobre una jota. Pides un palo. Entonces tiene que venir ese palo o una jota.';

  @override
  String get rulesMaumauSpecial =>
      'La primera carta del centro no cuenta como carta especial.\n9, 10, reina y rey son cartas normales.\nQuien echa su última carta gana, también con una carta especial.';

  @override
  String get rulesMaexchenGoal =>
      'No pierdas todas tus vidas. Quien al final aún tiene vidas gana.';

  @override
  String get rulesMaexchenTurn =>
      'Tira 2 dados bajo el cubilete. Solo tú los ves.\nAnuncia un valor. Tiene que ser más alto que el último anuncio. ¡También puedes farolear!\nEl rival te cree o duda.\nSi te cree, tira a su vez y tiene que anunciar todavía más alto.\nSi duda, se levanta el cubilete. Si la tirada es más baja que lo anunciado, quien anunció pierde una vida. Si no, pierde una vida quien dudó.';

  @override
  String get rulesMaexchenOrderTitle => '¿Qué tirada es más alta?';

  @override
  String get rulesMaexchenOrder =>
      'El dado más alto cuenta primero: 3 y 1 es 31.\nDe menor a mayor: 31, 32, 41, 42, 43 y así hasta 65.\nMás altos son los dobles: 11, 22, 33, 44, 55, 66.\nLo más alto es 21: ¡Mia!';

  @override
  String get rulesMaexchenSpecial =>
      'El primer anuncio de una ronda puede ser cualquier valor.\nSi se anuncia Mia, no puedes creerlo. Dudas o cedes una vida sin mirar.\nQuien pierde una vida empieza la ronda siguiente.\nAgitar: en lugar de tocar «Tirar», puedes agitar el móvil como un cubilete.';

  @override
  String rulesMaexchenLives(int count) {
    return 'Todos empiezan con $count vidas.';
  }

  @override
  String get shakeConsentTitle => '¿Tirar agitando?';

  @override
  String get shakeConsentBody =>
      'Tu navegador va a preguntar si Klunki puede notar el movimiento del móvil. Solo lo usamos para tirar los dados y se queda en el dispositivo.';

  @override
  String get shakeConsentYes => 'Sí, permitir agitar';

  @override
  String get shakeConsentNo => 'No, solo tocar';

  @override
  String get wordtilesHelp => 'Cómo se juega';

  @override
  String get wordtilesHelpJoker =>
      'Cambiar el comodín (variante de regla): si tienes la letra que representa un comodín del tablero, arrástrala sobre el comodín. El comodín pasa a tus fichas y colocas fichas en el mismo turno (el comodín puede ser una de ellas). Sin colocar, el cambio no cuenta. La palabra de antes y sus puntos se quedan.';

  @override
  String get wordtilesHelpJokerOn => 'Activada en esta partida.';

  @override
  String get wordtilesHelpJokerOff =>
      'Desactivada en esta partida. Podéis activarla antes de una partida.';

  @override
  String get menuGameDiceSheet => 'A los dados';

  @override
  String get menuDescDiceSheet => 'Cinco dados, una hoja, hasta cuatro';

  @override
  String get engineReasonDicesheetAllFilled =>
      'Todas las casillas están llenas';

  @override
  String get playerDefaultNameC => 'Carla';

  @override
  String get playerDefaultNameD => 'Diego';

  @override
  String get seatPlayerCount => '¿Cuántos juegan?';

  @override
  String get seatResignWho => '¿Quién se rinde? Los demás siguen jugando.';

  @override
  String get seatOut => 'se rindió';

  @override
  String seatPoints(int points) {
    String _temp0 = intl.Intl.pluralLogic(
      points,
      locale: localeName,
      other: '$points puntos',
      one: '$points punto',
    );
    return '$_temp0';
  }

  @override
  String get seatSharedFirst => '¡Empate en el primer puesto!';

  @override
  String get seatReasonOthersResigned => 'Todos los demás se rindieron';

  @override
  String get dicesheetBoxOnes => 'Unos';

  @override
  String get dicesheetBoxTwos => 'Doses';

  @override
  String get dicesheetBoxThrees => 'Treses';

  @override
  String get dicesheetBoxFours => 'Cuatros';

  @override
  String get dicesheetBoxFives => 'Cincos';

  @override
  String get dicesheetBoxSixes => 'Seises';

  @override
  String get dicesheetBoxThreeKind => 'Trío';

  @override
  String get dicesheetBoxFourKind => 'Póker';

  @override
  String get dicesheetBoxFullHouse => 'Full';

  @override
  String get dicesheetBoxSmallStraight => 'Escalera corta';

  @override
  String get dicesheetBoxLargeStraight => 'Escalera larga';

  @override
  String get dicesheetBoxFiveKind => 'Cinco iguales';

  @override
  String get dicesheetBoxChance => 'Suerte';

  @override
  String dicesheetMoveRoll(String dice) {
    return 'tira $dice';
  }

  @override
  String dicesheetMoveRollKeep(String dice, int count) {
    return 'tira $dice (guarda $count)';
  }

  @override
  String dicesheetMoveScore(String box, int points) {
    return '$box: $points';
  }

  @override
  String dicesheetMoveScoreBonus(String box, int points, int bonus) {
    return '$box: $points (+$bonus)';
  }

  @override
  String dicesheetLastScore(String player, String box, int points) {
    return '$player: $points en $box.';
  }

  @override
  String get dicesheetHintRoll => 'Toca Tirar.';

  @override
  String get dicesheetHintKeep =>
      'Toca los dados que quieres guardar y vuelve a tirar. O elige una casilla en la hoja.';

  @override
  String get dicesheetHintPick => 'Elige una casilla en la hoja.';

  @override
  String get dicesheetHintJoker =>
      'Cinco iguales como comodín: anótalo en una de las casillas permitidas.';

  @override
  String dicesheetRollButton(int count) {
    return 'Tirar (quedan $count)';
  }

  @override
  String get dicesheetPickBox => 'Elige una casilla';

  @override
  String dicesheetDie(int value) {
    return 'Dado $value';
  }

  @override
  String dicesheetDieKept(int value) {
    return 'Dado $value, guardado';
  }

  @override
  String get dicesheetKept => 'guardado';

  @override
  String dicesheetRound(int round, int total) {
    return 'Ronda $round/$total';
  }

  @override
  String dicesheetScoreAction(String box, int points) {
    return 'Anotar $points en $box';
  }

  @override
  String get dicesheetBonus => 'Premio';

  @override
  String dicesheetBonusRule(String bonus, int at) {
    return '$bonus desde $at';
  }

  @override
  String get dicesheetExtraFives => 'Cinco iguales extra';

  @override
  String get dicesheetTotal => 'Total';

  @override
  String get dicesheetOptionExtraFives =>
      'Cinco iguales extra (variante de regla)';

  @override
  String get dicesheetOptionExtraFivesExplain =>
      'Otro Cinco iguales cuando esa casilla ya tiene 50: 100 puntos más. Entonces es un comodín y va primero a la casilla de arriba de su número.';

  @override
  String get rulesDicesheetGoal =>
      'Consigue en tu hoja todos los puntos que puedas con cinco dados.\nTras 13 rondas todas las casillas están llenas. Gana quien tenga más puntos. Con los mismos puntos compartís el puesto.';

  @override
  String get rulesDicesheetTurn =>
      'Juegan de 2 a 4 en un solo dispositivo, por turnos.\nTira los cinco dados. Puedes tirar hasta tres veces.\nAntes de la 2.ª y la 3.ª tirada, toca los dados que quieres guardar. Vuelve a tirar los demás.\nLuego anota lo que valen los dados en una sola casilla vacía de tu hoja. La hoja te muestra cuántos puntos da cada casilla.\nSi nada encaja, tacha una casilla: vale 0.';

  @override
  String get rulesDicesheetUpperTitle => 'Arriba: Unos a Seises';

  @override
  String get rulesDicesheetUpper =>
      'Solo cuentan los dados con el número de la casilla, sumados.';

  @override
  String rulesDicesheetBonus(int at, int bonus) {
    return 'Con $at puntos o más arriba ganas $bonus puntos extra.';
  }

  @override
  String get rulesDicesheetLowerTitle => 'Abajo';

  @override
  String get rulesDicesheetThreeKind =>
      'Al menos 3 iguales. Cuentan todos los dados.';

  @override
  String get rulesDicesheetFourKind =>
      'Al menos 4 iguales. Cuentan todos los dados.';

  @override
  String rulesDicesheetFullHouse(int points) {
    return '3 iguales y 2 iguales: $points puntos.';
  }

  @override
  String rulesDicesheetSmallStraight(int points) {
    return '4 números seguidos: $points puntos.';
  }

  @override
  String rulesDicesheetLargeStraight(int points) {
    return '5 números seguidos: $points puntos.';
  }

  @override
  String rulesDicesheetFiveKind(int points) {
    return '5 iguales: $points puntos.';
  }

  @override
  String get rulesDicesheetChance => 'Siempre encaja. Cuentan todos los dados.';

  @override
  String get rulesDicesheetSpecial =>
      'Cada casilla se llena una sola vez.\nUna tirada cuenta enseguida. «Deshacer jugada» solo quita lo que anotaste en la hoja, mientras nadie haya vuelto a tirar.\nQuien se rinde queda fuera. Los demás siguen jugando.\nAgitar: en lugar de tocar «Tirar», puedes agitar el móvil.';

  @override
  String rulesDicesheetExtraFives(int bonus) {
    return 'Otro Cinco iguales cuando esa casilla ya tiene 50: $bonus puntos más. Cuando la casilla Cinco iguales ya está llena (también con 0), un Cinco iguales es un comodín: primero en la casilla de arriba de su número; si está llena, en una casilla libre de abajo con todos los puntos; si no, con 0 en una casilla de arriba.';
  }

  @override
  String get dicesheetStartTitle => '¿Quién empieza?';

  @override
  String get dicesheetStartFirst => 'Primer jugador';

  @override
  String get dicesheetStartOrder => 'Elegir el orden';

  @override
  String get dicesheetStartRandom => 'Al azar';

  @override
  String get dicesheetStartFirstExplain =>
      'Empieza el nombre de arriba de la lista. Luego, por turnos.';

  @override
  String get dicesheetStartOrderExplain =>
      'En el paso siguiente ponéis los nombres en vuestro orden.';

  @override
  String get dicesheetStartRandomExplain =>
      'El juego sortea quién empieza. Luego, por turnos.';

  @override
  String get seatOrderHint =>
      'Jugáis en el orden de los nombres de aquí. Cambia el orden con las flechas.';

  @override
  String get seatMoveUp => 'Subir';

  @override
  String get seatMoveDown => 'Bajar';

  @override
  String get seatRandomStartHint => 'El juego sortea quién empieza.';

  @override
  String seatStarts(String player) {
    return '¡Vamos! Empieza $player.';
  }

  @override
  String seatStartsRandom(String player) {
    return 'Sorteo: ¡empieza $player!';
  }

  @override
  String get rulesDicesheetStart =>
      'Antes de jugar elegís quién empieza: el nombre de arriba de la lista, vuestro propio orden o el azar.';

  @override
  String get maumauOptionMustPlay => 'Echar carta si se puede';

  @override
  String get maumauOptionMustPlayExplain =>
      'Solo puedes robar si ninguna carta encaja. Después de un 7 siempre puedes robar las cartas.';

  @override
  String get maumauHintMustPlay => 'Tienes una carta que encaja: échala.';

  @override
  String get maumauHintNoFit => 'Ninguna carta encaja. Roba una del mazo.';

  @override
  String get rulesMaumauTurnMustPlay =>
      'Hay 32 cartas. Cada jugador recibe 5 y una queda boca arriba en el centro. Empieza el Jugador 1.\nEcha encima una carta del mismo palo o del mismo valor, por ejemplo corazones sobre corazones o 9 sobre 9.\nSi no encaja ninguna carta, robas 1 carta. Si encaja, puedes echarla o quedártela. Si no encaja, le toca al rival.\nCuando el mazo se acaba, las cartas echadas se barajan y forman un mazo nuevo.';

  @override
  String get dicesheetBeginnerOption => 'Modo principiante';

  @override
  String get dicesheetBeginnerExplain =>
      'La casilla que va bien ahora se ilumina en la hoja. Puedes elegir cualquier casilla igualmente.';

  @override
  String get dicesheetTipsOption => 'Consejos';

  @override
  String get dicesheetTipsExplain =>
      'Un bocadillo dice qué casilla va bien ahora y por qué, y qué dados guardar.';

  @override
  String get dicesheetTipLabel => 'Consejo';

  @override
  String get dicesheetTipShow => 'Ver consejo';

  @override
  String dicesheetTipBonus(String box, int points, int goal) {
    return 'Consejo: $box – $points puntos te ayudan para el premio ($goal).';
  }

  @override
  String dicesheetTipAllDice(String box, int points) {
    return 'Consejo: $box – cuentan todos los dados, eso da $points puntos.';
  }

  @override
  String dicesheetTipFixed(String box, int points) {
    return 'Consejo: $box – eso da $points puntos. ¡Aprovéchalos!';
  }

  @override
  String dicesheetTipPoints(String box, int points) {
    return 'Consejo: $box – eso da $points puntos.';
  }

  @override
  String dicesheetTipLeastLoss(String box, int points) {
    return 'Consejo: ¿Ninguna casilla buena? $box solo da $points puntos, pero ahí pierdes lo mínimo.';
  }

  @override
  String dicesheetTipStrike(String box) {
    return 'Consejo: ¿Ninguna casilla buena? Tacha $box, ahí pierdes lo mínimo.';
  }

  @override
  String dicesheetTipRicher(String box, int points) {
    return '$box daría ahora $points puntos, pero vale más para después.';
  }

  @override
  String get dicesheetTipSaveChance => 'Guarda la Suerte para más tarde.';

  @override
  String get dicesheetTipOnce =>
      'Cada casilla se usa una sola vez, también la Suerte.';

  @override
  String get dicesheetTipKeep =>
      'Consejo: guarda estos dados y vuelve a tirar los demás:';

  @override
  String get dicesheetTipRerollAll =>
      'Consejo: nada encaja bien. Vuelve a tirar todos.';

  @override
  String get dicesheetTipStop => '¡Gran tirada! Ya no hace falta tirar más.';

  @override
  String get dicesheetTipsEnd => 'Quitar los consejos';

  @override
  String get dicesheetTipsEnded =>
      'Consejos desactivados. Puedes volver a activarlos en las opciones.';

  @override
  String dicesheetFreeBoxes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'quedan $count casillas libres',
      one: 'queda 1 casilla libre',
    );
    return '$_temp0';
  }

  @override
  String rulesDicesheetOnce(int count) {
    return 'Cada casilla se llena una sola vez. $count casillas, $count rondas.';
  }

  @override
  String get rulesDicesheetBeginner =>
      'Modo principiante (activado en la primera partida): la casilla que va bien ahora se ilumina en la hoja. Consejos (activados en las 5 primeras partidas): un bocadillo dice por qué y qué dados guardar. Puedes poner o quitar los dos en las opciones. Puedes elegir cualquier casilla igualmente.';

  @override
  String dicesheetCoachRoll(int count) {
    return 'Tienes hasta $count tiradas por turno.';
  }

  @override
  String get dicesheetCoachKeep => 'Toca los dados que deben quedarse.';

  @override
  String get dicesheetCoachSheet =>
      'Luego anotas la tirada en una casilla. El número muestra cuántos puntos da.';

  @override
  String dicesheetCoachOnce(int count) {
    return 'Cada casilla una sola vez: $count casillas, $count rondas. Gana quien tenga más puntos.';
  }

  @override
  String get dicesheetCoachReplay => 'Recorrido rápido';

  @override
  String get menuGameProperty => 'El Gran Constructor';

  @override
  String get menuDescProperty => 'Compra calles, cobra alquiler, construye';

  @override
  String get engineReasonPropertyLastSolvent =>
      'Todos los demás están en bancarrota o fuera';

  @override
  String engineReasonPropertyRoundLimit(int rounds) {
    return 'Tras $rounds rondas gana la mayor fortuna';
  }

  @override
  String propertyMoney(int amount) {
    return '$amount monedas';
  }

  @override
  String get propertyOptionsBoard => 'Tablero';

  @override
  String get propertyThemeBerlin => 'Berlín';

  @override
  String get propertyThemeFantasie => 'Ciudad Fantasía';

  @override
  String get propertyThemeGermanNote =>
      'Por ahora, las calles y las cartas están en alemán.';

  @override
  String get propertyOptionsLength => 'Duración';

  @override
  String get propertyOptionsUntilEnd => 'Hasta que solo quede uno';

  @override
  String propertyOptionsRounds(int rounds) {
    return '$rounds rondas';
  }

  @override
  String get propertyOptionsRoundsExplain =>
      'Con límite de rondas, gana al final quien más tenga.';

  @override
  String get propertyOptionsVariants => 'Variantes de reglas';

  @override
  String propertyFreeTitle(String square) {
    return 'En «$square»';
  }

  @override
  String get propertyFreeNone => 'No pasa nada';

  @override
  String get propertyFreePot => 'Bote con impuestos y multas';

  @override
  String propertyFreePotSeed(String amount) {
    return 'Bote, empieza con $amount';
  }

  @override
  String propertyFreeBonus(String amount) {
    return '$amount fijos';
  }

  @override
  String get propertyFreeExplain =>
      'Bote: impuestos y multas van al centro. Quien cae en la casilla se lo lleva todo.';

  @override
  String propertyFreeBonusExplain(String square, String amount) {
    return 'Caer en «$square» da $amount.';
  }

  @override
  String get propertyRuleDoubleStart => 'Doble sueldo en la Salida';

  @override
  String propertyRuleDoubleStartExplain(String amount) {
    return 'Caer justo en la Salida da $amount.';
  }

  @override
  String get propertyRuleNoRentInPause => 'Sin alquiler durante la pausa';

  @override
  String get propertyRuleNoRentInPauseExplain =>
      'Quien está en la pausa no cobra alquiler.';

  @override
  String get propertyRuleBankruptAuction => 'Subasta en bancarrota';

  @override
  String get propertyRuleBankruptAuctionExplain =>
      'Si alguien quiebra ante el banco, sus calles se subastan.';

  @override
  String get propertyRoll => 'Tirar';

  @override
  String propertyBuy(String amount) {
    return 'Comprar por $amount';
  }

  @override
  String get propertyDecline => 'No comprar – subasta';

  @override
  String get propertyTooPoor => 'No hay dinero suficiente para comprar';

  @override
  String propertyFreeToBuy(String square) {
    return '$square aún no es de nadie.';
  }

  @override
  String propertyAuctionTitle(String square) {
    return 'Subasta: $square';
  }

  @override
  String propertyAuctionHigh(String amount, String player) {
    return 'Puja más alta: $amount de $player';
  }

  @override
  String get propertyAuctionNone => 'Aún sin pujas';

  @override
  String propertyAuctionTurn(String player) {
    return 'Le toca pujar a $player.';
  }

  @override
  String propertyBid(String amount) {
    return 'Pujar $amount';
  }

  @override
  String get propertyPass => 'Retirarse';

  @override
  String get propertyEndTurn => 'Terminar turno';

  @override
  String propertyPayBail(String amount) {
    return 'Pagar $amount y salir';
  }

  @override
  String get propertyUseCard => 'Usar carta libre';

  @override
  String propertyInPause(String player, String square) {
    return '$player está en «$square»: saca dobles, paga o usa una carta.';
  }

  @override
  String get propertyManage => 'Mis calles';

  @override
  String propertyManageOf(String player) {
    return 'Calles: $player';
  }

  @override
  String propertyDebt(String player, String amount, String cash) {
    return '$player debe $amount pero solo tiene $cash. Vende edificios o hipoteca calles.';
  }

  @override
  String get propertyBankrupt => 'Declararse en bancarrota';

  @override
  String propertyBuild(String amount) {
    return 'Construir ($amount)';
  }

  @override
  String propertySell(String amount) {
    return 'Vender (+$amount)';
  }

  @override
  String propertyMortgage(String amount) {
    return 'Hipotecar (+$amount)';
  }

  @override
  String propertyUnmortgage(String amount) {
    return 'Levantar hipoteca ($amount)';
  }

  @override
  String get propertyManageEmpty => 'Aún no hay calles.';

  @override
  String get propertyMortgaged => 'hipotecada';

  @override
  String propertyOwnerLine(String player) {
    return 'Es de $player';
  }

  @override
  String get propertyOwnerNone => 'Aún es del banco';

  @override
  String propertyPrice(String amount) {
    return 'Precio: $amount';
  }

  @override
  String propertyRent(String amount) {
    return 'Alquiler: $amount';
  }

  @override
  String propertyHouseCost(String amount) {
    return 'Cada edificio cuesta $amount';
  }

  @override
  String get propertyStationRents => 'Alquiler según el número de estaciones';

  @override
  String propertyTax(String amount) {
    return 'Pagar: $amount';
  }

  @override
  String propertyCardSquare(String deck) {
    return 'Robar una carta: $deck';
  }

  @override
  String propertyStartSquare(String amount) {
    return 'Pasar por aquí da $amount.';
  }

  @override
  String get propertyPauseSquare =>
      'Pausa: se sale con dobles, dinero o carta. ¿Solo de visita? No pasa nada.';

  @override
  String get propertyGoToPauseSquare => '¡A la pausa!';

  @override
  String get propertyOut => 'fuera';

  @override
  String propertyStreets(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count calles',
      one: '1 calle',
      zero: 'ninguna calle',
    );
    return '$_temp0';
  }

  @override
  String get propertyCoachRoll => 'Tira y mueve tu ficha por el tablero.';

  @override
  String get propertyCoachBoard =>
      'Si caes en una calle libre, puedes comprarla. Quien caiga en tu calle te paga alquiler. Toca una casilla para ver más.';

  @override
  String get propertyCoachPlayers =>
      'Aquí ves el dinero de todos. Quien se queda sin dinero, quiebra.';

  @override
  String get propertyCoachManage =>
      'Si tienes todo un color, aquí construyes y el alquiler sube mucho.';

  @override
  String get propertyCoachReplay => 'Guía rápida';

  @override
  String propertyEvRolled(String player, int a, int b) {
    return '$player saca $a + $b';
  }

  @override
  String propertyEvSalary(String player, String amount) {
    return '$player cobra $amount de sueldo';
  }

  @override
  String propertyEvCard(String text) {
    return 'Carta: «$text»';
  }

  @override
  String propertyEvCollected(String player, String amount) {
    return '$player recibe $amount';
  }

  @override
  String propertyEvPot(String player, String amount) {
    return '$player se lleva el bote: $amount';
  }

  @override
  String propertyEvPaidBank(String player, String amount) {
    return '$player paga $amount al banco';
  }

  @override
  String propertyEvPaidPot(String player, String amount) {
    return '$player pone $amount en el bote';
  }

  @override
  String propertyEvPaid(String player, String amount, String other) {
    return '$player paga $amount a $other';
  }

  @override
  String propertyEvBought(String player, String square, String amount) {
    return '$player compra $square por $amount';
  }

  @override
  String propertyEvBid(String player, String amount) {
    return '$player puja $amount';
  }

  @override
  String propertyEvPassed(String player) {
    return '$player se retira';
  }

  @override
  String propertyEvUnsold(String square) {
    return 'Sin pujas: $square sigue en el banco';
  }

  @override
  String propertyEvBuilt(String player, String building, String square) {
    return '$player construye $building en $square';
  }

  @override
  String propertyEvSold(String player, String square, String amount) {
    return '$player vende en $square: +$amount';
  }

  @override
  String propertyEvMortgaged(String player, String square, String amount) {
    return '$player hipoteca $square: +$amount';
  }

  @override
  String propertyEvUnmortgaged(String player, String square, String amount) {
    return '$player levanta la hipoteca de $square: −$amount';
  }

  @override
  String propertyEvToPause(String player, String square) {
    return '$player va a «$square»';
  }

  @override
  String get propertyEvThreeDoubles => '¡Tres dobles seguidos!';

  @override
  String propertyEvLeftPause(String player) {
    return '$player vuelve a estar libre';
  }

  @override
  String propertyEvStayInPause(String player, int tries) {
    return 'Sin dobles: $player sigue en la pausa ($tries/3)';
  }

  @override
  String propertyEvBankrupt(String player) {
    return '$player está en bancarrota';
  }

  @override
  String propertyEvResigned(String player) {
    return '$player se rinde';
  }

  @override
  String get rulesPropertyGoal =>
      'Compra calles, cobra alquiler y construye en ellas.\nGana quien quede último en el juego. Con límite de rondas, gana al final la mayor fortuna.';

  @override
  String rulesPropertyTurn(String salary) {
    return 'Tira dos dados y avanza esas casillas.\nSi caes en una calle libre, puedes comprarla. Si no, se subasta: se la lleva la puja más alta.\nSi la calle es de otra persona, pagas alquiler.\nCon dobles vuelves a tirar.\nPasar por la Salida da $salary.';
  }

  @override
  String rulesPropertySpecial(String bail) {
    return 'Con todo un grupo de color, el alquiler es doble y puedes construir: por igual, primero 4 pequeños y luego 1 grande por calle.\nLas cartas dan dinero, cuestan dinero o te mueven por el tablero.\nTres dobles seguidos te mandan a la pausa. Sales con dobles, con $bail o con una carta libre.\n¿Te falta dinero? Vende edificios a mitad de precio o hipoteca calles. Solo quiebras si ni así alcanza.\nHipotecar da la mitad del precio; levantar la hipoteca cuesta un 10 % más. Una calle hipotecada no da alquiler.';
  }

  @override
  String get propertyDeedRent => 'Alquiler';

  @override
  String get propertyDeedRentGroup => 'Con todo el grupo';

  @override
  String get propertyDeedMortgageValue => 'Valor de hipoteca';

  @override
  String propertyDeedStations(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count estaciones',
      one: '1 estación',
    );
    return '$_temp0';
  }

  @override
  String get propertyDeedUtilityOne => 'Con uno de los dos';

  @override
  String get propertyDeedUtilityBoth => 'Con los dos';

  @override
  String propertyDeedDiceTimes(int factor) {
    return 'Suma de dados × $factor';
  }

  @override
  String get maexchenOptionUnlimited => 'Vidas ilimitadas';

  @override
  String get maexchenOptionUnlimitedExplain =>
      'Nadie queda fuera. Se cuenta cada vida perdida. Jugáis hasta terminar la partida: gana quien haya perdido menos vidas.';

  @override
  String get maexchenEndGame => 'Terminar la partida';

  @override
  String get maexchenEndGameTitle => '¿Terminar la partida?';

  @override
  String get maexchenEndGameBody =>
      'Gana quien haya perdido menos vidas. Con empate, compartís el puesto.';

  @override
  String get maexchenEndGameConfirm => 'Terminar';

  @override
  String get engineReasonMaexchenEnded =>
      'Habéis terminado la partida. Gana quien haya perdido menos vidas.';

  @override
  String maexchenLostOf(String player, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count vidas perdidas',
      one: '1 vida perdida',
    );
    return '$player: $_temp0';
  }

  @override
  String maexchenResultLost(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count vidas perdidas',
      one: '1 vida perdida',
    );
    return '$_temp0';
  }

  @override
  String maexchenResultLives(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count vidas restantes',
      one: '1 vida restante',
    );
    return '$_temp0';
  }

  @override
  String get maexchenResultOut => 'fuera';

  @override
  String get rulesMaexchenPlayers =>
      'De dos a cuatro en un dispositivo. El cubilete da la vuelta a la mesa: siempre anuncias a quien va después. Quien se queda sin vidas queda fuera y se le salta.';

  @override
  String get rulesMaexchenGoalUnlimited =>
      'Pierde las menos vidas posibles. Jugáis hasta terminar la partida.';

  @override
  String get rulesMaexchenEndHow =>
      '«Terminar la partida» está en el menú de los tres puntos.';

  @override
  String propertyInPausePhrase(String player, String place) {
    return '$player $place: saca dobles, paga o usa una carta.';
  }

  @override
  String propertyEvToPausePhrase(String player, String place) {
    return '$player va $place';
  }

  @override
  String get propertyTrade => 'Intercambiar';

  @override
  String get propertyTradeTitle => 'Proponer un intercambio';

  @override
  String get propertyTradeWith => '¿Con quién?';

  @override
  String get propertyTradeGive => 'Das';

  @override
  String get propertyTradeGet => 'Recibes';

  @override
  String get propertyTradeMoney => 'Dinero';

  @override
  String get propertyTradeMoneyReset => 'Volver a 0';

  @override
  String get propertyTradeFreeCards => 'Cartas libres';

  @override
  String propertyTradeCardCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count cartas libres',
      one: '1 carta libre',
    );
    return '$_temp0';
  }

  @override
  String get propertyTradeNothing => 'nada';

  @override
  String get propertyTradeNoStreets => 'Ninguna calle';

  @override
  String get propertyTradeOffer => 'Hacer la oferta';

  @override
  String propertyTradeOffersLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Quedan $count ofertas en este turno',
      one: 'Queda 1 oferta en este turno',
    );
    return '$_temp0';
  }

  @override
  String get propertyTradeEmpty => 'Elige qué vais a intercambiar.';

  @override
  String get propertyTradeHouses => 'Hay edificios en el color: no se cambia';

  @override
  String propertyTradeTooMany(int count) {
    return 'Ya hubo $count ofertas en este turno.';
  }

  @override
  String get propertyTradeNotNow => 'Ahora no se puede intercambiar.';

  @override
  String get propertyTradeNoMoney => 'No hay tanto dinero.';

  @override
  String propertyTradeOfferFor(String player, String other) {
    return 'Oferta de intercambio: $player → $other';
  }

  @override
  String get propertyTradeAccept => 'Aceptar';

  @override
  String get propertyTradeDecline => 'Rechazar';

  @override
  String propertyEvTradeOffered(
    String player,
    String other,
    String give,
    String get,
  ) {
    return 'Oferta de intercambio $player → $other: $give por $get';
  }

  @override
  String propertyEvTraded(String player) {
    return '$player acepta el intercambio';
  }

  @override
  String propertyEvTradeDeclined(String player) {
    return '$player rechaza el intercambio';
  }

  @override
  String get propertyCoachTrade =>
      '¿Te falta una calle para tener todo un color? Propón aquí un intercambio.';

  @override
  String rulesPropertyTrade(int count) {
    return 'En tu turno puedes proponer un intercambio antes o después de tirar: calles, dinero y cartas libres, hasta $count ofertas por turno.\nLas calles con edificios en su color no se intercambian: primero vende los edificios. Una calle hipotecada sigue hipotecada.\nEl dispositivo pasa a la otra persona, que acepta o rechaza. Un intercambio ya respondido no se puede deshacer.';
  }

  @override
  String get propertyTradeShowBoard => 'Ver el tablero';

  @override
  String get propertyTradeShowOffer => 'Volver a la oferta';

  @override
  String maexchenSummaryLives(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count vidas',
      one: '1 vida',
    );
    return '$_temp0';
  }
}
