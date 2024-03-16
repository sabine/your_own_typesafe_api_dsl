let gen_type_declaration_for_api_type ~type_namespace ~ppxes
    (decl : Ast.type_declaration) =
  match decl with
  | BasicTypeDecl decl ->
      Gen_types.Gen_ocaml.gen_type_declaration ~type_namespace decl ~ppxes
  | IdType name ->
      Format.sprintf
        "module %s = struct\n  type t = string [@@@@deriving yojson]\n\nend"
        (Gen_types.Names.to_pascal_case name)

(* input body type *)

let input_name ~endpoint_name ~type_namespace =
  Format.sprintf "%sInput"
    (type_namespace ^ Gen_types.Names.to_pascal_case endpoint_name)

let gen_input ~endpoint_name (json_body : Ast.JsonBody.t) ~type_namespace =
  match json_body with
  | [] -> ""
  | _ ->
      gen_type_declaration_for_api_type ~type_namespace ~ppxes:[ "yojson" ]
        (Dsl.record (input_name ~type_namespace ~endpoint_name) json_body)

let query_params_name ~endpoint_name ~type_namespace =
  Format.sprintf "%sQuery"
    (type_namespace ^ Gen_types.Names.to_pascal_case endpoint_name)

let gen_query_params ~name (query_params : Ast.QueryParams.t) ~type_namespace
    ~ppxes =
  match query_params with
  | [] ->
      gen_type_declaration_for_api_type ~type_namespace ~ppxes
        Dsl.(alias (TypeName.of_string name) unit)
  | _ ->
      gen_type_declaration_for_api_type ~type_namespace ~ppxes
        (BasicTypeDecl (Ast.QueryParams.record_of_t name query_params))

let gen_json_body_type ~name (json_body : Ast.JsonBody.t) ~type_namespace ~ppxes
    =
  match json_body with
  | [] ->
      gen_type_declaration_for_api_type ~type_namespace ~ppxes
        Dsl.(alias (TypeName.of_string name) unit)
  | _ ->
      gen_type_declaration_for_api_type ~type_namespace ~ppxes
        (Dsl.record name json_body)

let output_name ~endpoint_name ~type_namespace =
  Format.sprintf "%sOutput"
    (type_namespace ^ Gen_types.Names.to_pascal_case endpoint_name)

let response_type_name ~endpoint_name ~type_namespace =
  Format.sprintf "%sResponse"
    (type_namespace ^ Gen_types.Names.to_pascal_case endpoint_name)

type endpoint_param = { name : string; t : string }

let json_body = [ { name = "req"; t = "Dream.request" } ]

let handler_params (endpoint : Ast.endpoint) ~type_namespace =
  let params_of_url_params (url_params : Ast.UrlParams.t) =
    List.map
      (fun ({ name; t } : Ast.UrlParams.param) ->
        { name; t = Gen_types.Gen_ocaml.render_type t ~type_namespace })
      url_params
  in
  let params_of_query_params (query_params : Ast.QueryParams.t) =
    match query_params with
    | [] -> []
    | _ ->
        [
          {
            name = "query";
            t = query_params_name ~endpoint_name:endpoint.name ~type_namespace;
          };
        ]
  in
  match endpoint.shape with
  | Get { url_params; query_params; _ } ->
      ({ name = "req"; t = "Dream.request" } :: params_of_url_params url_params)
      @ params_of_query_params query_params
  | Post { url_params; input; query_params; _ } ->
      ({ name = "req"; t = "Dream.request" } :: params_of_url_params url_params)
      @ params_of_query_params query_params
      @
      if List.length input > 0 then
        [
          {
            name = "body";
            t = input_name ~endpoint_name:endpoint.name ~type_namespace;
          };
        ]
      else []
  | Delete { url_params; _ } ->
      { name = "req"; t = "Dream.request" } :: params_of_url_params url_params

let gen_endpoint_function_body (endpoint : Ast.endpoint) ~type_namespace
    ~handler_namespace =
  let gen_deserialize_query (query_params : Ast.QueryParams.t) =
    match query_params with
    | [] -> []
    | _ ->
        [
          Format.sprintf
            "match %s.parse_query req with\n\
            \  | Error msg -> %sbad_request msg\n\
            \  | Ok query -> \n"
            (query_params_name ~endpoint_name:endpoint.name ~type_namespace)
            handler_namespace;
        ]
  in
  let params_of_url_params (url_params : Ast.UrlParams.t) =
    List.map
      (fun ({ name; _ } : Ast.UrlParams.param) ->
        Format.sprintf "let %s = Dream.param req \"%s\" in" name name)
      url_params
  in
  let params =
    List.map (fun { name; _ } -> name) (handler_params endpoint ~type_namespace)
  in
  let body =
    match endpoint.shape with
    | Get { query_params; url_params; _ } ->
        gen_deserialize_query query_params @ params_of_url_params url_params
    | Post { query_params; url_params; input; _ } ->
        gen_deserialize_query query_params
        @ params_of_url_params url_params
        @
        if List.length input > 0 then
          [
            "let* body = Dream.body req in";
            Format.sprintf
              "let body = %s.t_of_yojson (Yojson.Safe.from_string body) in"
              (input_name ~endpoint_name:endpoint.name ~type_namespace);
          ]
        else []
    | Delete { url_params; _ } -> params_of_url_params url_params
  in
  String.concat "\n  "
    (body
    @ [
        Format.sprintf
          "let* result : (%s.t, Dream.response Lwt.t) result = %s%s %s in\n\
          \  match result with\n\
          \    | Ok result -> result |> %s.yojson_of_t |> \
           Yojson.Safe.to_string |> Dream.json\n\
          \    | Error response -> response"
          (output_name ~endpoint_name:endpoint.name ~type_namespace)
          handler_namespace endpoint.name (String.concat " " params)
          (output_name ~endpoint_name:endpoint.name ~type_namespace);
      ])

