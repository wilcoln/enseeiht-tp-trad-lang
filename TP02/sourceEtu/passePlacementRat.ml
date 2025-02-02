(* Module de la passe de gestion des types *)
module PassePlacementRat : Passe.Passe with type t1 = Ast.AstType.programme and type t2 = Ast.AstPlacement.programme =
struct

  open Tds
  open Exceptions
  open Type
  open Ast
  open AstType
  open AstPlacement

  type t1 = Ast.AstType.programme
  type t2 = Ast.AstPlacement.programme
 
    

(* analyse_placement_instruction : AstType.instruction -> AstPlacement.instruction *)
(* Paramètre i : l'instruction à analyser *)
(* Paramètre dep: déplacement *)
(* Paramètre base : registre SB ou LB *)
(* Modifie l'information d'adressage des variables déclarées dans l'instruction et
renvoie un couple contenant l'instruction et  taille des variables déclaréees dans l'instruction *)
let rec analyse_placement_instruction dep base i =
  match i with
  | AstType.Declaration (_, ia) ->
      begin
        match info_ast_to_info ia with
        | InfoVar (_, t, _, _) -> 
          begin 
            modifier_adresse_info dep base ia;
            (getTaille t, i)
          end
        | _ -> raise ErreurInterne
      end
  | AstType.Conditionnelle (c, bthen,belse) ->
      begin 
        analyse_placement_bloc dep base bthen;
        analyse_placement_bloc dep base belse;
        (0, i)
      end
  | AstType.TantQue (c, b) -> 
      begin
        analyse_placement_bloc dep base b;
        (0, i)
      end
  | _ -> (0, i)


(* analyse_placement_bloc : AstType.bloc -> AstPlacement.bloc *)
(* Paramètre li : liste d'instructions à analyser *)
(* Paramètre dep: déplacement *)
(* Paramètre base : registre SB ou LB *)
(* Analyse toutes les instructions du bloc *)
and analyse_placement_bloc dep base li =
  match li with
  | [] -> ()
  | t::q -> 
    begin
      let (taille, _) = analyse_placement_instruction dep base t in
      analyse_placement_bloc (dep+taille) base q
    end


(* analyse_placement_parametres : AstType.parametres -> AstPlacement.parametres *)
(* Paramètre lpia : liste des infos_ast sur les paramètres *)
(* Modifie l'information d'adressage associées aux paramètres et renvoie la taille totale des paramètres *)
let rec analyse_placement_parametres lpia = 
  match lpia with
  | [] -> 0
  | tia::qia -> 
    begin
      match info_ast_to_info tia with
      | InfoVar(_,t,_,_) -> 
        begin
          let tailleq = analyse_placement_parametres qia in
          let taillet = getTaille t in 
          let _ = modifier_adresse_info (-tailleq-taillet) "LB" tia in 
          taillet + tailleq
         end
      | _ -> raise ErreurInterne
     end


(* analyse_placement_fonction: AstType.fonction-> AstPlacement.fonction*)
(* Paramètre fonction : la fonction à analyser *)
(* Analyse les paramètres et le bloc de la fonction
Renvoie  *)
let analyse_placement_fonction fonction = 
  match fonction with 
  | AstType.Fonction(ia,lpia,li,e) ->
    begin 
      let _ = analyse_placement_parametres lpia in
      let _ = analyse_placement_bloc 3 "LB" li in
      match info_ast_to_info ia with
      | InfoFun(_, t, _) -> (getTaille t, Fonction(ia, lpia, li, e))
      | _ -> raise ErreurInterne
    end
  | AstType.Empty -> (0, Empty)


(* analyser : AstType.programme -> AstPlacement.programme *)
(* Paramètre : le programme à analyser *)
(* Analyse le premier bloc de fonctions, le programme puis le deuxième bloc de fonctions et tranforme le programme
en un programme de type AstType.programme *)
let analyser (AstType.Programme (lf1 ,prog, lf2)) =
  let (_, nlf1) = List.split(List.map (analyse_placement_fonction) lf1) in 
  let (_, nlf2) = List.split(List.map (analyse_placement_fonction) lf2) in
  let _ = analyse_placement_bloc 0 "SB" prog in
  Programme (nlf1, prog, nlf2)
end
