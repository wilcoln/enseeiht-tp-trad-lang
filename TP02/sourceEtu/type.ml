type typ = Bool | Int | Rat | String | Pointeur of typ | Undefined

let rec string_of_type t = 
  match t with
  | Bool ->  "Bool"
  | Int  ->  "Int"
  | Rat  ->  "Rat"
  | String -> "String"
  | Pointeur (tp) -> "Pointeur de "^(string_of_type tp)
  | Undefined -> "Undefined"


let rec est_compatible t1 t2 =
  match t1, t2 with
  | Bool, Bool -> true
  | Int, Int -> true
  | Rat, Rat -> true 
  | String, String -> true
  | Pointeur (tp1), Pointeur (tp2) -> est_compatible tp1 tp2
  | _ -> false 

let est_compatible_list lt1 lt2 =
  try
    List.for_all2 est_compatible lt1 lt2
  with Invalid_argument _ -> false

let getTaille t =
  match t with
  | Int -> 1
  | Pointeur (_) -> 1
  | Bool -> 1
  | Rat -> 2
  | String -> 1 (* Pas sûr*)
  | Undefined -> 0
  
