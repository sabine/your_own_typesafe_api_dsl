open T

let paginate name obj_t cursor_t =
  Gen_endpoints.Dsl.(
    record (TypeName.to_string name)
      [
        field "next" (nullable cursor_t);
        field "prev" (nullable cursor_t);
        field "objs" (array obj_t);
      ])

let t =
  Gen_endpoints.Dsl.
    [
      id_type (TypeName.to_string T.user_id);
      id_type (TypeName.to_string T.conversation_id);
      id_type (TypeName.to_string T.line_id);
      alias T.date_time str;
    ]

let it = []

let ot =
  Gen_endpoints.Dsl.
    [
      record
        (TypeName.to_string Ot.user)
        [ field "display_name" str; field "user_id" T.user_id ];
      paginate Ot.paginated_users Ot.user T.user_id;
      record
        (TypeName.to_string Ot.parent_line)
        [
          field "line_id" T.line_id;
          field "timestamp" T.date_time;
          field "from" Ot.user;
          field "message" str;
          field "data" str;
          (* JSON *)
        ];
      record
        (TypeName.to_string Ot.line)
        [
          field "line_id" T.line_id;
          field "timestamp" T.date_time;
          field "from" Ot.user;
          field "message" str;
          field "data" str;
          (* JSON *)
          field "reply_to_line" (nullable T.line_id);
        ];
      record
        (TypeName.to_string Ot.thread)
        [ field "line" Ot.line; field "replies" (array Ot.line) ];
      record_union
        (TypeName.to_string Ot.conversation_event)
        [
          record_union_variant "NewLine" [ field "line" Ot.line ];
          record_union_variant "Join"
            [ field "timestamp" T.date_time; field "from" Ot.user ];
          record_union_variant "Leave"
            [ field "timestamp" T.date_time; field "from" Ot.user ];
          record_union_variant "StartTyping"
            [ field "timestamp" T.date_time; field "from" Ot.user ];
          record_union_variant "EndTyping"
            [ field "timestamp" T.date_time; field "from" Ot.user ];
        ];
      record
        (TypeName.to_string Ot.conversation)
        [
          field "conversation_id" T.conversation_id;
          field "timestamp" T.date_time;
          field "number_of_unread_messages" i63;
          field "newest_line" (nullable Ot.line);
        ];
      paginate Ot.paginated_conversations Ot.conversation T.conversation_id;
    ]
