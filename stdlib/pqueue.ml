(**************************************************************************)
(*                                                                        *)
(*                                 OCaml                                  *)
(*                                                                        *)
(*                       Jean-Christophe Filliâtre                        *)
(*                                                                        *)
(*   Copyright 2023 CNRS                                                  *)
(*                                                                        *)
(*   All rights reserved.  This file is distributed under the terms of    *)
(*   the GNU Lesser General Public License version 2.1, with the          *)
(*   special exception on linking described in the file LICENSE.          *)
(*                                                                        *)
(**************************************************************************)

(* Priority queues over ordered elements.

   We choose to have polymorphic elements here, so that we can later
   derive both polymorphic and monomorphic priority queues from it.
*)

module type OrderedPolyType = sig
  type t('a)
  val compare : t('a) -> t('b) -> int
end

module MakeMinPoly(E: OrderedPolyType) =
  struct

    type elt('a) = E.t('a)

    (* Our priority queues are implemented using the standard "min heap"
       data structure, a dynamic array representing a binary tree. *)
    type t('a) = Dynarray.t(E.t('a))

    let create =
      Dynarray.create

    let length =
      Dynarray.length

    let is_empty =
      Dynarray.is_empty

    let clear =
      Dynarray.clear

    (* The node at index [i] has children nodes at indices [2 * i + 1]
       and [2 * i + 2] -- if they are valid indices in the dynarray. *)
    let left_child i = 2 * i + 1
    let right_child i = 2 * i + 2
    let parent_node i = (i - 1) / 2

    (* We say that a heap respects the "heap ordering" if the value of
       each node is no greater than the value of its children. The
       algorithm manipulates arrays that respect the heap ordering,
       except for one node whose value may be too small or too large.

       The auxiliary functions [sift_up] and [sift_down] take
       such a misplaced value, and move it "up" (respectively: "down")
       until the heap ordering is restored.

       Functions [sift_up] and [sift_down] do not perform swaps, but
       rather expect the value to be assigned in the heap as an
       additional parameter [x], resulting in twice less assignments. *)

    (* store [x] at index [i], moving it up if necessary *)
    let rec sift_up h i x =
      if i = 0 then Dynarray.set h 0 x else
      let p = parent_node i in
      let y = Dynarray.get h p in
      if E.compare x y < 0 then (
        Dynarray.set h i y;
        sift_up h p x
      ) else
        Dynarray.set h i x

    let add h x =
      let i = Dynarray.length h in
      Dynarray.add_last h x;
      if i > 0 then sift_up h i x

    let add_iter h iter x =
      iter (add h) x

    let min_elt h =
      if Dynarray.is_empty h then None else Some (Dynarray.get h 0)

    let get_min_elt h =
      if Dynarray.is_empty h then invalid_arg "empty priority queue";
      Dynarray.get h 0

    let lt h i j =
      E.compare (Dynarray.get h i) (Dynarray.get h j) < 0

    (* store [x] at index [i], moving it down if necessary *)
    let rec sift_down h ~len i x =
      let left = left_child i in
      if left >= len then Dynarray.set h i x (* no child, stop *) else
      let smallest =
        let right = right_child i in
        if right >= len then left (* no right child *) else
        if lt h left right then left else right
      in
      let y = Dynarray.get h smallest in
      if E.compare y x < 0 then (
        Dynarray.set h i y;
        sift_down h ~len smallest x
      ) else
        Dynarray.set h i x

    let pop_min h =
      let n = Dynarray.length h in
      if n = 0 then None else
      let x = Dynarray.pop_last h in
      if n = 1 then Some x else (
        let r = Dynarray.get h 0 in
        sift_down h ~len:(n - 1) 0 x;
        Some r
      )

    let remove_min h =
      let n = Dynarray.length h in
      if n > 0 then (
        let x = Dynarray.pop_last h in
        if n > 1 then sift_down h ~len:(n - 1) 0 x
      )

    let copy =
      Dynarray.copy

    (* array to heap in linear time (Floyd, 1964)

       many elements travel a short distance, few travel longer distances
       and we can show that it totals to O(N) *)
    let heapify h =
      let n = Dynarray.length h in
      for i = n/2 - 1 downto 0 do
        sift_down h ~len:n i (Dynarray.get h i)
      done;
      h

    let of_array a =
      Dynarray.of_array a |> heapify

    let of_list l =
      Dynarray.of_list l |> heapify

    let of_iter iter x =
      let a = Dynarray.create () in
      iter (Dynarray.add_last a) x;
      heapify a

    let iter_unordered =
      Dynarray.iter

    let fold_unordered =
      Dynarray.fold_left

  end

