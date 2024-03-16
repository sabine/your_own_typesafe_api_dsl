let render_type (t : Gen_types.Ast.t) =
  Gen_types.Gen_documentation.render_type t ~type_namespace:""

let render_query_params (t : Ast.QueryParams.value_t) =
  match t with
  | Str -> "string"
  | Int -> "integer"
  | Float -> "float"
  | StrList -> "string list"

let gen_endpoint_doc (endpoint : Ast.endpoint) =
  let meth, url_params, query_params, input, output =
    match endpoint.shape with
    | Get { url_params; query_params; output } ->
        ("GET", url_params, query_params, [], output)
    | Post { url_params; query_params; input; output } ->
        ("POST", url_params, query_params, input, output)
    | Delete { url_params; output } -> ("DELETE", url_params, [], [], output)
  in
  let url_params =
    match url_params with
    | [] -> []
    | _ ->
        [
          "URL params:\n  "
          ^ String.concat "\n  "
              ([ "|name|type|"; "|-|-|" ]
              @ List.map
                  (fun (p : Ast.UrlParams.param) ->
                    Format.sprintf "|%s|%s|" p.name (render_type p.t))
                  url_params);
        ]
  in
  let query_params =
    match query_params with
    | [] -> []
    | _ ->
        [
          "Query Parameters:\n  "
          ^ String.concat "\n  "
              ([ "|name|type|"; "|-|-|" ]
              @ List.map
                  (fun (p : Ast.QueryParams.field_t) ->
                    Format.sprintf "|%s|%s|" p.name (render_query_params p.t))
                  query_params);
        ]
  in
  let input =
    match input with
    | [] -> []
    | _ ->
        [
          "Input body:\n  "
          ^ String.concat "\n  "
              ([ "|name|type|"; "|-|-|" ]
              @ List.map
                  (fun (p : Gen_types.Ast.field) ->
                    Format.sprintf "|%s|%s|" p.field_name
                      (render_type p.field_t))
                  input);
        ]
  in

  let output =
    match output with
    | [] -> []
    | _ ->
        [
          "Response body:\n  "
          ^ String.concat "\n  "
              ([ "|name|type|"; "|-|-|" ]
              @ List.map
                  (fun (p : Gen_types.Ast.field) ->
                    Format.sprintf "|%s|%s|" p.field_name
                      (render_type p.field_t))
                  output);
        ]
  in
  let docs = url_params @ query_params @ input @ output in

  Format.sprintf "## %s\n\n%s\n\n%s %s\n\n%s"
    (Gen_types.Gen_documentation.linkable_anchor endpoint.name)
    endpoint.docstring meth endpoint.path
    (String.concat "\n\n" docs)

let gen_type_documentation (t : Ast.type_declaration) ~type_namespace =
  match t with
  | BasicTypeDecl t ->
      Gen_types.Gen_documentation.gen_type_documentation ~type_namespace t
  | IdType name ->
      Format.sprintf "## %s\n\nis an ID type (String)"
        (Gen_types.Names.to_pascal_case name)

let gen_docs ~t ~it ~ot (routes : Ast.endpoint list) =
  String.concat "\n\n"
    ([ "# Types" ]
    @ List.map (gen_type_documentation ~type_namespace:"") t
    @ List.map (gen_type_documentation ~type_namespace:"") it
    @ List.map (gen_type_documentation ~type_namespace:"") ot
    @ [ "# Endpoints" ]
    @ List.map gen_endpoint_doc routes)
