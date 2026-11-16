"""A small Hunspell affix expander (KLD-132), standard library only.

Turns a Hunspell dictionary (`.aff` rules + `.dic` stems with flags) into the full forms it accepts, for the
Wortgewandt word lists (klunki/tool/build_word_lists.py). Reads the files as data; nothing from them is run.

Supported (what the es, ar and fa sources use):
  * FLAG default (one character), UTF-8 (one code point), long (two characters), num (comma separated numbers);
  * AF flag aliases (a number instead of the flag string, in the .dic and in affix continuation classes) and
    AM morphology aliases (kept as the entry's morphology, so a builder can filter on it);
  * PFX / SFX with strip, append, condition (characters, `.`, `[...]`, `[^...]`) and cross product (Y / N);
  * continuation classes on affixes: a second suffix on a suffixed form (Hunspell's "twofold" suffixes), a prefix
    allowed by a suffix's continuation class, NEEDAFFIX on a stem or an affix (the form only counts with one more
    affix), ONLYINCOMPOUND and FORBIDDENWORD (never a form of its own), CIRCUMFIX (a circumfix prefix and suffix
    only count together);
  * IGNORE (characters dropped from stems and affixes).
Not supported, because the word lists do not want them: compounding (COMPOUND*), and two prefixes in a row
(COMPLEXPREFIXES). Suggestion settings (TRY, KEY, REP, MAP …) are irrelevant and skipped.
"""

import re


class Affix:
    __slots__ = ('kind', 'flag', 'cross', 'strip', 'add', 'cont', 'cond', 'morph', '_re')

    def __init__(self, kind, flag, cross, strip, add, cont, cond, morph):
        self.kind = kind
        self.flag = flag
        self.cross = cross
        self.strip = strip
        self.add = add
        self.cont = cont
        self.cond = cond
        self.morph = morph
        pattern = condition_regex(cond)
        self._re = re.compile(('^' + pattern) if kind == 'PFX' else (pattern + '$'))

    def applies(self, word):
        if self.kind == 'PFX':
            return word.startswith(self.strip) and len(word) > len(self.strip) - 1 and self._re.search(word) is not None
        return word.endswith(self.strip) and self._re.search(word) is not None

    def apply(self, word):
        if self.kind == 'PFX':
            return self.add + word[len(self.strip):]
        return (word[:len(word) - len(self.strip)] if self.strip else word) + self.add

    def __repr__(self):
        return f'{self.kind} {self.flag} {self.strip or 0} {self.add or 0}/{"".join(sorted(self.cont))} {self.cond}'


def condition_regex(cond):
    """A Hunspell affix condition as a Python regular expression (without anchors)."""
    if cond in ('', '.'):
        return ''
    out = []
    i = 0
    while i < len(cond):
        c = cond[i]
        if c == '[':
            j = cond.index(']', i + 1)
            body = cond[i + 1:j]
            neg = body.startswith('^')
            if neg:
                body = body[1:]
            out.append('[' + ('^' if neg else '') + ''.join(re.escape(x) for x in body) + ']')
            i = j + 1
        elif c == '.':
            out.append('.')
            i += 1
        else:
            out.append(re.escape(c))
            i += 1
    return ''.join(out)


class Dictionary:
    """The rules of one `.aff` file."""

    def __init__(self):
        self.flag_mode = 'char'
        self.af = []  # AF aliases, 1-based in the files
        self.am = []  # AM aliases, 1-based
        self.pfx = {}
        self.sfx = {}
        self.needaffix = None
        self.forbidden = None
        self.onlyincompound = None
        self.circumfix = None
        self.ignore = ''

    # --- flags

    def split_flags(self, s):
        """The flags of a flag string (no AF lookup)."""
        if not s:
            return []
        if self.flag_mode == 'long':
            return [s[i:i + 2] for i in range(0, len(s) - 1, 2)]
        if self.flag_mode == 'num':
            return [x for x in s.split(',') if x]
        return list(s)

    def flags(self, s):
        """The flags of a flag field of the .dic or of a continuation class: an AF alias number or a flag string."""
        if self.af and s.isdigit():
            n = int(s)
            if 1 <= n <= len(self.af):
                return set(self.af[n - 1])
            raise ValueError(f'unknown AF alias {s}')
        return set(self.split_flags(s))

    def morph(self, fields):
        """Morphology fields, AM aliases resolved."""
        out = []
        for f in fields:
            if self.am and f.isdigit() and 1 <= int(f) <= len(self.am):
                out.append(self.am[int(f) - 1])
            else:
                out.append(f)
        return ' '.join(out)

    def strip_ignored(self, s):
        return s.translate({ord(c): None for c in self.ignore}) if self.ignore else s

    # --- expansion

    def _allowed(self, flags):
        return not (flags & {self.needaffix, self.forbidden, self.onlyincompound} - {None})

    def expand(self, stem, flags):
        """Every form of [stem] with [flags] (a set): the stem itself, its prefixed and suffixed forms, both
        combined (cross product), second-level suffixes (continuation classes)."""
        out = set()
        if self._allowed(flags) and self.circumfix not in flags:
            out.add(stem)
        circ = self.circumfix
        # Suffixed forms: (word, the affixes' cross flag, continuation flags, needs another affix, circumfix).
        suffixed = []
        for f in flags:
            for a in self.sfx.get(f, ()):
                if not a.applies(stem):
                    continue
                w = a.apply(stem)
                need = self.needaffix in a.cont if self.needaffix else False
                is_circ = circ is not None and circ in a.cont
                suffixed.append((w, a.cross, a.cont, need, is_circ))
                if not need and not is_circ and self.forbidden not in a.cont and self.onlyincompound not in a.cont:
                    out.add(w)
                # Twofold: suffixes named in the continuation class.
                for f2 in a.cont:
                    for b in self.sfx.get(f2, ()):
                        if not b.applies(w):
                            continue
                        w2 = b.apply(w)
                        need2 = self.needaffix in b.cont if self.needaffix else False
                        circ2 = is_circ or (circ is not None and circ in b.cont)
                        suffixed.append((w2, a.cross and b.cross, a.cont | b.cont, need2, circ2))
                        if not need2 and not circ2 and self.forbidden not in b.cont:
                            out.add(w2)
        # Prefixes on the stem and, crossed, on the suffixed forms.
        for f in flags:
            for p in self.pfx.get(f, ()):
                p_need = self.needaffix in p.cont if self.needaffix else False
                p_circ = circ is not None and circ in p.cont
                if p.applies(stem) and not p_need and not p_circ:
                    out.add(p.apply(stem))
                if not p.cross:
                    continue
                for (w, cross, cont, need, s_circ) in suffixed:
                    if not cross or not p.applies(w):
                        continue
                    if p_circ != s_circ:
                        continue  # a circumfix needs both halves
                    out.add(p.apply(w))
        # Prefixes allowed by a suffix's continuation class.
        for (w, cross, cont, need, s_circ) in suffixed:
            for f in cont:
                for p in self.pfx.get(f, ()):
                    if not p.applies(w):
                        continue
                    p_circ = circ is not None and circ in p.cont
                    if p_circ != s_circ:
                        continue
                    out.add(p.apply(w))
        return out


