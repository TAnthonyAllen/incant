# What Is Incant?

A question that keeps evolving. This document is a snapshot, not an answer.

---

## The Elevator Pitch (for the clueless, the curious, and the impatient)

Most software is frozen. You write it, compile it, ship it. It knows what it knows, it does what it does. Changing it means stopping it, rewriting it, restarting it.

Incant doesn't work that way.

Incant is a programming language built entirely out of one thing: the **field**. A field can be data, a rule, a method, a parser, an action, or all of those at once. Fields contain other fields. Fields message other fields. Fields define new fields. An incant program can learn new rules while it runs, extend itself, redefine what it is.

That's it. One concept. Everything else is what you do with it.

Simple like a seed is simple. What grows from it is not.

---

## The Foundation: What Is a Field?

A field is incant's universal container. It can hold data (text, number, character set, another field, or a pointer), a list of fields (members), a C++ method callable from incant, an incant action written in incant itself, a parser that reads input and produces results, and attributes that characterize this field.

A field can be all of these at once. The same field definition that holds a person's name can also be a rule that parses names from input, have an action that formats the name for display, and contain a list of addresses.

In most languages those would be four separate things. In incant they're one field wearing four hats.

---

## JSON, YAML, and Incant — A Syntax Progression

The same hierarchical data, three syntaxes:

JSON (ugly, but ubiquitous):

```
{"person": {"name": "Anthony", "age": 42}}
```

YAML (cleaner, used for config files):

```
person:
  name: Anthony
  age: 42
```

Incant (minimal noise, maximum signal):

```
person name="Anthony" age=42;
```

Each step removes syntax ceremony and keeps signal. Incant wins on elegance. The progression illustrates what incant is doing — expressing structure with the least possible noise.

Incant can parse JSON in four or five rules. The reverse (JSON expressing incant structure) is theoretically possible but aesthetically unfortunate.

---

## What Is a Rule?

A rule is a field that can be used as a parsing instruction. When you invoke a rule's parser, it reads input and either matches or fails.

In the simplest case — a field containing `","` matches a comma in the input. Succeeds: cursor advances, result is a new field containing the matched comma. Fails: cursor stays, no result.

Rules can be composed:

```
Max : ',' maximum = Integer ;
```

`Max` matches a comma followed by an Integer. The `maximum =` part says "store the Integer result in a field called maximum." The result of matching `Max` is a field that has a `maximum` sub-field containing the matched integer.

Rules can have options (alternatives):

```
DatA:
    GrouP;
    NumbeR;
    SetBrackets '['- ']'};
    NotA=[^ \t\r\n;]+;;
```

`DatA` tries each option in order until one succeeds. This is not just pattern matching — it's grammar definition. Incant IS its own grammar.

Here is what reflexive and homoiconic mean in practice. This is incant's grammar, written in incant:

```
StatemenT:
    SemI;
    BlocK;
    WardeD;
    Xpress;
    CheckFor;;

Start=StatemenT+;
```

This is not pseudocode. This IS incant, being run by incant, to define what incant statements look like. The parser that reads this is the same parser that uses these rules to parse incant programs. Code and data — same structure, same syntax, same mechanism.

---

## A Rule Called as a Method

A rule can be called like any other incant method. It takes one argument — a GroupItem that provides the input the rule parses. It returns a result field containing whatever it matched.

Here is a rule from the incant unit tests:

```
list isRule entries=ANYstring+ SemI?-; {
    print "list tests the for statement:":;
    for sumGrup in entries; print `sumGrup:; }
