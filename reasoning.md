If we go with prefixes or suffixes around chars/strings, I think the most expected
syntaxes are:
- if we extend char syntax, `u'é'`, `'é'u`. We could also consider uppercase version
  `U'é'`, `'é'U`.
- if we extend string syntax, `c"é"` or `u"é"` or `uc"é"` or some other prefix, or
  their upper case versions. I don't consider a suffix, as strings can be arbitrarily
  long and it doesn't seem wise to include information about their interpretation at
  the end (which would also preclude any future syntax where the lexing itself changes
  based on the prefix).

In all cases, there's a choice between reserving exactly the syntax we need vs
reserving a more general class. Concretely, if we went `u'é'`, how is `a'é'` lexed?  It
could be a typer error like `123z` is a typer error (barring a ppx interpreting that
suffix), or it could be lexed the same as now, as two tokens.

The narrow version generally breaks less code (although, it can be no breakage either
way in opam, it depends on the case. Obviously we can't know what exists outside of
opam, but proprietary codebases are easier to rewrite if need be. Only code generators
that output strings instead of asts resist automatic fixes), the wide version is more
regular (renaming variables is less likely to change how the program is lexed). It's
also possible to start with the narrow version and widen later.

In all cases, the syntax is a bit redundant with escape: `u'\u{1234}'`, as we say
"u" twice, but it seems fine.

In terms of occurrences in opam:
- `u'é'`: 0
- `*'é'`: 3. `Bytes.set r j' '_'`, 2x `String.contains s' ']'`. These bits of code are
  extremely uncommon, but their style is completely conventional, so it's unclear what
  we should advise them to rewrite to. `Bytes.set r (j') '_'`? `Bytes.set r j' '_'`?
  `Bytes.set r j' ('_')`?  `Bytes.set r j2 '_'`?
- `'é'u`: 0
- `'é'*`: 3. `try String.index str '='with Not_found`, `(String.split_on_char ' 's)`, `let* _ = char_ws 'a'in`. These are clearly just mistypings. A different lexer implementation could allow these to parse unchanged.
- no occurrences for the single quotes + uppercase prefix/suffix
- `c"é"`: 0
- `*"é"`: maybe 300ish occurrences. Some of them are just cramped code (and similar code
  nearby can have extra spacing), some of them are on purpose (`r"a"` for a pretend
  rope-literal)
- `u"é"`: 2. `Rope.of_ustring (u"Simple ASCII string")`, `let page_links = ["About", u"/about"]`
- `uc"é"`: 0
- `**"é"`: not checked, but I assume it's used.
- `U"é"`/`C"é"`: 0. With some names (though not `U` and `C`), the syntax is present,
  almost all of it in ocamlbuild command lines constructions.

Thinking about possible extensions (not arguing for them, but just to avoid painting
oneself in a corner):

- more affixes around chars opens the door to almost nothing. It would theoretically
  be consistent with writing char literal as `c'a'` or `b'a'`, which could avoid rare
  confusions about apostrophes being part of char literal or identifiers.
- more affixes around strings would open the door to this sort of changes:
  - template/interpolated strings `let x = 1 in t"{x} + 1 = {x + 1}"` or whatever.
    Related links: https://ocaml.org/p/ppx_string/latest
    https://ocaml.org/p/ppx_string_interpolation/latest
  - nonindented multi-line strings, that is multi line strings where a string is
     visually indented but its contents doesn't contain the indentation:

     ```let f () =
          let y = d"line1
                     line2
                    line3"
          in
          assert (y = "line1\n line2\nline3")
     ```
     Related links: https://github.com/ocaml/ocaml/issues/13860 ,
     https://ocaml.org/p/dedent/latest (there's a ppx that goes with it)
  - the same way we have char/string, we could pair uchar with a ustring. Literals for
    ustrings would certainly be desired, and the syntax `u"..."` would be the obvious
    choice.
  - `b"..."` would be a possible `Bytes.t` literal, not that I've seen demand for it
  - the more kinds of strings you have, the more likely it is that you'd want to prefix
    a string with two prefixes, which may mean it's best to stick to single character 
    prefixes: `du"..."` for unicode nonindented strings. But perhaps some other syntax is
    possible that would allow multiple prefixes each with multiple characters, say
    `(d u)"..."` or `d+u"..."` or `d_u"..."`.
  - theoretically, it would possible to redefine char literals as `c"e"` over a long
    time, thus simplifying the role of apostrophes (I think it can confuse comment
    parsing for instance, although this is not exactly pressing).
- if this syntax ends up in the language, by analogy, one could imagine adding
  prefixing in other constructs, say `i[|...|]` for immutable arrays. That wouldn't
  obviously provide an equivalent for `a.(0)` though.

Thinking:

IMO the clear best syntax is `u'é'`. But it can require sensible code as shown above to
be rewritten in a weird way, which even if such cases don't show up in opam, seems like
a deal breaker since I see no clear solution.

I'd say the next best syntaxes are `'é'u` or `U"é"`. I tried both on my code, and
they're both fine. I think I might prefer `U"é"` marginally, but `'é'u` is probably
more self-evident.

Takeaway:

I suggest: `'é'u`, with the lexer special-casing the `u` suffix (no clear use case for
an arbitrary suffix, since the "payload" of a char/uchar literal is so restricted, and
it's not clear what payload should be allowed for an arbitrary suffix. I suspect that
supporting any text until a closing quote would break the parsing of type variables).

The question left is whether to tokenize `'é'uabc` as `'é' uabc` or `'é'u abc`. I think
no one should write this, so any parse will do, and ideally we'd emit a warning. In
practice, it's easier to use the first interpretation and to write the warning later,
if ever.

Since this bit of syntax is absent from opam, there's nothing more to do.
