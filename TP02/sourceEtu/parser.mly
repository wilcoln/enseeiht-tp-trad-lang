/* Imports. */

%{

open Utils
open Type
open Ast.AstSyntax
%}


%token <int> ENTIER
%token <string> ID
%token <string> CHAINE
%token RETURN
%token PV
%token AO
%token AF
%token PF
%token PO
%token EQUAL
%token CONST
%token PRINT
%token IF
%token ELSE
%token WHILE
%token BOOL
%token INT
%token RAT
%token CALL 
%token CO
%token CF
%token SLASH
%token NUM
%token DENOM
%token TRUE
%token FALSE
%token PLUS
%token MULT
%token INF
%token NULL
%token NEW
%token AMP
%token STRING
%token CARAT
%token VIRG
%token LENGTH
%token EOF

(* Type de l'attribut synthétisé des non-terminaux *)
%type <programme> prog
%type <instruction list> bloc
%type <fonction> fonc
%type <instruction list> is
%type <instruction> i
%type <typ> typ
%type <(typ*string) list> dp
%type <expression> e 
%type <expression list> cp
%type <affectable> a

(* Type et définition de l'axiome *)
%start <Ast.AstSyntax.programme> main

%%

main : lfi = prog EOF     {lfi}

prog :
    | ldfs1=dfs ID li=bloc ldfs2=dfs {Programme(ldfs1,li,ldfs2)}

dfs :                   
    |                           {[]}
    | d=decl ldfs=dfs           {d::ldfs} 
    | f=fonc ldfs=dfs           {f::ldfs} 

decl : t=typ n=ID PO lp=dp PF PV {let lt = fst (List.split lp) in Prototype(t,n,lt)}

fonc : t=typ n=ID PO lp=dp PF AO li=is RETURN exp=e PV AF {Fonction(t,n,lp,li,exp)}

bloc : AO li = is AF      {li}

is :
|                         {[]}
| i1=i li=is              {i1::li}

i :
| t=typ n=ID EQUAL e1=e PV          {Declaration (t,n,e1)}
| a1=a EQUAL e1=e PV                {Affectation (a1,e1)}
| CONST n=ID EQUAL e=ENTIER PV      {Constante (n,e)}
| PRINT e1=e PV                     {Affichage (e1)}
| IF exp=e li1=bloc ELSE li2=bloc   {Conditionnelle (exp,li1,li2)}
| WHILE exp=e li=bloc               {TantQue (exp,li)}

dp :
|                         {[]}
| t=typ n=ID lp=dp        {(t,n)::lp}

typ :
| BOOL              {Bool}
| INT               {Int}
| RAT               {Rat}
| STRING            {String}
| tp=typ MULT       {Pointeur(tp)}

e : 
| CALL n=ID PO lp=cp PF   {AppelFonction (n,lp)}
| CO e1=e SLASH e2=e CF   {Rationnel(e1,e2)}
| NUM e1=e                {Numerateur e1}
| DENOM e1=e              {Denominateur e1}
| TRUE                    {True}
| FALSE                   {False}
| e=ENTIER                {Entier e}
| s=CHAINE                {Chaine (trim_rat_str s)}
| PO e1=e AO e2=e VIRG e3=e AF PF {SousChaine (e1,e2,e3)}
| LENGTH e1=e             {Longueur (e1)}
| PO e1=e PLUS e2=e PF    {Binaire (Plus,e1,e2)}
| PO e1=e MULT e2=e PF    {Binaire (Mult,e1,e2)}
| PO e1=e EQUAL e2=e PF   {Binaire (Equ,e1,e2)}
| PO e1=e INF e2=e PF     {Binaire (Inf,e1,e2)}
| PO e1=e CARAT e2=e PF   {Binaire (Concat,e1,e2)}
| a1=a                    {Affectable (a1)}
| NULL                    {Null}
| PO NEW tp=typ PF        {New (tp)}
| AMP n=ID                {Adresse (n)}

a : 
| n=ID                    {Ident n}
| PO MULT a1=a PF         {Contenu (a1)}

cp :
|               {[]}
| e1=e le=cp    {e1::le}

