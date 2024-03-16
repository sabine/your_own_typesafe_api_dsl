(* TODO: NONE OF THIS WORKS BECAUSE the yojson pxx does not generate the same structure as Rust's serde did*)

(* names of generated types *)

let input_name ~endpoint_name =
  Format.sprintf "%sInput" (Gen_types.Names.to_pascal_case endpoint_name)

let query_params_name ~endpoint_name =
  Format.sprintf "%sQuery" (Gen_types.Names.to_pascal_case endpoint_name)

let output_name ~endpoint_name =
  Format.sprintf "%sOutput" (Gen_types.Names.to_pascal_case endpoint_name)

let response_type_name ~endpoint_name =
  Format.sprintf "%sResponse" (Gen_types.Names.to_pascal_case endpoint_name)

module Api_types = struct
  let gen_type_declaration_for_api_type ~type_namespace
      (decl : Ast.type_declaration) =
    match decl with
    | BasicTypeDecl decl ->
        Gen_types.Gen_typescript.gen_type_declaration ~type_namespace decl
    | IdType name ->
        Gen_types.(
          Gen_typescript.gen_type_declaration ~type_namespace
            Dsl.(alias (TypeName.of_string name) str))

  let gen_types ~(t : Ast.type_declaration list)
      ~(it : Ast.type_declaration list) ~(ot : Ast.type_declaration list)
      ~type_namespace =
    Format.sprintf
      "// API input and output types\n\
       %s\n\n\
       // API input types\n\
       %s\n\n\
       // API output types\n\
       %s"
      (String.concat "\n\n"
         (List.map (gen_type_declaration_for_api_type ~type_namespace) t))
      (String.concat "\n\n"
         (List.map (gen_type_declaration_for_api_type ~type_namespace) it))
      (String.concat "\n\n"
         (List.map (gen_type_declaration_for_api_type ~type_namespace) ot))
end

let gen_types = Api_types.gen_types

module Endpoint_types = struct
  let gen_input ~endpoint_name (endpoint_params : Ast.JsonBody.t)
      ~type_namespace =
    match endpoint_params with
    | [] -> ""
    | _ ->
        Api_types.gen_type_declaration_for_api_type ~type_namespace
          (Dsl.record (input_name ~endpoint_name) endpoint_params)

  let gen_endpoint_params_type ~name (endpoint_params : Ast.JsonBody.t)
      ~type_namespace =
    match endpoint_params with
    | [] -> Format.sprintf "export type %s = {}" name
    | _ ->
        Api_types.gen_type_declaration_for_api_type ~type_namespace
          (Dsl.record name endpoint_params)

  let gen_query_params_type ~name (query_params : Ast.QueryParams.t)
      ~type_namespace =
    match query_params with
    | [] -> Format.sprintf "export type %s = {}" name
    | _ ->
        Api_types.gen_type_declaration_for_api_type ~type_namespace
          (BasicTypeDecl (Ast.QueryParams.record_of_t name query_params))

  let gen_response_type ~endpoint_name =
    Format.sprintf "export type %s = utils.ApiResponse<%s>;"
      (response_type_name ~endpoint_name)
      (output_name ~endpoint_name)

  let gen_endpoint_types ~type_namespace (endpoint : Ast.endpoint) =
    match endpoint.shape with
    | Get s ->
        let output_t =
          gen_endpoint_params_type
            ~name:(output_name ~endpoint_name:endpoint.name)
            s.output ~type_namespace
        in
        let query_t =
          match s.query_params with
          | [] -> []
          | _ ->
              [
                gen_query_params_type
                  ~name:(query_params_name ~endpoint_name:endpoint.name)
                  s.query_params ~type_namespace;
              ]
        in

        query_t @ [ output_t ]
    | Post s ->
        let input_t =
          gen_endpoint_params_type
            ~name:(input_name ~endpoint_name:endpoint.name)
            s.input ~type_namespace
        in
        let output_t =
          gen_endpoint_params_type
            ~name:(output_name ~endpoint_name:endpoint.name)
            s.output ~type_namespace
        in
        let query_t =
          match s.query_params with
          | [] -> []
          | _ ->
              [
                gen_query_params_type
                  ~name:(query_params_name ~endpoint_name:endpoint.name)
                  s.query_params ~type_namespace;
              ]
        in

        query_t @ [ input_t; output_t ]
    | Delete s ->
        let output_t =
          gen_endpoint_params_type
            ~name:(output_name ~endpoint_name:endpoint.name)
            s.output ~type_namespace
        in
        [ output_t ]
end

module Endpoint_code = struct
  type endpoint_param = { name : string; t : string }

  let signature_endpoint_params (endpoint : Ast.endpoint) ~type_namespace =
    let params_of_url_params (url_params : Ast.UrlParams.t) =
      List.map
        (fun ({ name; t } : Ast.UrlParams.param) ->
          { name; t = Gen_types.Gen_typescript.render_type t ~type_namespace })
        url_params
    in

    let params_of_query_params (query_params : Ast.QueryParams.t) =
      match query_params with
      | [] -> []
      | _ ->
          [
            {
              name = "q";
              t =
                type_namespace ^ query_params_name ~endpoint_name:endpoint.name;
            };
          ]
    in
    match endpoint.shape with
    | Get { url_params; query_params; _ } ->
        params_of_url_params url_params @ params_of_query_params query_params
    | Post { url_params; input; query_params; _ } -> (
        params_of_url_params url_params
        @ params_of_query_params query_params
        @
        match input with
        | [] -> []
        | _ ->
            [
              {
                name = "body";
                t = type_namespace ^ input_name ~endpoint_name:endpoint.name;
              };
            ])
    | Delete { url_params; _ } -> params_of_url_params url_params

  let utils_call_endpoint_params (endpoint : Ast.endpoint) =
    match endpoint.shape with
    | Get _ -> []
    | Post { input; _ } -> if List.length input > 0 then [ "body" ] else []
    | Delete _ -> []

  let gen_endpoint_function_body (endpoint : Ast.endpoint) =
    let url =
      let re = Str.regexp "{" in
      Str.global_replace re "${" endpoint.path
    in
    let url =
      match endpoint.shape with
      | Get { query_params; _ } ->
          if List.length query_params > 0 then
            url ^ "${utils.stringify_query(q)}"
          else url
      | Post { query_params; _ } ->
          if List.length query_params > 0 then
            url ^ "${utils.stringify_query(q)}"
          else url
      | _ -> url
    in
    let params =
      [ Format.sprintf "`%s`" url ] @ utils_call_endpoint_params endpoint
    in
    match endpoint.shape with
    | Get _ ->
        Format.sprintf "return utils.get(%s);" (String.concat ", " params)
    | Post _ ->
        Format.sprintf "return utils.post(%s);" (String.concat ", " params)
    | Delete _ ->
        Format.sprintf "return utils.del(%s);" (String.concat ", " params)
end

type gen_endpoint_result = { types : string list; code : string }

let gen_endpoint ~type_namespace (endpoint : Ast.endpoint) =
  let types =
    Endpoint_types.gen_endpoint_types endpoint ~type_namespace
    @ [ Endpoint_types.gen_response_type ~endpoint_name:endpoint.name ]
  in

  let params =
    List.map
      (fun Endpoint_code.{ name; t } -> Format.sprintf "%s: %s" name t)
      (Endpoint_code.signature_endpoint_params endpoint ~type_namespace)
  in
  let code =
    Format.sprintf {|export function %s(%s): Promise<%s> {
  %s
}|}
      endpoint.name
      (String.concat ",\n    " params)
      (type_namespace ^ response_type_name ~endpoint_name:endpoint.name)
      (Endpoint_code.gen_endpoint_function_body endpoint)
  in

  { types; code }

let gen_endpoints ~type_namespace (routes : Ast.endpoint list) =
  let result =
    List.fold_left
      (fun { types; code } endpoint ->
        let result = gen_endpoint ~type_namespace endpoint in
        {
          types = List.concat [ types; result.types ];
          code = code ^ "\n\n" ^ result.code;
        })
      { types = []; code = "" } routes
  in
  result
