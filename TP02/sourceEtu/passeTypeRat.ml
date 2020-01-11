(* Module de la passe de gestion des types *)
module PasseTypeRat : Passe.Passe with type t1 = Ast.AstTds.programme and type t2 = Ast.AstType.programme =
struct

  open Tds
  open Exceptions
  open Type
  open Ast
  open AstType

  type t1 = Ast.AstTds.programme
  type t2 = Ast.AstType.programme


(* analyse_type_affectable : AstSyntax.affectable -> AstType.affectable *)
(* Paramètre a: l'affectable à analyser *)
(* Vérifie la bonne utilisation du type et tranforme l'affectable
en un affectable de type AstType.affectable et renvoie aussi le type de l'affectable *)
(* Erreur si mauvais utilisation du type *)

let rec analyse_type_affectable a = 
  match a with 
  | AstTds.Ident (ia) -> 
    begin
      match info_ast_to_info ia with 
      | InfoFun (_, t, _) -> (t, Ident(ia))
      | InfoVar (_, t, _, _) -> (t, Ident(ia))
      | InfoConst (_, _) -> (Int, Ident(ia))
    end
  | AstTds.Contenu (a) -> 
    begin
      let (t, na) = analyse_type_affectable a in 
      match t with 
      | Pointeur(tp) -> (tp, Contenu(na, tp))
      | _ -> raise DereferencementNonPointeur
    end

(* analyse_type_expression : AstTds.expression -> AstType.expression *)
(* Paramètre e : l'expression à analyser *)
(* Vérifie la bonne utilisation du type et tranforme l'expression
en un expression de type AstType.expression et renvoie aussi le type de l'expression *)
(* Erreur si mauvais utilisation du type *)
let rec analyse_type_expression  e = 
  match e with
    | AstTds.AppelFonction (ia, le) -> 
        begin
           match info_ast_to_info ia with 
           | InfoFun(n, t, bltl) -> 
              begin
                (* On analyse le type des arguments de l'appel *)
                let nle = List.map analyse_type_expression le in 
                (* On récupère la liste des signatures (surcharges) de la fonction *)
                let ltl = fst (List.split bltl) in 
                (* On récupère la liste des types des arguments *)
                let lte = fst (List.split nle) in
                (* On regarde si les arguments sont compatibles avec une des surcharges de la fonction *)
                let compatibilite = List.fold_right (fun lt tq -> tq || (est_compatible_list lt lte)) ltl false in 
                  if compatibilite then
                    (t, AppelFonction (ia, snd (List.split nle), lte))
                  else
                    raise (TypesParametresInattendus (ltl, lte))
              end
           | _ -> raise ErreurInterne
         end
    | AstTds.Affectable a -> let (t, na) = analyse_type_affectable a in (t, Affectable (na))
    | AstTds.Null -> (Pointeur(Undefined), Null)
    | AstTds.New (tp) -> (Pointeur(tp), New (tp))
    | AstTds.Adresse (ia) -> 
        begin 
          match info_ast_to_info ia with 
          | InfoVar(n, t, _, _) -> (Pointeur(t), Adresse(ia))
          | _ -> raise ErreurInterne
        end
    | AstTds.Rationnel (e1, e2) ->
        begin
            let (texp1, ne1) = analyse_type_expression  e1 in
            let (texp2, ne2) = analyse_type_expression  e2 in
            match (texp1, texp2) with 
            | (Int, Int) -> (Rat, Rationnel(ne1, ne2))
            | _ -> raise (TypeInattendu (texp1, texp2))    
        end
    | AstTds.Numerateur (e) -> 
        begin
            let (texp, ne) = analyse_type_expression e in
            if est_compatible texp Rat then 
              (Int, Numerateur (ne))
            else 
              raise (TypeInattendu (texp, Rat))
        end
    | AstTds.Denominateur (e) ->
        begin
          let (texp, ne) = analyse_type_expression e in
          if est_compatible texp Rat then 
            (Int, Denominateur (ne))
          else 
            raise (TypeInattendu (texp, Rat))
        end
    | AstTds.True -> (Bool, True)
    | AstTds.False -> (Bool, False)
    | AstTds.Entier (i) -> (Int, Entier (i))
    | AstTds.Chaine s -> (String, Chaine s)
    | AstTds.SousChaine (e1, e2, e3) ->
        begin 
          let (t1, ne1) = analyse_type_expression e1 in 
          let (t2, ne2) = analyse_type_expression e2 in 
          let (t3, ne3) = analyse_type_expression e3 in 
          if est_compatible t1 String then 
            begin
              match t2, t3 with 
              | Int, Int -> (String, SousChaine (ne1, ne2, ne3))
              | _ -> raise (TypesInattendus ([Int; Int], [t1; t2]))
            end
          else raise (TypeInattendu (t1, String))
          
        end
    | AstTds.Longueur e -> 
        begin 
          let (te, ne) = analyse_type_expression e in 
          if est_compatible String te 
            then (Int, Longueur (ne)) 
          else raise (TypeInattendu (te, String))
        end
    | AstTds.Binaire (op_binaire, e1, e2) ->
        begin
          let (texp1, ne1) = analyse_type_expression  e1 in
          let (texp2, ne2) = analyse_type_expression  e2 in
          match op_binaire with
          | Plus -> 
            begin
              match (texp1, texp2) with 
              | (Int, Int) ->  (Int, Binaire (PlusInt, ne1,  ne2))
              | (Rat, Rat) -> (Rat, Binaire (PlusRat, ne1,  ne2))
              | _ -> raise (TypeBinaireInattendu (Plus, texp1, texp2))
             end
          | Mult ->
            begin
              match (texp1, texp2) with 
              | (Int, Int) ->  (Int, Binaire (MultInt, ne1,  ne2))
              | (Rat, Rat) -> (Rat, Binaire (MultRat, ne1,  ne2))
              | _ -> raise (TypeBinaireInattendu (Mult, texp1, texp2))
             end
          | Equ -> 
            begin
              match (texp1, texp2) with 
              | (Int, Int) ->  (Bool, Binaire (EquInt, ne1,  ne2))
              | (Bool, Bool) -> (Bool, Binaire (EquBool, ne1,  ne2))
              | _ -> raise (TypeBinaireInattendu (Equ, texp1, texp2))
             end
          | Inf -> 
            begin
              if est_compatible texp1 Int && est_compatible texp2 Int
              then 
                (Bool, Binaire (Inf, ne1,  ne2))
              else 
                raise (TypeBinaireInattendu (Inf, texp1, texp2)) 
            end
          | Concat -> 
            begin
              if est_compatible texp1 String && est_compatible texp2 String
              then 
                (String, Binaire (Concat, ne1,  ne2))
              else 
                raise (TypeBinaireInattendu (Concat, texp1, texp2)) 
            end
        end
    

(* analyse_type_instruction : AstTds.instruction ->  -> AstType.instruction *)
(* Paramètre i : l'instruction à analyser *)
(* Vérifie la bonne utilisation du type et tranforme l'instruction
en un instruction de type AstType.instruction et renvoie aussi le type de l'instruction *)
(* Erreur si mauvais utilisation du type *)
let rec analyse_type_instruction  i =
  match i with
  | AstTds.Declaration (t, e, ia) ->
      begin
        let (texp, ne) = analyse_type_expression e in 
        if est_compatible t texp then
          let _ = modifier_type_info t ia in 
          Declaration (ne, ia)
        else 
          raise (TypeInattendu (texp, t))
      end
  | AstTds.Affectation (a, e) ->
      begin
        let (ta, na) = analyse_type_affectable a in 
        let (te, ne) = analyse_type_expression e in
        if est_compatible ta te then
          Affectation (na, ne)
        else 
          raise (TypeInattendu (te, ta))
      end
  | AstTds.Affichage e -> 
      (* Vérification de la bonne utilisation des identifiants dans l'expression *)
      (* et obtention de l'expression transformée *)
      let (texp, ne) = analyse_type_expression e in 
        begin
          match texp with 
          | Int -> AffichageInt ne
          | Rat -> AffichageRat ne
          | Bool -> AffichageBool ne
          | String -> AffichageString ne
          | _ -> raise TypeIndefini
        end
  | AstTds.Conditionnelle (c, bthen,belse) -> 
      (* Analyse de la condition *)
      let (texp, nc) = analyse_type_expression c in 
      if est_compatible Bool texp then
        let nbthen = analyse_type_bloc bthen in
        let nbelse = analyse_type_bloc belse in
        Conditionnelle(nc, nbthen, nbelse)
      else 
        raise (TypeInattendu (texp, Bool))
  | AstTds.TantQue (c, b) -> 
      (* Analyse de la condition *)
      let (texp, nc) = analyse_type_expression  c in 
      if est_compatible Bool texp then
        let nb = analyse_type_bloc  b in
        TantQue(nc, nb)
      else 
        raise (TypeInattendu (texp, Bool))
  | AstTds.Empty -> Empty

      
(* analyse_type_bloc : AstTds.bloc -> AstType.bloc *)
(* Paramètre li : liste d'instructions à analyser *)
(* Analyse chaque instruction de la liste li *)
and analyse_type_bloc li = List.map (analyse_type_instruction ) li

let analyse_type_parametre (ptype, pia) = 
  modifier_type_info ptype pia;
  (ptype, pia) 

(* analyse_type_fonction : AstTds.fonction -> AstType.fonction *)
(* Appel analyse type des paramètres, des instructions, modifie le type de la fonction
 et tranforme la fonction en une fonction de type AstType.fonction *)
(* Erreur si mauvaise utilisation des types  *)
let rec analyse_type_fonction fonction =
  match fonction with 
  | AstTds.Fonction(t,ia,lp,li,e) -> 
      begin
        let (texp, ne) = analyse_type_expression e in 
        if est_compatible t texp then
            let nlp = List.map analyse_type_parametre lp in
            let nli = List.map analyse_type_instruction li in
            modifier_type_fonction_info t (fst (List.split nlp)) ia;
            Fonction(ia, snd (List.split nlp), nli, ne)
        else 
          raise (TypeInattendu (texp, t))
      end
  | AstTds.Prototype(ia) -> Empty
  

(* analyser : AstTds.ast -> AstType.ast *)
(* Paramètre : le programme à analyser *)
(* Vérifie la bonne utilisation du type et tranforme le programme
en un programme de type AstType.programme et renvoie aussi le type de le programme *)
(* Erreur si mauvais utilisation du type *)
let analyser (AstTds.Programme (lf1, prog, lf2)) =
  let nlf1 = List.map analyse_type_fonction lf1 in 
  let nbloc = List.map analyse_type_instruction prog in
  let nlf2 = List.map analyse_type_fonction lf2 in 
  Programme (nlf1, nbloc, nlf2)
end