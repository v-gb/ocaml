(**************************************************************************)
(*                                                                        *)
(*                                 OCaml                                  *)
(*                                                                        *)
(*                         The OCaml programmers                          *)
(*                                                                        *)
(*   Copyright 2018 Institut National de Recherche en Informatique et     *)
(*     en Automatique.                                                    *)
(*                                                                        *)
(*   All rights reserved.  This file is distributed under the terms of    *)
(*   the GNU Lesser General Public License version 2.1, with the          *)
(*   special exception on linking described in the file LICENSE.          *)
(*                                                                        *)
(**************************************************************************)

(** Result values.

    Result values handle computation results and errors in an explicit
    and declarative manner without resorting to exceptions.

    @since 4.08 *)

(** {1:results Results} *)

type t('a, 'e) = result('a, 'e) = Ok of 'a | Error of 'e (**)
(** The type for result values. Either a value [Ok v] or an error [Error e]. *)

val ok : 'a -> result('a, 'e)
(** [ok v] is [Ok v]. *)

val error : 'e -> result('a, 'e)
(** [error e] is [Error e]. *)

val value : result('a, 'e) -> default:'a -> 'a
(** [value r ~default] is [v] if [r] is [Ok v] and [default] otherwise. *)

val get_ok : result('a, 'e) -> 'a
(** [get_ok r] is [v] if [r] is [Ok v] and raise otherwise.

    @raise Invalid_argument if [r] is [Error _]. *)

val get_ok' : result('a, string) -> 'a
(** [get_ok'] is like {!get_ok} but in case of error uses the
    error message for raising [Invalid_argument].

    @since 5.4 *)

val get_error : result('a, 'e) -> 'e
(** [get_error r] is [e] if [r] is [Error e] and raise otherwise.

    @raise Invalid_argument if [r] is [Ok _]. *)

val error_to_failure : result('a, string) -> 'a
(** [error_to_failure r] is [v] if [r] is [Ok v] and raises [Failure e]
    if [r] is [Error e].

    @since 5.4 *)

val bind : result('a, 'e) -> ('a -> result('b, 'e)) -> result('b, 'e)
(** [bind r f] is [f v] if [r] is [Ok v] and [r] if [r] is [Error _]. *)

val join : result(result('a, 'e), 'e) -> result('a, 'e)
(** [join rr] is [r] if [rr] is [Ok r] and [rr] if [rr] is [Error _]. *)

val map : ('a -> 'b) -> result('a, 'e) -> result('b, 'e)
(** [map f r] is [Ok (f v)] if [r] is [Ok v] and [r] if [r] is [Error _]. *)

val product : result('a, 'e) -> result('b, 'e) -> result('a * 'b, 'e)
(** [product r0 r1] is [Ok (v0, v1)] if [r0] is [Ok v0] and [r1] is [Ok v2]
    and otherwise returns the error of [r0], if any, or the error of [r1].

    @since 5.4 *)

val map_error : ('e -> 'f) -> result('a, 'e) -> result('a, 'f)
(** [map_error f r] is [Error (f e)] if [r] is [Error e] and [r] if
    [r] is [Ok _]. *)

val fold : ok:('a -> 'c) -> error:('e -> 'c) -> result('a, 'e) -> 'c
(** [fold ~ok ~error r] is [ok v] if [r] is [Ok v] and [error e] if [r]
    is [Error e]. *)

val retract : result('a, 'a) -> 'a
(** [retract r] is [v] if [r] is [Ok v] or [Error v].

    @since 5.4 *)

val iter : ('a -> unit) -> result('a, 'e) -> unit
(** [iter f r] is [f v] if [r] is [Ok v] and [()] otherwise. *)

val iter_error : ('e -> unit) -> result('a, 'e) -> unit
(** [iter_error f r] is [f e] if [r] is [Error e] and [()] otherwise. *)

(** {1:preds Predicates and comparisons} *)

val is_ok : result('a, 'e) -> bool
(** [is_ok r] is [true] if and only if [r] is [Ok _]. *)

val is_error : result('a, 'e) -> bool
(** [is_error r] is [true] if and only if [r] is [Error _]. *)

val equal :
  ok:('a -> 'a -> bool) -> error:('e -> 'e -> bool) -> result('a, 'e) ->
  result('a, 'e) -> bool
(** [equal ~ok ~error r0 r1] tests equality of [r0] and [r1] using [ok]
    and [error] to respectively compare values wrapped by [Ok _] and
    [Error _]. *)

val compare :
  ok:('a -> 'a -> int) -> error:('e -> 'e -> int) -> result('a, 'e) ->
  result('a, 'e) -> int
(** [compare ~ok ~error r0 r1] totally orders [r0] and [r1] using [ok] and
    [error] to respectively compare values wrapped by [Ok _ ] and [Error _].
    [Ok _] values are smaller than [Error _] values. *)

(** {1:convert Converting} *)

val to_option : result('a, 'e) -> option('a)
(** [to_option r] is [r] as an option, mapping [Ok v] to [Some v] and
    [Error _] to [None]. *)

val to_list : result('a, 'e) -> list('a)
(** [to_list r] is [[v]] if [r] is [Ok v] and [[]] otherwise. *)

val to_seq : result('a, 'e) -> Seq.t('a)
(** [to_seq r] is [r] as a sequence. [Ok v] is the singleton sequence
    containing [v] and [Error _] is the empty sequence. *)

(** {1:syntax Syntax} *)

(** Binding operators.

    @since 5.4 *)
module Syntax : sig

  val ( let* ) : result('a, 'e) -> ('a -> result('b, 'e)) -> result('b, 'e)
  (** [( let* )] is {!Result.bind}. *)

  val ( and* ) : result('a, 'e) -> result('b, 'e) -> result('a * 'b, 'e)
  (** [( and* )] is {!Result.product}. *)

  val ( let+ ) : result('a, 'e) -> ('a -> 'b) -> result('b, 'e)
  (** [( let+ )] is {!Result.map}. *)

  val ( and+ ) : result('a, 'e) -> result('b, 'e) -> result('a * 'b, 'e)
  (** [( and+ )] is {!Result.product}. *)
end
