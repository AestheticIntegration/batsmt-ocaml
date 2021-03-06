
module Ctx : sig
  type t

  val create : unit -> t
end

module Lit : sig
  type t

  val abs : t -> t
  val neg : t -> t
  val to_int : t -> int
  val sign : t -> bool
  val to_string : t -> string
  val pp : Format.formatter -> t -> unit
  val equal : t -> t -> bool
  val compare : t -> t -> int
  val hash : t -> int
end

module Ty : sig
  type t

  val id : t -> int

  val equal : t -> t -> bool
  val hash : t -> int
  val compare : t -> t -> int

  val mk_bool : Ctx.t -> t
  val mk_str : Ctx.t -> string -> t

  type view =
    | Bool
    | Const of string

  (* TODO: val view : Ctx.t -> t -> view *)
  (* TODO: val pp : Ctx.t -> t printer *)
end

module Term : sig
  type t

  val id: t -> int

  val equal : t -> t -> bool
  val hash : t -> int
  val compare : t -> t -> int

  val mk_const : Ctx.t -> string -> Ty.t list -> Ty.t -> t
  val mk_cstor : Ctx.t -> string -> Ty.t list -> Ty.t -> t
  val mk_select: Ctx.t -> cstor:t -> int -> t -> t
  val mk_bool : Ctx.t -> bool -> t
  val mk_eq : Ctx.t -> t -> t -> t
  val mk_not : Ctx.t -> t -> t
  val app_l : Ctx.t -> t -> t list -> t
  val app_a : Ctx.t -> t -> t array -> t

  type view =
    | Bool of bool
    | App of t * t list
    | Cst_unin of string
    | Cst_cstor of string
    | Select of {
        c: t;
        idx: int;
        sub: t;
      }
    | Not of t

  val view : Ctx.t -> t -> view

  (* FIXME:
  val ty : Ctx.t -> t -> Ty.t
     *)

  (** Printing, based on {!view} *)
  val pp : Ctx.t -> Format.formatter -> t -> unit

  (* TODO
     - selectors
   *)

  val __undef : t (** do not use in any method *)
end

module Lbool : sig
  type t = True | False | Undefined
  val equal : t -> t -> bool
  val to_string : t -> string
  val neg : t -> t
  val of_bool : bool -> t
  val pp : Format.formatter -> t -> unit
end

type res =
  | Sat
  | Unsat

exception E_unsat

module Solver : sig
  type t

  val create : Ctx.t -> t

  val add_clause_l : t -> Lit.t list -> unit
  val add_clause_a : t -> Lit.t array -> unit

  val make_lit : t -> Lit.t
  (** Make a pure boolean literal *)

  val make_term_lit : t -> Ctx.t -> Term.t -> Lit.t
  (** Make a literal associated with the given term *)

  val simplify : t -> res
  (** Boolean simplification *)

  val simplify_exn : t -> unit
  (** Same as {!simplify} but:
      @raise E_unsat if problem is unsat *)

  val solve_a : ?assumptions:Lit.t array -> t -> Ctx.t -> res
  val solve : ?assumptions:Lit.t list -> t -> Ctx.t -> res

  val solve_exn_a : ?assumptions:Lit.t array -> t -> Ctx.t -> unit
  (** Same as {!solve_a}, but @raise E_unsat if unsat *)

  val solve_exn : ?assumptions:Lit.t list -> t -> Ctx.t -> unit
  (** Same as {!solve}, but @raise E_unsat if unsat *)

  val unsat_core : t -> Lit.t array
  val unsat_core_contains : t -> Lit.t -> bool
  val value_lvl_0 : t -> Lit.t -> Lbool.t

  (** Value in the model *)
  val value : t -> Lit.t -> Lbool.t

  val n_proved_lvl_0 : t -> int
  val proved_lvl_0 : t -> int -> Lit.t

  val n_lits : t -> int
  val n_clauses : t -> int
  val n_conflicts : t -> int
  val n_decisions: t -> int
  val n_props : t -> int
end

val set_log_lvl : string -> unit
