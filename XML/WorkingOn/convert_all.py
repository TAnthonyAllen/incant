#!/usr/bin/env python3
"""convert_all.py - convert the XML form tree into the IncantForms tree.

XML is the source, IncantForms is the output. Walks the source tree for
*.xml files and writes each converted form to the matching path in the
output tree with the '.xml' extension stripped.

Skip rule: skip if the target already exists AND is already in incant format
(a hand-converted file - never clobber prior work). A target that is missing,
or that still holds XML-format content (a leftover copy not yet converted), is
(re)converted. Pure existence is not enough to skip because every form already
has an extensionless IncantForms copy, converted or not.

The XML source tree is never modified.

Usage:
    convert_all.py [src_dir] [dst_dir]

Defaults: src = XML/Windows, dst = IncantForms/Windows (relative to the repo
root, derived from this script's location in XML/WorkingOn/).
"""
import os
import sys

# import convert_form from this script's own directory
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import convert_form
import re

# An IncantForms target counts as "already converted" (skip) when it has no
# XML markers: no '<tag' open tags and no leading #registry/#include directives.
XML_MARKER = re.compile(r'<\w|^\s*#(registry|include)\b', re.MULTILINE)


def is_xml_format(path):
    try:
        with open(path, 'r') as f:
            return XML_MARKER.search(f.read()) is not None
    except OSError:
        return False


def main(argv):
    here = os.path.dirname(os.path.abspath(__file__))
    repo = os.path.normpath(os.path.join(here, '..', '..'))   # XML/WorkingOn -> repo root
    src = argv[1] if len(argv) > 1 else os.path.join(repo, 'XML', 'Windows')
    dst = argv[2] if len(argv) > 2 else os.path.join(repo, 'IncantForms', 'Windows')

    if not os.path.isdir(src):
        sys.stderr.write('source not a directory: %s\n' % src)
        return 2
    if not os.path.isdir(dst):
        sys.stderr.write('destination not a directory: %s\n' % dst)
        return 2

    converted = skipped = errors = 0
    for dirpath, dirnames, filenames in os.walk(src):
        for name in sorted(filenames):
            if not name.endswith('.xml'):
                continue
            inp = os.path.join(dirpath, name)
            rel = os.path.relpath(inp, src)
            out = os.path.join(dst, rel[:-4])    # strip '.xml'
            if os.path.exists(out) and not is_xml_format(out):
                print('skipped   %s (already converted)' % rel)
                skipped += 1
                continue
            try:
                with open(inp, 'r') as f:
                    text = f.read()
                os.makedirs(os.path.dirname(out), exist_ok=True)
                with open(out, 'w') as f:
                    f.write(convert_form.convert_text(text))
                print('converted %s -> %s' % (rel, os.path.relpath(out, dst)))
                converted += 1
            except Exception as e:
                print('error     %s: %s' % (rel, e))
                errors += 1

    print()
    print('summary: %d converted, %d skipped, %d errors' % (converted, skipped, errors))
    return 0


if __name__ == '__main__':
    sys.exit(main(sys.argv))
