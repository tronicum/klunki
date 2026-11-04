// The relay's wire vocabulary, ported from
// packages/klunki_net/lib/src/relay/relay_protocol.dart and club_codes.dart
// (KLD-114). PROTOCOL.md, "Relay" and "Club codes", is the specification;
// packages/klunki_net/test/relay_vectors.json holds the vectors both
// implementations are tested against.

export const relayPath = '/relay';

export const roomCodeLength = 5;

/** Digits and capital letters without the lookalikes 0/O, 1/I/L (31 symbols). */
export const roomCodeAlphabet = '23456789ABCDEFGHJKMNPQRSTUVWXYZ';

export const relayRoom = 'relay.room';
export const relayPeer = 'relay.peer';
export const relayLeft = 'relay.left';
export const relayClosed = 'relay.closed';
export const relayError = 'relay.error';
export const relayKick = 'relay.kick';

export const relayClubParam = 'club';
export const relayErrorClubMissing = 'club-missing';
export const relayErrorClubWrong = 'club-wrong';
export const relayClubMissingText = 'club code required';
export const relayClubWrongText = 'club code not accepted';

// KLD-120: a host whose connection dropped comes back with the room's key.
export const relayResumeParam = 'resume';
export const relayKeyParam = 'key';
export const relayErrorHostAway = 'host-away';

/** WebSocket close codes the Dart relay uses (dart:io WebSocketStatus). */
export const closeNormal = 1000;
export const closeGoingAway = 1001;
export const closePolicyViolation = 1008;
/** A clean close without a status (the client sent none). */
export const closeNoStatus = 1005;

/** Encodes a relay control message (`t` first, like the Dart relay). */
export function relayControl(t, fields = {}) {
  return JSON.stringify({ t, ...fields });
}

/**
 * The control message in `line` (its decoded object), or null for any other
 * line (game messages, garbage). Only lines that mention `"t"` are decoded.
 */
export function parseRelayControl(line) {
  if (!line.includes('"t"')) return null;
  let decoded;
  try {
    decoded = JSON.parse(line);
  } catch {
    return null;
  }
  if (decoded === null || typeof decoded !== 'object' || Array.isArray(decoded)) return null;
  const t = decoded.t;
  if (typeof t === 'string' && t.startsWith('relay.') && !Object.prototype.hasOwnProperty.call(decoded, 'type')) {
    return decoded;
  }
  return null;
}

/** Uniformly random symbols of `alphabet` (rejection sampling, no modulo bias). */
function randomSymbols(count, alphabet = roomCodeAlphabet) {
  const limit = 256 - (256 % alphabet.length);
  let out = '';
  while (out.length < count) {
    const bytes = new Uint8Array(count * 2);
    crypto.getRandomValues(bytes);
    for (const b of bytes) {
      if (b < limit && out.length < count) out += alphabet[b % alphabet.length];
    }
  }
  return out;
}

/** A random room code. */
export function newRoomCode() {
  return randomSymbols(roomCodeLength);
}

/** A random club code, `XXXX-XXXX` (same shape as `klunki relay-code new`). */
export function newClubCode() {
  return `${randomSymbols(4)}-${randomSymbols(4)}`;
}

const spacesAndDashes = /[\s-]/g;

/**
 * Normalises a typed room code: case-insensitive, spaces and dashes are
 * ignored. Null if it is not a valid code.
 */
export function normalizeRoomCode(input) {
  const code = input.replace(spacesAndDashes, '').toUpperCase();
  if (code.length !== roomCodeLength) return null;
  for (const c of code) {
    if (!roomCodeAlphabet.includes(c)) return null;
  }
  return code;
}

/**
 * Normalises a club code: case, spaces and dashes ignored; null unless the
 * result is 4 to 64 of A–Z and 0–9.
 */
export function normalizeClubCode(input) {
  const code = input.replace(spacesAndDashes, '').toUpperCase();
  if (code.length < 4 || code.length > 64) return null;
  if (!/^[A-Z0-9]+$/.test(code)) return null;
  return code;
}

/**
 * The normalised codes of a codes text (the `CLUB_CODES` secret, same format
 * as the `--codes` file: one code per line, `# label` after it, blank and
 * `#` lines skipped, invalid lines ignored). Labels are dropped: the Worker
 * logs nothing.
 */
export function parseClubCodes(text) {
  const codes = [];
  for (const line of text.split(/\r\n|\r|\n/)) {
    const hash = line.indexOf('#');
    const raw = (hash < 0 ? line : line.substring(0, hash)).trim();
    if (raw === '') continue;
    const code = normalizeClubCode(raw);
    if (code !== null) codes.push(code);
  }
  return codes;
}

const encoder = new TextEncoder();

async function digest(text) {
  return new Uint8Array(await crypto.subtle.digest('SHA-256', encoder.encode(text)));
}

/**
 * Club codes checked in constant time: SHA-256 digests, every entry
 * compared with no early exit (like `ClubCodes.check` in Dart). The digests
 * of a codes text are computed once and reused while the text is the same.
 */
export class ClubCodes {
  constructor(text) {
    this.text = text;
    this._digests = Promise.all(parseClubCodes(text).map(digest));
  }

  /** Whether `raw` (as sent by a client) is one of the codes. */
  async check(raw) {
    const code = normalizeClubCode(raw);
    const probe = await digest(code ?? raw);
    const entries = await this._digests;
    let found = 0;
    for (const entry of entries) {
      let diff = 0;
      for (let i = 0; i < probe.length; i++) diff |= probe[i] ^ entry[i];
      found |= diff === 0 ? 1 : 0;
    }
    return code !== null && found === 1;
  }
}

/**
 * Counts wrong club codes per client address: after `limit` wrong codes
 * within `windowMs` that address is refused (as a wrong code) until the
 * window has passed. In a Worker this lives in one isolate's memory, so it
 * is a best-effort brake (see README.md), not a global limit.
 */
export class ClubStrikes {
  constructor({ limit = 10, windowMs = 10 * 60 * 1000, now = () => Date.now() } = {}) {
    this.limit = limit;
    this.windowMs = windowMs;
    this.now = now;
    this._strikes = new Map();
  }

  blocked(address) {
    const s = this._strikes.get(address);
    if (s === undefined) return false;
    if (this.now() - s.since > this.windowMs) {
      this._strikes.delete(address);
      return false;
    }
    return s.count >= this.limit;
  }

  strike(address) {
    const s = this._strikes.get(address);
    if (s === undefined || this.now() - s.since > this.windowMs) {
      this._strikes.set(address, { count: 1, since: this.now() });
    } else {
      s.count++;
    }
    if (this._strikes.size > 10000) this.prune();
  }

  prune() {
    const now = this.now();
    for (const [address, s] of this._strikes) {
      if (now - s.since > this.windowMs) this._strikes.delete(address);
    }
  }
}
