#!/usr/bin/env python3
"""Old name of site/export_legal_text.py, kept so the old command still works.

    python3 -I site/export_privacy_text.py   # same as: export_legal_text.py privacy

Use export_legal_text.py (no arguments) to export all bundled legal pages.
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import export_legal_text  # noqa: E402

if __name__ == '__main__':
    sys.exit(export_legal_text.main(['privacy']))
