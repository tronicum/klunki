// Quartett (Trumpf) adapter for the browser live driver (KLD-089).
//
// Reads the screen from the semantics labels (German UI):
//   reveal: "X wählt Leistung", "X gewinnt die Runde" / "Gleichstand – Stechen!",
//           cue "O wählt als Nächstes" / "X wählt noch einmal" /
//           "Karten in den Topf (jetzt 2), X wählt noch einmal",
//           "X – gewinnt" / "O – verliert" above each card, the card ids
//           ("B3") under them (the picker's card on the left);
//   table:  "Deine Karte (X)", the card id, stat buttons
//           "höher gewinnt\nLeistung\n800 PS";
//   cover:  "Ich bin O – weiter"; grace: "Weiter in 4 s";
//   result: "Du gewinnst!" / "… gewinnt!" / "Unentschieden".

export const game = {
  id: 'quartett-trumpf',
  /** Menu tile / host setup label. */
  label: 'Quartett (Trumpf)',
};

const CARD_ID = /^[A-H][1-4]$/;

/** What the screen shows: {kind: 'reveal'|'table'|'cover'|'none', ...} plus result/overlay flags. */
export function observe(nodes, viewportWidth) {
  const by = (re) => nodes.find((n) => re.test(n.label));
  const result = !!by(/^(Du gewinnst!|.+ gewinnt!|Unentschieden)$/m) && !!by(/^Menü$/);
  // The status pill is the topmost match: in hot-seat (KLD-092) it reads
  // like the cue under the result ("O wählt als Nächstes").
  // "X wählt Leistung" on a reveal; not the cue ("X wählt noch einmal" / "O
  // wählt als Nächstes"), the hint ("X wählt …") or a named status line.
  const picked = nodes.find((n) => /^(X|O) wählt (.+)$/.test(n.label) && !/…$/.test(n.label)
    && !/ wählt (noch einmal|als Nächstes)$/.test(n.label));
  const status = nodes.filter((n) => / ist am Zug$|^Du bist am Zug|^Warte auf | wählt als Nächstes$| wählt noch einmal$|^Du wählst als Nächstes/.test(n.label)
    && !/^Karten in den Topf/.test(n.label) && (!picked || n.y < picked.y)).sort((a, b) => a.y - b.y)[0]?.label ?? '';
  // KLD-091: "noch 2 Runden" next to the status line while rounds are queued.
  const badge = by(/^noch \d+ Runden?$/)?.label ?? null;
  const cover = by(/^Ich bin (.+) – weiter$/);
  if (cover) {
    const reason = by(/^(.+) hat die Runde gewonnen$/)?.label.match(/^(.+) hat die Runde gewonnen$/)[1] ?? null;
    return { kind: 'cover', name: cover.label.match(/^Ich bin (.+) – weiter$/)[1], reason, node: cover, result, status };
  }
  // "Weiter – O wählt" (KLD-091: names the next picker).
  const cont = nodes.find((n) => n.role === 'button' && /^Weiter – (X|O) wählt$/.test(n.label));
  if (picked && cont) {
    const contNext = cont.label.match(/^Weiter – (X|O) wählt$/)[1];
    // The cue sits below the "X wählt PS" line (the status pill, above it,
    // can read the same in hot-seat).
    const cueNode = nodes.find((n) => n.y > picked.y
      && /^(X|O) wählt (noch einmal|als Nächstes)$|^Karten in den Topf \(jetzt \d+\), (X|O) wählt noch einmal$/.test(n.label));
    const cueMatch = cueNode?.label.match(/(X|O) wählt (noch einmal|als Nächstes)$/);
    const cue = cueMatch ? { next: cueMatch[1], again: cueMatch[2] === 'noch einmal', text: cueNode.label } : null;
    const [, picker, stat] = picked.label.match(/^(X|O) wählt (.+)$/);
    const head = by(/^(X|O) gewinnt die Runde$|^Gleichstand – Stechen!$/);
    const winner = head ? (head.label.match(/^(X|O) gewinnt/)?.[1] ?? null) : undefined;
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
  const caption = by(/^Deine Karte \((X|O)\)$/);
  if (caption) {
    const viewer = caption.label.match(/\((X|O)\)/)[1];
    const card = nodes.filter((n) => CARD_ID.test(n.label) && n.y > caption.y).sort((a, b) => a.y - b.y)[0]?.label;
    const stats = nodes.filter((n) => n.role === 'button' && /^(höher|niedriger) gewinnt\n/.test(n.label))
      .map((n) => ({ node: n, stat: n.label.split('\n')[1], enabled: !n.disabled }));
    const counts = Object.fromEntries(nodes.filter((n) => /^(X|O): \d+ Karten?$/.test(n.label))
      .map((n) => { const m = n.label.match(/^(X|O): (\d+)/); return [m[1], Number(m[2])]; }));
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
 * ("O wählt als Nächstes" / "X wählt noch einmal"), not "X ist am Zug".
 */
export function revealProblems(o, me) {
  const p = [];
  const next = nextPicker(o.rec);
  if (!o.cue) p.push('no "… wählt als Nächstes / noch einmal" cue');
  else {
    if (o.cue.next !== next) p.push(`cue "${o.cue.text}", ${next} picks next`);
    if (o.cue.again !== (next === o.rec.picker)) p.push(`cue "${o.cue.text}" after ${show(o.rec)}`);
  }
  if (o.contNext !== next) p.push(`button "Weiter – ${o.contNext} wählt", ${next} picks next`);
  if (!me) {
    const want = next === o.rec.picker ? `${next} wählt noch einmal` : `${next} wählt als Nächstes`;
    const wantNamed = next === o.rec.picker ? `(${next}) wählt noch einmal` : `(${next}) wählt als Nächstes`;
    if (o.status !== want && !o.status.endsWith(wantNamed)) p.push(`hot-seat status "${o.status}" under ${show(o.rec)}, want "${want}"`);
    if (o.badge) p.push(`badge "${o.badge}" in hot-seat`);
  }
  if (me) {
    const follows = /\) wählt als Nächstes$|^Du wählst als Nächstes/.test(o.status);
    if (o.queued) {
      if (!o.badge) p.push(`rounds queued ("${o.queued}") but no "noch n Runden" badge`);
      const want = next === me ? `Du wählst als Nächstes (${me})` : null;
      if (want ? o.status !== want : !o.status.endsWith(`(${next}) wählt als Nächstes`)) {
        p.push(`status "${o.status}" while an older trick is shown, ${next} picks after it`);
      }
    } else {
      if (o.badge) p.push(`badge "${o.badge}" but nothing queued`);
      if (follows) p.push(`status "${o.status}" on the newest trick (should be live)`);
    }
  }
  return p;
}

/** Stable identity of a reveal for "is this a new one?". */
export const revealKey = (o) => o.key;

/** Display string of a trick record. */
export function show(rec) {
  const w = rec.winner === null ? 'tie' : rec.winner === undefined ? '??' : `${rec.winner} wins`;
  return `${rec.picker} ${rec.stat} → ${w} (X:${rec.cards.X} O:${rec.cards.O})`;
}

/** Who picks after [rec]: the winner, or the picker after a tie. */
export const nextPicker = (rec) => rec.winner ?? rec.picker;

/** Chooses a stat from the table [o]: random or the first/last row. */
export function choose(o, rng) {
  const enabled = o.stats.filter((s) => s.enabled);
  if (enabled.length === 0) return null;
  return enabled[Math.floor(rng() * enabled.length)];
}
