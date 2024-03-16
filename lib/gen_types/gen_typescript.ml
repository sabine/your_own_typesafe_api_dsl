let rec render_type (t : Ast.t) ~type_namespace =
  match t with
  | PrimitiveType Str -> "string"
  | PrimitiveType I63 -> "number"
  | PrimitiveType Float -> "number"
  | PrimitiveType Bool -> "boolean"
  | PrimitiveType Unit -> "{}"
  | TypeName n -> type_namespace ^ n
  | Array t -> Format.sprintf "%s[]" (render_type t ~type_namespace)
  | Nullable t -> Format.sprintf "%s | null" (render_type t ~type_namespace)
  | Map { key_t; value_t } -> (
      match value_t with
      | Nullable _ ->
          Format.sprintf "{[key: %s]: %s | null}"
            (render_type key_t ~type_namespace)
            (render_type value_t ~type_namespace)
      | _ ->
          Format.sprintf "{[key: %s]: %s}"
            (render_type key_t ~type_namespace)
            (render_type value_t ~type_namespace))

let render_struct_field (f : Ast.field) =
  match f.field_t with
  | Nullable t ->
      Format.sprintf "%s: %s | null" f.field_name
        (render_type t ~type_namespace:"")
  | _ ->
      Format.sprintf "%s: %s" f.field_name
        (render_type f.field_t ~type_namespace:"")

let gen_record_union_variant ~prefix (s : Ast.record) =
  Format.sprintf "export type %s = [\"%s\", {\n    %s\n}]"
    (prefix ^ s.record_name)
    (Names.to_pascal_case s.record_name)
    (String.concat ",\n    " (List.map render_struct_field s.fields))

let gen_record (s : Ast.record) =
  Format.sprintf "export type %s = {\n    %s\n}"
    (Names.to_pascal_case s.record_name)
    (String.concat ",\n    " (List.map render_struct_field s.fields))

let gen_type_declaration (decl : Ast.type_declaration) ~type_namespace =
  match decl with
  | TypeAlias { name; t } ->
      Format.sprintf "export type %s = %s"
        (Names.to_pascal_case name)
        (render_type t ~type_namespace)
  | RecordUnion { name; variants } ->
      let variant_names =
        List.map
          (fun (variant : Ast.record) -> name ^ variant.record_name)
          variants
      in
      let variant_declarations =
        List.map (gen_record_union_variant ~prefix:name) variants
      in
      Format.sprintf "export type %s = %s\n\n%s"
        (Names.to_pascal_case name)
        (String.concat " | " variant_names)
        (String.concat "\n\n" variant_declarations)
  | Record s -> gen_record s
  | StringEnum { name; options } ->
      Format.sprintf "export enum %s {\n    %s\n}"
        (Names.to_pascal_case name ^ "Choices")
        (String.concat ",\n    "
           (List.map (fun o -> Format.sprintf "%s = \"%s\"" o o) options))
  | IntEnum { name; options } ->
      Format.sprintf "export enum %s {\n    %s\n}"
        (Names.to_pascal_case name ^ "Choices")
        (String.concat ",\n    "
           (List.map (fun (o, i) -> Format.sprintf "%s = %d" o i) options))
