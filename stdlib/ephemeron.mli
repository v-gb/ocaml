(**************************************************************************)
(*                                                                        *)
(*                                 OCaml                                  *)
(*                                                                        *)
(*             Damien Doligez, projet Para, INRIA Rocquencourt            *)
(*                                                                        *)
(*   Copyright 1997 Institut National de Recherche en Informatique et     *)
(*     en Automatique.                                                    *)
(*                                                                        *)
(*   All rights reserved.  This file is distributed under the terms of    *)
(*   the GNU Lesser General Public License version 2.1, with the          *)
(*   special exception on linking described in the file LICENSE.          *)
(*                                                                        *)
(**************************************************************************)

(** Ephemerons and weak hash tables.

    Ephemerons and weak hash tables are useful when one wants to cache
    or memorize the computation of a function, as long as the
    arguments and the function are used, without creating memory leaks
    by continuously keeping old computation results that are not
    useful anymore because one argument or the function is freed. An
    implementation using {!Hashtbl.t} is not suitable because all
    associations would keep the arguments and the result in memory.

    Ephemerons can also be used for "adding" a field to an arbitrary
    boxed OCaml value: you can attach some information to a value
    created by an external library without memory leaks.

    Ephemerons hold some keys and one or no data. They are all boxed
    OCaml values. The keys of an ephemeron have the same behavior
    as weak pointers according to the garbage collector. In fact
    OCaml weak pointers are implemented as ephemerons without data.

    The keys and data of an ephemeron are said to be full if they
    point to a value, or empty if the value has never been set, has
    been unset, or was erased by the GC. In the function that accesses
    the keys or data these two states are represented by the [option]
    type.

    The data is considered by the garbage collector alive if all the
    full keys are alive and if the ephemeron is alive. When one of the
    keys is not considered alive anymore by the GC, the data is
    emptied from the ephemeron. The data could be alive for another
    reason and in that case the GC will not free it, but the ephemeron
    will not hold the data anymore.

    The ephemerons complicate the notion of liveness of values, because
    it is not anymore an equivalence with the reachability from root
    value by usual pointers (not weak and not ephemerons). With ephemerons
    the notion of liveness is constructed by the least fixpoint of:
       A value is alive if:
        - it is a root value
        - it is reachable from alive value by usual pointers
        - it is the data of an alive ephemeron with all its full keys alive

    Notes:
    - All the types defined in this module cannot be marshaled
    using {!Stdlib.output_value} or the functions of the
    {!Marshal} module.

    Ephemerons are defined in a language agnostic way in this paper:
    B. Hayes, Ephemerons: A New Finalization Mechanism, OOPSLA'97

    @since 4.03
*)

(** {b Unsynchronized accesses} *)

[@@@alert unsynchronized_access
  "Unsynchronized accesses to weak hash tables are a programming error."
]

(**
    Unsynchronized accesses to a weak hash table may lead to an invalid
    weak hash table state. Thus, concurrent accesses to a weak hash table
    must be synchronized (for instance with a {!Mutex.t}).
*)

