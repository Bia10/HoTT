Add LoadPath "..".
Require Import Homotopy.

<<<<<<< HEAD
(** The following should probably go somewhere in Paths.v. Hopefully it can
   act as a good subtitute for the rewrite tactic. *)

Lemma hrewrite {A : Type} (P : A -> Type) {x y : A} (p : x == y) : P y -> P x.
Proof.
  intro u.
  induction p.
  exact u.
Defined.

Ltac hrewrite p :=
  match type of p with
    |  ?x == ?y  =>
      pattern x ; apply (hrewrite _ p)
  end.

(** The circle type S^1, as a higher inductive type. We phrase it here
   as a structure so that we can consider having two circles alter on. *)

Structure circleStruct := mkCircle {
  carrier :> Type ;
  base : carrier ;
  loop : base == base ;
  circle_rect :
  (forall (P : carrier -> Type) (pt : P base) (lp : transport loop pt == pt),
    forall x : carrier, P x) ;
  compute_base :
  (forall (P : carrier -> Type) (pt : P base) (lp : transport loop pt == pt), 
    circle_rect P pt lp base == pt);
  compute_loop :
  (forall (P : carrier -> Type) (pt : P base) (lp : transport loop pt == pt), 
    map_dep (circle_rect P pt lp) loop
    == map (transport loop) (compute_base P pt lp) @ lp @  (!compute_base P pt lp))
}.

Implicit Arguments base [c].
Implicit Arguments loop [c].
Implicit Arguments circle_rect [c].
Implicit Arguments compute_base [c].
Implicit Arguments compute_loop [c].

Section NonDependent.

  (** Next we construct the non-dependent version of the circle axioms. *)

  Variable S1 : circleStruct.

  Definition circle_rect' (B : Type) (pt : B) (lp : pt == pt) : S1 -> B.
  Proof.
    apply circle_rect with (P := fun _ => B) (pt := pt).
    (* Since [pt] doesn't depend on [loop], the source [transport loop
       pt] is equivalent to [pt].  The lemma which says this is
       [trans_trivial], so it is tempting to write [apply
       trans_trivial].  However, that would use it to solve the whole
       goal, rather than allowing us to incorporate [lp] as well.  We
       also need to be careful with our path-constructing tactics, lest
       they overzealously use an identity path where we want to use a
       nontrivial self-path. *)
    hrewrite (trans_trivial (@loop S1) pt).
    exact lp.
Defined.

Definition compute_base' (B : Type) (pt : B) (lp : pt == pt) :
  circle_rect' B pt lp base == pt.
Proof.
  unfold circle_rect'.
  apply compute_base with (P := fun _ => B).
Defined.

