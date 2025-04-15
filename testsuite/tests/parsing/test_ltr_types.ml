(* TEST_BELOW *)

let _ : int list * list(int) = [1], [1]
let _ : Hashtbl.t(string, int) = Hashtbl.of_seq (List.to_seq [ "a", 1 ])
type t1('a) = 'a option
type t3(+'a, !'b, _) = ('a * 'b) option
module M = struct
  type e(_) = ..
  type e(_) += A : e(int)
end
type M.e(_) += A : M.e(int)
module type S = sig type t('a) end
module type S2 = S with type t('a) = t3('a, unit, unit)
module type S3 = S with type t('a) := t3('a, unit, unit)
class a<'a, 'b> x = object val x : ('a * 'b) = x end
class b = object inherit a<int, float> (1, 2.) end
type 'a t_a = #a(int, float) as 'a

(* TEST
 setup-ocamlc.byte-build-env;
 ocamlc.byte;
 check-ocamlc.byte-output;
*)