module type S = sig
  (** Propose the same interface as usual hash table. However since
      the bindings are weak, even if [mem h k] is true, a subsequent
      [find h k] may raise [Not_found] because the garbage collector
      can run between the two.
  *)

  type key
  type t(!'a)
  val create : int -> t('a)
  val clear : t('a) -> unit
  val reset : t('a) -> unit
  val copy : t('a) -> t('a)
  val add : t('a) -> key -> 'a -> unit
  val remove : t('a) -> key -> unit
  val find : t('a) -> key -> 'a
  val find_opt : t('a) -> key -> option('a)
  val find_all : t('a) -> key -> list('a)
  val replace : t('a) -> key -> 'a -> unit
  val mem : t('a) -> key -> bool
  val length : t('a) -> int
  val stats : t('a) -> Hashtbl.statistics
  val add_seq : t('a) -> Seq.t(key * 'a) -> unit
  val replace_seq : t('a) -> Seq.t(key * 'a) -> unit
  val of_seq : Seq.t(key * 'a) -> t('a)

  val clean: t('a) -> unit
  (** remove all dead bindings. Done automatically during automatic resizing. *)

  val stats_alive: t('a) -> Hashtbl.statistics
  (** same as {!Hashtbl.SeededS.stats} but only count the alive bindings *)
end
(** The output signature of the functors {!K1.Make} and {!K2.Make}.
    These hash tables are weak in the keys. If all the keys of a binding are
    alive the binding is kept, but if one of the keys of the binding
    is dead then the binding is removed.
*)

module type SeededS = sig

  type key
  type t(!'a)
  val create : ?random (*thwart tools/sync_stdlib_docs*) : bool -> int -> t('a)
  val clear : t('a) -> unit
  val reset : t('a) -> unit
  val copy : t('a) -> t('a)
  val add : t('a) -> key -> 'a -> unit
  val remove : t('a) -> key -> unit
  val find : t('a) -> key -> 'a
  val find_opt : t('a) -> key -> option('a)
  val find_all : t('a) -> key -> list('a)
  val replace : t('a) -> key -> 'a -> unit
  val mem : t('a) -> key -> bool
  val length : t('a) -> int
  val stats : t('a) -> Hashtbl.statistics
  val add_seq : t('a) -> Seq.t(key * 'a) -> unit
  val replace_seq : t('a) -> Seq.t(key * 'a) -> unit
  val of_seq : Seq.t(key * 'a) -> t('a)

  val clean: t('a) -> unit
  (** remove all dead bindings. Done automatically during automatic resizing. *)

  val stats_alive: t('a) -> Hashtbl.statistics
  (** same as {!Hashtbl.SeededS.stats} but only count the alive bindings *)
end
(** The output signature of the functors {!K1.MakeSeeded} and {!K2.MakeSeeded}.
*)

module K1 : sig
  type t('k,'d) (** an ephemeron with one key *)

  val make : 'k -> 'd -> t('k, 'd)
  (** [Ephemeron.K1.make k d] creates an ephemeron with key [k] and data [d]. *)

  val query : t('k, 'd) -> 'k -> option('d)
  (** [Ephemeron.K1.query eph key] returns [Some x] (where [x] is the
      ephemeron's data) if [key] is physically equal to [eph]'s key, and
      [None] if [eph] is empty or [key] is not equal to [eph]'s key. *)

  module Make (H:Hashtbl.HashedType) : S with type key = H.t
  (** Functor building an implementation of a weak hash table *)

  module MakeSeeded (H:Hashtbl.SeededHashedType) : SeededS with type key = H.t
  (** Functor building an implementation of a weak hash table.
      The seed is similar to the one of {!Hashtbl.MakeSeeded}. *)

  module Bucket : sig

    type t('k, 'd)
    (** A bucket is a mutable "list" of ephemerons. *)

    val make : unit -> t('k, 'd)
    (** Create a new bucket. *)

    val add : t('k, 'd) -> 'k -> 'd -> unit
    (** Add an ephemeron to the bucket. *)

    val remove : t('k, 'd) -> 'k -> unit
    (** [remove b k] removes from [b] the most-recently added
        ephemeron with key [k], or does nothing if there is no such
        ephemeron. *)

    val find : t('k, 'd) -> 'k -> option('d)
    (** Returns the data of the most-recently added ephemeron with the
        given key, or [None] if there is no such ephemeron. *)

    val length : t('k, 'd) -> int
    (** Returns an upper bound on the length of the bucket. *)

    val clear : t('k, 'd) -> unit
    (** Remove all ephemerons from the bucket. *)

  end

end
(** Ephemerons with one key. *)

module K2 : sig
  type t('k1,'k2,'d) (** an ephemeron with two keys *)

  val make : 'k1 -> 'k2 -> 'd -> t('k1, 'k2, 'd)
  (** Same as {!Ephemeron.K1.make} *)

  val query : t('k1, 'k2, 'd) -> 'k1 -> 'k2 -> option('d)
  (** Same as {!Ephemeron.K1.query} *)

  module Make
      (H1:Hashtbl.HashedType)
      (H2:Hashtbl.HashedType) :
    S with type key = H1.t * H2.t
  (** Functor building an implementation of a weak hash table *)

  module MakeSeeded
      (H1:Hashtbl.SeededHashedType)
      (H2:Hashtbl.SeededHashedType) :
    SeededS with type key = H1.t * H2.t
  (** Functor building an implementation of a weak hash table.
      The seed is similar to the one of {!Hashtbl.MakeSeeded}. *)

  module Bucket : sig

    type t('k1, 'k2, 'd)
    (** A bucket is a mutable "list" of ephemerons. *)

    val make : unit -> t('k1, 'k2, 'd)
    (** Create a new bucket. *)

    val add : t('k1, 'k2, 'd) -> 'k1 -> 'k2 -> 'd -> unit
    (** Add an ephemeron to the bucket. *)

    val remove : t('k1, 'k2, 'd) -> 'k1 -> 'k2 -> unit
    (** [remove b k1 k2] removes from [b] the most-recently added
        ephemeron with keys [k1] and [k2], or does nothing if there
        is no such ephemeron. *)

    val find : t('k1, 'k2, 'd) -> 'k1 -> 'k2 -> option('d)
    (** Returns the data of the most-recently added ephemeron with the
        given keys, or [None] if there is no such ephemeron. *)

    val length : t('k1, 'k2, 'd) -> int
    (** Returns an upper bound on the length of the bucket. *)

    val clear : t('k1, 'k2, 'd) -> unit
    (** Remove all ephemerons from the bucket. *)

  end

end
(** Ephemerons with two keys. *)

module Kn : sig
  type t('k,'d) (** an ephemeron with an arbitrary number of keys
                      of the same type *)

  val make : array('k) -> 'd -> t('k, 'd)
  (** Same as {!Ephemeron.K1.make} *)

  val query : t('k, 'd) -> array('k) -> option('d)
  (** Same as {!Ephemeron.K1.query} *)

  module Make
      (H:Hashtbl.HashedType) :
    S with type key = array(H.t)
  (** Functor building an implementation of a weak hash table *)

  module MakeSeeded
      (H:Hashtbl.SeededHashedType) :
    SeededS with type key = array(H.t)
  (** Functor building an implementation of a weak hash table.
      The seed is similar to the one of {!Hashtbl.MakeSeeded}. *)

  module Bucket : sig

    type t('k, 'd)
    (** A bucket is a mutable "list" of ephemerons. *)

    val make : unit -> t('k, 'd)
    (** Create a new bucket. *)

    val add : t('k, 'd) -> array('k) -> 'd -> unit
    (** Add an ephemeron to the bucket. *)

    val remove : t('k, 'd) -> array('k) -> unit
    (** [remove b k] removes from [b] the most-recently added
        ephemeron with keys [k], or does nothing if there is no such
        ephemeron. *)

    val find : t('k, 'd) -> array('k) -> option('d)
    (** Returns the data of the most-recently added ephemeron with the
        given keys, or [None] if there is no such ephemeron. *)

    val length : t('k, 'd) -> int
    (** Returns an upper bound on the length of the bucket. *)

    val clear : t('k, 'd) -> unit
    (** Remove all ephemerons from the bucket. *)

  end

end
(** Ephemerons with arbitrary number of keys of the same type. *)
