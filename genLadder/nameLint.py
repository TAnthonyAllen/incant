#!/usr/bin/env python3
"""nameLint.py <incantation> [more incantations]

Report tier, like alphaLint.sh and codeOnly.py: it always exits 0 and is on no seal checklist.

Kant does not refuse a misspelled name. An undeclared name in an action body becomes a fresh empty local, so
`currrentField` beside `currentField` runs clean and reads empty (2026-11-24, delimitedData). This lists every name in a
file that is ONE keystroke away from a better-established name: a letter doubled, dropped, added, changed, or two
letters swapped.

"Better established" means the other name is used more often in the same file, or is in the shared vocabulary
(incant/setup, incant/grammar, incant/kantGrammar, incant/utilities). A name already in that vocabulary is never
reported. Pairs that differ only by a digit (row1 / row2) or by a final s are skipped as deliberate. Short names are
held to a stricter test, because short words sit one letter apart by chance (text / next, from / form): a doubled
letter counts from four letters up, an extra, missing or swapped letter from five, a changed letter or case from six.

What is read: the live part of the file only. Comments, quoted strings, (...#) literals and everything below the first
stop(); or bail(); line are dropped first, since prose there is not names.
"""
import re
import sys
import os
from collections import defaultdict

MINLEN = 4
VOCAB_FILES = ["incant/setup", "incant/grammar", "incant/kantGrammar", "incant/utilities"]
NAME = re.compile(r"[A-Za-z_][A-Za-z0-9_]*")


def live(text):
    """The file with dead region, comments, strings and (...#) literals blanked; line count kept."""
    lines = text.split("\n")
    for i, line in enumerate(lines):
        if re.match(r"\s*(stop|bail)\(\);", line):
            lines = lines[:i]
            break
    text = "\n".join(lines)

    def blank(m):
        return re.sub(r"[^\n]", " ", m.group(0))

    text = re.sub(r"/\*.*?\*/", blank, text, flags=re.S)
    text = re.sub(r"=\(.*?#\)", blank, text, flags=re.S)
    text = re.sub(r"//[^\n]*", blank, text)
    text = re.sub(r'"[^"\n]*"', blank, text)
    text = re.sub(r"'[^'\n]*'", blank, text)
    return text


def names(text):
    found = defaultdict(list)
    for n, line in enumerate(text.split("\n"), 1):
        for m in NAME.finditer(line):
            found[m.group(0)].append(n)
    return found


def slip(a, b):
    """How a (the suspect) differs from b by one keystroke, or None."""
    la, lb = len(a), len(b)
    if la == lb:
        diff = [i for i in range(la) if a[i] != b[i]]
        if len(diff) == 1:
            i = diff[0]
            if a[i].isdigit() or b[i].isdigit():
                return None
            if a[i].lower() == b[i].lower():
                return "case of one letter"
            return "one letter changed"
        if len(diff) == 2 and diff[1] == diff[0] + 1 and a[diff[0]] == b[diff[1]] and a[diff[1]] == b[diff[0]]:
            return "two letters swapped"
        return None
    if abs(la - lb) != 1:
        return None
    longer, shorter = (a, b) if la > lb else (b, a)
    for i in range(len(longer)):
        if longer[:i] + longer[i + 1:] == shorter:
            extra = longer[i]
            if extra.isdigit() or (extra == "s" and i == len(longer) - 1):
                return None
            doubled = (i > 0 and longer[i - 1] == extra) or (i + 1 < len(longer) and longer[i + 1] == extra)
            if la > lb:
                return "letter doubled" if doubled else "one letter extra"
            return "one of a doubled letter dropped" if doubled else "one letter missing"
    return None


def main():
    root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    vocab = set()
    for v in VOCAB_FILES:
        p = os.path.join(root, v)
        if os.path.isfile(p):
            vocab |= set(names(live(open(p, errors="replace").read())))
        else:
            print("nameLint: vocabulary file MISSING: " + v)
    total = 0
    for path in sys.argv[1:]:
        if not os.path.isfile(path):
            print("nameLint: file MISSING: " + path)
            continue
        own = names(live(open(path, errors="replace").read()))
        rows = []
        for a, where in own.items():
            if len(a) < MINLEN or a in vocab:
                continue
            for b in set(own) | vocab:
                if b == a or len(b) < MINLEN:
                    continue
                how = slip(a, b)
                if not how:
                    continue
                need = 4 if "doubled" in how else 6 if ("changed" in how or "case" in how) else 5
                if min(len(a), len(b)) < need:
                    continue
                inVocab = b in vocab
                if not inVocab and len(own[b]) < len(where):
                    continue
                if not inVocab and len(own[b]) == len(where) and b < a:
                    continue
                source = "shared vocabulary" if inVocab and b not in own else "used %d time(s) here" % len(own[b])
                rows.append((where[0], a, where, b, how, source))
        rows.sort()
        print("%s: %d suspect name(s), %d names read" % (path, len(rows), len(own)))
        for _, a, where, b, how, source in rows:
            lines = ",".join(str(n) for n in where[:6]) + ("..." if len(where) > 6 else "")
            print("  line %-12s %-24s near %-24s %s (%s)" % (lines, a, b, how, source))
        total += len(rows)
    print("nameLint: %d suspect name(s) in %d file(s) -- report only" % (total, len(sys.argv) - 1))
    return 0


if __name__ == "__main__":
    sys.exit(main())
