#!/usr/bin/env python3
"""C-155 groupDirectives resolver.

Grammar (parts.g:104, measured):
    DebugDirective : '#'! Comment? method=Name body=CodeMatch? locate=Directives?
                     active='active'? code='#;'}
    Directives keyword bin (keywords.g:85) = before | ending | starting | within
Anchor semantics (Tawk.twk:1147, 2723):
    strncmp(codeMatch, pointInCode.itemStart, strlen(codeMatch))
    -- a PREFIX test against the source text at a statement / if-statement point.
"""
import os, re, sys, json

ROOT = "/Users/anthony/Library/CloudStorage/Dropbox/data/InProcess/Groups"
LOCATES = {"before", "ending", "starting", "within"}

# ---------------------------------------------------------------- directives
def parse_directives(path):
    lines = open(path, encoding="utf-8", errors="replace").read().split("\n")
    entries, section, i, incomment = [], None, 0, False
    while i < len(lines):
        raw = lines[i]; s = raw.strip()
        if incomment:
            if "*/" in raw: incomment = False
            i += 1; continue
        if s.startswith("/*"):
            if "*/" not in raw: incomment = True
            i += 1; continue
        if not s:
            i += 1; continue
        if raw.startswith("#") and s != "#;":
            section = s[1:].strip(); i += 1; continue
        if raw[:1] not in (" ", "\t"):
            header, hline = s, i + 1
            body = []
            j = i + 1
            while j < len(lines) and lines[j].strip() != "#;":
                body.append(lines[j]); j += 1
            entries.append(dict(section=section, header=header, line=hline,
                                code="\n".join(body), endline=j + 1))
            i = j + 1; continue
        i += 1
    for e in entries:
        e.update(tokenize(e["header"]))
    return entries

def tokenize(header):
    m = re.match(r'^(\S+)\s*(.*)$', header)
    name, rest = m.group(1), m.group(2).strip()
    anchor = None
    if rest.startswith('"'):
        q = re.match(r'^"([^"]*)"\s*(.*)$', rest)
        anchor, rest = q.group(1), q.group(2).strip()
    elif rest:
        first = rest.split()[0]
        if first not in LOCATES and first != "active":
            anchor = first; rest = rest[len(first):].strip()
    toks = rest.split()
    locate = toks[0] if toks and toks[0] in LOCATES else None
    if locate: toks = toks[1:]
    armed = bool(toks) and toks[0] == "active"
    trailing = " ".join(toks[1:] if armed else toks)
    return dict(method=name, anchor=anchor, locate=locate,
                armed=armed, trailing=trailing)

# ---------------------------------------------------------------- source index
DEF = re.compile(r'^(?:extern\s+|static\s+|inline\s+)*[A-Za-z_][\w:*&\s]*?'
                 r'\b([A-Za-z_]\w*)\s*\(')

def index_sources(files):
    idx = {}
    for f in files:
        p = os.path.join(ROOT, f)
        if not os.path.exists(p): continue
        L = open(p, encoding="utf-8", errors="replace").read().split("\n")
        n = 0
        while n < len(L):
            line = L[n]
            if line[:1] not in (" ", "\t", "", "#", "/", "*", "}", "{") :
                m = DEF.match(line)
                if m and n + 1 < len(L) and L[n + 1].startswith("{"):
                    name = m.group(1)
                    k = n + 2; depth = 1
                    while k < len(L):
                        if L[k].startswith("}"): break
                        k += 1
                    idx.setdefault(name, []).append(
                        dict(file=f, start=n + 1, end=k + 1, body=L[n + 2:k]))
                    n = k + 1; continue
            n += 1
    return idx

# ---------------------------------------------------------------- resolution
def anchor_hits(body, anchor):
    hits = []
    for off, line in enumerate(body):
        t = line.lstrip()
        if not t: continue
        if t.startswith(anchor): hits.append((off, line.rstrip()))
        else:
            # a statement can begin mid-line after else/or/{
            for lead in ("else ", "or ", "{ "):
                if t.startswith(lead) and t[len(lead):].lstrip().startswith(anchor):
                    hits.append((off, line.rstrip())); break
    return hits

