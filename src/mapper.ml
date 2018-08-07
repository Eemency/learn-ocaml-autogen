open Ast_mapper
open Ast_helper
open Asttypes
open Parsetree

let is_sampler_extension = function
  | {pvb_pat = {ppat_desc = Ppat_extension ({txt = "sampler"}, _)}} -> true
  | _ -> false

let is_sampler_function = function
  | {pvb_pat = {ppat_desc = Ppat_var {txt = fun_name}}} ->
      begin
        try String.sub fun_name 0 7 = "sample_"
        with Invalid_argument _ -> false
      end
  | x -> false

let is_sampler x =
  is_sampler_extension x || is_sampler_function x

let remove_samplers = function
  | {pstr_desc = Pstr_value (rec_flag, vbs)} ->
      let no_sampler = List.filter (fun x -> not (is_sampler x)) vbs in
      Str.value rec_flag no_sampler
  | x -> x

let is_let_definition = function
  | {pstr_desc = Pstr_value (_, vbs)} -> vbs <> []
  | _ -> false

(* The type of the function is only used in grading, not in the solution nor
 * the template. *)
let rec remove_type_annotations keep_body = function
  (* Argument type annotations. *)
  | {pexp_loc = loc; pexp_desc = Pexp_fun (rec_flag, e,
      {ppat_desc = Ppat_constraint (pattern, ty)}, body)} ->
        Exp.fun_ ~loc rec_flag e pattern (remove_type_annotations keep_body body)
  (* ty is the last type annotation: the return type. *)
  | {pexp_loc = loc; pexp_attributes = attrs;
      pexp_desc = Pexp_constraint (e, ty)} ->
        if keep_body then e
        else
          Exp.constant ~loc ~attrs (Pconst_string (
            "Replace this string by your implementation.", None))
  | {pexp_loc = loc} ->
      raise Location.(Error (
        error ~loc "Not a function or lacking type annotations."))

let remove_type_annotations_in_vbs keep_body =
  let fetch_e_and_remove {pvb_pat; pvb_expr; pvb_attributes; pvb_loc} =
    let e = remove_type_annotations keep_body pvb_expr in
    {pvb_pat; pvb_expr = e; pvb_attributes; pvb_loc}
  in List.map fetch_e_and_remove

let remove_type_annotations_in_expression keep_body = function
  | {pstr_desc = Pstr_value (rec_flag, vbs)} ->
      let vbs' = remove_type_annotations_in_vbs keep_body vbs in
      Str.value rec_flag vbs'
  | x -> x

let unwrap_extension = function
  | {pstr_desc = Pstr_extension ((_, PStr items), _)} -> items
  | _ -> []

let is_correct_extension extension_names = function
  | {pstr_desc = Pstr_extension (({txt}, _), _)}
      when List.mem txt extension_names -> true
  | _ -> false

let keep_unwrapped_extensions extension_names s =
  List.filter (is_correct_extension extension_names) s
    |> List.fold_left (fun acc x -> acc @ (unwrap_extension x)) []

(* Generates a mapper that ignores all expressions but the ones with the
 * extension txt. For prepare and prelude. *)
let prepare_prelude_mapper txt _argv =
  { default_mapper with
    structure = (fun mapper s -> keep_unwrapped_extensions [txt] s)
  }

(* Structure mapper for template and solution. *)
let solution_template_structure_mapper is_solution extension_mapper mapper s =
  let rec replace acc = function
    | {pstr_desc = Pstr_value (rec_flag, vbs)} :: s ->
        let vbs' = remove_type_annotations_in_vbs is_solution vbs in
        let rec_flag = if is_solution then rec_flag else Nonrecursive in
        replace (Str.value rec_flag vbs' :: acc) s
    | {pstr_desc = Pstr_extension (({txt}, PStr items), payload)} :: s ->
        replace (extension_mapper items payload txt @ acc) s
    | _ :: s -> replace acc s
    | [] -> acc in
  let s' = List.map remove_samplers s in
  List.rev (replace [] s')
