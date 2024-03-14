open T

let endpoints =
  Gen_endpoints.Types.
    [
      {
        name = "create_user";
        url = "/users";
        docstring = "create a new user";
        shape =
          Post
            {
              url_params = None;
              input_type =
                Fields [ field "display_name" str; field "user_id" str ];
              query_param_type = None;
              output_type = Fields [ field "user_id" T.user_id ];
              error_type = None;
            };
      };
      {
        name = "users";
        url = "/users";
        docstring = "list users";
        shape =
          Get
            {
              url_params = None;
              query_param_type =
                Fields
                  QueryParams.
                    [
                      field "name" Str;
                      field "next" Int;
                      field "prev" Int;
                      field "limit" Int;
                    ];
              output_type = Fields [ field "users" Ot.paginated_users ];
            };
      };
      {
        name = "get_user";
        url = "/user/{user_id}";
        docstring = "get user by id";
        shape =
          Get
            {
              url_params = Some [ { name = "user_id"; t = T.user_id } ];
              query_param_type = None;
              output_type = Fields [ field "user" T.user ];
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
              query_param_type = None;
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
