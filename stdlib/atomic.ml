(**************************************************************************)
(*                                                                        *)
(*                                 OCaml                                  *)
(*                                                                        *)
(*                 Stephen Dolan, University of Cambridge                 *)
(*                                                                        *)
(*   Copyright 2017-2018 University of Cambridge.                         *)
(*                                                                        *)
(*   All rights reserved.  This file is distributed under the terms of    *)
(*   the GNU Lesser General Public License version 2.1, with the          *)
(*   special exception on linking described in the file LICENSE.          *)
(*                                                                        *)
(**************************************************************************)

type t(!'a)

external make : 'a -> t('a) = "%makemutable"
external make_contended : 'a -> t('a) = "caml_atomic_make_contended"
external get : t('a) -> 'a = "%atomic_load"
external exchange : t('a) -> 'a -> 'a = "%atomic_exchange"
external compare_and_set : t('a) -> 'a -> 'a -> bool = "%atomic_cas"
external fetch_and_add : t(int) -> int -> int = "%atomic_fetch_add"
external ignore : 'a -> unit = "%ignore"

let set r x = ignore (exchange r x)
let incr r = ignore (fetch_and_add r 1)
let decr r = ignore (fetch_and_add r (-1))
