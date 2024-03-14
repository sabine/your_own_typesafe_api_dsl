let rec message_loop () =
  let%lwt () = Lwt_unix.sleep (2. +. Random.float 2.) in

  let _ =
    Api.Server_sent_events.broadcast_message
    @@ Api.Generated_types.ConversationEvent.ConversationEventNewLine
         {
           line =
             {
               line_id = "TODO";
               timestamp = "TODO";
               from = UserMember { user_id = "TODO"; display_name = "TODO" };
               message = "TODO";
               data = "";
               reply_to_line = None;
             };
         }
  in

  message_loop ()

let () =
  let routes =
    [
      Dream.scope ""
        [ Api.Auth.check_server_api_key ~api_key:"TESTING_API_KEY" ]
        Api.Generated_endpoints.routes;
      Dream.get "/push" (fun _ ->
          Dream.stream
            ~headers:[ ("Content-Type", "text/event-stream") ]
            Api.Server_sent_events.forward_messages);
    ]
  in

  Lwt.async message_loop;

  Dream.run @@ Dream.logger
  @@ Dream.router ([ Dream.get "/" (fun _ -> Dream.html Home.render) ] @ routes)
