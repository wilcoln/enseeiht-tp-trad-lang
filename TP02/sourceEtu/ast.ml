open Type
open String
(* Interface des arbres abstraits *)
module type Ast =
sig
   type expression
   type instruction
   type fonction
   type programme
end

(* Interface d'affichage des arbres abstraits *)
module type PrinterAst =
sig
  module A:Ast

(* string_of_expression :  expression -> string *)
(* transforme une expression en chaîne de caractère *)
val string_of_expression : A.expression -> string

(* string_of_instruction :  instruction -> string *)
(* transforme une instruction en chaîne de caractère *)
val string_of_instruction : A.instruction -> string

(* string_of_fonction :  fonction -> string *)
(* transforme une fonction en chaîne de caractère *)
val string_of_fonction : A.fonction -> string

(* string_of_ast :  ast -> string *)
(* transforme un ast en chaîne de caractère *)
val string_of_programme : A.programme -> string

(* print_ast :  ast -> unit *)
(* affiche un ast *)
val print_programme : A.programme -> unit

end


(*******************************************)
(* AST après la phase d'analyse syntaxique *)
(*******************************************)
module AstSyntax =
struct

(* Opérateurs binaires de Rat *)
type binaire = Plus | Mult | Equ | Inf | Concat

(* Affectables de Rat *)
type affectable = 
  (* Accès à un identifiant représenté par son nom *)
  | Ident of string
  | Contenu of affectable

(* Expressions de Rat *)
type expression =
  (* Appel de fonction représenté par le nom de la fonction et la liste des paramètres réels *)
  | AppelFonction of string * expression list 
  (* Rationnel représenté par le numérateur et le dénominateur *)
  | Rationnel of expression * expression 
  (* Accès au numérateur d'un rationnel *)
  | Numerateur of expression
  (* Accès au dénominateur d'un rationnel *)
  | Denominateur of expression
  (* Affectable *)
  | Affectable of affectable
  (* Null *)
  | Null
  (* New de typ *)
  | New of typ 
  (* Adresse d'identifiant *)
  | Adresse of string
  (* Booléen vrai *)
  | True
  (* Booléen faux *)
  | False
  (* Entier *)
  | Entier of int
  (* String *)
  | Chaine of string
  | SousChaine of expression * expression * expression
  | Longueur of expression
  (* Opération binaire représentée par l'opérateur, l'opérande gauche et l'opérande droite *)
  | Binaire of binaire * expression * expression
  

(* Instructions de Rat *)
type bloc = instruction list
and instruction =
  (* Déclaration de variable représentée par son type, son nom et l'expression d'initialisation *)
  | Declaration of typ * string * expression
  (* Affectation d'une variable représentée par son nom et la nouvelle valeur affectée *)
  | Affectation of affectable * expression
  (* Déclaration d'une constante représentée par son nom et sa valeur (entier) *)
  | Constante of string * int
  (* Affichage d'une expression *)
  | Affichage of expression
  (* Conditionnelle représentée par la condition, le bloc then et le bloc else *)
  | Conditionnelle of expression * bloc * bloc
  (*Boucle TantQue représentée par la conditin d'arrêt de la boucle et le bloc d'instructions *)
  | TantQue of expression * bloc

(* Structure des fonctions de Rat *)
(* type de retour - nom - liste des paramètres (association type et nom) - corps de la fonction - expression de retour *)
type fonction = 
  | Prototype of typ * string * typ list
  | Fonction of typ * string * (typ * string) list * instruction list * expression

(* Structure d'un programme Rat *)
(* liste de fonction - programme principal *)
type programme = Programme of fonction list * bloc * fonction list

end


(*Module d'affiche des AST issus de la phase d'analyse syntaxique *)
module PrinterAstSyntax : PrinterAst with module A = AstSyntax =
struct

  module A = AstSyntax
  open A

  (* Conversion des opérateurs binaires *)
  let string_of_binaire b =
    match b with
    | Plus -> "+ "
    | Mult -> "* "
    | Equ -> "= "
    | Inf -> "< "
    | Concat -> "^ "

  (* Conversion des affectables *)
  let rec string_of_affectable a =
    match a with
    | Ident n -> n^" "
    | Contenu a -> "contenu de "^(string_of_affectable a)
  (* Conversion des expressions *)
  let rec string_of_expression e =
    match e with
    | AppelFonction (n,le) -> "call "^n^"("^((List.fold_right (fun i tq -> (string_of_expression i)^tq) le ""))^") "
    | Rationnel (e1,e2) -> "["^(string_of_expression e1)^"/"^(string_of_expression e2)^"] "
    | Numerateur e1 -> "num "^(string_of_expression e1)^" "
    | Denominateur e1 ->  "denom "^(string_of_expression e1)^" "
    | Affectable a -> (string_of_affectable a)^" "
    | Null -> "Null "
    | New tp -> "New de "^(string_of_type tp)^" "
    | Adresse n -> "adresse de "^n^" "
    | True -> "true "
    | False -> "false "
    | Entier i -> (string_of_int i)^" "
    | Chaine s -> "chaine "^s^" "
    | SousChaine (e1,e2,e3) -> "sous chaine "^(string_of_expression e1)^" "^(string_of_expression e2)^" "^(string_of_expression e3)^" "
    | Longueur e -> "longueur "^(string_of_expression e)^" "
    | Binaire (b,e1,e2) -> (string_of_expression e1)^(string_of_binaire b)^(string_of_expression e2)^" "

  (* Conversion des instructions *)
  let rec string_of_instruction i =
    match i with
    | Declaration (t, n, e) -> "Declaration  : "^(string_of_type t)^" "^n^" = "^(string_of_expression e)^"\n"
    | Affectation (a, e) ->  "Affectation  : "^(string_of_affectable a)^" = "^(string_of_expression e)^"\n"
    | Constante (n, i) ->  "Constante  : "^n^" = "^(string_of_int i)^"\n"
    | Affichage e ->  "Affichage  : "^(string_of_expression e)^"\n"
    | Conditionnelle (c, t, e) ->  "Conditionnelle  : IF "^(string_of_expression c)^"\n"^
                                  "THEN \n"^((List.fold_right (fun i tq -> (string_of_instruction i)^tq) t ""))^
                                  "ELSE \n"^((List.fold_right (fun i tq -> (string_of_instruction i)^tq) e ""))^"\n"
    | TantQue (c, b) -> "TantQue  : TQ "^(string_of_expression c)^"\n"^
                                  "FAIRE \n"^((List.fold_right (fun i tq -> (string_of_instruction i)^tq) b ""))^"\n"

  (* Conversion des fonctions *)
  let string_of_fonction func = 
    match func with 
    | Fonction(t,n,lp,li,e) -> "Fonction : "^(string_of_type t)^" "^n^" ("^((List.fold_right (fun (t,n) tq -> (string_of_type t)^" "^n^" "^tq) lp ""))^") = \n"^
                                        ((List.fold_right (fun i tq -> (string_of_instruction i)^tq) li ""))^
                                        "Return "^(string_of_expression e)^"\n"
    | Prototype(t,n,lt) -> "Prototype : "^(string_of_type t)^" "^n^" ("^((List.fold_right (fun t tq -> (string_of_type t)^" "^tq) lt ""))^")\n"

  (* Conversion d'un programme Rat *)
  let string_of_programme (Programme (fonctions1, instruction, fonctions2)) =
    (List.fold_right (fun f tq -> (string_of_fonction f)^tq) fonctions1 "")^
    (List.fold_right (fun i tq -> (string_of_instruction i)^tq) instruction "")^
    (List.fold_right (fun f tq -> (string_of_fonction f)^tq) fonctions2 "")

  (* Affichage d'un programme Rat *)
  let print_programme programme =
    print_string "AST : \n";
    print_string (string_of_programme programme);
    flush_all ()

end

(*************************************************)
(* AST après la phase d'analyse des identifiants *)
(*************************************************)
module AstTds =
struct

  (* Affectables existantes dans notre langage *)
  (* ~ affectable de l'AST syntaxique où les noms des identifiants ont été 
  remplacés par les informations associées aux identificateurs *)
  type affectable = 
  (* Accès à un identifiant représenté par son nom *)
  | Ident of Tds.info_ast (* le nom de l'identifiant est remplacé par ses informations *)
  | Contenu of affectable

  (* Expressions existantes dans notre langage *)
  (* ~ expression de l'AST syntaxique où les noms des identifiants ont été 
  remplacés par les informations associées aux identificateurs *)
  type expression =
    | AppelFonction of Tds.info_ast * expression list
    | Rationnel of expression * expression
    | Numerateur of expression
    | Denominateur of expression
    | Affectable of affectable
    | Null
    | New of typ 
    | Adresse of Tds.info_ast
    | True
    | False
    | Entier of int
    | Chaine of string
    | SousChaine of expression * expression * expression
    | Longueur of expression
    | Binaire of AstSyntax.binaire * expression * expression

  (* instructions existantes dans notre langage *)
  (* ~ instruction de l'AST syntaxique où les noms des identifiants ont été 
  remplacés par les informations associées aux identificateurs 
  + suppression de nœuds (const) *)
  type bloc = instruction list
  and instruction =
    | Declaration of typ * expression * Tds.info_ast (* le nom de l'identifiant est remplacé par ses informations *)
    | Affectation of  affectable * expression(* le nom de l'identifiant est remplacé par ses informations *)
    | Affichage of expression
    | Conditionnelle of expression * bloc * bloc
    | TantQue of expression * bloc
    | Empty (* les nœuds ayant disparus: Const *)


  (* Structure des fonctions dans notre langage *)
  (* type de retour - nom - liste des paramètres (association type et information sur les paramètres) - corps de la fonction - expression de retour - information sur la fonction*)
  (* le nom de la fonction est gardé car il sera nécessaire au moment de la génération de code*)
  type fonction = 
    | Prototype of Tds.info_ast
    | Fonction of typ * Tds.info_ast * (typ * Tds.info_ast ) list * instruction list * expression 

  (* Structure d'un programme dans notre langage *)
  type programme = Programme of fonction list * bloc * fonction list

end
    

(***********************************)
(* AST après la phase de typage *)
(***********************************)
module AstType =
struct

(* Opérateurs binaires existants dans Rat - résolution de la surcharge *)
type binaire = PlusInt | PlusRat | MultInt | MultRat | EquInt | EquBool | Inf | Concat

(* Affectables existantes dans Rat *)
(* = affectables de AstTds *)
type affectable = 
  (* Accès à un identifiant représenté par son nom *)
  | Ident of Tds.info_ast (* le nom de l'identifiant est remplacé par ses informations *)
  | Contenu of affectable * typ

(* Expressions existantes dans Rat *)
(* = expression de AstTds *)
type expression =
  | AppelFonction of Tds.info_ast * expression list * typ list
  | Rationnel of expression * expression
  | Numerateur of expression
  | Denominateur of expression
  | Affectable of affectable
  | Null
  | New of typ 
  | Adresse of Tds.info_ast
  | True
  | False
  | Entier of int
  | Chaine of string
  | SousChaine of expression * expression * expression
  | Longueur of expression
  | Binaire of binaire * expression * expression

(* instructions existantes Rat *)
(* = instruction de AstTds + informations associées aux identificateurs, mises à jour *)
(* + résolution de la surcharge de l'affichage *)
type bloc = instruction list
 and instruction =
  | Declaration of expression * Tds.info_ast
  | Affectation of affectable * expression
  | AffichageInt of expression
  | AffichageRat of expression
  | AffichageBool of expression
  | AffichageString of expression
  | Conditionnelle of expression * bloc * bloc
  | TantQue of expression * bloc
  | Empty (* les nœuds ayant disparus: Const *)

(* nom, liste des paramètres, corps, expression de retour, informations associées à l'identificateur *)
type fonction = 
  | Empty (* Les noeuds ayant disparus: Prototype *)
  | Fonction of Tds.info_ast * Tds.info_ast list * instruction list * expression 

(* Structure d'un programme dans notre langage *)
type programme = Programme of fonction list * bloc * fonction list

let taille_variables_declarees i = 
  match i with
  | Declaration (_,info) -> 
    begin
    match Tds.info_ast_to_info info with
    | InfoVar (_,t,_,_) -> getTaille t
    | _ -> failwith "internal error"
    end
  | _ -> 0 ;;

end

(***********************************)
(* AST après la phase de placement *)
(***********************************)
module AstPlacement =
struct

(* Affectables existantes dans notre langage *)
(* = affectables  de AstType  *)
type affectable = AstType.affectable

(* Expressions existantes dans notre langage *)
(* = expression de AstType  *)
type expression = AstType.expression

(* instructions existantes dans notre langage *)
(* = instructions de AstType  *)
type bloc = instruction list
 and instruction = AstType.instruction

(* nom, corps, expression de retour, informations associées à l'identificateur *)
(* Plus besoin de la liste des paramètres mais on la garde pour les tests du placements mémoire *)
type fonction = 
  | Empty (* Les noeuds ayant disparus: Prototype *)
  | Fonction of Tds.info_ast * Tds.info_ast list * instruction list * expression
(* Structure d'un programme dans notre langage *)
type programme = Programme of fonction list * bloc * fonction list

end


