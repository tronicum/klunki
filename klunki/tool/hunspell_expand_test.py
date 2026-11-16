#!/usr/bin/env python3
"""Tests of the Hunspell affix expander (KLD-132) with hand-made affix files.

Run from klunki/:  python3 -I tool/hunspell_expand_test.py
"""
import os
import sys
import unittest

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import hunspell_expand as hx  # noqa: E402


def forms(aff, dic):
    d = hx.parse_aff(aff)
    out = set()
    for line in dic.strip().split('\n'):
        p = hx.parse_dic_line(d, line)
        if p:
            out |= d.expand(p[0], p[1])
    return out


class ExpandTest(unittest.TestCase):
    def test_suffix_strip_and_condition(self):
        aff = """
SFX S Y 3
SFX S 0 s [^sxy]
SFX S y ies [^aeiou]y
SFX S 0 s [aeiou]y
"""
        self.assertEqual(forms(aff, 'cat/S\nfly/S\nboy/S\nfox'), {'cat', 'cats', 'fly', 'flies', 'boy', 'boys', 'fox'})

    def test_prefix_and_cross_product(self):
        aff = """
PFX U Y 1
PFX U 0 un .

PFX R N 1
PFX R 0 re .

SFX S Y 1
SFX S 0 s .
"""
        self.assertEqual(forms(aff, 'do/US'), {'do', 'dos', 'undo', 'undos'})
        self.assertEqual(forms(aff, 'do/RS'), {'do', 'dos', 'redo'}, 'R is not crossed')

    def test_prefix_strip_and_condition(self):
        aff = """
PFX A Y 2
PFX A 0 im [bp]
PFX A 0 in [^bp]
"""
        self.assertEqual(forms(aff, 'posible/A\nutil/A'), {'posible', 'imposible', 'util', 'inutil'})

    def test_twofold_suffixes(self):
        aff = """
SFX A Y 1
SFX A 0 ing/B .

SFX B Y 1
SFX B 0 s .
"""
        self.assertEqual(forms(aff, 'walk/A'), {'walk', 'walking', 'walkings'})

    def test_needaffix_on_stem_and_on_affix(self):
        aff = """
NEEDAFFIX X
SFX S Y 1
SFX S 0 s .

SFX C Y 1
SFX C 0 a/XS .
"""
        self.assertEqual(forms(aff, 'foo/XS'), {'foos'})
        self.assertEqual(forms(aff, 'bar/C'), {'bar', 'baras'}, 'bara needs one more affix')

    def test_forbidden_and_onlyincompound(self):
        aff = """
FORBIDDENWORD !
ONLYINCOMPOUND O
SFX S Y 1
SFX S 0 s .
"""
        self.assertEqual(forms(aff, 'bad/!\npart/OS\nok/S'), {'parts', 'ok', 'oks'})

    def test_long_flags_and_af_aliases(self):
        aff = """
FLAG long
AF 2
AF AaBb # 1
AF Bb # 2
SFX Aa Y 1
SFX Aa 0 x/2 .

SFX Bb Y 1
SFX Bb 0 y .
"""
        self.assertEqual(forms(aff, 'w/1\nv/2\nu/AaBb'),
                         {'w', 'wx', 'wy', 'wxy', 'v', 'vy', 'u', 'ux', 'uy', 'uxy'})

    def test_numeric_flags(self):
        aff = """
FLAG num
SFX 101 Y 1
SFX 101 0 a .

SFX 7 Y 1
SFX 7 0 b .
"""
        self.assertEqual(forms(aff, 'x/101,7'), {'x', 'xa', 'xb'})

    def test_utf8_flags(self):
        aff = """
FLAG UTF-8
SFX ▲ Y 1
SFX ▲ o a o
"""
        self.assertEqual(forms(aff, 'niño/▲'), {'niño', 'niña'})

    def test_circumfix(self):
        aff = """
CIRCUMFIX C
PFX G Y 1
PFX G 0 ge/C .

SFX T Y 2
SFX T 0 t/C .
SFX T 0 st .
"""
        self.assertEqual(forms(aff, 'sag/GT'), {'sag', 'gesagt', 'sagst'})

    def test_prefix_from_a_suffix_continuation_class(self):
        aff = """
PFX P N 1
PFX P 0 al .

SFX S Y 1
SFX S 0 a/P .
"""
        self.assertEqual(forms(aff, 'kitab/S'), {'kitab', 'kitaba', 'alkitaba'})

    def test_ignore_escaped_slash_comments_and_morphology(self):
        aff = """
FLAG long
IGNORE َُ
AM 1
AM po:noun is:proper
SFX Aa Y 1
SFX Aa 0 َات .  # a comment
"""
        d = hx.parse_aff(aff)
        self.assertEqual(hx.parse_dic_line(d, 'كَتَب/Aa\t1'), ('كتب', {'Aa'}, 'po:noun is:proper'))
        self.assertEqual(hx.parse_dic_line(d, 'a\\/b'), ('a/b', set(), ''))
        self.assertIsNone(hx.parse_dic_line(d, '# comment'))
        self.assertEqual(d.expand('كتب', {'Aa'}), {'كتب', 'كتبات'})

    def test_condition_regex(self):
        self.assertEqual(hx.condition_regex('.'), '')
        self.assertEqual(hx.condition_regex('[^aeiou]y'), '[^aeiou]y')
        self.assertEqual(hx.condition_regex('a.c'), 'a.c')


if __name__ == '__main__':
    unittest.main()
