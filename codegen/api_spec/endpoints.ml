open T

let endpoints =
  Gen_endpoints.Types.
    [
      post ~name:"create_user" ~path:"/users"
        ~input_type:[ field "display_name" str; field "user_id" T.user_id ]
          (* ~input_type:([
             field "display_name" str;
             field "user_id" T.user_id;
             field "recruited_by" T.user_id; ]) *)
        ~output_type:[ field "user_id" T.user_id ]
        ();
      get ~name:"users" ~path:"/users"
        ~query_params:
          QueryParams.
            [
              field "name" Str;
              field "next" Int;
              field "prev" Int;
              field "limit" Int;
            ]
        ~output_type:[ field "users" Ot.paginated_users ]
        ();
      {
        name = "get_user";
        url = "/user/{user_id}";
        docstring = "get user by id";
        shape =
          Get
            {
              url_params = Some [ { name = "user_id"; t = T.user_id } ];
              query_param_type = None;
              output_type = Fields [ field "user" Ot.user ];
            };
      };
      {
        name = "delete_user";
        url = "/user/{user_id}";
        docstring = "delete user by id";
        shape =
          Delete
            {
              url_params = Some [ { name = "user_id"; t = T.user_id } ];
              output_type = None;
              error_type = None;
            };
      };
      {
        name = "create_conversation";
        url = "/converations";
        docstring = "create a new conversation";
        shape =
          Post
            {
              url_params = None;
              input_type =
                Fields [ field "user_ids" (vec T.user_id); field "data" str ];
              query_param_type = Fields QueryParams.[ field "user" Str ];
              output_type = Fields [ field "conversation_id" T.conversation_id ];
              error_type = None;
            };
      };
      {
        name = "update_conversation";
        url = "/converation/{conversation_id}";
        docstring = "update data on a conversation";
        shape =
          Post
            {
              url_params =
                Some [ { name = "conversation_id"; t = T.conversation_id } ];
              input_type = Fields [ field "data" str ];
              query_param_type = None;
              output_type = None;
              error_type = None;
            };
      };
      {
        name = "add_users_to_conversation";
        url = "/converation/{conversation_id}/add-users";
        docstring = "add users to an existing conversation";
        shape =
          Post
            {
              url_params =
                Some [ { name = "conversation_id"; t = T.conversation_id } ];
              input_type = Fields [ field "user_ids" (vec T.user_id) ];
              query_param_type = None;
              output_type = None;
              error_type = None;
            };
      };
      {
        name = "remove_users_from_conversation";
        url = "/converation/{conversation_id}/remove-users";
        docstring = "remove users from a conversation";
        shape =
          Post
            {
              url_params =
                Some [ { name = "conversation_id"; t = T.conversation_id } ];
              input_type = Fields [ field "user_ids" (vec T.user_id) ];
              query_param_type = None;
              output_type = None;
              error_type = None;
            };
      };
    ]