type endpoint_result = { types : string; code : string }

let url_of_endpoint (endpoint : Ast.endpoint) =
  let re = Str.regexp "{" in
  let re2 = Str.regexp "}" in
  Str.global_replace re2 "" (Str.global_replace re ":" endpoint.path)

let gen_endpoint_types ~type_namespace (endpoint : Ast.endpoint) =
  match endpoint.shape with
  | Get s ->
      let query_t =
        if List.length s.query_params > 0 then
          gen_query_params
            ~name:
              (query_params_name ~endpoint_name:endpoint.name ~type_namespace)
            s.query_params ~type_namespace ~ppxes:[ "query" ]
        else ""
      in
      let output_t =
        gen_json_body_type
          ~name:(output_name ~endpoint_name:endpoint.name ~type_namespace)
          s.output ~type_namespace ~ppxes:[ "yojson_of" ]
      in
      [ query_t; output_t ]
  | Post s ->
      let query_t =
        if List.length s.query_params > 0 then
          gen_query_params
            ~name:
              (query_params_name ~endpoint_name:endpoint.name ~type_namespace)
            s.query_params ~type_namespace ~ppxes:[ "query" ]
        else ""
      in
      let input_t =
        gen_json_body_type
          ~name:(input_name ~endpoint_name:endpoint.name ~type_namespace)
          s.input ~type_namespace ~ppxes:[ "of_yojson" ]
      in
      let output_t =
        gen_json_body_type
          ~name:(output_name ~endpoint_name:endpoint.name ~type_namespace)
          s.output ~type_namespace ~ppxes:[ "yojson_of" ]
      in
      [ query_t; input_t; output_t ]
  | Delete s ->
      let output_t =
        gen_json_body_type
          ~name:(output_name ~endpoint_name:endpoint.name ~type_namespace)
          s.output ~type_namespace ~ppxes:[ "yojson_of" ]
      in
      [ output_t ]

let gen_endpoint ~type_namespace ~handler_namespace (endpoint : Ast.endpoint) =
  let params =
    List.map (fun { name; t } -> Format.sprintf "(%s: %s)" name t) json_body
  in
  let code =
    Format.sprintf "let %s %s =\n  %s" endpoint.name (String.concat " " params)
      (gen_endpoint_function_body endpoint ~type_namespace ~handler_namespace)
  in
  code

let gen_endpoint_declaration (endpoint : Ast.endpoint) =
  match endpoint.shape with
  | Get _ ->
      Format.sprintf "Dream.get \"%s\" %s" (url_of_endpoint endpoint)
        endpoint.name
  | Post _ ->
      Format.sprintf "Dream.post \"%s\" %s" (url_of_endpoint endpoint)
        endpoint.name
  | Delete _ ->
      Format.sprintf "Dream.delete \"%s\" %s" (url_of_endpoint endpoint)
        endpoint.name

let gen_endpoints ~type_namespace ~handler_namespace
    (routes : Ast.endpoint list) =
  let endpoints =
    List.map (gen_endpoint ~type_namespace ~handler_namespace) routes
  in

  let endpoint_declarations =
    Format.sprintf "let routes = [\n  %s\n]"
      (String.concat ";\n  " (List.map gen_endpoint_declaration routes))
  in

  String.concat "\n\n"
    ([ "open Lwt.Syntax" ] @ endpoints @ [ endpoint_declarations ])

let gen_types ~(t : Ast.type_declaration list) ~(it : Ast.type_declaration list)
    ~(ot : Ast.type_declaration list) ~type_namespace
    (routes : Ast.endpoint list) =
  let gen_declarations ~ppxes =
    List.map (gen_type_declaration_for_api_type ~type_namespace ~ppxes)
  in
  Format.sprintf
    "(* API input and output types *)\n\
     %s\n\n\
     (* API input types *)\n\
     %s\n\n\
     (* API output types *)\n\
     %s\n\n\
     (* endpoint types *)\n\
     %s"
    (String.concat "\n\n" (gen_declarations ~ppxes:[ "yojson" ] t))
    (String.concat "\n\n" (gen_declarations ~ppxes:[ "yojson" ] it))
    (String.concat "\n\n" (gen_declarations ~ppxes:[ "yojson" ] ot))
    (String.concat "\n\n"
       (List.flatten (List.map (gen_endpoint_types ~type_namespace) routes)))
