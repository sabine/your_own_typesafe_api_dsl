let rec render_type (t : Types.t) ~type_namespace =
  match t with
  | PrimitiveType Str -> "string"
  | PrimitiveType I63 -> "int"
  | PrimitiveType F32 -> "Float32.t"
  | PrimitiveType F64 -> "Float64.t"
  | PrimitiveType Bool -> "bool"
  | PrimitiveType Unit -> "unit"
  | PrimitiveType Json -> failwith "not implemented"
  | TypeName n -> type_namespace ^ Names.to_pascal_case n ^ ".t"
  | Vec t -> Format.sprintf "(%s) list" (render_type t ~type_namespace)
  | Option t -> Format.sprintf "(%s) option" (render_type t ~type_namespace)
  | Nullable t -> Format.sprintf "(%s) option" (render_type t ~type_namespace)
  | Map { key_t = _; value_t = _ } -> failwith "not implemented"

let render_struct_field (f : Types.field) =
  Format.sprintf "%s: %s" f.field_name
    (render_type f.field_t ~type_namespace:"")

let deriving = function
  | [] -> ""
  | ppxes -> Format.sprintf " [@@@@deriving %s]" (String.concat ", " ppxes)

let gen_variant_constructor ~prefix (s : Types.struct_) =
  Format.sprintf "%s of %s \n" (prefix ^ s.struct_name)
    (Names.to_snake_case (prefix ^ s.struct_name))

let gen_variant_type ~prefix ~ppxes (s : Types.struct_) =
  Format.sprintf "type %s = {\n  %s\n} %s \n"
    (Names.to_snake_case (prefix ^ s.struct_name))
    (String.concat ";\n  " (List.map render_struct_field s.fields))
    (deriving ppxes)

let gen_type_declaration (decl : Types.type_declaration) ~type_namespace ~ppxes
    =
  match decl with
  | TypeAlias { name; t } ->
      Format.sprintf {|module %s = struct
  type t = %s%s
end|}
        (Names.to_pascal_case name)
        (render_type t ~type_namespace)
        (deriving ppxes)
  | StructUnion { name; variants } ->
      let variant_constructors =
        List.map
          (fun (variant : Types.struct_) ->
            gen_variant_constructor ~prefix:name variant)
          variants
      in
      let variant_types =
        List.map
          (fun (variant : Types.struct_) ->
            gen_variant_type ~prefix:name variant ~ppxes)
          variants
      in
      let yojson_of_fun = "TODO: yojson_of" in
      let of_yojson_fun = "TODO: of_yojson" in
      let variant_decoder =
        match
          ( List.mem "yojson" ppxes,
            List.mem "yojson_of" ppxes,
            List.mem "of_yojson" ppxes )
        with
        | true, _, _ -> of_yojson_fun ^ "\n" ^ yojson_of_fun
        | false, true, _ -> yojson_of_fun
        | false, false, true -> of_yojson_fun
        | _, _, _ -> ""
      in
      Format.sprintf "module %s = struct\n  %stype t =\n    | %s\n  %s\nend"
        (Names.to_pascal_case name)
        (String.concat "\n    " variant_types)
        (String.concat "\n    | " variant_constructors)
        variant_decoder
  | Struct s ->
      Format.sprintf "module %s = struct\n  type t = {\n    %s\n}%s\nend"
        (Names.to_pascal_case s.struct_name)
        (String.concat ";\n    " (List.map render_struct_field s.fields))
        (deriving ppxes)
  | StringEnum { name; options } ->
      Format.sprintf "module %s = struct\n  type t = %s%s\nend"
        (Names.to_pascal_case name)
        (String.concat "   | " options)
        (deriving ppxes)
  | IntEnum { name = _; options = _ } -> failwith "not implemented"