CLASSFILE = {"GroupItem": "GroupItem.twk", "GroupMain": "GroupMain.twk",
             "GroupRules": "GroupRules.twk", "RuleStuff": "RuleStuff.twk"}
GLOBALS = ["Commands.rtn", "GroupActions.rtn", "ruleActions.rtn", "Debug.rtn",
           "Instruct.rtn", "jitEmitters.rtn", "genParse.rtn", "Generate.rtn"]
ALL = GLOBALS + ["GroupRules.twk", "GroupItem.twk", "GroupMain.twk",
                 "RuleStuff.twk", "GroupBody.twk", "GroupControl.twk",
                 "GroupList.twk", "GroupStak.twk", "GroupDraw.twk",
                 "Bytecode.twk", "groups.twk", "Layout.twk", "Stylish.twk"]

def grade(entries, idx):
    seen_armed = {}
    for e in entries:
        defs = idx.get(e["method"], [])
        want = CLASSFILE.get(e["section"])
        # tok resolves currentType.getMethod(name), falling back to
        # findGlobalMethod ONLY when currentType.isGlobal (Tawk.twk:4436).
        # So a class-section entry naming a global is not found at all.
        pick = [d for d in defs if d["file"] == want] if want else \
               [d for d in defs if d["file"] in GLOBALS]
        e["defs"] = [f'{d["file"]}:{d["start"]}' for d in defs]
        if not pick:
            e["grade"] = "FUNCTION GONE"; e["hits"] = []
            if defs: e["note"] = "out of section: " + ", ".join(e["defs"])
            continue
        d = pick[0]; e["site"] = f'{d["file"]}:{d["start"]}'
        if not e["anchor"]:
            e["hits"] = []
            e["grade"] = "RESOLVES" if e["locate"] in ("ending", "starting") \
                         else "MALFORMED (no anchor, locate not ending/starting)"
        else:
            h = anchor_hits(d["body"], e["anchor"])
            e["hits"] = [(d["start"] + 2 + o, t) for o, t in h]
            e["grade"] = ("ANCHOR GONE" if len(h) == 0 else
                          "RESOLVES" if len(h) == 1 else "AMBIGUOUS")
        if e["armed"]:
            key = (e["section"], e["method"])
            if key in seen_armed:
                e["shadowed_by"] = seen_armed[key]
            else:
                seen_armed[key] = e["line"]
    return entries

if __name__ == "__main__":
    arg = sys.argv[1] if len(sys.argv) > 1 else "groupDirectives"
    d = parse_directives(arg if os.path.exists(arg) else os.path.join(ROOT, arg))
    idx = index_sources(ALL)
    grade(d, idx)
    json.dump(d, open(os.path.join(os.path.dirname(os.path.abspath(__file__)), "census.json"), "w"), indent=1)
    print(f"{'ln':>4} {'sec':<11} {'method':<20} {'anchor':<20} {'loc':<9} "
          f"{'arm':<4} {'n':>3}  grade")
    for e in d:
        print(f'{e["line"]:>4} {str(e["section"]):<11} {e["method"]:<20} '
              f'{str(e["anchor"])[:20]:<20} {str(e["locate"]):<9} '
              f'{"ARM" if e["armed"] else "-":<4} {len(e["hits"]):>3}  '
              f'{e["grade"]}{"  SHADOWED by ln " + str(e["shadowed_by"]) if "shadowed_by" in e else ""}')
    print(f"\ntotal entries: {len(d)}   armed: {sum(1 for e in d if e['armed'])}")
    from collections import Counter
    for g, n in Counter(e["grade"] for e in d).most_common(): print(f"  {g}: {n}")

# C-155, 2026-09-04. Certified per rule H7 by driving it on a name known retired
# in full (tokenize) and one known live (compile endCompile); they grade
# differently, and the grade predicted injection on all nine armed entries of the
# pre-cut file with no exceptions. See docs/c155Cull.md §2.
