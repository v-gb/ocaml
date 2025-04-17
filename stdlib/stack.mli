(**************************************************************************)
(*                                                                        *)
(*                                 OCaml                                  *)
(*                                                                        *)
(*             Xavier Leroy, projet Cristal, INRIA Rocquencourt           *)
(*                                                                        *)
(*   Copyright 1996 Institut National de Recherche en Informatique et     *)
(*     en Automatique.                                                    *)
(*                                                                        *)
(*   All rights reserved.  This file is distributed under the terms of    *)
(*   the GNU Lesser General Public License version 2.1, with the          *)
(*   special exception on linking described in the file LICENSE.          *)
(*                                                                        *)
(**************************************************************************)

(** Last-in first-out stacks.

   This module implements stacks (LIFOs), with in-place modification.
*)

(** {b Unsynchronized accesses} *)

[@@@alert unsynchronized_access
    "Unsynchronized accesses to stacks are a programming error."
]

 (**
    Unsynchronized accesses to a stack may lead to an invalid queue state.
    Thus, concurrent accesses to stacks must be synchronized (for instance
    with a {!Mutex.t}).
*)

type t(!'a)
(** The type of stacks containing elements of type ['a]. *)

exception Empty
(** Raised when {!Stack.pop} or {!Stack.top} is applied to an empty stack. *)


val create : unit -> t('a)
(** Return a new stack, initially empty. *)

val push : 'a -> t('a) -> unit
(** [push x s] adds the element [x] at the top of stack [s]. *)

val pop : t('a) -> 'a
(** [pop s] removes and returns the topmost element in stack [s],
   or raises {!Empty} if the stack is empty. *)

val pop_opt : t('a) -> option('a)
(** [pop_opt s] removes and returns the topmost element in stack [s],
   or returns [None] if the stack is empty.
   @since 4.08 *)

val drop : t('a) -> unit
(** [drop s] removes the topmost element in stack [s],
   or raises {!Empty} if the stack is empty.
   @since 5.1 *)

val top : t('a) -> 'a
(** [top s] returns the topmost element in stack [s],
   or raises {!Empty} if the stack is empty. *)

val top_opt : t('a) -> option('a)
(** [top_opt s] returns the topmost element in stack [s],
   or [None] if the stack is empty.
   @since 4.08 *)

val clear : t('a) -> unit
(** Discard all elements from a stack. *)

val copy : t('a) -> t('a)
(** Return a copy of the given stack. *)

val is_empty : t('a) -> bool
(** Return [true] if the given stack is empty, [false] otherwise. *)

val length : t('a) -> int
(** Return the number of elements in a stack. Time complexity O(1) *)

val iter : ('a -> unit) -> t('a) -> unit
(** [iter f s] applies [f] in turn to all elements of [s],
   from the element at the top of the stack to the element at the
   bottom of the stack. The stack itself is unchanged. *)

val fold : ('acc -> 'a -> 'acc) -> 'acc -> t('a) -> 'acc
(** [fold f accu s] is [(f (... (f (f accu x1) x2) ...) xn)]
    where [x1] is the top of the stack, [x2] the second element,
    and [xn] the bottom element. The stack is unchanged.
    @since 4.03 *)

(** {1 Stacks and Sequences} *)

val to_seq : t('a) -> Seq.t('a)
(** Iterate on the stack, top to bottom.
    It is safe to modify the stack during iteration.
    @since 4.07 *)

val add_seq : t('a) -> Seq.t('a) -> unit
(** Add the elements from the sequence on the top of the stack.
    @since 4.07 *)

val of_seq : Seq.t('a) -> t('a)
(** Create a stack from the sequence.
    @since 4.07 *)
