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


  (* Convertit de la chaine en list de sous chaine d'1 caractère *)
  let str_split s =
    let rec exp i l =
      if i < 0 then l else exp (i - 1) ((sub s i 1) :: l) in
    exp (String.length s - 1) []
  
  let rec analyse_code_affectable a  = 
    match a with 
    | Ident (ia) -> 
      begin
      match info_ast_to_info ia with
        | InfoVar(n, t, base, reg) -> "LOAD ("^(string_of_int (getTaille t))^") "^(string_of_int base)^"["^reg^"]\n" 
        | InfoConst(n, v) -> "LOADL "^(string_of_int v)^"\n"
        | _ -> ""
      end
    | Contenu (a, tp) ->
      begin 
        let ca = analyse_code_affectable a in ca^"LOADI ("^(string_of_int (getTaille tp))^")\n"
      end

  let rec analyse_code_expression e = 
    match e with 
    | AppelFonction(ia, le, lte) -> 
      begin
        match info_ast_to_info ia with
          | InfoFun(n, t , bltl) -> 
            begin
              let unique_suffix = List.fold_right (fun te tq -> (string_of_type te)^tq) lte "" in
              let cle = List.fold_right (fun t tq -> (analyse_code_expression t)^tq) le "" in 
              cle^"CALL (SB) "^n^unique_suffix^"\n"
            end
          | _ -> ""
      end
      | Affectable a -> analyse_code_affectable a
      | Null -> "SUBR MVoid\n"
      | New (tp) -> "LOADL "^(string_of_int (getTaille tp))^"\nSUBR MAlloc\n"
      | Adresse (ia) -> 
           begin 
            match info_ast_to_info ia with 
            | InfoVar(n, t, base, reg) -> "LOADA "^(string_of_int base)^"["^reg^"]\n"
            | _ -> ""
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
        let lst = str_split s in
        "LOADL "^(string_of_int (1 + taille_chaine))^"\n"^
        "SUBR MAlloc\n"^
        "LOADL "^(string_of_int taille_chaine)^"\n"^
        (List.fold_right (fun t tq -> "LOADL '"^t^"'\n"^tq) lst "")^
        "LOAD (1) -"^(string_of_int (2 + taille_chaine))^"[ST]\n"^
        "STOREI ("^(string_of_int (1 + taille_chaine))^")\n"
      end
    | SousChaine (e1, e2, e3) ->
      begin
        let c1 = analyse_code_expression e1 in 
        let c2 = analyse_code_expression e2 in
        let c3 = analyse_code_expression e3 in
        c1^c2^c3^"CALL (SB) SSub\n"
      end
    | Longueur e -> let ce = analyse_code_expression e in ce^"\nLOADI (1)\n"
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

  let rec analyse_code_bloc b = 
    match b with 
    | [] -> ""
    | i::q -> (analyse_code_instruction i)^(analyse_code_bloc q)
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
          | _ -> ""
        end
    | Affectation (a, e) ->
        begin
          let ce = analyse_code_expression e in 
          match a with
          | Ident(ia) ->
            begin
              match info_ast_to_info ia with 
              | InfoVar (_, t, base, reg) -> ce^"STORE ("^(string_of_int (getTaille t))^") "^(string_of_int base)^"["^reg^"]\n"
              | _ -> ""
            end
          | Contenu (a, tp) -> 
            begin 
              let rec aux a acc = 
                match a with 
                | Ident(ia) -> 
                  begin
                    match info_ast_to_info ia with 
                    | InfoVar (_, t, base, reg) -> "LOAD (1) "^(string_of_int base)^"["^reg^"]\n"
                    | _ -> ""
                  end
                | Contenu (ap, _) -> aux ap acc^"LOADI (1)\n" in 
                  ce^(aux a "")^"STOREI ("^(string_of_int (getTaille tp))^")\n"
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
    
    | _ -> ""

let analyse_code_fonction fonction = 
  match fonction with 
  | Fonction(ia, lpia, li, e) -> 
      begin
        match info_ast_to_info ia with 
        | InfoFun(n,t,_) -> 
          begin
            (* On récupère la signature de la fonction *)
            let lt = List.map (fun pia -> match info_ast_to_info pia with | InfoVar(_,t,_,_) -> t | _ -> raise ErreurInterne ) lpia in
            (* On crée un suffix unique pour cette signature *)
            let unique_suffix = List.fold_right (fun te tq -> (string_of_type te)^tq) lt "" in
            (* On crée le label de la fonction en utilisant le suffix unique précédent *)
            let labelFonction = n^unique_suffix in 
            let code_bloc = analyse_code_bloc li in
            let ce = analyse_code_expression e in
            labelFonction^"\n"^code_bloc^ce^"RETURN ("^(string_of_int (getTaille t))^") "^(string_of_int (List.fold_right (+) (List.map getTaille lt) 0))^"\n"
          end
        | _ -> ""
        end
  | _ -> ""

let analyser (Programme (lf1, prog, lf2)) =
  let code_fonctions1 = List.fold_right (fun f tq -> (analyse_code_fonction f)^tq) lf1 "" in
  let code_programme = analyse_code_bloc prog in
  let label_main = "main;" in
  let code_fonctions2 = List.fold_right (fun f tq -> (analyse_code_fonction f)^tq) lf2 "" in
  let code_tam = code_fonctions1^code_fonctions2^label_main^"\n"^code_programme^"HALT" in 
  (* print_endline code_tam; *)
  (getEntete () )^code_tam
end