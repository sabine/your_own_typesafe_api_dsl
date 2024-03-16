type primitive_type = Str | I63 | Bool | Float | Unit

type t =
  | TypeName of string
  | PrimitiveType of primitive_type
  | Nullable of t
  | Array of t
  | Map of { key_t : t; value_t : t }

type field = { field_name : string; field_t : t }
type record = { record_name : string; fields : field list }

type type_declaration =
  | TypeAlias of { name : string; t : t }
  | Record of record
  | StringEnum of { name : string; options : string list }
  | IntEnum of { name : string; options : (string * int) list }
  | RecordUnion of { name : string; variants : record list }
