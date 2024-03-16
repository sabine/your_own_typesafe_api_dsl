open T

let endpoints =
  Gen_endpoints.Dsl.
    [
      post ~name:"create_user"
        ~path:"/users"
          (* ~input:[ field "display_name" str; field "user_id" T.user_id ] *)
        ~input:
          [
            field "display_name" str;
            field "user_id" T.user_id;
            field "recruited_by" T.user_id;
          ]
        ~output:[ field "user_id" T.user_id ]
        ();
      get ~name:"users" ~path:"/users"
        ~query_params:
          Gen_endpoints.Ast.QueryParams.
            [
              field "name" Str;
              field "next" Int;
              field "prev" Int;
              field "limit" Int;
            ]
        ~output:[ field "users" Ot.paginated_users ]
        ();
      get ~name:"get_user" ~path:"/user/{user_id}" ~docstring:"get user by id"
        ~url_params:[ param "user_id" T.user_id ]
        ~output:[ field "user" Ot.user ]
        ();
      delete ~name:"delete_user" ~path:"/user/{user_id}"
        ~docstring:"delete user by id"
        ~url_params:[ param "user_id" T.user_id ]
        ~output:[] ();
      post ~name:"create_conversation" ~path:"/converations"
        ~docstring:"create a new conversation"
        ~input:[ field "user_ids" (array T.user_id); field "data" str ]
        ~output:[ field "conversation_id" T.conversation_id ]
        ();
      post ~name:"update_conversation" ~path:"/converation/{conversation_id}"
        ~docstring:"update data on a conversation"
        ~url_params:[ { name = "conversation_id"; t = T.conversation_id } ]
        ~input:[ field "data" str ]
        ~output:[] ();
      post ~name:"add_users_to_conversation"
        ~path:"/converation/{conversation_id}/add-users"
        ~docstring:"add users to an existing conversation"
        ~url_params:[ param "conversation_id" T.conversation_id ]
        ~input:[ field "user_ids" (array T.user_id) ]
        ~output:[] ();
      post ~name:"remove_users_from_conversation"
        ~path:"/converation/{conversation_id}/remove-users"
        ~docstring:"remove users from a conversation"
        ~url_params:[ { name = "conversation_id"; t = T.conversation_id } ]
        ~input:[ field "user_ids" (array T.user_id) ]
        ~output:[] ();
    ]
