(* Module de la passe de gestion des types *)
module PasseCodeRatToTam : Passe.Passe with type t1 = Ast.AstPlacement.programme and type t2 = string =
struct

  open String
  open Tds
  open Exceptions
  open Type
  open Ast
  open AstType
  open AstPlacement
  open Code
  open PasseTypeRat

  type t1 = Ast.AstPlacement.programme
  type t2 = string


(***************************************************)
(* Quelques fonctions utilitaires pour cette passe *)
(***************************************************)

(* str_split : string -> string list *)
(* Paramètre s : la chaine de caractère à traiter *)
(* Décompose la chaine en list de sous chaine d'1 caractère et renvoie cette liste *)
let str_split s =
  let rec aux i l =
    if i < 0 then l else aux (i - 1) ((sub s i 1) :: l) in
  aux (String.length s - 1) []


(* get_adresse_pointe : AstPlacement.affectable -> string *)
(* Paramètre a : un affectable qui est de type pointeur *)
(* Renvoie le code tam qui permet de récupérer l'adresse pointée par un a *)
let rec get_adresse_pointe a = 
    match a with 
    | Ident(ia) -> 
      begin
        match info_ast_to_info ia with 
        | InfoVar (_, t, base, reg) -> "LOAD (1) "^(string_of_int base)^"["^reg^"]\n"
        | _ -> raise ErreurInterne
      end
    | Contenu (pa, _) -> (get_adresse_pointe pa)^"LOADI (1)\n"


(* string_taille_of_type : typ -> string *)
(* Paramètre t : un type du langage rat *)
(* Convertit la taille du type en chaine de caractère et renvoie le résultat *)
let string_taille_of_type t = string_of_int (getTaille t)


(* get_type_param : info_ast -> typ *)
(* Paramètre pia : l'info_ast associé à un paramètre *)
(* Récupérer le type d'un paramètre à partir de son info_ast *)
let get_type_param pia = 
  begin 
     match info_ast_to_info pia with 
     | InfoVar(_,t,_,_) -> t 
     | _ -> raise ErreurInterne 
     (* à ce stade l'info d'un paramètre est forcément une InfoVar *)
  end
  
(************Fin fonction utilitaires ************)



(* analyse_code_affectable : AstPlacement.affectable *)
(* Paramètre a: l'affectable à analyser *)
(* Construit le code tam correspondant le renvoie *)
let rec analyse_code_affectable a = 
    match a with 
    | Ident (ia) -> 
      (* Si l'affectable est un identifiant on charge juste sa valeur *)
      begin
        match info_ast_to_info ia with
          | InfoVar(n, t, base, reg) -> "LOAD ("^(string_taille_of_type t)^") "^(string_of_int base)^"["^reg^"]\n" 
          | InfoConst(n, v) -> "LOADL "^(string_of_int v)^"\n"
          | _ -> raise ErreurInterne
      end
    | Contenu (a, tp) ->
    (* Si l'affectable est un déréférencement d'affectable,
    on analyse l'affectable à déréférencer et on le déréférence *)
      begin 
        let ca = analyse_code_affectable a in 
        ca^"LOADI ("^(string_taille_of_type tp)^")\n" 
      end


(* analyse_code_expression : AstPlacement.expression *)
(* Paramètre e: l'expression à analyser *)
(* Construit le code tam correspondant le renvoie *)
let rec analyse_code_expression e = 
    match e with 
    | AppelFonction(ia, le, lte) -> 
      begin
        match info_ast_to_info ia with
          | InfoFun(n, t , bltl) -> 
            begin
              (* On récupère le nom de la fonction à appeler à partir des types des expressions passées en arguments *)
              let suffix = List.fold_right (fun te tq -> (string_of_type te)^tq) lte "" in
              let nom_fonction = n^suffix in 
              (* On analyse chacune des expressions passées en argument *)
              let cle = List.fold_right (fun t tq -> (analyse_code_expression t)^tq) le "" in 
              (* Enfin, on fait l'appel à la fonction *)
              cle^"CALL (SB) "^nom_fonction^"\n"
            end
          | _ -> raise ErreurInterne
      end
      | Affectable a -> analyse_code_affectable a
      | Null -> "SUBR MVoid\n"
      | New (tp) -> "LOADL "^(string_taille_of_type tp)^"\nSUBR MAlloc\n"
      | Adresse (ia) -> 
           begin 
            match info_ast_to_info ia with 
            | InfoVar(n, t, base, reg) -> "LOADA "^(string_of_int base)^"["^reg^"]\n"
            | _ -> raise ErreurInterne
           end
    | Rationnel (e1, e2) -> 
      begin
        let c1 = analyse_code_expression e1 in 
        let c2 = analyse_code_expression e2 in
        c1^c2
      end
    | Numerateur (e) -> 
      begin
        let ce = analyse_code_expression e in 
        ce^"LOAD (1) -2[ST]\n"
      end
    | Denominateur (e) -> 
    begin
      let ce = analyse_code_expression e in 
      ce^"LOAD (1) -1[ST]\n"
    end
    | True -> "LOADL 1\nSUBR I2B\n"
    | False -> "LOADL 0\nSUBR I2B\n"
    | Entier (i) -> "LOADL "^(string_of_int i)^"\n"
    | Chaine s ->
      begin
        let taille_chaine = length s in 
        (* On décompose la chaine en sous chaine d'1 caractère *)
        let char_lst = str_split s in
        (* On charge 1 + taille de la chaine  *)
        "LOADL "^(string_of_int (1 + taille_chaine))^"\n"^
        (* On alloue l'espace pour la structure *)
        "SUBR MAlloc\n"^
        (* On charge la taille de la chaine :  premier élt de la structure *)
        "LOADL "^(string_of_int taille_chaine)^"\n"^
        (* On charge successivement chaque caractère de la chaine : prochains élts de la structure *)
        (List.fold_right (fun t tq -> "LOADL '"^t^"'\n"^tq) char_lst "")^
        (* On récupère l'adresse de l'espace alloué plus haut *)
        "LOAD (1) -"^(string_of_int (2 + taille_chaine))^"[ST]\n"^
        (* On stock la structure à cette adresse*)
        "STOREI ("^(string_of_int (1 + taille_chaine))^")\n"
      end
    | SousChaine (e1, e2, e3) ->
      begin
        (* On analyse chaque expression *)
        let c1 = analyse_code_expression e1 in 
        let c2 = analyse_code_expression e2 in
        let c3 = analyse_code_expression e3 in
        (* On appelle la fonction fournie *)
        c1^c2^c3^"CALL (SB) SSub\n"
      end
    | Longueur e -> 
      begin 
        (* On charge la pointeur sur la structure de la chaine *)
        let ce = analyse_code_expression e in
        (* On charge le premier élément de la structure, 
        Il s'agit de la longueur *)
        ce^"\nLOADI (1)\n"
      end
    | Binaire (b, e1, e2) -> 
      begin
        let c1 = analyse_code_expression e1 in 
        let c2 = analyse_code_expression e2 in
        match b with
        | PlusInt -> c1^c2^"SUBR IAdd\n"
        | PlusRat -> c1^c2^"CALL (SB) RAdd\n"
        | MultInt -> c1^c2^"SUBR IMul\n"
        | MultRat -> c1^c2^"CALL (SB) RMul\n"
        | EquBool -> c1^c2^"SUBR BAnd\n"^c1^"SUBR BNeg\n"^c2^"SUBR BNeg\n"^"SUBR BAnd\n"^"SUBR BOr\n"
        | EquInt -> c1^c2^"SUBR IEq\n"
        | Inf -> c1^c2^"SUBR ILss\n"
        | Concat -> c1^c2^"CALL (SB) Scat\n"
      end


(* analyse_code_bloc: AstPlacement.bloc -> string *)
(* Paramètre b : le bloc à analyser *)
(* Analyse chacune des instructions du bloc *)
let rec analyse_code_bloc b = 
    match b with 
    | [] -> ""
    | i::q -> (analyse_code_instruction i)^(analyse_code_bloc q)


(* analyse_code_instruction: AstPlacement.instruction -> string *)
(* Paramètre i : l'instruction à analyser *)
(* Analyse les expressions, construit le code tam de l'instruction et le renvoie *)
and analyse_code_instruction i =
    match i with
    | Declaration (e, ia) ->
        begin
          match info_ast_to_info ia with
          | InfoVar (_, t, base, reg) -> 
            begin 
              let ce = analyse_code_expression e in 
              "PUSH "^(string_of_int (getTaille t))^"\n"^ce^"STORE ("^(string_of_int (getTaille t))^") "^(string_of_int base)^"["^reg^"]\n"
              end
          | _ -> raise ErreurInterne
        end
    | Affectation (a, e) ->
        begin
          (* On analyse l'expression à affecter *)
          let ce = analyse_code_expression e in 
          match a with
          | Ident(ia) ->
            begin
              (* Si l'affectable est un identifiant on fait un STORE à l'adresse de son info *)
              match info_ast_to_info ia with 
              | InfoVar (_, t, base, reg) -> ce^"STORE ("^(string_taille_of_type t)^") "^(string_of_int base)^"["^reg^"]\n"
              | _ -> raise ErreurInterne
            end
          | Contenu (a, tp) -> 
            begin 
              (* Si l'affectable est un contenu on charge d'abord l'adresse pointé par l'affectable,
              et à cette adresse on fait un STOREI *)  
              ce^(get_adresse_pointe a)^"STOREI ("^(string_taille_of_type tp)^")\n"
            end
        end
    | AffichageInt e -> let ce = analyse_code_expression e in ce^"SUBR IOut\n"
    | AffichageRat e -> let ce = analyse_code_expression e in ce^"CALL (SB) ROut\n"
    | AffichageBool e -> let ce = analyse_code_expression e in ce^"SUBR BOut\n"
    | AffichageString e -> let ce = analyse_code_expression e in ce^"CALL (SB) SOut\n"
    | Conditionnelle (c, t, e) ->
        begin
          let codeC = analyse_code_expression c in 
          let codeT = analyse_code_bloc t in 
          let codeE = analyse_code_bloc e in 
          let labelElse = getEtiquette () in 
          let labelFinElse = getEtiquette () in 
          codeC^"JUMPIF (0) "^labelElse^"\n"^codeT^"JUMP "^labelFinElse^"\n\n"^labelElse^"\n"^codeE^"\n\n"^labelFinElse^"\n"
        end
    | TantQue (c, b) ->
        begin
          let codeC = analyse_code_expression c in 
          let codeB = analyse_code_bloc b in 
          let labelDebutTantQue = getEtiquette () in
          let labelFinTantQue = getEtiquette () in 
          let code = "\n"^labelDebutTantQue^"\n"^codeC^"JUMPIF (0) "^labelFinTantQue^"\n"^codeB^"JUMP "^labelDebutTantQue^"\n\n"^labelFinTantQue^"\n" in 
          code
        end
    | Empty -> ""


(* analyse_code_fonction: AstPlacement.fonction -> string *)
(* Paramètre fonction : la fonction à analyser *)
(* Analyse le bloc d'instruction et l'expression de retour de la fonction, puis le code tam correspondant *)
let analyse_code_fonction fonction = 
  match fonction with 
  | Fonction(ia, lpia, li, e) -> 
      begin
        match info_ast_to_info ia with 
        | InfoFun(n,t,_) -> 
          begin 
            (* On récupère la signature de la fonction à partir de ses paramètres *)
            let lt = List.map get_type_param lpia in
            (* On crée un suffix unique pour cette signature *)
            let unique_suffix = List.fold_right (fun te tq -> (string_of_type te)^tq) lt "" in
            (* On crée le label de la fonction en utilisant le suffix unique précédent *)
            let labelFonction = n^unique_suffix in 
            (* On récupère la taille totale des paramètres*)
            let taille_params = List.fold_right (+) (List.map getTaille lt) 0 in 
            (* On analyse le bloc d'instruction de la fonction *)
            let cb = analyse_code_bloc li in
            (* On analyse l'expression de retour de la fonction *)
            let ce = analyse_code_expression e in
            labelFonction^"\n"^cb^ce^"RETURN ("^(string_taille_of_type t)^") "^(string_of_int taille_params)^"\n"
          end
        | _ -> raise ErreurInterne
        end
  | Empty -> ""

(* analyser : AstPlacement.programme -> string *)
(* Paramètre : le programme à analyser *)
(* Analyse le premier bloc de fonctions, le programme, puis le deuxième bloc de fonctions et 
renvoie le code tam correspondant au programme *)
let analyser (Programme (lf1, prog, lf2)) =
  (* On analyse toutes les fonctions qui se trouvent avant le programme principal *)
  let code_fonctions1 = List.fold_right (fun f tq -> (analyse_code_fonction f)^tq) lf1 "" in
  (* On analyse le programme principal *)
  let code_programme = analyse_code_bloc prog in
  (* On analyse toutes les fonctions qui se trouvent après le programme principal *)
  let code_fonctions2 = List.fold_right (fun f tq -> (analyse_code_fonction f)^tq) lf2 "" in
  (* On concatène les code des trois parties et on rajoute le label main, l'instruction de fin et l'entête *)
  let code_tam = code_fonctions1^code_fonctions2^"main;\n"^code_programme^"HALT" in 
  (getEntete ())^code_tam
end