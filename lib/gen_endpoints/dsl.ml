open Ast
include Gen_types.Dsl

let alias n t = BasicTypeDecl (Gen_types.Dsl.alias n t)
let record n f = BasicTypeDecl (Gen_types.Dsl.record n f)
let string_enum n options = BasicTypeDecl (Gen_types.Dsl.string_enum n options)
let int_enum n options = BasicTypeDecl (Gen_types.Dsl.int_enum n options)
let record_union n v = BasicTypeDecl (Gen_types.Dsl.record_union n v)
let record_union_variant n f = Gen_types.Ast.{ record_name = n; fields = f }

(* Dsl specific to this API *)

let id_type name = IdType name

(* UrlParams *)
let param name t = UrlParams.{ name; t }

(* endpoints *)
let get ~name ~path ?(docstring = "") ?(url_params = []) ?(query_params = [])
    ~output () =
  { name; path; docstring; shape = Get { url_params; query_params; output } }

let post ~name ~path ?(docstring = "") ?(url_params = []) ?(query_params = [])
    ~input ~output () =
  {
    name;
    path;
    docstring;
    shape = Post { url_params; query_params; input; output };
  }

let delete ~name ~path ?(docstring = "") ?(url_params = []) ~output () =
  { name; path; docstring; shape = Delete { url_params; output } }
