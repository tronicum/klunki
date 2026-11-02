// One relay room = one Durable Object (named by its room code), holding the
// host's and the guest's WebSocket. Port of `_Room` in
// packages/klunki_net/lib/src/relay/relay_server.dart (KLD-114).
//
// It uses the WebSocket Hibernation API (`ctx.acceptWebSocket` and the
// `webSocketMessage` / `webSocketClose` / `webSocketError` handlers): while
// nothing happens (a host waiting for its guest) the object is evicted from
// memory and costs nothing, and the WebSockets stay open. Because of that the
// object keeps NO state in memory: who is host and guest comes from the
// socket tags, everything else from each socket's attachment
// (`{role, code, active, gone}`), which survives hibernation.

import {
  closeGoingAway,
  closeNormal,
  closePolicyViolation,
  parseRelayControl,
  relayClosed,
  relayControl,
  relayError,
  relayKick,
  relayLeft,
  relayPeer,
  relayRoom,
} from './protocol.js';

/** Defaults of the Dart relay (`RelayServer.start`). */
export const defaultIdleTimeoutMs = 10 * 60 * 1000;
export const defaultMaxLineLength = 256 * 1024;

const OPEN = 1;

function positive(value, fallback) {
  const n = Number(value);
  return Number.isFinite(n) && n > 0 ? n : fallback;
}

function attachment(ws) {
  return ws.deserializeAttachment() ?? {};
}

function mark(ws, fields) {
  ws.serializeAttachment({ ...attachment(ws), ...fields });
}

function send(ws, line) {
  try {
    if (ws.readyState === OPEN) ws.send(line);
  } catch {
    // the socket is going away: nothing to tell it
  }
}

function close(ws, code) {
  try {
    ws.close(code, '');
  } catch {
    // already closed
  }
}

export class RelayRoom {
  constructor(ctx, env) {
    this.ctx = ctx;
    this.idleTimeoutMs = positive(env?.IDLE_TIMEOUT_SECONDS, defaultIdleTimeoutMs / 1000) * 1000;
    this.maxLineLength = positive(env?.MAX_LINE_LENGTH, defaultMaxLineLength);
  }

  /** The current host socket, or null (none, or it is leaving). */
  host() {
    return this.ctx.getWebSockets('host').find((ws) => ws.readyState === OPEN && !attachment(ws).gone) ?? null;
  }

  /** The current guest socket, or null. */
  guest() {
    return this.ctx.getWebSockets('guest').find((ws) => ws.readyState === OPEN && !attachment(ws).gone) ?? null;
  }

  /**
   * Called by the Worker only (Durable Objects have no public URL):
   * header `X-Klunki-Op: create|join`, `X-Klunki-Room: CODE`. Answers 101
   * with the client's WebSocket, or 409 (create: code in use; join: room
   * full) / 404 (join: no room) without one; the Worker turns those into
   * the relay's `relay.error` messages.
   */
  async fetch(request) {
    const op = request.headers.get('X-Klunki-Op');
    const code = request.headers.get('X-Klunki-Room') ?? '';
    if (op === 'create') {
      if (this.host() !== null) return new Response(null, { status: 409 });
      const [client, server] = Object.values(new WebSocketPair());
      this.ctx.acceptWebSocket(server, ['host']);
      server.serializeAttachment({ role: 'host', code, active: Date.now() });
      send(server, relayControl(relayRoom, { code }));
      await this.ctx.storage.setAlarm(Date.now() + this.idleTimeoutMs);
      return new Response(null, { status: 101, webSocket: client });
    }
    if (op === 'join') {
      const host = this.host();
      if (host === null) return new Response(null, { status: 404 });
      if (this.guest() !== null) return new Response(null, { status: 409 });
      const [client, server] = Object.values(new WebSocketPair());
      this.ctx.acceptWebSocket(server, ['guest']);
      server.serializeAttachment({ role: 'guest' });
      this.touch(host);
      send(host, relayControl(relayPeer));
      return new Response(null, { status: 101, webSocket: client });
    }
    return new Response(null, { status: 400 });
  }

