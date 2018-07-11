open Ast_mapper
open Ast_helper
open Asttypes
open Parsetree

let solution_structure_mapper mapper s =
  let remove_type_annotations_in_expression = function
    | {pstr_desc = Pstr_value (rec_flag, vbs)} ->
        let vbs' = Mapper.remove_type_annotations_in_vbs true vbs in
        Str.value rec_flag vbs'
    | x -> x
  in
  List.filter Mapper.keep_let_definitions s
    |> List.map remove_type_annotations_in_expression

let solution_mapper _argv =
  { default_mapper with
    structure = solution_structure_mapper
  }

let () = register "solution" solution_mapper
