let rec render_type (t : Ast.t) ~type_namespace =
  match t with
  | PrimitiveType Str -> "String"
  | PrimitiveType I63 -> "63-bit Integer"
  | PrimitiveType Float -> "64-bit Float"
  | PrimitiveType Bool -> "Boolean"
  | PrimitiveType Unit -> "Unit"
  | TypeName n ->
      Format.sprintf "[%s](#%s)" (Names.to_pascal_case n)
        (type_namespace ^ Names.to_pascal_case n)
  | Array t -> Format.sprintf "Array of (%s)" (render_type t ~type_namespace)
  | Nullable t -> Format.sprintf "Nullable (%s)" (render_type t ~type_namespace)
  | Map { key_t = _; value_t = _ } -> failwith "not implemented"

let render_struct_field (f : Ast.field) =
  Format.sprintf "|%s|%s|" f.field_name
    (render_type f.field_t ~type_namespace:"")

let deriving = function
  | [] -> ""
  | ppxes -> Format.sprintf " [@@@@deriving %s]" (String.concat ", " ppxes)

let linkable_anchor name = Format.sprintf "<a name=\"%s\">%s</a>" name name

let gen_type_documentation (decl : Ast.type_declaration) ~type_namespace =
  match decl with
  | Ast.TypeAlias { name; t } ->
      Format.sprintf "## %s\n\n  is an alias for %s"
        (linkable_anchor (Names.to_pascal_case name))
        (render_type t ~type_namespace)
  | RecordUnion { name; variants } ->
      let gen_variant ~prefix (s : Ast.record) =
        Format.sprintf "* `%s`\n\n%s\n" (prefix ^ s.record_name)
          (String.concat "\n"
             ([ "|field_name|type|"; "|-|-|" ]
             @ List.map render_struct_field s.fields))
      in
      let variants =
        List.map
          (fun (variant : Ast.record) -> gen_variant ~prefix:name variant)
          variants
      in
      Format.sprintf "## %s\n\n  is one of these variants:\n\n%s"
        (linkable_anchor (Names.to_pascal_case name))
        (String.concat "\n" variants)
  | Record s ->
      Format.sprintf "## %s\n\nis a struct with these fields:\n%s"
        (linkable_anchor (Names.to_pascal_case s.record_name))
        (String.concat "\n"
           ([ "|name|type|"; "|-|-|" ] @ List.map render_struct_field s.fields))
  | StringEnum { name; options } ->
      Format.sprintf "## %s\n\nis a string enum with these options:\n%s"
        (linkable_anchor (Names.to_pascal_case name))
        (String.concat "\n"
           ([ "|option|"; "|-|" ]
           @ List.map (fun o -> Format.sprintf "|%s|" o) options))
  | IntEnum { name = _; options = _ } -> failwith "not implemented"
