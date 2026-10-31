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
  String get quartettTrumpfTie => 'Empate – las cartas van al bote';

  @override
  String quartettTrumpfWinsTrick(String player) {
    return '$player gana la baza';
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
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count cartas',
      many: '$count de cartas',
      one: '$count carta',
    );
    return 'En el bote: $_temp0 – $player vuelve a elegir';
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
  String schiffeSetupProgress(int index, int total, String player) {
    return 'Barco $index de $total · coloca $player';
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
      'Esta página se abrió con https. Desde ahí, los navegadores bloquean las conexiones ws:// a la red local. Abre Klunki con http://.';

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
    return 'Límite de bazas, mismas cartas ($a:$b)';
  }

  @override
  String engineReasonQuartettTrickLimitMoreCards(int a, int b) {
    return 'Límite de bazas, más cartas ($a:$b)';
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
  String get engineStatPs => 'Potencia';

  @override
  String get engineStatKmh => 'Velocidad máx.';

  @override
  String get engineStatCcm => 'Cilindrada';

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
  String get webJoinDirectTitle =>
      'O conectar con un dispositivo anfitrión (app o terminal)';
}
