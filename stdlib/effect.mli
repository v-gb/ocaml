(**************************************************************************)
(*                                                                        *)
(*                                 OCaml                                  *)
(*                                                                        *)
(*      KC Sivaramakrishnan, Indian Institute of Technology, Madras       *)
(*                                                                        *)
(*   Copyright 2021 Indian Institute of Technology, Madras                *)
(*                                                                        *)
(*   All rights reserved.  This file is distributed under the terms of    *)
(*   the GNU Lesser General Public License version 2.1, with the          *)
(*   special exception on linking described in the file LICENSE.          *)
(*                                                                        *)
(**************************************************************************)

(** Effects.

    See 'Language extensions/Effect handlers' section in the manual.

    @since 5.0 *)

[@@@alert unstable
    "The Effect interface may change in incompatible ways in the future."
]

type t('a) = eff('a) = ..
(** The type of effects. *)

exception Unhandled : t('a) -> exn
(** [Unhandled e] is raised when effect [e] is performed and there is no
    handler for it. *)

exception Continuation_already_resumed
(** Exception raised when a continuation is continued or discontinued more
    than once. *)

external perform : t('a) -> 'a = "%perform"
(** [perform e] performs an effect [e].

    @raise Unhandled if there is no handler for [e]. *)

module Deep : sig
  (** Deep handlers *)

  type nonrec continuation('a,'b) = continuation('a, 'b)
  (** [('a,'b) continuation] is a delimited continuation that expects a ['a]
      value and returns a ['b] value. *)

  val continue: continuation('a, 'b) -> 'a -> 'b
  (** [continue k x] resumes the continuation [k] by passing [x] to [k].

      @raise Continuation_already_resumed if the continuation has already been
      resumed. *)

  val discontinue: continuation('a, 'b) -> exn -> 'b
  (** [discontinue k e] resumes the continuation [k] by raising the
      exception [e] in [k].

      @raise Continuation_already_resumed if the continuation has already been
      resumed. *)

  val discontinue_with_backtrace:
    continuation('a, 'b) -> exn -> Printexc.raw_backtrace -> 'b
  (** [discontinue_with_backtrace k e bt] resumes the continuation [k] by
      raising the exception [e] in [k] using [bt] as the origin for the
      exception.

      @raise Continuation_already_resumed if the continuation has already been
      resumed. *)

  type handler('a,'b) =
    { retc: 'a -> 'b;
      exnc: exn -> 'b;
      effc: 'c.t('c) -> option(continuation('c, 'b) -> 'b) }
  (** [('a,'b) handler] is a handler record with three fields -- [retc]
      is the value handler, [exnc] handles exceptions, and [effc] handles the
      effects performed by the computation enclosed by the handler. *)

  val match_with: ('c -> 'a) -> 'c -> handler('a, 'b) -> 'b
  (** [match_with f v h] runs the computation [f v] in the handler [h]. *)

  type effect_handler('a) =
    { effc: 'b. t('b) -> option(continuation('b, 'a) -> 'a) }
  (** ['a effect_handler] is a deep handler with an identity value handler
      [fun x -> x] and an exception handler that raises any exception
      [fun e -> raise e]. *)

  val try_with: ('b -> 'a) -> 'b -> effect_handler('a) -> 'a
  (** [try_with f v h] runs the computation [f v] under the handler [h]. *)

  external get_callstack :
    continuation('a, 'b) -> int -> Printexc.raw_backtrace =
    "caml_get_continuation_callstack"
  (** [get_callstack c n] returns a description of the top of the call stack on
      the continuation [c], with at most [n] entries. *)
end

module Shallow : sig
  (* Shallow handlers *)

  type continuation('a,'b)
  (** [('a,'b) continuation] is a delimited continuation that expects a ['a]
      value and returns a ['b] value. *)

  val fiber : ('a -> 'b) -> continuation('a, 'b)
  (** [fiber f] constructs a continuation that runs the computation [f]. *)

  type handler('a,'b) =
    { retc: 'a -> 'b;
      exnc: exn -> 'b;
      effc: 'c.t('c) -> option(continuation('c, 'a) -> 'b) }
  (** [('a,'b) handler] is a handler record with three fields -- [retc]
      is the value handler, [exnc] handles exceptions, and [effc] handles the
      effects performed by the computation enclosed by the handler. *)

  val continue_with : continuation('c, 'a) -> 'c -> handler('a, 'b) -> 'b
  (** [continue_with k v h] resumes the continuation [k] with value [v] with
      the handler [h].

      @raise Continuation_already_resumed if the continuation has already been
      resumed.
   *)

  val discontinue_with : continuation('c, 'a) -> exn -> handler('a, 'b) -> 'b
  (** [discontinue_with k e h] resumes the continuation [k] by raising the
      exception [e] with the handler [h].

      @raise Continuation_already_resumed if the continuation has already been
      resumed.
   *)

  val discontinue_with_backtrace :
    continuation('a, 'b) -> exn -> Printexc.raw_backtrace ->
    handler('b, 'c) -> 'c
  (** [discontinue_with k e bt h] resumes the continuation [k] by raising the
      exception [e] with the handler [h] using the raw backtrace [bt] as the
      origin of the exception.

      @raise Continuation_already_resumed if the continuation has already been
      resumed.
   *)

  external get_callstack :
    continuation('a, 'b) -> int -> Printexc.raw_backtrace =
    "caml_get_continuation_callstack"
  (** [get_callstack c n] returns a description of the top of the call stack on
      the continuation [c], with at most [n] entries. *)
end
