let make_request ~meth ?body path =
  Unix.sleepf 0.2;
  match
    Curly.(
      run
        (Request.make
           ~headers:[ ("X-Access-Token", "TESTING_API_KEY") ]
           ~url:("http://localhost:8080" ^ path)
           ?body ~meth ()))
  with
  | Ok x ->
      Format.printf "status: %d\n" x.Curly.Response.code;

      Format.printf "headers: %a\n" Curly.Header.pp x.Curly.Response.headers;
      Format.printf "body: %s\n" x.Curly.Response.body
  | Error e ->
      Format.printf "Failed: %s" (Format.asprintf "%a" Curly.Error.pp e)

let main () =
  Unix.sleep 2;

  make_request ~meth:`POST "/users"
    ~body:{|{ "display_name": "sabine", "user_id": "sabine" }|};

  make_request ~meth:`POST "/users"
    ~body:{|{ "display_name": "test", "user_id": "test" }|};

  make_request ~meth:`POST "/users"
    ~body:{|{ "display_name": "sabine", "user_id": "sabine" }|};
  make_request ~meth:`GET "/user/sabine";
  make_request ~meth:`GET "/user/abc";
  make_request ~meth:`GET "/users";
  make_request ~meth:`DELETE "/user/sabine";

  (* make_request ~meth:`GET "/user/sabine";
     make_request ~meth:`DELETE "/user/sabine";*)
  ()

let () =
  match Unix.fork () with
  | 0 ->
      (* Child process *)
      Unix.execv "../app/main.exe" [||]
  | pid ->
      (* Parent process *)
      main ();

      Unix.kill pid Sys.sigterm
