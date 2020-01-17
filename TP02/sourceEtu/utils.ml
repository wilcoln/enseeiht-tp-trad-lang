open String
(**************************************************)
(* Quelques fonctions utilitaires sur les strings *)
(**************************************************)


(* str_split : string -> string list *)
(* Paramètre s : la chaine de caractère à traiter *)
(* Décompose la chaine en list de sous chaine d'1 caractère et renvoie cette liste *)
let str_split s =
  let rec aux i l =
    if i < 0 then l else aux (i - 1) ((sub s i 1) :: l) in
  aux (String.length s - 1) []

(* trim_rat_str : string -> string *)
(* Paramètre s : la chaine de caractère à traiter *)
(* Traite une chaine de caractère provenant d'un fichier rat, prend en compte les retour à la ligne  *)
let trim_rat_str s =
begin
    let rat_str = String.sub s 1 ((String.length s) - 2) in
    let rec aux str_list =
        match str_list with
        | [] -> ""
        | "\\"::("n"::q) -> "\n"^(String.concat "" q)
        | t::q -> t^(aux q)
     in aux (str_split rat_str)
end

(* unescape : string -> string *)
(* Paramètre s : la chaine de caractère à traiter *)
(* 'déséchape' le retour à la ligne *)
let unescape s =  if s = "\n" then "\\n" else s