def parse_aff(text):
    d = Dictionary()
    pending = {}  # (kind, flag) -> (cross, remaining count)
    for raw in text.splitlines():
        line = raw.strip()
        if not line or line.startswith('#'):
            continue
        parts = line.split()
        key = parts[0]
        if key == 'FLAG' and len(parts) > 1:
            d.flag_mode = {'long': 'long', 'num': 'num', 'UTF-8': 'char'}.get(parts[1], 'char')
        elif key == 'AF' and len(parts) > 1:
            if len(parts) == 2 and parts[1].isdigit() and not d.af and not pending.get('AF'):
                pending['AF'] = int(parts[1])
            else:
                d.af.append(d.split_flags(parts[1]))
        elif key == 'AM' and len(parts) > 1:
            if len(parts) == 2 and parts[1].isdigit() and not d.am and not pending.get('AM'):
                pending['AM'] = int(parts[1])
            else:
                d.am.append(' '.join(parts[1:]))
        elif key == 'NEEDAFFIX' and len(parts) > 1:
            d.needaffix = parts[1]
        elif key == 'FORBIDDENWORD' and len(parts) > 1:
            d.forbidden = parts[1]
        elif key == 'ONLYINCOMPOUND' and len(parts) > 1:
            d.onlyincompound = parts[1]
        elif key == 'CIRCUMFIX' and len(parts) > 1:
            d.circumfix = parts[1]
        elif key == 'IGNORE' and len(parts) > 1:
            d.ignore = parts[1]
        elif key in ('PFX', 'SFX') and len(parts) >= 4:
            flag = parts[1]
            if (key, flag) not in pending and parts[2] in ('Y', 'N') and parts[3].isdigit() and len(parts) <= 5:
                pending[(key, flag)] = (parts[2] == 'Y', int(parts[3]))
                (d.pfx if key == 'PFX' else d.sfx).setdefault(flag, [])
                continue
            cross, left = pending.get((key, flag), (True, 0))
            if left <= 0:
                continue
            pending[(key, flag)] = (cross, left - 1)
            strip = '' if parts[2] == '0' else d.strip_ignored(parts[2])
            add_field = parts[3]
            add, _, cont = add_field.partition('/')
            add = '' if add == '0' else d.strip_ignored(add)
            cond = parts[4] if len(parts) > 4 and not parts[4].startswith('#') else '.'
            morph_fields = []
            for x in parts[5:]:
                if x.startswith('#'):
                    break
                morph_fields.append(x)
            (d.pfx if key == 'PFX' else d.sfx)[flag].append(
                Affix(key, flag, cross, strip, add, d.flags(cont) if cont else set(), cond, d.morph(morph_fields)))
    return d


def parse_dic_line(d, line):
    """(stem, flags, morphology) of one .dic line, or None for a comment, the count line or an empty line.

    A stem may contain an escaped slash (`\\/`); flags follow the first unescaped slash; morphology fields follow
    a tab or a space (AM aliases resolved)."""
    line = line.rstrip('\n').rstrip('\r')
    if not line.strip() or line.startswith('#'):
        return None
    fields = re.split(r'[\t ]+', line.strip())
    head, rest = fields[0], fields[1:]
    stem, flags = head, ''
    i = 0
    while i < len(head):
        if head[i] == '\\' and i + 1 < len(head):
            i += 2
            continue
        if head[i] == '/':
            stem, flags = head[:i], head[i + 1:]
            break
        i += 1
    stem = stem.replace('\\/', '/')
    morph = []
    for x in rest:
        if x.startswith('#'):
            break
        morph.append(x)
    return d.strip_ignored(stem), d.flags(flags) if flags else set(), d.morph(morph)