Definition compute_loop' (B : Type) (pt : B) (lp : pt == pt) :
    map (circle_rect' B pt lp) loop ==
    (compute_base' B pt lp) @ lp @ (!compute_base' B pt lp).
Proof.
  intros B pt lp.
  pose (P := fun _ : S1 => B).
  pose (lp' := trans_trivial (@loop S1) pt @ lp).
  unfold circle_rect'.
  
  path_via (!compute_base P pt lp'
    @ !trans_trivial loop _
    @ map_dep (circle_rect P pt lp') loop
    @ compute_base P pt lp').
  unwhisker.
  moveleft_onleft.
  apply opposite, map_dep_trivial.
  path_via (!trans_trivial loop  _
    @ (!map (transport loop) (compute_base P pt lp'))
    @ map_dep (circle_rect P pt lp') loop
    @ compute_base P pt lp').
  do_opposite_concat.
  associate_right.
  moveright_onleft.
  moveright_left.
  apply compute_loop with (P := P) (pt := pt) (lp := lp').
Defined.

End NonDependent.

(** If the circle is contractible, then UIP holds. *)

Theorem circle_contr_implies_UIP (S1 : circle) : is_contr S1 ->
  forall (A : Type) (x y : A) (p q : x == y), p == q.

Proof.
  intros H A x y p q.
  induction p.
  pose (cq := circle_rect' S1 A x q).
  pose (cqb := cq base).
  pose (cqcb := compute_base' S1 A x q : cqb == x).
  pose (cql := map cq loop : cqb == cqb).
  pose (cqcl := compute_loop' S1 A x q : (!cqcb @ cql @ cqcb == q)).
  path_via (!cqcb @ cql @ cqcb).
  moveleft_onright.
  moveleft_onleft.
  cancel_units.
  cancel_opposites.
  path_via (map cq (idpath base)).
  apply @contr_path2. 
  assumption.
Defined.

(* There is only one circle. *)

Lemma one_circle (A : circle) (B : circle) : A <~> B.
Proof.
  exists (circle_rect' A B base loop).
  apply hequiv_is_equiv with (g := circle_rect' B A base loop).
  intro b.
  path_via (@base B).
  path_via (circle_rect' A B base loop ).

  path_via b.
=======
(** The circle type S^1, as a higher inductive type. We define it as a Coq
   structure so that we can have several circles at the same time. Also, it's a
   bit cleaner because it avoids postulating axioms.
*)

Structure Circle := {
  circle :> Type;
  base : circle;
  loop : base == base;
  circle_rect :
    (forall (P : circle -> Type) (pt : P base) (lp : transport loop pt == pt), 
      forall x : circle, P x);
  compute_base :
    (forall (P : circle -> Type) (pt : P base) (lp : transport loop pt == pt), 
      circle_rect P pt lp base == pt);
  compute_loop :
    (forall P pt lp,
      map_dep (circle_rect P pt lp) loop
      == map (transport loop) (compute_base P pt lp) @ lp @ !compute_base P pt lp)
}.

(* Old compute_loop:

    (forall (P : circle -> Type) (pt : P base) (lp : transport loop pt == pt), 
      (! map (transport loop) (compute_base P pt lp)
        @ (map_dep (circle_rect P pt lp) loop)
        @ (compute_base P pt lp))
      == lp)
*)

Implicit Arguments base [c].
Implicit Arguments loop [c].

Section Non_dependent.

  (** From this we can derive the non-dependent version of the
     eliminator, with its propositional computation rules. *)

  Variable circle : Circle.

  Definition circle_rect' :
    forall (B : Type) (pt : B) (lp : pt == pt), circle -> B.
  Proof.
    intros B pt lp.
    apply circle_rect with (P := fun x => B) (pt := pt).
    (* Since [pt] doesn't depend on [loop], the source [transport loop
       pt] is equivalent to [pt].  The lemma which says this is
       [trans_trivial], so it is tempting to write [apply
       trans_trivial].  However, that would use it to solve the whole
       goal, rather than allowing us to incorporate [lp] as well.  We
       also need to be careful with our path-constructing tactics, lest
       they overzealously use an identity path where we want to use a
       nontrivial self-path. *)
    apply @concat with (y := pt).
    apply trans_trivial.
    exact lp.
  Defined.

  Definition compute_base' :
    forall (B : Type) (pt : B) (lp : pt == pt),
      circle_rect' B pt lp base == pt.
  Proof.
    intros B pt lp.
    unfold circle_rect'.
    apply compute_base with (P := fun x => B).
  Defined.

  Lemma map_dep_trivial2 {A B} {x y : A} (f : A -> B) (p: x == y):
    map f p == !trans_trivial p (f x) @ map_dep f p.
  Proof.
    path_induction.
  Defined.

  Definition compute_loop' : forall B pt lp,
    map (circle_rect' B pt lp) loop
    == compute_base' B pt lp @ lp @ !compute_base' B pt lp.
  Proof.
    intros B pt lp.
    eapply concat.
    apply map_dep_trivial2.
    moveright_onleft.
    eapply concat.
    apply compute_loop with (P := fun _ => B).
    unwhisker.
  Defined.

  (** If the circle is contractible, then UIP holds. *)

  (*
  Theorem circle_contr_implies_UIP : is_contr (circle) ->
    forall (A : Type) (x y : A) (p q : x == y), p == q.
  Proof.
    intros H A x y p q.
    induction p.
    set (cq := circle_rect' A x q).
    set (cqb := cq base).
    set (cqcb := compute_base' A x q : cqb == x).
    set (cql := map cq loop : cqb == cqb).
    set (cqcl := compute_loop' A x q : (!cqcb @ cql @ cqcb == q)).
    path_via (!cqcb @ cql @ cqcb).
    moveleft_onright.
    moveleft_onleft.
    cancel_units.
    cancel_opposites.
    path_via (map cq (idpath base)).
    apply contr_path2.
    assumption.
  Defined.
  *)
End Non_dependent.

>>>>>>> 9628e691209411a23bf90710a5c61af363ced5e4
