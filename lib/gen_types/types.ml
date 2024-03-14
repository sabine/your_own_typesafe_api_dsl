type primitive_type = Str | I63 | Bool | Json | F32 | F64 | Unit

type t =
  | TypeName of string
  | PrimitiveType of primitive_type
  | Nullable of t
  | Option of t
  | Vec of t
  | Map of { key_t : t; value_t : t }

type field = { field_name : string; field_t : t }
type struct_ = { struct_name : string; fields : field list }

type type_declaration =
  | TypeAlias of { name : string; t : t }
  | Struct of struct_
  | StringEnum of { name : string; options : string list }
  | IntEnum of { name : string; options : (string * int) list }
  | StructUnion of { name : string; variants : struct_ list }

let alias name t =
  match name with
  | TypeName name -> TypeAlias { name; t }
  | _ -> failwith "name on type alias must by a PrimitiveType (TypeName _)"

let struct_ name fields = Struct { struct_name = name; fields }
let string_enum name options = StringEnum { name; options }
let int_enum name options = IntEnum { name; options }
let struct_union name variants = StructUnion { name; variants }

module TypeDeclarations = struct
  let t name = TypeName name

  let u name =
    match name with
    | TypeName name -> name
    | _ -> failwith "u takes a TypeName _"

  let field name t = { field_name = name; field_t = t }
  let struct_union_variant name fields = { struct_name = name; fields }
  let str = PrimitiveType Str
  let i63 = PrimitiveType I63
  let f32 = PrimitiveType F32
  let f64 = PrimitiveType F64
  let bool = PrimitiveType Bool
  let unit = PrimitiveType Unit
  let nullable t = Nullable t
  let option t = Option t
  let vec t = Vec t
  let map k t = Map { key_t = k; value_t = t }
end

include TypeDeclarations
