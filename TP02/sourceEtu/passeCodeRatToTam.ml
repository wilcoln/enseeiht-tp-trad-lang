(* Module de la passe de gestion des types *)
module PasseCodeRatToTam : Passe.Passe with type t1 = Ast.AstPlacement.programme and type t2 = string =
struct

  open Tds
  open Exceptions
  open Type
  open Ast
  open AstType
  open AstPlacement
  open Code

  type t1 = Ast.AstPlacement.programme
  type t2 = string
 
  let rec analyse_code_expression e = 
    match e with 
    | AppelFonction(ia, le) -> ""
    | Ident (ia) -> ""
    | Rationnel (e1, e2) -> 
      begin
        let c1 = analyse_code_expression e1 in 
        let c2 = analyse_code_expression e2 in
        c1^c2
      end
    | Numerateur (e) -> "LOAD (1) 0[ST]\n"
    | Denominateur (e) -> "LOAD (1) 1[ST]\n"
    | True -> "LOADL 1\nSUBR I2B\n"
    | False -> "LOADL 0\nSUBR I2B\n"
    | Entier (i) -> "LOADL "^(string_of_int i)^"\n"
    | Binaire (b, e1, e2) -> 
      begin
        let c1 = analyse_code_expression e1 in 
        let c2 = analyse_code_expression e2 in
        match b with
        | PlusInt -> c1^c2^"SUBR IAdd\n"
        | PlusRat -> c1^c2^"CALL (SB) RAdd\n"
        | MultInt -> c1^c2^"SUBR IMul\n"
        | MultRat -> c1^c2^"CALL (SB) RMul\n"
        | EquBool -> c1^c2^"SUBR BAnd\n"^c1^"SUBR BNeg\n"^c2^"SUBR BNeg\n"^"SUBR BAnd\n"^"SUBR BOr\n" (** p = q <=> pq ou (non p non q)*)
        | EquInt -> c1^c2^"SUBR IEq\n"
        | Inf -> c1^c2^"SUBR ILss\n"
      end

  let rec analyse_code_bloc b = 
    match b with 
    | [] -> ""
    | i::q -> (analyse_code_instruction i)^"\n"^(analyse_code_bloc q)
and analyse_code_instruction i =
    match i with
    | Declaration (e, ia) ->
        begin
          match info_ast_to_info ia with
          | InfoVar (_, t, base, reg) -> 
            begin 
              let ce = analyse_code_expression e in 
              "PUSH "^(string_of_int (getTaille t))^"\n"^ce^"\nSTORE ("^(string_of_int (getTaille t))^") "^(string_of_int base)^"[SB]\n"
              end
          | _ -> failwith "erreur generation code instruction"
        end
    | AffichageInt e -> let ce = analyse_code_expression e in ce^"SUBR IOut\n"
    | AffichageRat e -> let ce = analyse_code_expression e in ce^"CALL (SB) ROut\n"
    | AffichageBool e -> let ce = analyse_code_expression e in ce^"SUBR BOut\n"
    | Conditionnelle (c, t, e) ->
        begin
          let codeC = analyse_code_expression c in 
          let codeT = analyse_code_bloc t in 
          let codeE = analyse_code_bloc e in 
          let labelElse = getEtiquette () in 
          let labelFinElse = getEtiquette () in 
          codeC^"JUMPIF 0\n"^labelElse^"\n"^codeT^"\n"^"JUMP (0)\n"^labelElse^"\n"^codeE^"\n"^labelFinElse^"\n"
        end

    | _ -> ""

let analyse_code_fonction (Fonction(ia, lpia, li, e)) = ""

let analyser (Programme (fonctions,prog)) =
  let code_fonctions = List.fold_right (fun f tq -> (analyse_code_fonction f)^tq) fonctions "" in
  let code_programme = analyse_code_bloc prog in
  let label_main = "main;" in
  let code_tam = (getEntete () )^code_fonctions^label_main^"\n"^code_programme in 
  code_tam
end