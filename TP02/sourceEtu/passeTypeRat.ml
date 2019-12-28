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


(* analyse_type_affectable : AstSyntax.affectable -> Asttype.affectable *)
(* Paramètre type : la table des symboles courante *)
(* Paramètre e : l'affectable à analyser *)
(* Vérifie la bonne utilisation des identifiants et tranforme l'affectable
en une affectable de type Asttype.affectable *)
(* Erreur si mauvaise utilisation des identifiants *)

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
      | Pointeur(tp) -> (tp, Contenu(na))
      | _ -> failwith "impossible de dereferencer un non pointeur"
    end

(* analyse_type_expression : AstTds.expression -> AstType.expression *)
(* Paramètre e : l'expression à analyser *)
(* Vérifie la bonne utilisation des identifiants et tranforme l'expression
en une expression de type AstType.expression *)
(* Erreur si mauvaise utilisation des identifiants *)
let rec analyse_type_expression  e = 
match e with
    | AstTds.AppelFonction (ia, le) -> 
        begin
           match info_ast_to_info ia with 
           | InfoFun(n, t, lt) -> 
           begin
            let nle = List.map analyse_type_expression le in 
            let lte = fst (List.split nle) in
              if est_compatible_list lt lte
              then
                (t, AppelFonction (ia, snd (List.split nle)))
              else
                raise (TypesParametresInattendus (lt, lte))
           end
           | _ -> failwith "error appel fonction"
         end
    | AstTds.Affectable a -> let (t, na) = analyse_type_affectable a in (t, Affectable (na))
    | AstTds.Null -> (Pointeur(Undefined), Null)
    | AstTds.New (tp) -> (Pointeur(tp), New (tp))
    | AstTds.Adresse (ia) -> 
         begin 
          match info_ast_to_info ia with 
          | InfoVar(n, t, _, _) -> (Pointeur(t), Adresse(ia))
          | _ -> failwith "erreur"
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
            if est_compatible texp Rat
            then 
              (Int, Numerateur (ne))
            else 
              raise (TypeInattendu (texp, Rat))
        end
    | AstTds.Denominateur (e) ->
        begin
          let (texp, ne) = analyse_type_expression e in
          if est_compatible texp Rat
          then 
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
              | _ -> failwith "types indices inattendus"
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
(* Vérifie la bonne utilisation des identifiants et tranforme l'instruction
en une instruction de type AstType.instruction *)
(* Erreur si mauvaise utilisation des identifiants *)
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
(* Vérifie la bonne utilisation des identifiants et tranforme le bloc
en un bloc de type AstType.bloc *)
(* Erreur si mauvaise utilisation des identifiants *)
and analyse_type_bloc  li =
  List.map (analyse_type_instruction ) li

let analyse_type_parametre (ptype, pia) = 
  modifier_type_info ptype pia;
  (ptype, pia) 

(* analyse_type_fonction : AstTds.fonction -> AstType.fonction *)
(* Vérifie la bonne utilisation des identifiants et tranforme la fonction
en une fonction de type AstType.fonction *)
(* Erreur si mauvaise utilisation des identifiants *)
let rec analyse_type_fonction (AstTds.Fonction(t,ia,lp,li,e))  =
  begin
    (* Analyse de la condition *)
    let (texp, ne) = analyse_type_expression e in 
    if est_compatible t texp then
        let nlp = List.map analyse_type_parametre lp in
        let nli = List.map analyse_type_instruction li in
        modifier_type_fonction_info t (fst (List.split nlp)) ia;
        Fonction(ia, snd (List.split nlp), nli, ne)
    else 
      raise (TypeInattendu (texp, t))
  end
  

(* analyser : AstTds.ast -> AstType.ast *)
(* Paramètre : le programme à analyser *)
(* Vérifie la bonne utilisation des identifiants et tranforme le programme
en un programme de type AstType.ast *)
(* Erreur si mauvaise utilisation des identifiants *)
let analyser (AstTds.Programme (fonctions,prog)) =
  let nlf = List.map analyse_type_fonction fonctions in 
  let nb = List.map analyse_type_instruction prog in
  Programme (nlf, nb)
end