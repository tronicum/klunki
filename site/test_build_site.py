#!/usr/bin/env python3
"""Tests for site/build_site.py (KLD-115). Stdlib only.

    python3 -I site/test_build_site.py
"""
import json
import os
import sys
import tempfile
import unittest

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import build_site  # noqa: E402


def fixture_arb_dir(tmp: str) -> str:
    """Copies of the real ARB files plus the help keys from the fixture."""
    with open(os.path.join(HERE, 'testdata', 'help_fixture.json'), encoding='utf-8') as f:
        fixture = json.load(f)
    for lang in build_site.LANGS:
        arb = build_site.load_arb(lang)
        arb = {k: v for k, v in arb.items() if not k.lstrip('@').startswith('help')}
        arb.update(fixture[lang])
        with open(os.path.join(tmp, f'app_{lang}.arb'), 'w', encoding='utf-8') as f:
            json.dump(arb, f, ensure_ascii=False)
    return tmp


class FaqTest(unittest.TestCase):
    def test_blocks_in_file_order(self):
        with tempfile.TemporaryDirectory() as tmp:
            arb = build_site.load_arb('de', fixture_arb_dir(tmp))
        heading, items = build_site.faq_blocks(arb)
        self.assertEqual(heading, 'So spielt ihr zusammen')
        self.assertEqual([q for q, _ in items], ['Auf einem Gerät', 'Im WLAN'])
        html = build_site.faq_html(arb, 'de')
        self.assertIn('<details><summary>Im WLAN</summary>', html)
        self.assertIn('<ul><li>Raum starten</li><li>Raum beitreten</li></ul>', html)
        self.assertIn('support/#de', html)

    def test_without_help_keys_only_the_support_link(self):
        html = build_site.faq_html({'menuGameChess': 'Schach'}, 'en')
        self.assertNotIn('<details>', html)
        self.assertIn('support/#en', html)

    def test_placeholders_are_skipped(self):
        _, items = build_site.faq_blocks({'helpXTitle': 'Q', 'helpXBody': 'Hallo {player}'})
        self.assertEqual(items, [('Q', [])])


class StoresTest(unittest.TestCase):
    def test_closed_without_urls(self):
        html = build_site.stores_html('de', '', '')
        self.assertEqual(html.count('Geschlossene Beta'), 2)
        self.assertNotIn('<a ', html)

    def test_open_with_https_urls_only(self):
        v = build_site.landing_values({'CONTACT_EMAIL': 'a@example.org'},
                                      {'KLUNKI_IOS_BETA_URL': 'https://testflight.apple.com/join/x',
                                       'KLUNKI_ANDROID_URL': 'http://insecure.example'})
        self.assertIn('href="https://testflight.apple.com/join/x"', v['STORES_EN'])
        self.assertIn('Closed beta', v['STORES_EN'])  # Android: not https
        self.assertIn('mailto:a@example.org?subject=Klunki%20Beta%3A%20Android', v['BETA_MAIL_ANDROID_DE'])


class BuildTest(unittest.TestCase):
    def test_build_into_a_directory(self):
        with tempfile.TemporaryDirectory() as tmp:
            os.makedirs(os.path.join(tmp, 'arb'))
            arb_dir = fixture_arb_dir(os.path.join(tmp, 'arb'))
            app = os.path.join(tmp, 'app')
            os.makedirs(app)
            for name in ('index.html', 'main.dart.js'):
                with open(os.path.join(app, name), 'w') as f:
                    f.write('x')
            out = os.path.join(tmp, 'out')
            old = build_site.ARB_DIR
            build_site.ARB_DIR = arb_dir
            try:
                self.assertEqual(build_site.main([out, '--app', app]), 0)
            finally:
                build_site.ARB_DIR = old
            for rel in ('index.html', 'privacy/index.html', 'support/index.html', 'impressum/index.html',
                        'klunki_sw.js', 'favicon.png', 'assets/icon-192.png', 'play/main.dart.js'):
                self.assertTrue(os.path.isfile(os.path.join(out, rel)), rel)
            with open(os.path.join(out, 'index.html'), encoding='utf-8') as f:
                page = f.read()
            self.assertNotIn('{{', build_site.COMMENT.sub('', page))
            self.assertEqual(page.count('data-game='), 2 * len(build_site.GAMES))
            self.assertIn('So spielt ihr zusammen', page)
            self.assertIn('How to play together', page)
            self.assertEqual(build_site.external_loads(page), [])
            # A web build as OUT (the pre-KLD-115 usage) is refused.
            self.assertEqual(build_site.main([app]), 1)

    def test_external_loads(self):
        found = build_site.external_loads(
            '<img src="https://x/y.png"><a href="https://github.com">ok</a>'
            '<link rel="stylesheet" href="//cdn/x.css"><style>a{background:url(https://x)}</style>'
            '<!-- <img src="https://in-a-comment"> -->')
        self.assertEqual(len(found), 3)


if __name__ == '__main__':
    unittest.main()
