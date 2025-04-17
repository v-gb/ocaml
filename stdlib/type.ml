(**************************************************************************)
(*                                                                        *)
(*                                 OCaml                                  *)
(*                                                                        *)
(*                         The OCaml programmers                          *)
(*                                                                        *)
(*   Copyright 2022 Institut National de Recherche en Informatique et     *)
(*     en Automatique.                                                    *)
(*                                                                        *)
(*   All rights reserved.  This file is distributed under the terms of    *)
(*   the GNU Lesser General Public License version 2.1, with the          *)
(*   special exception on linking described in the file LICENSE.          *)
(*                                                                        *)
(**************************************************************************)

(* Type equality witness *)

type eq(_, _) = Equal: eq('a, 'a)

(* Type identifiers *)

module Id = struct
  type id(_) = ..
  module type ID = sig
    type t
    type _ id += Id : id(t)
  end

  type t(!'a) = (module ID with type t = 'a)

  let make (type a) () : t(a) =
    (module struct type t = a type _ id += Id : id(t) end)

  let[@inline] uid (type a) ((module A) : t(a)) =
    Obj.Extension_constructor.id [%extension_constructor A.Id]

  let provably_equal
      (type a b) ((module A) : t(a)) ((module B) : t(b)) : option(eq(a, b))
    =
    match A.Id with B.Id -> Some Equal | _ -> None
end
