// Quartett (Trumpf) adapter for the browser live driver (KLD-089).
//
// Players are named (KLD-103/106: no X / O on screen). The driver passes the
// two names; internally the first player (who starts) is 'X' and the second
// 'O', and every label is mapped back by name. Reads the screen from the
// semantics labels (German UI):
//   reveal: "Anna wählt Leistung", "Anna gewinnt die Runde" /
//           "Gleichstand – Stechen!", cue "Ben wählt als Nächstes" /
//           "Anna wählt noch einmal" /
//           "Karten in den Topf (jetzt 2), Anna wählt noch einmal",
//           "Anna – gewinnt" / "Ben – verliert" above each card, the card
//           ids ("B3") under them (the picker's card on the left);
//   table:  "Deine Karte (Anna)", the card id, stat buttons
//           "höher gewinnt\nLeistung\n800 PS", counts "Anna: 16 Karten";
//   choose (KLD-100, 2–3 cards left): "Du hast nur noch 3 Karten – wähle eine
//           aus." (picker) / "Anna spielt Leistung. Wähle deine Karte."
//           (defender), one button per card;
//   cover:  "Ich bin Ben – weiter" with a reason: "Ben hat die Runde
//           gewonnen" / "Ben wählt noch einmal" / "Anna spielt Leistung.
//           Wähle deine Karte."; grace: "Weiter in 4 s";
//   result: "Du gewinnst!" / "… gewinnt!" / "Unentschieden".

export const game = {
  id: 'quartett-trumpf',
  /** Menu tile / room setup label. */
  label: 'Quartett (Trumpf)',
};

const CARD_ID = /^[A-H][1-4]$/;
const esc = (s) => s.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');

/**
 * What the screen shows: {kind: 'reveal'|'table'|'choose'|'cover'|'none', ...}
 * plus result/overlay flags. [names] = {X: first player's name, O: second's}.
 */
