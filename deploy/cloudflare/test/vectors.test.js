// The relay protocol vectors shared with the Dart relay
// (packages/klunki_net/test/relay_vectors.json, run there by
// relay_vectors_test.dart against the real server). Every scenario runs
// twice: plainly, and with every room object evicted after each step
// (hibernation), which the Worker must survive.
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { describe, test } from 'node:test';

import { makeRelay } from './harness.js';

const { normalizeClubCode, normalizeRoomCode, parseClubCodes, parseRelayControl } = await import(
  '../src/protocol.js'
);

const vectors = JSON.parse(
  readFileSync(new URL('../../../packages/klunki_net/test/relay_vectors.json', import.meta.url), 'utf8'),
);

describe('protocol helpers', () => {
  test('normalizeRoomCode', () => {
    for (const [input, want] of vectors.normalizeRoomCode) assert.equal(normalizeRoomCode(input), want, input);
  });
  test('normalizeClubCode', () => {
    for (const [input, want] of vectors.normalizeClubCode) assert.equal(normalizeClubCode(input), want, input);
  });
  test('parseRelayControl', () => {
    for (const [line, want] of vectors.parseRelayControl) assert.equal(parseRelayControl(line) !== null, want, line);
  });
  test('codes file format', () => {
    assert.deepEqual(parseClubCodes(vectors.clubCodesFile.text), vectors.clubCodesFile.codes);
  });
});

async function run(scenario, { hibernate }) {
  const { open, rooms } = makeRelay(scenario.codes === undefined ? {} : { CLUB_CODES: scenario.codes });
  const peers = new Map();
  let room = null;
  let key = null; // the room's host key (KLD-120)
  const fill = (s) => {
    const r = room === null ? s : s.replaceAll('{roomLower}', room.toLowerCase()).replaceAll('{room}', room);
    return key === null ? r : r.replaceAll('{key}', key);
  };
  const fillJson = (v) =>
    typeof v === 'string'
      ? fill(v)
      : v !== null && typeof v === 'object'
        ? Object.fromEntries(Object.entries(v).map(([k, x]) => [k, fillJson(x)]))
        : v;

  for (const [i, step] of scenario.steps.entries()) {
    const at = `step ${i + 1} ${JSON.stringify(step).slice(0, 120)}`;
    if (step.open !== undefined) {
      peers.set(step.open, await open(step.open, fill(step.query)));
    } else if (step.room !== undefined) {
      const msg = await peers.get(step.room).nextJson();
      assert.equal(msg.t, 'relay.room', at);
      room = msg.code;
      key = msg.key ?? null;
      assert.equal(normalizeRoomCode(room), room, at);
    } else if (step.recv !== undefined) {
      assert.deepEqual(await peers.get(step.recv).nextJson(), fillJson(step.json), at);
    } else if (step.recvText !== undefined) {
      assert.equal(await peers.get(step.recvText).next(), fill(step.text), at);
    } else if (step.recvFill !== undefined) {
      assert.equal(await peers.get(step.recvFill).next(), 'x'.repeat(step.length), at);
    } else if (step.send !== undefined) {
      await peers.get(step.send).send(step.fill !== undefined ? 'x'.repeat(step.fill) : fill(step.text));
    } else if (step.sendBinary !== undefined) {
      await peers.get(step.sendBinary).send(new TextEncoder().encode('{"type":"ping","v":3}').buffer);
    } else if (step.closed !== undefined) {
      await peers.get(step.closed).expectClosed(step.code);
    } else if (step.close !== undefined) {
      await peers.get(step.close).close(step.code);
    } else {
      assert.fail(`unknown step ${at}`);
    }
    if (hibernate) rooms.hibernateAll();
  }
}

for (const hibernate of [false, true]) {
  describe(hibernate ? 'scenarios, hibernating after every step' : 'scenarios', () => {
    for (const scenario of vectors.scenarios) {
      test(scenario.name, () => run(scenario, { hibernate }));
    }
  });
}
