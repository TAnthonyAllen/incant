# ruleMethod shares an action (SEQ 528 R2, 2026-11-04, branch rule-shares-action)

`ruleMethod=` takes a C method, as before, or the name of a coded rule. With no C method by that name, the rule takes the named rule's builtinActoR; a copy shares its body (`addProperty` of a
parented node), so the two rules hold one CodE and one BlocK. A name that is neither refuses by name. It must sit after the named rule's own `code=`: the actor exists from then.

**Before, verbatim:**
```
    // ELSEIf only builds (SEQ 491): an or arm is an if in If's else slot -- the same ifThen instruct as If (condition, then, else if present), so opIf runs it and If's else slot takes it
    ELSEIf code={
        :actionLabel EXPRESSIOn STATEMENt ELSe;
        // twoStars each child label holds its instruct, as XPRESs reads EXPRESSIOn
        cond    := **EXPRESSIOn;
        thenS   := **STATEMENt;
        // armRefused an arm that handed up no instruct refuses by name, never attaches a null (SEQ 476 R6)
        thenM   := *thenS.methoD;
        if thenM == 0;
            cerr "REFUSED ELSEIf -- its then arm handed up no instruct":;
            clear(*actionLabel);
            return *actionLabel;
        ifArms  +% *cond;
        ifArms  +% *thenS;
        eLen    := *ELSe.listLengtH;
        if eLen != 0;
            elseS   := **ELSe;
            elseM   := *elseS.methoD;
            if elseM == 0;
                cerr "REFUSED ELSEIf -- its else arm handed up no instruct":;
                clear(*actionLabel);
                return *actionLabel;
            ifArms  +% *elseS;
        op := Operators["ifThen"];
        armsMint    := copyOf(ifArms);
        miArgs      +% op armsMint;
        built       := makeInstruct(miArgs);
        *actionLabel   := *built;
        return  *actionLabel;
        };
```

**After, verbatim:**
```
    // ELSEIf shares If's action (SEQ 528): an or arm is an if in If's else slot -- the same ifThen instruct, so opIf runs it and If's else slot takes it
    ELSEIf ruleMethod=If;
```

**One thing does change:** ELSEIf's refusal text reads `REFUSED If`, the shared action's. No row reads it for ELSEIf.

**Certificate:** pop.sh and jitLadder row for row, no diff in any existing row; elseIfT unchanged; ruleShareT added (actors body #2 and #2, the rule's own #5). Canary 426 -> 427 (locateShared).
**H7 (ELSEIf's line removed; grammar-only, no rebuild, md5 restored):** all eight elseIfT new-road rows read nothing, `R1`, `REFUSED If -- its else arm handed up no instruct`. Control: `ruleMethod=NoSuchRule` refuses by name.
