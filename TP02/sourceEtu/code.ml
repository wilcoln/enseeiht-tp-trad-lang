(* Génération d'étiquette à l'aide d'un compteur *)
let getEtiquette = 
  let num = ref 0 in
  fun () ->
    num := (!num)+1 ;
    "label"^((string_of_int (!num)))

let pgcd = 
"pgcd
LOADL 0
LOAD (1) -2[LB]
LOAD (1) -1[LB]
boucle
LOAD (1) 5[LB]
JUMPIF (0) fin
LOAD (1) 4[LB]
LOAD (1) 5 [LB]
SUBR IMod
STORE (1) 3[LB]
LOAD (1) 5[LB]
STORE (1) 4[LB]
LOAD (1) 3[LB]
STORE(1) 5[LB]
JUMP boucle
fin
LOAD (1) 4[LB]
RETURN (1) 2\n\n"

let norm =
"norm
LOAD (1) -2[LB]
LOAD (1) -1[LB]
CALL (LB) pgcd
LOAD (1) -2[LB]
LOAD (1) 3[LB]
SUBR IDiv
LOAD (1) -1[LB]
LOAD (1) 3[LB]
SUBR IDiv
RETURN (2) 2\n\n"

let rout =
"ROut
LOADL '['
SUBR COut
LOAD (1) -2[LB]
SUBR IOut
LOADL '/'
SUBR COut
LOAD (1) -1[LB]
SUBR IOut
LOADL ']'
SUBR COut
POP (0) 1
RETURN (0) 2\n\n"

let radd =
"RAdd
LOAD (1) -4[LB]
LOAD (1) -1[LB]
SUBR IMul
LOAD (1) -2[LB]
LOAD (1) -3[LB]
SUBR IMul
SUBR IAdd
LOAD (1) -3[LB]
LOAD (1) -1[LB]
SUBR IMul
CALL (ST) norm
POP (2) 4
RETURN (2) 4\n\n"

let rmul =
"RMul
LOAD (1) -4[LB]
LOAD (1) -2[LB]
SUBR IMul
LOAD (1) -3[LB]
LOAD (1) -1[LB]
SUBR IMul
CALL (ST) norm
POP (2) 4
RETURN (2) 4\n\n"


let sout = 
  "SOut ; affiche une chaîne de caracteres dont l'adresse dans le tas est en -1[LB]
  LOAD (1) -1[LB] ; adresse dans le tas de la chaine en sommet de pile
  LOADI (1) ; taille de la chaine en 3[LB]
  LOADL 0 ; indice de parcours de la chaine en 4[LB]
  bouclePrintSout ; etiquette de boucle de l'affichage 
  LOAD (1) 3[LB] 
  LOAD (1) 4[LB]
  SUBR INeg
  JUMPIF (0) finBouclePrintSout
  LOAD (1) -1[LB] ; adresse de la chaine en sommet de pile
  LOAD (1) 4[LB] ; indice pour le décalage
  LOADL 1 ; +1 parce qu'il faut compter le champ taille
  SUBR IAdd
  SUBR IAdd ; adresse du caractère a afficher 
  LOADI (1) ; caractere a afficher
  SUBR COut ; adresse du caractere a afficher 
  LOAD (1) 4[LB] ; début de l'incrémentation de l'indice de boucle
  LOADL 1
  SUBR IAdd
  STORE (1) 4[LB] ; fin de l'incrementation de l'indice de boucle
  JUMP bouclePrintSout
  finBouclePrintSout
  RETURN (0) 1\n\n"
  
  let scat =
    "SCat ; concatene deux chaines de caracteres passées en paramètre -2[LB] adresse de la premiere chaine -1[LB] adresse de la seconde chaine
    LOAD (1) -2[LB]
    LOADI (1) ; taille de c1
    LOAD (1) -1[LB]
    LOADI (1) ; taille de c2
    SUBR IAdd ; taille de la nouvelle chaine en 3[LB]
    LOAD (1) -1[ST] ; duplication de la taille de la chaine
    LOADL 1
    SUBR IAdd
    SUBR MAlloc ; taille réservée dans le tas et adresse de la chaine en 4[LB]
    LOAD (1) -2[LB]
    LOADI (1) ; taille de c1
    LOAD (1) -1[LB]
    LOADI (1) ; taille de c2
    SUBR IAdd ; taille de la chaine
    LOAD (1) 4[LB] ; adresse où stocker la taille
    STOREI (1)
    LOAD (1) -2[LB]
    LOADI (1) ; taille de c1 en 5[LB]
    LOADL 0 ; indice de parcours en 6[LB] 
    copiec1
    LOAD (1) 5[LB]
    LOAD (1) 6[LB]
    SUBR INeg ; test si on a fini la boucle
    JUMPIF (0) fincopiec1
    LOAD (1) -2[LB]
    LOAD (1) 6[LB]
    LOADL 1
    SUBR IAdd
    SUBR IAdd ; adresse du caractère à copier
    LOADI (1) ; caractère à copier
    LOAD (1) 4[LB]
    LOADL 1
    LOAD (1) 6[LB]
    SUBR IAdd
    SUBR IAdd ; adresse où copier le caratère
    STOREI (1)
    LOAD (1) 6[LB]
    LOADL 1
    SUBR IAdd
    STORE (1)  6[LB] ; incrément de l'indice de boucle
    JUMP copiec1
    fincopiec1
    LOAD (1) -1[LB]
    LOADI (1) ; taille de c2
    STORE (1) 5[LB] ; taille de c2 en 5[LB]
    LOADL 0
    STORE (1) 6[LB] ; indice de parcours en 6[LB]
    copiec2
    LOAD (1) 5[LB]
    LOAD (1) 6[LB]
    SUBR INeg ; test si on a fini la boucle
    JUMPIF (0) fincopiec2
    LOAD (1) -1[LB]
    LOAD (1) 6[LB]
    LOADL 1
    SUBR IAdd
    SUBR IAdd ; adresse du caractère à copier
    LOADI (1) ; caractère à copier
    LOAD (1) 4[LB]
    LOADL 1 ; décalage pour la taille
    LOAD (1) -2[LB]
    LOADI (1) ; décalage pour la taille de c1
    LOAD (1) 6[LB] ; décalage pour l'indice
    SUBR IAdd
    SUBR IAdd
    SUBR IAdd ; adresse où copier le caractère
    STOREI (1)
    LOAD (1) 6[LB]
    LOADL 1
    SUBR IAdd
    STORE (1)  6[LB] ; incrément de l'indice de boucle
    JUMP copiec2
    fincopiec2
    LOAD (1) 4[LB] ; on charge le résultat - ie l'adresse
    RETURN (1) 2; dépile les deux adresses, laisse en sommet de pile l'adresse de la chaine concatenee \n\n "
  
  let ssub =
    "SSub ; -3[LB] adresse de la chaine - -2[LB] indice de départ - -1[LB] indice de fin
    LOAD (1) -1[LB]
    LOAD (1) -2[LB]
    SUBR INeg 
    LOADL 1
    SUBR IAdd ; taille de la chaine en 3[LB]
    LOAD (1) -1[ST]
    LOADL 1 
    SUBR IAdd
    SUBR MAlloc ; réservation de l'espace + adresse de la nouvelle chaine en 4[LB]
    LOAD (1) 3[LB]
    LOAD (1) 4[LB]
    STOREI (1) ; enregistrement de la taille de la nouvelle chaine dans son espace
    LOADL 0 ; indice de boucle en 5[LB]
    bouclesub
    LOAD (1) 3[LB]
    LOAD (1) 5[LB]
    SUBR INeg
    JUMPIF (0) finbouclesub
    LOAD (1) -3[LB]
    LOADL 1
    LOAD (1) 5[LB]
    LOAD (1) -2[LB]
    SUBR IAdd
    SUBR IAdd
    SUBR IAdd ; adresse du caractere à copier
    LOADI (1) ; caractere a copier
    LOAD (1) 4[LB]
    LOADL 1
    LOAD (1) 5[LB]
    SUBR IAdd
    SUBR IAdd ; adresse où copier le caractere
    STOREI (1) ; copie
    LOADL 1
    LOAD (1) 5[LB]
    SUBR IAdd
    STORE (1) 5[LB] ; incrément de l'indice de boucle
    JUMP bouclesub
    finbouclesub
    LOAD (1) 4[LB] ; on charge le résultat en sommet de pile
    RETURN (1) 3 ; dépile les trois paramètres et laisse en somme de pile la nouvelle adresse \n\n"
  

(* Entête des fichiers Rat  contenant :
- un saut vers le programme principal
- la fonction pgcd nécessaire à la normalisation des rationnels
- une fonction de normalisation des rationnels
- les fonctions d'affichage (ROut), d'addition (RAdd) et de multiplication (RMult) de rationnel
*)
let getEntete () =
  "JUMP main\n\n"
  ^pgcd
  ^norm
  ^rout
  ^radd
  ^rmul

(*Ecriture dans un fichier *)
let ecrireFichier nom texte =
  let fich = open_out nom in
  output_string fich texte ;
  close_out fich
