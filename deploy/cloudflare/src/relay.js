// The Worker's request handling (KLD-114; prepared, not deployed by the
// project). Same protocol as `klunki relay` (PROTOCOL.md, "Relay" and "Club
// codes"): this Worker checks the request (path, upgrade, Origin, club code)
// and hands create/join to one Durable Object per room code (`RelayRoom`).
//
// Environment (wrangler.toml / secrets):
//   ROOMS                 Durable Object namespace bound to RelayRoom (required)
//   CLUB_CODES            secret: club codes, one per line (`# label` allowed),
//                         same format as `klunki relay --codes FILE`. Unset =
//                         open relay; set (even empty) = gated.
//   ALLOWED_ORIGINS       optional, comma-separated: browsers from other web
//                         origins are refused (apps send no Origin and pass)
//   IDLE_TIMEOUT_SECONDS  optional, default 600
//   MAX_LINE_LENGTH       optional, default 262144 (UTF-16 code units)
//
// Nothing is logged: no console output at all (club codes travel in the URL).

import {
  ClubCodes,
  ClubStrikes,
  closePolicyViolation,
  newRoomCode,
  normalizeRoomCode,
  relayClubMissingText,
  relayClubParam,
  relayClubWrongText,
  relayControl,
  relayError,
  relayErrorClubMissing,
  relayErrorClubWrong,
  relayPath,
} from './protocol.js';

/** How often `create` draws a new code when the drawn one is in use. */
const createAttempts = 8;

function text(status, body, headers = {}) {
  return new Response(body, {
    status,
    headers: { 'Content-Type': 'text/plain; charset=utf-8', 'Cache-Control': 'no-store', ...headers },
  });
}

/**
 * Accepts the WebSocket only to say why it is refused (`relay.error`), then
 * closes it (1008), like the Dart relay: clients read the reason from the
 * message, which a plain HTTP error would not give a browser.
 */
function refuse(message, error) {
  const [client, server] = Object.values(new WebSocketPair());
  server.accept();
  server.send(relayControl(relayError, error === undefined ? { message } : { error, message }));
  server.close(closePolicyViolation, '');
  return new Response(null, { status: 101, webSocket: client });
}

function list(value) {
  return (value ?? '')
    .split(',')
    .map((s) => s.trim())
    .filter((s) => s !== '');
}

/** Builds the Worker; tests pass their own strike counter. */
export function createRelay({ strikes = new ClubStrikes() } = {}) {
  let codes = null; // ClubCodes of the current CLUB_CODES text

  function clubCodes(textValue) {
    if (codes === null || codes.text !== textValue) codes = new ClubCodes(textValue);
    return codes;
  }

  function room(env, op, code) {
    const stub = env.ROOMS.get(env.ROOMS.idFromName(code));
    // A fixed internal URL: the club code in the client's URL never reaches
    // the room object.
    return stub.fetch('https://room.internal/', {
      headers: { Upgrade: 'websocket', 'X-Klunki-Op': op, 'X-Klunki-Room': code },
    });
  }

  return {
    async fetch(request, env) {
      const url = new URL(request.url);
      if (url.pathname !== relayPath && url.pathname !== `${relayPath}/`) {
        return text(404, `Klunki relay: connect a WebSocket to ${relayPath}.\n`);
      }
      if ((request.headers.get('Upgrade') ?? '').toLowerCase() !== 'websocket') {
        return text(426, 'Klunki relay: connect a WebSocket (?create to host, ?join=CODE to join).\n', {
          Upgrade: 'websocket',
        });
      }
      const allowed = list(env.ALLOWED_ORIGINS);
      const origin = request.headers.get('Origin');
      if (allowed.length > 0 && origin !== null && !allowed.includes(origin)) {
        return text(403, 'Klunki relay: this web page may not use the relay.\n');
      }
      const query = url.searchParams;

      // Club codes (KLD-112) are checked before anything else, so a refused
      // client learns nothing about rooms.
      if (typeof env.CLUB_CODES === 'string') {
        const raw = query.get(relayClubParam);
        if (raw === null || raw.trim() === '') return refuse(relayClubMissingText, relayErrorClubMissing);
        const address = request.headers.get('CF-Connecting-IP') ?? '?';
        if (strikes.blocked(address)) {
          return refuse('too many wrong club codes, try again later', relayErrorClubWrong);
        }
        if (!(await clubCodes(env.CLUB_CODES).check(raw))) {
          strikes.strike(address);
          return refuse(relayClubWrongText, relayErrorClubWrong);
        }
      }

      if (query.has('create')) {
        for (let i = 0; i < createAttempts; i++) {
          const response = await room(env, 'create', newRoomCode());
          if (response.status === 101) return response;
        }
        return refuse('too many rooms, try again later');
      }
      const join = query.get('join');
      if (join !== null) {
        const code = normalizeRoomCode(join);
        if (code === null) return refuse(`no room with code ${join.trim().toUpperCase()}`);
        const response = await room(env, 'join', code);
        if (response.status === 101) return response;
        if (response.status === 409) return refuse(`room ${code} is full`);
        return refuse(`no room with code ${code}`);
      }
      return refuse('bad request: use ?create or ?join=CODE');
    },
  };
}
