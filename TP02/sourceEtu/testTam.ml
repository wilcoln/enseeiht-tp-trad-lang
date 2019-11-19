open Compilateur

(* Changer le chemin d'accès du jar. *)
let runtamcmde = "java -jar ../../../../../tools/runtam/runtam.jar"
(* let runtamcmde = "java -jar /mnt/n7fs/.../tools/runtam/runtam.jar" *)

(* read up to maxlen characters from the input channel. *)
let load_chan ic =
  let maxlen = 10000 in   (* this is ugly but I cannot use in_channel_length on a pipe *)
  let s = Bytes.create maxlen in
  begin
    try really_input ic s 0 maxlen
    with End_of_file -> ()     (* don't care if maxlen was too large *)
  end;
  Bytes.to_string (Bytes.sub s 0 (Bytes.index s '\000'))  (* truncate the bytes and stringify them *)

(* requires module Str, not installed by default
let remove_blanks s = Str.global_replace (Str.regexp "[\r\n\t ]") "" s
*)
let remove_blanks = String.trim

(* Execute the TAM code obtained from the rat file and return the ouptut of this code *)
let runtamcode cmde ratfile =
  let tamcode = compiler ratfile in
  let (tamfile, chan) = Filename.open_temp_file "test" ".tam" in
  output_string chan tamcode;
  close_out chan;
  let ic = Unix.open_process_in (cmde ^ " " ^ tamfile) in
  let printed = load_chan ic in
  close_in ic;
  Sys.remove tamfile;    (* à commenter si on veut étudier le code TAM. *)
  remove_blanks printed

(* Compile and run ratfile, and compare its output to the expected output *)
let compareoutputstring ratfile expected =
  let printed = runtamcode runtamcmde ratfile in
    (* Printf.printf "> %s\n" printed;
    Printf.printf "< %s\n" expected; *)
    (printed = (remove_blanks expected))

(* Compile and run ratfile, and compare its output to the expected output stored in the out file. *)
let compareoutputfile ratfile =
  let expectedchan = open_in ((Filename.remove_extension ratfile) ^ ".out") in
  let expected = load_chan expectedchan in
  close_in expectedchan;
  compareoutputstring ratfile expected

(* Compile and run ratfile, then print its output *)
let runtam ratfile =
  print_string (runtamcode runtamcmde ratfile)

(* requires ppx_expect in jbuild, and `opam install ppx_expect` *)
(*
let%expect_test "testprintint" =
  runtam "../../fichiersRat/src-rat-tam-test/testprintint.rat";
  [%expect{| 42 |}]

let%expect_test "testprintbool" =
  runtam "../../fichiersRat/src-rat-tam-test/testprintbool.rat";
  [%expect{| true |}]

let%expect_test "testprintrat" =
   runtam "../../fichiersRat/src-rat-tam-test/testprintrat.rat";
   [%expect{| [4/5] |}]

let%expect_test "testaddint" =
  runtam "../../fichiersRat/src-rat-tam-test/testaddint.rat";
  [%expect{| 42 |}]

let%expect_test "testaddrat" =
  runtam "../../fichiersRat/src-rat-tam-test/testaddrat.rat";
  [%expect{| [7/6] |}]

let%expect_test "testmultint" =
  runtam "../../fichiersRat/src-rat-tam-test/testmultint.rat";
  [%expect{| 440 |}]

let%expect_test "testmultrat" =
  runtam "../../fichiersRat/src-rat-tam-test/testmultrat.rat";
  [%expect{| [14/3] |}]

let%expect_test "testnum" =
  runtam "../../fichiersRat/src-rat-tam-test/testnum.rat";
  [%expect{| 4 |}]

let%expect_test "testdenom" =
  runtam "../../fichiersRat/src-rat-tam-test/testdenom.rat";
  [%expect{| 7 |}]

let%expect_test "testwhile1" =
  runtam "../../fichiersRat/src-rat-tam-test/testwhile1.rat";
  [%expect{| 19 |}]

let%expect_test "testif1" =
  runtam "../../fichiersRat/src-rat-tam-test/testif1.rat";
  [%expect{| 18 |}]

let%expect_test "testif2" =
  runtam "../../fichiersRat/src-rat-tam-test/testif2.rat";
  [%expect{| 21 |}]

let%expect_test "factiter" =
  runtam "../../fichiersRat/src-rat-tam-test/factiter.rat";
  [%expect{| 120 |}]

let%expect_test "complique" =
  runtam "../../fichiersRat/src-rat-tam-test/complique.rat";
  [%expect{| [9/4][27/14][27/16][3/2] |}]

let%expect_test "factfun1" =
  runtam "../../fichiersRat/src-rat-tam-test/testfun1.rat";
  [%expect{| 1 |}]

let%expect_test "factfun2" =
  runtam "../../fichiersRat/src-rat-tam-test/testfun2.rat";
  [%expect{| 7 |}]

let%expect_test "factfun3" =
  runtam "../../fichiersRat/src-rat-tam-test/testfun3.rat";
  [%expect{| 10 |}]

let%expect_test "factfun4" =
  runtam "../../fichiersRat/src-rat-tam-test/testfun4.rat";
  [%expect{| 10 |}]

let%expect_test "factfuns" =
  runtam "../../fichiersRat/src-rat-tam-test/testfuns.rat";
  [%expect{| 28 |}]

let%expect_test "factrec" =
  runtam "../../fichiersRat/src-rat-tam-test/factrec.rat";
  [%expect{| 120 |}]
*)