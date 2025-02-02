(* Module de la passe de gestion des identifiants *)
module PasseTdsRat : Passe.Passe with type t1 = Ast.AstSyntax.programme and type t2 = Ast.AstTds.programme =
struct

  open Tds
  open Exceptions
  open Ast
  open AstTds
  open Type

  type t1 = Ast.AstSyntax.programme
  type t2 = Ast.AstTds.programme


(* analyse_tds_affectable : AstSyntax.affectable -> AstTds.affectable *)
(* Paramètre tds : la table des symboles courante *)
(* Paramètre a : l'affectable à analyser *)
(* Vérifie la bonne utilisation des identifiants et tranforme l'affectable
en un affectable de type AstTds.affectable *)
(* Erreur si mauvaise utilisation des identifiants *)
  let rec analyse_tds_affectable tds a = 
    match a with 
    | AstSyntax.Ident (n) ->
      begin
          match chercherGlobalement tds n with
              | None -> raise (IdentifiantNonDeclare n)
              | Some ia -> 
                begin
                  match info_ast_to_info ia with
                  | InfoFun(_) -> raise (MauvaiseUtilisationIdentifiant n)
                  | _ -> Ident(ia)
                end
      end
    | AstSyntax.Contenu (a) -> 
      begin 
        let na = analyse_tds_affectable tds a in
        Contenu(na)
      end


(* analyse_tds_expression : AstSyntax.expression -> AstTds.expression *)
(* Paramètre tds : la table des symboles courante *)
(* Paramètre e : l'expression à analyser *)
(* Vérifie la bonne utilisation des identifiants et tranforme l'expression
en une expression de type AstTds.expression *)
(* Erreur si mauvaise utilisation des identifiants *)
let rec analyse_tds_expression tds e = 
match e with
    | AstSyntax.AppelFonction (n, le) -> 
        begin
            match chercherGlobalement tds n with
                | None -> raise (IdentifiantNonDeclare n)
                | Some ia -> 
                  begin
                      match info_ast_to_info ia with
                        | InfoFun(_) -> let nle = List.map (analyse_tds_expression tds) le in AppelFonction (ia, nle)
                        | _ -> raise (MauvaiseUtilisationIdentifiant n)
                  end
         end
    | AstSyntax.Rationnel (e1, e2) ->
        begin
            let ne1 = analyse_tds_expression tds e1 in
            let ne2 = analyse_tds_expression tds e2 in
            Rationnel (ne1, ne2) 
        end
    | AstSyntax.Numerateur (e) -> 
        begin
            let ne = analyse_tds_expression tds e in
            Numerateur(ne)
        end
    | AstSyntax.Denominateur (e) ->
        begin
            let ne = analyse_tds_expression tds e in
            Denominateur(ne)
        end
    | AstSyntax.Affectable (a) -> 
      begin 
        let na = analyse_tds_affectable tds a in 
          Affectable(na)
      end
    | AstSyntax.Null -> Null
    | AstSyntax.New (tp) -> New(tp)
    | AstSyntax.Adresse (n) ->
      begin
        match chercherGlobalement tds n with
        | None -> raise (IdentifiantNonDeclare n)
        | Some ia -> 
          begin
            match info_ast_to_info ia with 
            | InfoVar(_) -> Adresse (ia)
            | _ -> raise (MauvaiseUtilisationIdentifiant n)
          end
      end
    | AstSyntax.True -> True
    | AstSyntax.False -> False
    | AstSyntax.Entier (i) -> Entier (i)
    | AstSyntax.Chaine (s) -> Chaine (s)
    | AstSyntax.Longueur (e) -> 
      begin 
        let ne = analyse_tds_expression tds e in
        Longueur (ne)
      end
    | AstSyntax.SousChaine (e1,e2,e3) ->
        begin
          let ne1 = analyse_tds_expression tds e1 in 
          let ne2 = analyse_tds_expression tds e2 in
          let ne3 = analyse_tds_expression tds e3 in 
          SousChaine(ne1, ne2, ne3)
        end
    | AstSyntax.Binaire (op_binaire, e1, e2) ->
        begin
            let ne1 = analyse_tds_expression tds e1 in
            let ne2 = analyse_tds_expression tds e2 in
            Binaire(op_binaire, ne1, ne2)
        end
    

(* analyse_tds_instruction : AstSyntax.instruction -> tds -> AstTds.instruction *)
(* Paramètre tds : la table des symboles courante *)
(* Paramètre i : l'instruction à analyser *)
(* Vérifie la bonne utilisation des identifiants et tranforme l'instruction
en une instruction de type AstTds.instruction *)
(* Erreur si mauvaise utilisation des identifiants *)
let rec analyse_tds_instruction tds i =
  match i with
  | AstSyntax.Declaration (t, n, e) ->
      begin
        match chercherLocalement tds n with
        | None ->
            (* L'identifiant n'est pas trouvé dans la tds locale, 
            il n'a donc pas été déclaré dans le bloc courant *)
            (* Vérification de la bonne utilisation des identifiants dans l'expression *)
            (* et obtention de l'expression transformée *) 
            let ne = analyse_tds_expression tds e in
            (* Création de l'information associée à l'identfiant *)
            let info = InfoVar (n, t, 0, "") in
            (* Création du New sur l'information *)
            let ia = info_to_info_ast info in
            (* Ajout de l'information (New) dans la tds *)
            ajouter tds n ia;
            (* Renvoie de la nouvelle déclaration où le nom a été remplacé par l'information 
            et l'expression remplacée par l'expression issue de l'analyse *)
            Declaration (t, ne, ia) 
        | Some _ ->
            (* L'identifiant est trouvé dans la tds locale, 
            il a donc déjà été déclaré dans le bloc courant *) 
            raise (DoubleDeclaration n)
      end
  | AstSyntax.Affectation (a,e) ->
      begin
        let ne = analyse_tds_expression tds e in
        let na = analyse_tds_affectable tds a in 
          begin
            match na with
            | Ident(ia) -> 
              begin
                match info_ast_to_info ia with 
                | InfoVar _ -> 
                  begin
                    (* Vérification de la bonne utilisation des identifiants dans l'expression *)
                    (* et obtention de l'expression transformée *) 
                    let ne = analyse_tds_expression tds e in
                    (* Renvoie la nouvelle affectation où le nom a été remplacé par l'information 
                    et l'expression remplacée par la nouvelle expression issue de l'analyse *)
                    Affectation (na, ne)
                  end
                |  InfoFun(n,_,_) -> raise (MauvaiseUtilisationIdentifiant n)
                |  InfoConst(n,_) -> raise (MauvaiseUtilisationIdentifiant n)
              end
            | _ -> Affectation(na, ne)
          end
      end
  | AstSyntax.Constante (n,v) -> 
      begin
        match chercherLocalement tds n with
        | None -> 
        (* L'identifiant n'est pas trouvé dans la tds locale, 
        il n'a donc pas été déclaré dans le bloc courant *)
        (* Ajout dans la tds de la constante *)
        ajouter tds n (info_to_info_ast (InfoConst (n,v))); 
        (* Suppression du noeud de déclaration des constantes devenu inutile *)
        Empty
        | Some _ ->
          (* L'identifiant est trouvé dans la tds locale, 
          il a donc déjà été déclaré dans le bloc courant *) 
          raise (DoubleDeclaration n)
      end
  | AstSyntax.Affichage e -> 
      (* Vérification de la bonne utilisation des identifiants dans l'expression *)
      (* et obtention de l'expression transformée *)
      let ne = analyse_tds_expression tds e in
      (* Renvoie du nouvel affichage où l'expression remplacée par l'expression issue de l'analyse *)
      Affichage (ne)
  | AstSyntax.Conditionnelle (c,t,e) -> 
      (* Analyse de la condition *)
      let nc = analyse_tds_expression tds c in
      (* Analyse du bloc then *)
      let tast = analyse_tds_bloc tds t in
      (* Analyse du bloc else *)
      let east = analyse_tds_bloc tds e in
      (* Renvoie la nouvelle structure de la conditionnelle *)
      Conditionnelle (nc, tast, east)
  | AstSyntax.TantQue (c,b) -> 
      (* Analyse de la condition *)
      let nc = analyse_tds_expression tds c in
      (* Analyse du bloc *)
      let bast = analyse_tds_bloc tds b in
      (* Renvoie la nouvelle structure de la boucle *)
      TantQue (nc, bast)

      
(* analyse_tds_bloc : AstSyntax.bloc -> AstTds.bloc *)
(* Paramètre tds : la table des symboles courante *)
(* Paramètre li : la liste d'instructions à analyser *)
(* Vérifie la bonne utilisation des identifiants et tranforme le bloc
en un bloc de type AstTds.bloc *)
(* Erreur si mauvaise utilisation des identifiants *)
and analyse_tds_bloc tds li =
  (* Entrée dans un nouveau bloc, donc création d'une nouvelle tds locale 
  pointant sur la table du bloc parent *)
  let tdsbloc = creerTDSFille tds in
  (* Analyse des instructions du bloc avec la tds du nouveau bloc 
  Cette tds est modifiée par effet de bord *)
  List.map (analyse_tds_instruction tdsbloc) li


(* analyse_tds_parametre : AstSyntax.parametre -> AstTds.parametre *)
(* Paramètre tdsfonc : la table des symboles d'une fonction *)
(* Paramètre (ptype, pnom) : le paramètre à analyser (son type, son nom) *)
(* Vérie que le nom du paramètre est unique et crée une infoVar associé  *)
(* Erreur si double déclaration du paramètre *)
let analyse_tds_parametre tdsfonc (ptype, pnom) = 
  match chercherLocalement tdsfonc pnom with 
    | None -> 
      begin
        let info  = InfoVar(pnom, ptype, 0, "") in
        let pia = info_to_info_ast info in
        ajouter tdsfonc pnom pia;
        (ptype, pia)
      end      
    | Some _ -> raise (DoubleDeclaration pnom)


(* analyse_tds_fonction : AstSyntax.fonction -> AstTds.fonction *)
(* Paramètre tds : la table des symboles courante *)
(* Paramètre : la fonction à analyser *)
(* Vérifie la bonne utilisation des identifiants et tranforme la fonction
en une fonction de type AstTds.fonction *)
(* Erreur si mauvaise utilisation des identifiants *)
let rec analyse_tds_fonction maintds fonction  =
  match fonction with 
  | AstSyntax.Fonction(t,n,lp,li,e) -> 
    begin
      match chercherLocalement maintds n with 
      | None ->
        (* Aucune info n'est associée à cet identifiant *)
        begin
          (* On crée une tds locale à la fonction *)
          let tdsfonc = creerTDSFille maintds in 
          (* On récupère la signature de la fonction *)
          let lt = fst (List.split lp) in 
          (* On crée une InfoFun et on initialise la liste des signatures avec la signature de la fonction *)
          (* Le booléan associé à cet signature est à true car on fournit une implémentation de la fonction *)
          let info = InfoFun(n, t, (lt, true)::[]) in 
          let ia = info_to_info_ast info in
          (* On rajoute l'info dans la tds globale *)
          ajouter maintds n ia;
          (* On rajoute l'info dans la tds locale, pour permettre les appels récursifs *)
          ajouter tdsfonc n ia;
          let nlp = List.map (analyse_tds_parametre tdsfonc) lp in
          let nli = List.map (analyse_tds_instruction tdsfonc) li in
          let ne = analyse_tds_expression tdsfonc e in 
          Fonction(t, ia, nlp , nli, ne)
        end
      | Some ia ->
        (* Une Info est déjà associée à cet identifiant *)
        begin
          match info_ast_to_info ia with
            | InfoFun _ -> 
              begin
                (* On récupère la signature de la fonction *)
                let lt = fst (List.split lp) in 
                match chercher_signature lt ia with 
                | None -> 
                  begin 
                    (* La signature ne se trouve pas dans l'info *)
                    let tdsfonc = creerTDSFille maintds in 
                    (* On rajoute l'info dans la tds globale *)
                    ajouter maintds n ia;
                    (* On rajoute l'info dans la tds locale, pour permettre les appels récursifs *)
                    ajouter tdsfonc n ia;
                    let nlp = List.map (analyse_tds_parametre tdsfonc) lp in
                    let nli = List.map (analyse_tds_instruction tdsfonc) li in
                    let ne = analyse_tds_expression tdsfonc e in 
                    
                    (* On rajoute la signature dans l'info *)
                    (* Le booléan associé à cet signature est à true car on fournit une implémentation de la fonction *)
                    ajouter_signature (lt, true) ia;

                    Fonction(t, ia, nlp , nli, ne)
                  end
                | Some impl -> 
                  begin
                  (* La signature se trouve déjà dans l'info *)
                    if not impl then 
                      (* L'implémentation de la fonction n'est pas fournie *)
                      begin
                        (* On crée une tds locale à la fonction *)
                        let tdsfonc = creerTDSFille maintds in 
                        (* On rajoute l'info dans la tds locale, pour permettre les appels récursifs *)
                        ajouter tdsfonc n ia;
                        let nlp = List.map (analyse_tds_parametre tdsfonc) lp in
                        let nli = List.map (analyse_tds_instruction tdsfonc) li in
                        let ne = analyse_tds_expression tdsfonc e in 
                        (* la signature est maintenant implémentée donc on met à jour l'info ast *)
                        implementer_signature lt ia;
                        (* On renvoie la nouvelle fonction *)
                        Fonction(t, ia, nlp , nli, ne)
                      end
                    else raise (DoubleDeclaration n)
                end 
              end
            | _ -> raise (MauvaiseUtilisationIdentifiant n)
        end
    end
  | AstSyntax.Prototype(t, n, lt) ->
    begin
      match chercherLocalement maintds n with 
      | None ->
        (* Aucune info n'est associée à cet identifiant *)
        begin
          (* On crée une InfoFun et on initialise la liste des signatures avec la signature du prototype *)
          let info = InfoFun(n, t, (lt, false)::[]) in 
          let ia = info_to_info_ast info in
          (* On rajoute l'info_ast dans la tds globale *)
          ajouter maintds n ia;
          Prototype(ia)
        end
      | Some ia ->
        (* Une info est déjà associée à cet identifiant *)
        begin
          match info_ast_to_info ia with
            | InfoFun _ -> 
              begin 
                match chercher_signature lt ia with 
                | None -> 
                  begin 
                    (* La signature ne se trouve pas dans l'info *)
                    (* On rajoute la signature dans l'info *)
                    (* Le booléan associé à cet signature est à false car l'implémentation de la fonction n'est pas encore fournie *)
                    ajouter_signature (lt, false) ia;
                    (* On rajoute l'info_ast dans la tds globale *)
                    ajouter maintds n ia;
                    Prototype(ia)
                  end
                | Some _ -> 
                  begin 
                    (* La signature se trouve déjà dans l'info *)
                    raise (DoubleDeclarationSignature (n, lt))
                  end 
              end
            | _ -> raise (MauvaiseUtilisationIdentifiant n)
        end
  end
  

(* analyser : AstSyntax.programme -> AstTds.programme *)
(* Paramètre : le programme à analyser *)
(* Analyse le premier bloc de fonctions, le programme puis le deuxième bloc de fonctions et tranforme le programme
en un programme de type AstType.programme *)
let analyser (AstSyntax.Programme (lf1, prog, lf2)) =
  let tds_mere = creerTDSMere () in 
  let nlf1 = List.map (analyse_tds_fonction tds_mere) lf1 in 
  let nbloc = List.map (analyse_tds_instruction tds_mere) prog in
  let nlf2 = List.map (analyse_tds_fonction tds_mere) lf2 in 
  Programme (nlf1, nbloc, nlf2)
end