export function observe(nodes, viewportWidth, names) {
  const P = `(${esc(names.X)}|${esc(names.O)})`;
  const slot = (name) => (name === names.X ? 'X' : name === names.O ? 'O' : `?${name}`);
  const re = (s, flags) => new RegExp(s.replaceAll('{P}', P), flags);
  const by = (r) => nodes.find((n) => r.test(n.label));
  const result = !!by(/^(Du gewinnst!|.+ gewinnt!|Unentschieden)$/m) && !!by(/^Menü$/);
  // "Anna wählt Leistung" on a reveal; not the cue ("… wählt noch einmal" /
  // "… wählt als Nächstes"), the hint ("Anna wählt …") or a choice.
  const pickedRe = re('^{P} wählt (.+)$');
  const picked = nodes.find((n) => pickedRe.test(n.label) && !/…$/.test(n.label)
    && !/ wählt (noch einmal|als Nächstes|eine Karte)$/.test(n.label));
  // The status pill is the topmost match: in hot-seat (KLD-092) it reads
  // like the cue under the result ("Ben wählt als Nächstes").
  const status = nodes.filter((n) => / ist am Zug$|^Du bist am Zug|^Warte auf | wählt als Nächstes$| wählt noch einmal$|^Du wählst als Nächstes/.test(n.label)
    && !/^Karten in den Topf/.test(n.label) && (!picked || n.y < picked.y)).sort((a, b) => a.y - b.y)[0]?.label ?? '';
  // KLD-091: "noch 2 Runden" next to the status line while rounds are queued.
  const badge = by(/^noch \d+ Runden?$/)?.label ?? null;
  const cover = by(re('^Ich bin {P} – weiter$'));
  if (cover) {
    const won = by(re('^{P} hat die Runde gewonnen$'));
    const again = by(re('^{P} wählt noch einmal$'));
    const defend = by(re('^{P} spielt (.+)\\. Wähle deine Karte\\.$'));
    const reason = won ? { kind: 'won', player: slot(won.label.match(re('^{P}'))[1]) }
      : again ? { kind: 'again', player: slot(again.label.match(re('^{P}'))[1]) }
        : defend ? { kind: 'defend', picker: slot(defend.label.match(re('^{P}'))[1]), stat: defend.label.match(/ spielt (.+)\. Wähle/)[1] }
          : null;
    return { kind: 'cover', name: slot(cover.label.match(re('^Ich bin {P}'))[1]), reason, node: cover, result, status };
  }
  // "Weiter – Ben wählt" (KLD-091: names the next picker).
  const contRe = re('^Weiter – {P} wählt$');
  const cont = nodes.find((n) => n.role === 'button' && contRe.test(n.label));
  if (picked && cont) {
    const contNext = slot(cont.label.match(contRe)[1]);
    // The cue sits below the "Anna wählt PS" line (the status pill, above
    // it, can read the same in hot-seat).
    const cueRe = re('{P} wählt (noch einmal|als Nächstes)$');
    const cueNode = nodes.find((n) => n.y > picked.y
      && (re('^{P} wählt (noch einmal|als Nächstes)$').test(n.label)
        || re('^Karten in den Topf \\(jetzt \\d+\\), {P} wählt noch einmal$').test(n.label)));
    const cueMatch = cueNode?.label.match(cueRe);
    const cue = cueMatch ? { next: slot(cueMatch[1]), again: cueMatch[2] === 'noch einmal', text: cueNode.label } : null;
    const [, pickerName, stat] = picked.label.match(pickedRe);
    const picker = slot(pickerName);
    const head = by(re('^{P} gewinnt die Runde$|^Gleichstand – Stechen!$'));
    const winnerName = head?.label.match(re('^{P} gewinnt'))?.[1];
    const winner = head ? (winnerName ? slot(winnerName) : null) : undefined;
    const half = viewportWidth / 2;
    // Card ids below the summary line, left = picker's side.
    const ids = nodes.filter((n) => CARD_ID.test(n.label) && n.y > picked.y).sort((a, b) => a.x - b.x);
    const left = ids.find((n) => n.x < half)?.label ?? '?';
    const right = ids.find((n) => n.x >= half)?.label ?? '?';
    const other = picker === 'X' ? 'O' : 'X';
    const grace = by(/^Weiter in \d+ s$/);
    const queued = by(/ hat gewählt: /);
    return {
      kind: 'reveal',
      rec: {
        picker,
        stat,
        winner, // 'X' | 'O' | null (tie) | undefined (headline not found)
        cards: { [picker]: left, [other]: right },
      },
      key: `${picker}|${stat}|${winner}|X:${picker === 'X' ? left : right}|O:${picker === 'X' ? right : left}`,
      grace: grace?.label ?? null,
      queued: queued?.label ?? null,
      cont,
      contNext,
      cue,
      badge,
      result,
      status,
    };
  }
  // KLD-100: the low player chooses one of its 2–3 cards.
  const chooseHint = by(/^Du hast nur noch \d+ Karten – wähle eine aus\.$/) ?? by(re('^{P} spielt (.+)\\. Wähle deine Karte\\.$'));
  if (chooseHint) {
    const cards = nodes.filter((n) => n.role === 'button' && n.y > chooseHint.y && !n.disabled
      && n.label.split('\n').some((l) => CARD_ID.test(l.trim())));
    if (cards.length) {
      const defending = !/^Du hast nur noch/.test(chooseHint.label);
      return { kind: 'choose', defending, hint: chooseHint.label, cards, result, status, badge };
    }
  }
  const caption = by(re('^Deine Karte \\({P}\\)$'));
  if (caption) {
    const viewer = slot(caption.label.match(re('\\({P}\\)'))[1]);
    const card = nodes.filter((n) => CARD_ID.test(n.label) && n.y > caption.y).sort((a, b) => a.y - b.y)[0]?.label;
    const stats = nodes.filter((n) => n.role === 'button' && /^(höher|niedriger) gewinnt\n/.test(n.label))
      .map((n) => ({ node: n, stat: n.label.split('\n')[1], enabled: !n.disabled }));
    const countRe = re('^{P}: (\\d+) Karten?$');
    const counts = Object.fromEntries(nodes.filter((n) => countRe.test(n.label))
      .map((n) => { const m = n.label.match(countRe); return [slot(m[1]), Number(m[2])]; }));
    return { kind: 'table', viewer, card, stats, counts, result, status, badge };
  }
  return { kind: 'none', result, status, badge };
}