module type MinPoly =
  sig
    type t('a)
    type elt('a)
    val create: unit ->t('a)
    val length: t('a) -> int
    val is_empty: t('a) -> bool
    val add: t('a) -> elt('a) -> unit
    val add_iter: t('a) -> ((elt('a) -> unit) -> 'x -> unit) -> 'x -> unit
    val min_elt: t('a) -> option(elt('a))
    val get_min_elt: t('a) -> elt('a)
    val pop_min: t('a) -> option(elt('a))
    val remove_min: t('a) -> unit
    val clear: t('a) -> unit
    val copy: t('a) -> t('a)
    val of_array: array(elt('a)) -> t('a)
    val of_list: list(elt('a)) -> t('a)
    val of_iter: ((elt('a) -> unit) -> 'x -> unit) -> 'x -> t('a)
    val iter_unordered: (elt('a) -> unit) -> t('a) -> unit
    val fold_unordered: ('acc -> elt('a) -> 'acc) -> 'acc -> t('a) -> 'acc
  end

module type MaxPoly =
  sig
    type t('a)
    type elt('a)
    val create: unit -> t('a)
    val length: t('a) -> int
    val is_empty: t('a) -> bool
    val add: t('a) -> elt('a) -> unit
    val add_iter: t('a) -> ((elt('a) -> unit) -> 'x -> unit) -> 'x -> unit
    val max_elt: t('a) -> option(elt('a))
    val get_max_elt: t('a) -> elt('a)
    val pop_max: t('a) -> option(elt('a))
    val remove_max: t('a) -> unit
    val clear: t('a) -> unit
    val copy: t('a) -> t('a)
    val of_array: array(elt('a)) -> t('a)
    val of_list: list(elt('a)) -> t('a)
    val of_iter: ((elt('a) -> unit) -> 'x -> unit) -> 'x -> t('a)
    val iter_unordered: (elt('a) -> unit) -> t('a) -> unit
    val fold_unordered: ('acc -> elt('a) -> 'acc) -> 'acc -> t('a) -> 'acc
end

module MakeMaxPoly(E: OrderedPolyType)
  : MaxPoly with type elt('a) = E.t('a) =
  struct
    include MakeMinPoly(struct
      type t('a) = E.t('a)
      let compare x y = E.compare y x
    end)
    (* renaming a few functions... *)
    let max_elt = min_elt
    let get_max_elt = get_min_elt
    let pop_max = pop_min
    let remove_max = remove_min
  end

(* Monomorphic priority queues *)

module type OrderedType =
  sig
    type t
    val compare: t -> t -> int
  end

module type Min =
  sig
    type t
    type elt
    val create: unit ->t
    val length: t -> int
    val is_empty: t -> bool
    val add: t -> elt -> unit
    val add_iter: t -> ((elt -> unit) -> 'x -> unit) -> 'x -> unit
    val min_elt: t -> option(elt)
    val get_min_elt: t -> elt
    val pop_min: t -> option(elt)
    val remove_min: t -> unit
    val clear: t -> unit
    val copy: t -> t
    val of_array: array(elt) -> t
    val of_list: list(elt) -> t
    val of_iter: ((elt -> unit) -> 'x -> unit) -> 'x -> t
    val iter_unordered: (elt -> unit) -> t -> unit
    val fold_unordered: ('acc -> elt -> 'acc) -> 'acc -> t -> 'acc
  end

module MakeMin(E: OrderedType) =
  struct
    include MakeMinPoly(struct type t('a) = E.t
                               let compare = E.compare end)
    type t = Dynarray.t(E.t)
  end

module type Max =
  sig
    type t
    type elt
    val create: unit ->t
    val length: t -> int
    val is_empty: t -> bool
    val add: t -> elt -> unit
    val add_iter: t -> ((elt -> unit) -> 'x -> unit) -> 'x -> unit
    val max_elt: t -> option(elt)
    val get_max_elt: t -> elt
    val pop_max: t -> option(elt)
    val remove_max: t -> unit
    val clear: t -> unit
    val copy: t -> t
    val of_array: array(elt) -> t
    val of_list: list(elt) -> t
    val of_iter: ((elt -> unit) -> 'x -> unit) -> 'x -> t
    val iter_unordered: (elt -> unit) -> t -> unit
    val fold_unordered: ('acc -> elt -> 'acc) -> 'acc -> t -> 'acc
  end

module MakeMax(E: OrderedType) =
  struct
    include MakeMinPoly(struct type t('a) = E.t
                               let compare x y = E.compare y x end)
    type t = Dynarray.t(E.t)
    let max_elt = min_elt
    let get_max_elt = get_min_elt
    let pop_max = pop_min
    let remove_max = remove_min
  end
