#!/usr/bin/env python3
"""convert_form.py - mechanical XML-form -> incant-form converter.

Takes a single XML-format form file and writes the converted incant form.
NEVER modifies the input file (the XML source is the backup).

Usage:
    convert_form.py <input> [output]

If <output> is omitted: strip a trailing '.xml' from <input>; if <input> has
no '.xml' extension, append '.incant' so the XML-format original is never
clobbered.

Conversion rules (applied per line, in order; indentation preserved):
    1. #include PATH            -> include(PATH);
    2. #registry NAME [flags]   -> register(NAME);  + 'define' on the next line
                                   (registry flags are dropped in this pass)
    3. <tag>LONGTEXT</tag>      -> tag=(LONGTEXT#);   (prose description)
       <tag="LONGTEXT"/>        -> tag=(LONGTEXT#);
    4. <INNER/>                 -> INNER;             (self-closing element)
    5. <INNER>                  -> INNER              (block opener; children follow)
    6. </tag>                   -> removed (standalone, or stripped when trailing)
    7. #;                       -> ;
    8. anything else            -> line + '  # TODO: review'
"""
import re
import sys
import os

CLOSE_TAG = re.compile(r'</\w+>')


def split_indent(line):
    """Return (leading_whitespace, rest-without-trailing-newline)."""
    stripped = line.lstrip(' \t')
    indent = line[:len(line) - len(stripped)]
    return indent, stripped.rstrip('\n')


def convert_line(line):
    """Convert one input line; return a list of zero or more output lines."""
    indent, content = split_indent(line)

    # blank / whitespace-only line: emit empty (nothing to indent)
    if content.strip() == '':
        return ['']

    # Rule 7: #; -> ;
    if content.strip() == '#;':
        return [indent + ';']

    # Rule 1: #include PATH -> include(PATH);
    m = re.match(r'#include\s+(.+?);?\s*$', content)
    if m:
        return [indent + 'include(' + m.group(1).strip() + ');']

    # Rule 2: #registry NAME [flags] -> register(NAME); + define
    # Flags are not silently dropped: when present they are emitted as a
    # '# TODO: registry flags: <flags>' line between register() and define.
    m = re.match(r'#registry\s+([^\s;]+)\s*(.*?)\s*;?\s*$', content)
    if m:
        name = m.group(1)
        flags = m.group(2).strip()
        out = [indent + 'register(' + name + ');']
        if flags:
            out.append(indent + '# TODO: registry flags: ' + flags)
        out.append(indent + 'define')
        return out

    # Rule: #search NAME... -> search NAME...;   (a leading modifier on the
    # directive, e.g. the '+' in '#search+', is dropped to match 'search NAME;')
    m = re.match(r'#search\S*\s+(.+?)\s*;?\s*$', content)
    if m:
        return [indent + 'search ' + m.group(1) + ';']

    # Rule 3a: <tag>LONGTEXT</tag>  (bareword tag, text content) -> tag=(LONGTEXT#);
    m = re.match(r'<(\w+)>(.*)</\1>\s*$', content)
    if m:
        return [indent + m.group(1) + '=(' + m.group(2) + '#);']

    # Rule 3b: <tag="LONGTEXT"/>  (quoted value, no other attrs) -> tag=(LONGTEXT#);
    m = re.match(r'<(\w+)="([^"]*)"/>\s*$', content)
    if m:
        return [indent + m.group(1) + '=(' + m.group(2) + '#);']

    # Rule 6 (trailing) + Rule 4: a self-closing element, optionally followed by
    # one or more close tags. Strip the close tags, then strip the < .. /> wrapper.
    trimmed = CLOSE_TAG.sub('', content).rstrip()
    m = re.match(r'<(.*?)/>\s*$', trimmed)
    if m:
        return [indent + m.group(1).rstrip() + ';']

    # Rule 6: standalone close tag(s) only -> removed entirely
    if CLOSE_TAG.sub('', content).strip() == '':
        return []

    # Rule 5: block opener <INNER> -> INNER  (children follow; no semicolon added,
    # but an inner trailing ';' such as '<help ...;>' is preserved)
    m = re.match(r'<(.*)>\s*$', trimmed)
    if m:
        return [indent + m.group(1)]

    # Rule 8: uncategorizable -> pass through with a review marker
    return [indent + content + '  # TODO: review']


def convert_text(text):
    """Convert a whole form's text. Returns the converted text."""
    out = []
    for line in text.splitlines():
        out.extend(convert_line(line))
    return '\n'.join(out) + '\n'


def default_output(inp):
    """Output path for an input: strip '.xml', else append '.incant'."""
    if inp.endswith('.xml'):
        return inp[:-4]
    return inp + '.incant'


def main(argv):
    if len(argv) < 2:
        sys.stderr.write('usage: convert_form.py <input> [output]\n')
        return 2
    inp = argv[1]
    out = argv[2] if len(argv) > 2 else default_output(inp)
    if os.path.abspath(out) == os.path.abspath(inp):
        sys.stderr.write('refusing to overwrite the input: %s\n' % inp)
        return 2
    with open(inp, 'r') as f:
        text = f.read()
    with open(out, 'w') as f:
        f.write(convert_text(text))
    sys.stderr.write('converted %s -> %s\n' % (inp, out))
    return 0


if __name__ == '__main__':
    sys.exit(main(sys.argv))