/**
 * KLD-091 checks on a reveal [o] (list of problems): the cue and "Weiter"
 * name the next picker; on a network device [me] the status line follows
 * the reveal exactly while rounds are queued behind it (the "… hat gewählt"
 * notice is up) and carries the "noch n Runden" badge, else it is live.
 * KLD-092, hot-seat (no [me]): the status line reads like the cue
 * ("Ben wählt als Nächstes" / "Anna wählt noch einmal"), not "Anna ist am Zug".
 */
export function revealProblems(o, me, names) {
  const p = [];
  const next = nextPicker(o.rec);
  const N = names[next];
  if (!o.cue) p.push('no "… wählt als Nächstes / noch einmal" cue');
  else {
    if (o.cue.next !== next) p.push(`cue "${o.cue.text}", ${N} picks next`);
    if (o.cue.again !== (next === o.rec.picker)) p.push(`cue "${o.cue.text}" after ${show(o.rec, names)}`);
  }
  if (o.contNext !== next) p.push(`button "Weiter – ${names[o.contNext] ?? o.contNext} wählt", ${N} picks next`);
  if (!me) {
    const want = next === o.rec.picker ? `${N} wählt noch einmal` : `${N} wählt als Nächstes`;
    if (o.status !== want) p.push(`hot-seat status "${o.status}" under ${show(o.rec, names)}, want "${want}"`);
    if (o.badge) p.push(`badge "${o.badge}" in hot-seat`);
  }
  if (me) {
    const follows = / wählt als Nächstes$|^Du wählst als Nächstes/.test(o.status);
    if (o.queued) {
      if (!o.badge) p.push(`rounds queued ("${o.queued}") but no "noch n Runden" badge`);
      const want = next === me ? 'Du wählst als Nächstes' : `${N} wählt als Nächstes`;
      if (o.status !== want) p.push(`status "${o.status}" while an older trick is shown, ${N} picks after it`);
    } else {
      if (o.badge) p.push(`badge "${o.badge}" but nothing queued`);
      if (follows) p.push(`status "${o.status}" on the newest trick (should be live)`);
    }
  }
  return p;
}

/** Stable identity of a reveal for "is this a new one?". */
export const revealKey = (o) => o.key;

/** Display string of a trick record ([names] maps 'X'/'O' to the names). */
export function show(rec, names = { X: 'X', O: 'O' }) {
  const w = rec.winner === null ? 'tie' : rec.winner === undefined ? '??' : `${names[rec.winner]} wins`;
  return `${names[rec.picker]} ${rec.stat} → ${w} (${names.X}:${rec.cards.X} ${names.O}:${rec.cards.O})`;
}

/** Who picks after [rec]: the winner, or the picker after a tie. */
export const nextPicker = (rec) => rec.winner ?? rec.picker;

/** Chooses a stat from the table [o]: random or the first/last row. */
export function choose(o, rng) {
  const enabled = o.stats.filter((s) => s.enabled);
  if (enabled.length === 0) return null;
  return enabled[Math.floor(rng() * enabled.length)];
}

/** KLD-100: chooses one of the cards of a choose view [o]. */
export function chooseCard(o, rng) {
  return o.cards[Math.floor(rng() * o.cards.length)];
}
