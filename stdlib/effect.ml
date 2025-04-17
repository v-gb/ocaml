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

type t('a) = eff('a) = ..
external perform : t('a) -> 'a = "%perform"

type exn += Unhandled: t('a) -> exn
exception Continuation_already_resumed

let () =
  let printer = function
    | Unhandled x ->
        let msg = Printf.sprintf "Stdlib.Effect.Unhandled(%s)"
            (Printexc.string_of_extension_constructor @@ Obj.repr x)
        in
        Some msg
    | _ -> None
  in
  Printexc.register_printer printer

(* Register the exceptions so that the runtime can access it *)
type _ t += Should_not_see_this__ : t(unit)
let _ = Callback.register_exception "Effect.Unhandled"
          (Unhandled Should_not_see_this__)
let _ = Callback.register_exception "Effect.Continuation_already_resumed"
          Continuation_already_resumed

type stack('a, 'b) [@@immediate]
type last_fiber [@@immediate]

external resume :
  stack('a, 'b) -> ('c -> 'a) -> 'c -> last_fiber -> 'b = "%resume"
external runstack : stack('a, 'b) -> ('c -> 'a) -> 'c -> 'b = "%runstack"

module Deep = struct

  type nonrec continuation('a,'b) = continuation('a, 'b)

  external take_cont_noexc : continuation('a, 'b) -> stack('a, 'b) =
    "caml_continuation_use_noexc" [@@noalloc]
  external alloc_stack :
    ('a -> 'b) ->
    (exn -> 'b) ->
    (t('c) -> continuation('c, 'b) -> last_fiber -> 'b) ->
    stack('a, 'b) = "caml_alloc_stack"
  external cont_last_fiber : continuation('a, 'b) -> last_fiber = "%field1"

  let continue k v =
    resume (take_cont_noexc k) (fun x -> x) v (cont_last_fiber k)

  let discontinue k e =
    resume (take_cont_noexc k) (fun e -> raise e) e (cont_last_fiber k)

  let discontinue_with_backtrace k e bt =
    resume (take_cont_noexc k) (fun e -> Printexc.raise_with_backtrace e bt)
      e (cont_last_fiber k)

  type handler('a,'b) =
    { retc: 'a -> 'b;
      exnc: exn -> 'b;
      effc: 'c.t('c) -> option(continuation('c, 'b) -> 'b) }

  external reperform :
    t('a) -> continuation('a, 'b) -> last_fiber -> 'b = "%reperform"

  let match_with comp arg handler =
    let effc eff k last_fiber =
      match handler.effc eff with
      | Some f -> f k
      | None -> reperform eff k last_fiber
    in
    let s = alloc_stack handler.retc handler.exnc effc in
    runstack s comp arg

  type effect_handler('a) =
    { effc: 'b. t('b) -> option(continuation('b, 'a) -> 'a) }

  let try_with comp arg handler =
    let effc' eff k last_fiber =
      match handler.effc eff with
      | Some f -> f k
      | None -> reperform eff k last_fiber
    in
    let s = alloc_stack (fun x -> x) (fun e -> raise e) effc' in
    runstack s comp arg

  external get_callstack :
    continuation('a, 'b) -> int -> Printexc.raw_backtrace =
    "caml_get_continuation_callstack"
end

module Shallow = struct

  type continuation('a,'b)

  external alloc_stack :
    ('a -> 'b) ->
    (exn -> 'b) ->
    (t('c) -> continuation('c, 'b) -> last_fiber -> 'b) ->
    stack('a, 'b) = "caml_alloc_stack"

  external cont_last_fiber : continuation('a, 'b) -> last_fiber = "%field1"

  let fiber : type a b. (a -> b) -> continuation(a, b) = fun f ->
    let module M = struct type _ t += Initial_setup__ : t(a) end in
    let exception E of continuation(a, b) in
    let f' () = f (perform M.Initial_setup__) in
    let error _ = failwith "impossible" in
    let effc eff k _last_fiber =
      match eff with
      | M.Initial_setup__ -> raise_notrace (E k)
      | _ -> error ()
    in
    let s = alloc_stack error error effc in
    match runstack s f' () with
    | exception E k -> k
    | _ -> error ()

  type handler('a,'b) =
    { retc: 'a -> 'b;
      exnc: exn -> 'b;
      effc: 'c.t('c) -> option(continuation('c, 'a) -> 'b) }

  external update_handler :
    continuation('a, 'b) ->
    ('b -> 'c) ->
    (exn -> 'c) ->
    (t('d) -> continuation('d, 'b) -> last_fiber -> 'c) ->
    stack('a, 'c) = "caml_continuation_use_and_update_handler_noexc" [@@noalloc]

  external reperform :
    t('a) -> continuation('a, 'b) -> last_fiber -> 'c = "%reperform"

  let continue_gen k resume_fun v handler =
    let effc eff k last_fiber =
      match handler.effc eff with
      | Some f -> f k
      | None -> reperform eff k last_fiber
    in
    let last_fiber = cont_last_fiber k in
    let stack = update_handler k handler.retc handler.exnc effc in
    resume stack resume_fun v last_fiber

  let continue_with k v handler =
    continue_gen k (fun x -> x) v handler

  let discontinue_with k v handler =
    continue_gen k (fun e -> raise e) v handler

  let discontinue_with_backtrace k v bt handler =
    continue_gen k (fun e -> Printexc.raise_with_backtrace e bt) v handler

  external get_callstack :
    continuation('a, 'b) -> int -> Printexc.raw_backtrace =
    "caml_get_continuation_callstack"
end
