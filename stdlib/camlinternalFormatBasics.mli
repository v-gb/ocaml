(**************************************************************************)
(*                                                                        *)
(*                                 OCaml                                  *)
(*                                                                        *)
(*                          Benoit Vaugon, ENSTA                          *)
(*                                                                        *)
(*   Copyright 2014 Institut National de Recherche en Informatique et     *)
(*     en Automatique.                                                    *)
(*                                                                        *)
(*   All rights reserved.  This file is distributed under the terms of    *)
(*   the GNU Lesser General Public License version 2.1, with the          *)
(*   special exception on linking described in the file LICENSE.          *)
(*                                                                        *)
(**************************************************************************)

(* No comments, OCaml stdlib internal use only. *)

type padty = Left | Right | Zeros

type int_conv =
  | Int_d | Int_pd | Int_sd | Int_i | Int_pi | Int_si
  | Int_x | Int_Cx | Int_X | Int_CX | Int_o | Int_Co | Int_u
  | Int_Cd | Int_Ci | Int_Cu

type float_flag_conv =
  | Float_flag_ | Float_flag_p | Float_flag_s
type float_kind_conv =
  | Float_f | Float_e | Float_E | Float_g | Float_G
  | Float_F | Float_h | Float_H | Float_CF
type float_conv = float_flag_conv * float_kind_conv

type char_set = string

type counter = Line_counter | Char_counter | Token_counter

type padding('a, 'b) =
  | No_padding  : padding('a, 'a)
  | Lit_padding : padty * int -> padding('a, 'a)
  | Arg_padding : padty -> padding(int -> 'a, 'a)

type pad_option = option(int)

type precision('a, 'b) =
  | No_precision : precision('a, 'a)
  | Lit_precision : int -> precision('a, 'a)
  | Arg_precision : precision(int -> 'a, 'a)

type prec_option = option(int)

