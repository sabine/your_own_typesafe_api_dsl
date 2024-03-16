(* type declarations *)

type type_declaration =
  | BasicTypeDecl of Gen_types.Ast.type_declaration
  | IdType of string

(* endpoint types *)
type method_ = Get | Post | Delete

module UrlParams = struct
  type param = { name : string; t : Gen_types.Ast.t }
  type t = param list
end

module JsonBody = struct
  type t = Gen_types.Ast.field list
end

module QueryParams = struct
  type value_t = Str | Float | Int | StrList
  type field_t = { name : string; t : value_t }
  type t = field_t list

  let field name t = { name; t }

  let type_of_value_t (t : value_t) =
    let open Gen_types.Ast in
    match t with
    | Str -> Nullable (PrimitiveType Str)
    | Float -> Nullable (PrimitiveType Float)
    | Int -> Nullable (PrimitiveType I63)
    | StrList -> Nullable (Array (PrimitiveType Str))

  let record_field_of_field_t (f : field_t) =
    Gen_types.Ast.{ field_name = f.name; field_t = type_of_value_t f.t }

  let record_of_t name (fields : t) =
    match fields with
    | [] -> Gen_types.Dsl.record name []
    | _ -> Gen_types.Dsl.record name (List.map record_field_of_field_t fields)
end

type get = {
  url_params : UrlParams.t;
  query_params : QueryParams.t;
  output : JsonBody.t;
}

type post = {
  url_params : UrlParams.t;
  query_params : QueryParams.t;
  input : JsonBody.t;
  output : JsonBody.t;
}

type delete = { url_params : UrlParams.t; output : JsonBody.t }
type endpoint_shape = Get of get | Post of post | Delete of delete

type endpoint = {
  name : string;
  path : string;
  docstring : string;
  shape : endpoint_shape;
}