```

`list` is a rule that matches one or more strings, stores them as `entries`, and fires an action that prints each entry. It doesn't return anything useful — it's a proof of concept. But the mechanism it demonstrates is not trivial.

If that action instead messaged a GroupItem in AWS — which happens to be Claude — which returned a response stored back as a field — then `list("some input")` would trigger a chain of events spanning devices, networks, and AI models. The caller just called a method. It didn't know or care what happened inside.

That's the power hiding in the simplicity. A rule is a method is a parser is a field. One thing, four faces.

---

## Methods and Actions

A field can have behavior attached in two forms.

Methods are written in C++. Fast, powerful, access to the full C++ ecosystem. The C++ method receives the matched result as a GroupItem argument and can do anything — format output, call APIs, modify data, redirect input. Methods are the bridge between incant and the outside world.

Actions are written in incant. Interpreted for now — the JIT will compile them. An action is a list of incant statements, stored as fields, interpreted by incant's own runtime. Actions are what incant programming looks like once the language is defined enough to express itself.

The boundary between methods and actions is moving. As the JIT matures, more behavior can be expressed in incant rather than C++. The goal: shrink the C++ layer until incant defines and runs itself with minimal bootstrapping.

---

## Defer — When Timing Matters

Some actions must happen after the parse completes, not during. Incant handles this with `defer`:

```
BlocK   "{" Lines=StatemenT+ "}"  defer;
```

The `defer` keyword says: match this now, fire the action later. A block of code needs all its statements collected before any of them can be interpreted — `defer` handles that naturally.

`defer` is a first-class keyword in incant's grammar, not a callback convention bolted on later. The language understood from the start that timing matters.

---

## Labels vs Rules

When a rule matches, it produces a result stored in a label — a field with the same name as the rule that produced it. Labels and rules share names but carry different flags: `isRule` marks a field as a rule definition, `isLabel` marks a field as a result captured from matching a rule. Same name, two different roles. Navigation follows the flags. Everything inside a label context is `isLabel` — mixing them is a bug.

---

For a deeper dive into the bootstrap rules — the hard-coded seed from which incant defines itself — see **[The Bootstrap Rules](BootstrapRules)**.

---

## The Distributed Vision — Where This Is Going

A GroupItem field is not just a data structure. It's a deployable unit.

The long term vision: incant fields run anywhere — Mac, iOS, Android, Windows, cloud. They message each other across platforms and device boundaries. Location transparent. You don't care if the field you're talking to is local or in AWS.

Work distribution becomes natural. "You have the GPU cluster, handle the matrix math. Send me the result." The field doesn't know or care where the work happens. It just messages and receives.

The file system becomes GroupItem fields. Directories are groups with members. Files are fields. Navigation is field traversal. Storage — MongoDB, filesystem, whatever — is just a persistence layer for the in-memory GroupItem graph.

An AI model running in the cloud is just another field type — `isCLAUDE` alongside `isSTRING`, `isNUMBER`, `isGROUP`. You message it, it messages back. The response is just a GroupItem. The AI is not a tool called from incant — it IS a field in incant, indistinguishable from any other field except it reasons instead of computes.

iMessage, WhatsApp as a GroupItem — not a separate app. One field definition. Oh by the way, look what I can do in just one of my little fields.

---

## What Incant Is Not (Yet)

Incant cannot yet fully define itself without the C++ bootstrap layer. The JIT is in progress — actions are currently interpreted, not compiled. Threading and messaging are designed but not fully implemented. Display and layout (the typesetting vision) is in early design. The editor, the distributed OS, the Claude-as-field-type — these are on the roadmap.

The language works. It interprets itself. It defines itself as far as it can without the JIT. The rest is construction in progress.

---

## Why?

"Why in hell did I spend a couple of years writing yet another computer language?"

Because software should be able to grow. Most programs are frozen at compile time — they know what they know, they do what they do. Changing them means stopping them, rewriting them, restarting them. Incant doesn't work that way. An incant program can learn new rules while it runs, extend itself, redefine what it is. That's not a feature. That's a different philosophy of what software is.

The technical answer: none of the existing languages had the right combination. Lisp had the homoiconicity but the parentheses. Forth had the minimalism but the stack gymnastics. C++ had the ecosystem but the ceremony. Python had the readability that incant copies. Incant tries to steal the best ideas from all of them as it tries to invent its own programming paradigm.

And none of them had the field as a universal primitive. One concept simultaneously data, rule, method, parser, and container. One concept to represent a number, a grammar rule, a file system, a messaging protocol, or an AI model — using the same syntax, the same operations, the same mental model.
    The key departure from all of them: everything is a GroupItem field. Not a list. Not a stack frame.
    Not an expression. A field — which can BE any of those things, simultaneously, depending on context.

That's what incant is for. And the answer to "what will it be used for" is still evolving.

"Cannot answer that yet."