type custom_arity('a, 'b, 'c) =
  | Custom_zero : custom_arity('a, string, 'a)
  | Custom_succ : custom_arity('a, 'b, 'c) ->
    custom_arity('a, 'x -> 'b, 'x -> 'c)

type block_type = Pp_hbox | Pp_vbox | Pp_hvbox | Pp_hovbox | Pp_box | Pp_fits

type formatting_lit =
  | Close_box
  | Close_tag
  | Break of string * int * int
  | FFlush
  | Force_newline
  | Flush_newline
  | Magic_size of string * int
  | Escaped_at
  | Escaped_percent
  | Scan_indic of char

type formatting_gen('a, 'b, 'c, 'd, 'e, 'f) =
  | Open_tag : format6('a, 'b, 'c, 'd, 'e, 'f) ->
    formatting_gen('a, 'b, 'c, 'd, 'e, 'f)
  | Open_box : format6('a, 'b, 'c, 'd, 'e, 'f) ->
    formatting_gen('a, 'b, 'c, 'd, 'e, 'f)

and fmtty('a, 'b, 'c, 'd, 'e, 'f) =
    fmtty_rel('a, 'b, 'c, 'd, 'e, 'f, 'a, 'b, 'c, 'd, 'e, 'f)
and fmtty_rel('a1, 'b1, 'c1, 'd1, 'e1, 'f1,
   'a2, 'b2, 'c2, 'd2, 'e2, 'f2) =
| Char_ty :                                                 (* %c  *)
    fmtty_rel('a1, 'b1, 'c1, 'd1, 'e1, 'f1, 'a2, 'b2, 'c2, 'd2, 'e2, 'f2) ->
    fmtty_rel(char -> 'a1, 'b1, 'c1, 'd1, 'e1, 'f1, char -> 'a2, 'b2, 'c2, 'd2, 'e2, 'f2)
| String_ty :                                               (* %s  *)
    fmtty_rel('a1, 'b1, 'c1, 'd1, 'e1, 'f1, 'a2, 'b2, 'c2, 'd2, 'e2, 'f2) ->
    fmtty_rel( string -> 'a1,
      'b1,
      'c1,
      'd1,
      'e1,
      'f1,
      string -> 'a2,
      'b2,
      'c2,
      'd2,
      'e2,
      'f2 )
| Int_ty :                                                  (* %d  *)
    fmtty_rel('a1, 'b1, 'c1, 'd1, 'e1, 'f1, 'a2, 'b2, 'c2, 'd2, 'e2, 'f2) ->
    fmtty_rel(int -> 'a1, 'b1, 'c1, 'd1, 'e1, 'f1, int -> 'a2, 'b2, 'c2, 'd2, 'e2, 'f2)
| Int32_ty :                                                (* %ld *)
    fmtty_rel('a1, 'b1, 'c1, 'd1, 'e1, 'f1, 'a2, 'b2, 'c2, 'd2, 'e2, 'f2) ->
    fmtty_rel(int32 -> 'a1, 'b1, 'c1, 'd1, 'e1, 'f1, int32 -> 'a2, 'b2, 'c2, 'd2, 'e2, 'f2)
| Nativeint_ty :                                            (* %nd *)
    fmtty_rel('a1, 'b1, 'c1, 'd1, 'e1, 'f1, 'a2, 'b2, 'c2, 'd2, 'e2, 'f2) ->
    fmtty_rel( nativeint -> 'a1,
      'b1,
      'c1,
      'd1,
      'e1,
      'f1,
      nativeint -> 'a2,
      'b2,
      'c2,
      'd2,
      'e2,
      'f2 )
| Int64_ty :                                                (* %Ld *)
    fmtty_rel('a1, 'b1, 'c1, 'd1, 'e1, 'f1, 'a2, 'b2, 'c2, 'd2, 'e2, 'f2) ->
    fmtty_rel(int64 -> 'a1, 'b1, 'c1, 'd1, 'e1, 'f1, int64 -> 'a2, 'b2, 'c2, 'd2, 'e2, 'f2)
| Float_ty :                                                (* %f  *)
    fmtty_rel('a1, 'b1, 'c1, 'd1, 'e1, 'f1, 'a2, 'b2, 'c2, 'd2, 'e2, 'f2) ->
    fmtty_rel(float -> 'a1, 'b1, 'c1, 'd1, 'e1, 'f1, float -> 'a2, 'b2, 'c2, 'd2, 'e2, 'f2)
| Bool_ty :                                                 (* %B  *)
    fmtty_rel('a1, 'b1, 'c1, 'd1, 'e1, 'f1, 'a2, 'b2, 'c2, 'd2, 'e2, 'f2) ->
    fmtty_rel(bool -> 'a1, 'b1, 'c1, 'd1, 'e1, 'f1, bool -> 'a2, 'b2, 'c2, 'd2, 'e2, 'f2)
| Format_arg_ty :                                           (* %{...%} *)
    fmtty('g, 'h, 'i, 'j, 'k, 'l) *
    fmtty_rel('a1, 'b1, 'c1, 'd1, 'e1, 'f1, 'a2, 'b2, 'c2, 'd2, 'e2, 'f2) ->
    fmtty_rel( format6('g, 'h, 'i, 'j, 'k, 'l) -> 'a1,
      'b1,
      'c1,
      'd1,
      'e1,
      'f1,
      format6('g, 'h, 'i, 'j, 'k, 'l) -> 'a2,
      'b2,
      'c2,
      'd2,
      'e2,
      'f2 )
| Format_subst_ty :                                         (* %(...%) *)
    fmtty_rel('g, 'h, 'i, 'j, 'k, 'l, 'g1, 'b1, 'c1, 'j1, 'd1, 'a1) *
    fmtty_rel('g, 'h, 'i, 'j, 'k, 'l, 'g2, 'b2, 'c2, 'j2, 'd2, 'a2) *
    fmtty_rel('a1, 'b1, 'c1, 'd1, 'e1, 'f1, 'a2, 'b2, 'c2, 'd2, 'e2, 'f2) ->
    fmtty_rel( format6('g, 'h, 'i, 'j, 'k, 'l) -> 'g1,
      'b1,
      'c1,
      'j1,
      'e1,
      'f1,
      format6('g, 'h, 'i, 'j, 'k, 'l) -> 'g2,
      'b2,
      'c2,
      'j2,
      'e2,
      'f2 )

(* Printf and Format specific constructors. *)
| Alpha_ty :                                                (* %a  *)
    fmtty_rel('a1, 'b1, 'c1, 'd1, 'e1, 'f1, 'a2, 'b2, 'c2, 'd2, 'e2, 'f2) ->
    fmtty_rel( ('b1 -> 'x -> 'c1) -> 'x -> 'a1,
      'b1,
      'c1,
      'd1,
      'e1,
      'f1,
      ('b2 -> 'x -> 'c2) -> 'x -> 'a2,
      'b2,
      'c2,
      'd2,
      'e2,
      'f2 )
| Theta_ty :                                                (* %t  *)
    fmtty_rel('a1, 'b1, 'c1, 'd1, 'e1, 'f1, 'a2, 'b2, 'c2, 'd2, 'e2, 'f2) ->
    fmtty_rel( ('b1 -> 'c1) -> 'a1,
      'b1,
      'c1,
      'd1,
      'e1,
      'f1,
      ('b2 -> 'c2) -> 'a2,
      'b2,
      'c2,
      'd2,
      'e2,
      'f2 )
| Any_ty :                                         (* Used for custom formats *)
    fmtty_rel('a1, 'b1, 'c1, 'd1, 'e1, 'f1, 'a2, 'b2, 'c2, 'd2, 'e2, 'f2) ->
    fmtty_rel('x -> 'a1, 'b1, 'c1, 'd1, 'e1, 'f1, 'x -> 'a2, 'b2, 'c2, 'd2, 'e2, 'f2)

(* Scanf specific constructor. *)
| Reader_ty :                                               (* %r  *)
    fmtty_rel('a1, 'b1, 'c1, 'd1, 'e1, 'f1, 'a2, 'b2, 'c2, 'd2, 'e2, 'f2) ->
    fmtty_rel( 'x -> 'a1,
      'b1,
      'c1,
      ('b1 -> 'x) -> 'd1,
      'e1,
      'f1,
      'x -> 'a2,
      'b2,
      'c2,
      ('b2 -> 'x) -> 'd2,
      'e2,
      'f2 )
| Ignored_reader_ty :                                       (* %_r  *)
    fmtty_rel('a1, 'b1, 'c1, 'd1, 'e1, 'f1, 'a2, 'b2, 'c2, 'd2, 'e2, 'f2) ->
    fmtty_rel( 'a1,
      'b1,
      'c1,
      ('b1 -> 'x) -> 'd1,
      'e1,
      'f1,
      'a2,
      'b2,
      'c2,
      ('b2 -> 'x) -> 'd2,
      'e2,
      'f2 )

| End_of_fmtty :
    fmtty_rel('f1, 'b1, 'c1, 'd1, 'd1, 'f1, 'f2, 'b2, 'c2, 'd2, 'd2, 'f2)

(**)

(** List of format elements. *)
and fmt('a, 'b, 'c, 'd, 'e, 'f) =
| Char :                                                   (* %c *)
    fmt('a, 'b, 'c, 'd, 'e, 'f) ->
      fmt(char -> 'a, 'b, 'c, 'd, 'e, 'f)
| Caml_char :                                              (* %C *)
    fmt('a, 'b, 'c, 'd, 'e, 'f) ->
      fmt(char -> 'a, 'b, 'c, 'd, 'e, 'f)
| String :                                                 (* %s *)
    padding('x, string -> 'a) * fmt('a, 'b, 'c, 'd, 'e, 'f) ->
      fmt('x, 'b, 'c, 'd, 'e, 'f)
| Caml_string :                                            (* %S *)
    padding('x, string -> 'a) * fmt('a, 'b, 'c, 'd, 'e, 'f) ->
      fmt('x, 'b, 'c, 'd, 'e, 'f)
| Int :                                                    (* %[dixXuo] *)
    int_conv * padding('x, 'y) * precision('y, int -> 'a) *
    fmt('a, 'b, 'c, 'd, 'e, 'f) ->
      fmt('x, 'b, 'c, 'd, 'e, 'f)
| Int32 :                                                  (* %l[dixXuo] *)
    int_conv * padding('x, 'y) * precision('y, int32 -> 'a) *
    fmt('a, 'b, 'c, 'd, 'e, 'f) ->
      fmt('x, 'b, 'c, 'd, 'e, 'f)
| Nativeint :                                              (* %n[dixXuo] *)
    int_conv * padding('x, 'y) * precision('y, nativeint -> 'a) *
    fmt('a, 'b, 'c, 'd, 'e, 'f) ->
      fmt('x, 'b, 'c, 'd, 'e, 'f)
| Int64 :                                                  (* %L[dixXuo] *)
    int_conv * padding('x, 'y) * precision('y, int64 -> 'a) *
    fmt('a, 'b, 'c, 'd, 'e, 'f) ->
      fmt('x, 'b, 'c, 'd, 'e, 'f)
| Float :                                                  (* %[feEgGFhH] *)
    float_conv * padding('x, 'y) * precision('y, float -> 'a) *
    fmt('a, 'b, 'c, 'd, 'e, 'f) ->
      fmt('x, 'b, 'c, 'd, 'e, 'f)
| Bool :                                                   (* %[bB] *)
    padding('x, bool -> 'a) * fmt('a, 'b, 'c, 'd, 'e, 'f) ->
      fmt('x, 'b, 'c, 'd, 'e, 'f)
| Flush :                                                  (* %! *)
    fmt('a, 'b, 'c, 'd, 'e, 'f) ->
      fmt('a, 'b, 'c, 'd, 'e, 'f)

| String_literal :                                         (* abc *)
    string * fmt('a, 'b, 'c, 'd, 'e, 'f) ->
      fmt('a, 'b, 'c, 'd, 'e, 'f)
| Char_literal :                                           (* x *)
    char * fmt('a, 'b, 'c, 'd, 'e, 'f) ->
      fmt('a, 'b, 'c, 'd, 'e, 'f)

| Format_arg :                                             (* %{...%} *)
    pad_option * fmtty('g, 'h, 'i, 'j, 'k, 'l) *
    fmt('a, 'b, 'c, 'd, 'e, 'f) ->
      fmt(format6('g, 'h, 'i, 'j, 'k, 'l) -> 'a, 'b, 'c, 'd, 'e, 'f)
| Format_subst :                                           (* %(...%) *)
    pad_option *
    fmtty_rel('g, 'h, 'i, 'j, 'k, 'l, 'g2, 'b, 'c, 'j2, 'd, 'a) *
    fmt('a, 'b, 'c, 'd, 'e, 'f) ->
    fmt(format6('g, 'h, 'i, 'j, 'k, 'l) -> 'g2, 'b, 'c, 'j2, 'e, 'f)

(* Printf and Format specific constructor. *)
| Alpha :                                                  (* %a *)
    fmt('a, 'b, 'c, 'd, 'e, 'f) ->
      fmt(('b -> 'x -> 'c) -> 'x -> 'a, 'b, 'c, 'd, 'e, 'f)
| Theta :                                                  (* %t *)
    fmt('a, 'b, 'c, 'd, 'e, 'f) ->
      fmt(('b -> 'c) -> 'a, 'b, 'c, 'd, 'e, 'f)

(* Format specific constructor: *)
| Formatting_lit :                                         (* @_ *)
    formatting_lit * fmt('a, 'b, 'c, 'd, 'e, 'f) ->
      fmt('a, 'b, 'c, 'd, 'e, 'f)
| Formatting_gen :                                             (* @_ *)
    formatting_gen('a1, 'b, 'c, 'd1, 'e1, 'f1) *
    fmt('f1, 'b, 'c, 'e1, 'e2, 'f2) -> fmt('a1, 'b, 'c, 'd1, 'e2, 'f2)

(* Scanf specific constructors: *)
| Reader :                                                 (* %r *)
    fmt('a, 'b, 'c, 'd, 'e, 'f) ->
      fmt('x -> 'a, 'b, 'c, ('b -> 'x) -> 'd, 'e, 'f)
| Scan_char_set :                                          (* %[...] *)
    pad_option * char_set * fmt('a, 'b, 'c, 'd, 'e, 'f) ->
      fmt(string -> 'a, 'b, 'c, 'd, 'e, 'f)
| Scan_get_counter :                                       (* %[nlNL] *)
    counter * fmt('a, 'b, 'c, 'd, 'e, 'f) ->
      fmt(int -> 'a, 'b, 'c, 'd, 'e, 'f)
| Scan_next_char :                                         (* %0c *)
    fmt('a, 'b, 'c, 'd, 'e, 'f) ->
    fmt(char -> 'a, 'b, 'c, 'd, 'e, 'f)
  (* %0c behaves as %c for printing, but when scanning it does not
     consume the character from the input stream *)
| Ignored_param :                                          (* %_ *)
    ignored('a, 'b, 'c, 'd, 'y, 'x) * fmt('x, 'b, 'c, 'y, 'e, 'f) ->
      fmt('a, 'b, 'c, 'd, 'e, 'f)

(* Custom printing format *)
| Custom :
    custom_arity('a, 'x, 'y) * (unit -> 'x) * fmt('a, 'b, 'c, 'd, 'e, 'f) ->
    fmt('y, 'b, 'c, 'd, 'e, 'f)

| End_of_format :
      fmt('f, 'b, 'c, 'e, 'e, 'f)

and ignored('a, 'b, 'c, 'd, 'e, 'f) =
  | Ignored_char :
      ignored('a, 'b, 'c, 'd, 'd, 'a)
  | Ignored_caml_char :
      ignored('a, 'b, 'c, 'd, 'd, 'a)
  | Ignored_string :
      pad_option -> ignored('a, 'b, 'c, 'd, 'd, 'a)
  | Ignored_caml_string :
      pad_option -> ignored('a, 'b, 'c, 'd, 'd, 'a)
  | Ignored_int :
      int_conv * pad_option -> ignored('a, 'b, 'c, 'd, 'd, 'a)
  | Ignored_int32 :
      int_conv * pad_option -> ignored('a, 'b, 'c, 'd, 'd, 'a)
  | Ignored_nativeint :
      int_conv * pad_option -> ignored('a, 'b, 'c, 'd, 'd, 'a)
  | Ignored_int64 :
      int_conv * pad_option -> ignored('a, 'b, 'c, 'd, 'd, 'a)
  | Ignored_float :
      pad_option * prec_option -> ignored('a, 'b, 'c, 'd, 'd, 'a)
  | Ignored_bool :
      pad_option -> ignored('a, 'b, 'c, 'd, 'd, 'a)
  | Ignored_format_arg :
      pad_option * fmtty('g, 'h, 'i, 'j, 'k, 'l) ->
        ignored('a, 'b, 'c, 'd, 'd, 'a)
  | Ignored_format_subst :
      pad_option * fmtty('a, 'b, 'c, 'd, 'e, 'f) ->
        ignored('a, 'b, 'c, 'd, 'e, 'f)
  | Ignored_reader :
      ignored('a, 'b, 'c, ('b -> 'x) -> 'd, 'd, 'a)
  | Ignored_scan_char_set :
      pad_option * char_set -> ignored('a, 'b, 'c, 'd, 'd, 'a)
  | Ignored_scan_get_counter :
      counter -> ignored('a, 'b, 'c, 'd, 'd, 'a)
  | Ignored_scan_next_char :
      ignored('a, 'b, 'c, 'd, 'd, 'a)

and format6('a, 'b, 'c, 'd, 'e, 'f) =
  Format of fmt('a, 'b, 'c, 'd, 'e, 'f) * string

val concat_fmtty :
  fmtty_rel('g1, 'b1, 'c1, 'j1, 'd1, 'a1, 'g2, 'b2, 'c2, 'j2, 'd2, 'a2) ->
  fmtty_rel('a1, 'b1, 'c1, 'd1, 'e1, 'f1, 'a2, 'b2, 'c2, 'd2, 'e2, 'f2) ->
  fmtty_rel('g1, 'b1, 'c1, 'j1, 'e1, 'f1, 'g2, 'b2, 'c2, 'j2, 'e2, 'f2)

val erase_rel :
  fmtty_rel('a, 'b, 'c, 'd, 'e, 'f, 'g, 'h, 'i, 'j, 'k, 'l) -> fmtty('a, 'b, 'c, 'd, 'e, 'f)

val concat_fmt :
    fmt('a, 'b, 'c, 'd, 'e, 'f) ->
    fmt('f, 'b, 'c, 'e, 'g, 'h) ->
    fmt('a, 'b, 'c, 'd, 'g, 'h)

type neutral_concat =
  { f:
      'a 'b 'c 'd 'e 'f. [`String of string | `Char of char ] ->
      fmt('a, 'b, 'c, 'd, 'e, 'f) -> fmt('a, 'b, 'c, 'd, 'e, 'f)
  }

val string_concat_map:
  neutral_concat ->
   fmt('a, 'b, 'c, 'd, 'e, 'f) -> fmt('a, 'b, 'c, 'd, 'e, 'f)
(** Helper function for splitting format string and char literal.
    @since 5.4 *)
