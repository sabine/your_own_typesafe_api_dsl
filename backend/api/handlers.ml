let bad_request msg =
  Dream.json ~code:400 (Format.sprintf "{ \"message\": \"%s\" }" msg)

let not_found = Dream.json ~code:404 "{ \"message\": \"Not found\" }"

let internal_error msg =
  Dream.json ~code:500 (Format.sprintf "{ \"message\": \"%s\" }" msg)

module Server = struct
  module T = Generated_types

  let bad_request = bad_request
  let internal_error = internal_error

  module User = struct
    type t = { user_id : string; display_name : string }

    let compare u1 u2 = String.compare u1.user_id u2.user_id
  end

  module UsersSet = Set.Make (User)

  let users_state = ref UsersSet.empty

  let create_user _req ({ user_id; display_name } : T.CreateUserInput.t) =
    let new_user = User.{ user_id; display_name } in
    (* let _ = recruited_by in *)
    match UsersSet.find_opt new_user !users_state with
    | Some _ ->
        Lwt.return
          (Error (bad_request ("User '" ^ user_id ^ "' already exists!")))
    | None ->
        users_state := UsersSet.add new_user !users_state;
        Lwt.return (Ok T.CreateUserOutput.{ user_id })

  let get_user _req user_id =
    let maybe_user =
      UsersSet.find_first_opt (fun u -> u.user_id = user_id) !users_state
    in
    match maybe_user with
    | None -> Lwt.return (Error not_found)
    | Some user ->
        Lwt.return
          (Ok
             T.GetUserOutput.
               {
                 user =
                   { user_id = user.user_id; display_name = user.display_name };
               })

  let users _req (_query : T.UsersQuery.t) =
    let users =
      UsersSet.to_list !users_state
      |> List.map (fun User.{ user_id; display_name } ->
             T.User.{ user_id; display_name })
    in

    Lwt.return
      (Ok T.UsersOutput.{ users = { objs = users; next = None; prev = None } })

  let delete_user _req user_id =
    let maybe_user =
      UsersSet.find_first_opt (fun u -> u.user_id = user_id) !users_state
    in
    match maybe_user with
    | None -> Lwt.return (Error not_found)
    | Some user ->
        users_state := UsersSet.remove user !users_state;
        Lwt.return (Ok ())

  let create_conversation _req _query (_body : T.CreateConversationInput.t) =
    failwith "not_implemented"
  (*Lwt.return T.CreateConversationOutput.{ conversation_id }*)

  let update_conversation _req _conversation_id _body =
    failwith "not_implemented"

  let add_users_to_conversation _req _conversation_id _body =
    failwith "not_implemented"

  let remove_users_from_conversation _req _conversation_id _body =
    failwith "not_implemented"
end
