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
 
    

(* analyse_placement_instruction : AstType.instruction ->  -> AstPlacement.instruction *)
(* Paramètre i : l'instruction à analyser *)
(* Paramètre dep: déplacement *)
(* Paramètre base : registre SB ou LB *)
(* Vérifie la bonne utilisation de la mémoire et tranforme l'instruction
en une instruction de type AstPlacement.instruction *)
(* Erreur si mauvaise utilisation des identifiants *)
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
        | _ -> failwith "variable not found"
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
(* Vérifie la bonne utilisation des identifiants et tranforme le bloc
en un bloc de type AstPlacement.bloc *)
(* Erreur si mauvaise utilisation des identifiants *)
and analyse_placement_bloc dep base li =
  match li with
  | [] -> ()
  | t::q -> 
    begin
      let (taille, _) = analyse_placement_instruction dep base t in
      analyse_placement_bloc (dep+taille) base q
    end


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
      | _ -> failwith "erreur analyse placemnet paramètre"
     end

(* analyse_placement_fonction : AstType.fonction -> AstPlacement.fonction *)
let analyse_placement_fonction (AstType.Fonction(ia,lpia,li,e)) = 
  let _ = analyse_placement_parametres lpia in
  let _ = analyse_placement_bloc 3 "LB" li in
  match info_ast_to_info ia with
  | InfoFun(_, t, _) -> (getTaille t, Fonction(ia, lpia, li, e))
  | _ -> failwith "error analyse placement fonction"

(* analyser : AstType.ast -> AstPlacement.ast *)
let analyser (AstType.Programme (fonctions,prog)) =
  (*let (taillesFonctions, nFonctions) = List.split (analyse_placement_fonctions 0 "SB" fonctions) in*)
  let (tailleResultatFonctions,nFonctions) = List.split(List.map (analyse_placement_fonction) fonctions) in 
  let _ = List.fold_right (+) tailleResultatFonctions 0 in
  let _ = analyse_placement_bloc 0 "SB" prog in
  Programme (nFonctions, prog)
end