  // ------------------------------------------------- hibernation handlers

  webSocketMessage(ws, message) {
    const a = attachment(ws);
    if (a.gone) return;
    if (a.role === 'host') this.fromHost(ws, message);
    else if (a.role === 'guest') this.fromGuest(ws, message);
  }

  webSocketClose(ws, _code, _reason, _wasClean) {
    // Complete the closing handshake (needed with older compatibility
    // dates; harmless otherwise).
    close(ws, closeNormal);
    this.gone(ws, 'disconnected');
  }

  webSocketError(ws, _error) {
    this.gone(ws, 'connection failed');
  }

  /** Idle expiry: no forwarded frame for `idleTimeoutMs` closes the room. */
  async alarm() {
    const host = this.host();
    if (host === null) return this.shutDown('room expired (idle)');
    const active = attachment(host).active ?? 0;
    if (Date.now() - active >= this.idleTimeoutMs) return this.shutDown('room expired (idle)');
    await this.ctx.storage.setAlarm(active + this.idleTimeoutMs);
  }

  // ------------------------------------------------------------ forwarding

  /** Checks one frame; returns the line to forward, or null after refusing. */
  check(ws, frame) {
    if (typeof frame !== 'string') {
      this.violation(ws, 'binary frames are not relayed');
      return null;
    }
    if (frame.length > this.maxLineLength) {
      this.violation(ws, `line too long (max ${this.maxLineLength} characters)`);
      return null;
    }
    return frame;
  }

  fromHost(host, frame) {
    const line = this.check(host, frame);
    if (line === null) return;
    this.touch(host);
    const control = parseRelayControl(line);
    if (control !== null) {
      if (control.t === relayKick) this.dropGuest();
      return; // other control lines from the host are ignored
    }
    const guest = this.guest();
    if (guest !== null) send(guest, line);
  }

  fromGuest(ws, frame) {
    const line = this.check(ws, frame);
    if (line === null) return;
    if (parseRelayControl(line) !== null) {
      return this.violation(ws, 'relay control messages are not allowed from a guest');
    }
    const host = this.host();
    if (host === null) return;
    this.touch(host);
    send(host, line);
  }

  /** Marks the room active (in the host's attachment: survives hibernation). */
  touch(host) {
    mark(host, { active: Date.now() });
  }

  /**
   * A rule broken by `ws`: `relay.error`, then close. The host breaking a
   * rule closes the room; a guest only loses its own connection.
   */
  violation(ws, message) {
    send(ws, relayControl(relayError, { message }));
    if (attachment(ws).role === 'host') {
      this.shutDown('host broke the relay rules');
    } else {
      this.guestGone(ws, message);
      close(ws, closePolicyViolation);
    }
  }

  /** The host asked to drop the guest; no `relay.left` follows. */
  dropGuest() {
    const guest = this.guest();
    if (guest === null) return;
    mark(guest, { gone: true });
    close(guest, closeNormal);
  }

  /** A socket's connection ended (closed by the client, or failed). */
  gone(ws, what) {
    const a = attachment(ws);
    if (a.gone) return;
    if (a.role === 'host') this.shutDown(`host ${what === 'disconnected' ? 'left' : 'connection failed'}`);
    else if (a.role === 'guest') this.guestGone(ws, `guest ${what}`);
  }

  guestGone(ws, reason) {
    if (attachment(ws).gone) return;
    mark(ws, { gone: true });
    const host = this.host();
    if (host !== null) send(host, relayControl(relayLeft, { reason }));
  }

  /**
   * Closes the room: everyone still connected gets `relay.closed {reason}`,
   * then the connection is closed. Nothing is left in storage.
   */
  shutDown(reason) {
    const sockets = [...this.ctx.getWebSockets('host'), ...this.ctx.getWebSockets('guest')];
    for (const ws of sockets) {
      if (attachment(ws).gone) continue;
      mark(ws, { gone: true });
      send(ws, relayControl(relayClosed, { reason }));
      close(ws, closeGoingAway);
    }
    return this.ctx.storage.deleteAlarm();
  }
}
