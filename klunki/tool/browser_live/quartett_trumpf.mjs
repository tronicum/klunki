// Quartett (Trumpf) adapter for the browser live driver (KLD-089).
//
// Reads the screen from the semantics labels (German UI):
//   reveal: "X wählt Leistung", "X gewinnt den Stich" / "Gleichstand – …",
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
  const status = by(/ ist am Zug$|^Du bist am Zug|^Warte auf /)?.label ?? '';
  const cover = by(/^Ich bin (.+) – weiter$/);
  if (cover) return { kind: 'cover', name: cover.label.match(/^Ich bin (.+) – weiter$/)[1], node: cover, result, status };
  const picked = nodes.find((n) => /^(X|O) wählt (.+)$/.test(n.label) && !/…$/.test(n.label));
  const cont = nodes.find((n) => n.role === 'button' && /^Weiter$/.test(n.label));
  if (picked && cont) {
    const [, picker, stat] = picked.label.match(/^(X|O) wählt (.+)$/);
    const head = by(/^(X|O) gewinnt den Stich$|^Gleichstand/);
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
    return { kind: 'table', viewer, card, stats, counts, result, status };
  }
  return { kind: 'none', result, status };
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
