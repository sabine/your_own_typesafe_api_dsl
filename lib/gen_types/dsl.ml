include Ast

module TypeName = struct
  let of_string name = TypeName name

  let to_string name =
    match name with
    | TypeName name -> name
    | _ -> failwith "TypeName.to_string takes a TypeName _"
end

let field name t = { field_name = name; field_t = t }
let record_union_variant name fields = { record_name = name; fields }
let str = PrimitiveType Str
let i63 = PrimitiveType I63
let float = PrimitiveType Float
let bool = PrimitiveType Bool
let unit = PrimitiveType Unit
let nullable t = Nullable t
let array t = Array t
let map k t = Map { key_t = k; value_t = t }

let alias name t =
  match name with
  | TypeName name -> TypeAlias { name; t }
  | _ -> failwith "name on type alias must by a PrimitiveType (TypeName _)"

let record name fields = Record { record_name = name; fields }
let string_enum name options = StringEnum { name; options }
let int_enum name options = IntEnum { name; options }
let record_union name variants = RecordUnion { name; variants }
