(* type declarations *)

type type_declaration =
  | BasicTypeDecl of Gen_types.Types.type_declaration
  | IdType of string

(* Generic types from Gen_types *)

include Gen_types.Types.TypeDeclarations

let alias n t = BasicTypeDecl (Gen_types.Types.alias n t)
let struct_ n f = BasicTypeDecl (Gen_types.Types.struct_ n f)

let string_enum n options =
  BasicTypeDecl (Gen_types.Types.string_enum n options)

let int_enum n options = BasicTypeDecl (Gen_types.Types.int_enum n options)
let struct_union n v = BasicTypeDecl (Gen_types.Types.struct_union n v)
let struct_union_variant n f = Gen_types.Types.{ struct_name = n; fields = f }

(* Types specific to this API *)

let id_type name = IdType name

(* route types *)
type method_ = Get | Post | Delete
type url_param = { name : string; t : Gen_types.Types.t }
type url_params = url_param list option

type error_variant = {
  variant : Gen_types.Types.struct_;
  status_code : int;
  title : string;
}

module JsonBody = struct
  type t = Fields of Gen_types.Types.field list | None
end

module QueryParams = struct
  type value_t = Str | Float | Int | StrList
  type field_t = { name : string; t : value_t }
  type t = Fields of field_t list | None

  let field name t = { name; t }

  let type_of_value_t (t : value_t) =
    match t with
    | Str -> option str
    | Float -> option f64
    | Int -> option i63
    | StrList -> vec str

  let struct_field_of_field_t (f : field_t) =
    Gen_types.Types.(field f.name (type_of_value_t f.t))

  let struct_of_t name (q : t) =
    match q with
    | Fields fields -> struct_ name (List.map struct_field_of_field_t fields)
    | None -> struct_ name []
end

type get_route = {
  url_params : url_params;
  query_param_type : QueryParams.t;
  output_type : JsonBody.t;
}

type post_route = {
  url_params : url_params;
  query_param_type : QueryParams.t;
  input_type : JsonBody.t;
  output_type : JsonBody.t;
  error_type : error_variant list option;
}

type delete_route = {
  url_params : url_params;
  output_type : JsonBody.t;
  error_type : error_variant list option;
}

type route_shape =
  | Get of get_route
  | Post of post_route
  | Delete of delete_route

type route = {
  name : string;
  url : string;
  docstring : string;
  shape : route_shape;
}
