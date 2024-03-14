let check_server_api_key ~api_key : Dream.middleware =
 fun h req ->
  let key = Dream.header req "X-Access-Token" in
  match key with
  | Some key ->
      if key = api_key then h req
      else Lwt.return (Dream.response ~code:403 "API key is invalid")
  | None ->
      Lwt.return
        (Dream.response ~code:400 "API key in X-Access-Token is missing")
