let tmp_path = "/tmp/ocaml-nix-updater"

let setup_log ?style_renderer level =
  let pp_header src ppf (l, h) =
    if l = Logs.App
    then Format.fprintf ppf "%a" Logs_fmt.pp_header (l, h)
    else
      let x =
        match Array.length Sys.argv with
        | 0 -> Filename.basename Sys.executable_name
        | _n -> Filename.basename Sys.argv.(0)
      in
      let x =
        if Logs.Src.equal src Logs.default then x else Logs.Src.name src
      in
      Format.fprintf ppf "%s: %a " x Logs_fmt.pp_header (l, h)
  in
  let format_reporter =
    let report src =
      let { Logs.report } = Logs_fmt.reporter ~pp_header:(pp_header src) () in
      report src
    in
    { Logs.report }
  in
  Fmt_tty.setup_std_outputs ?style_renderer ();
  Logs.set_level (Some level);
  Logs.set_reporter format_reporter

let error_handler _client_addr ?request:_ ~respond _err =
  let error_handler =
    respond
      ~headers:(Piaf.Headers.of_list [ "connection", "close" ])
      (Piaf.Body.of_string "error")
  in
  Lwt.return error_handler

let packages =
  Ocaml_nix_updater.Package_list.read "./packages_to_update.txt" |> Lwt_main.run

let packages_data ~opam_repo_path ~nixpkgs_repo_path =
  Lazy.from_fun (fun () ->
      let open Lwt.Infix in
      List.map
        (fun (nixpkg, opampkg) ->
          Ocaml_nix_updater.Package_data.get
            nixpkgs_repo_path
            opam_repo_path
            nixpkg
            opampkg)
        packages
      |> Lwt.all
      >|= Ocaml_nix_updater.Package_data.filter)

let request_handler
    ~opam_repo_path
    ~nixpkgs_repo_path
    ({ request; _ } : Unix.sockaddr Piaf.Server.ctx)
  =
  match request.meth with
  | `GET ->
    let open Lwt.Syntax in
    let* _ =
      [ Ocaml_nix_updater.Opam.prepare_repo opam_repo_path
      ; Ocaml_nix_updater.Nixpkgs.prepare_repo nixpkgs_repo_path
      ]
      |> Lwt.all
    in
    let+ package_datas =
      Lazy.force @@ packages_data ~opam_repo_path ~nixpkgs_repo_path
    in
    let body =
      List.map
        (Format.asprintf "%a" Ocaml_nix_updater.Package_data.pp)
        package_datas
      |> String.concat "\n"
    in
    let () = Ocaml_nix_updater.Opam.clear_cache () in
    Piaf.Response.of_string ~body `OK
  | _ -> assert false

open Lwt.Infix

let main port ~opam_repo_path ~nixpkgs_repo_path =
  let listen_address = Unix.(ADDR_INET (inet_addr_loopback, port)) in
  Lwt.async (fun () ->
      Lwt_io.establish_server_with_client_socket
        listen_address
        (Piaf.Server.create
           ?config:None
           ~error_handler
           (request_handler ~opam_repo_path ~nixpkgs_repo_path))
      >|= fun _server ->
      Printf.printf "Listening on port %i and echoing POST requests.\n%!" port);
  let forever, _ = Lwt.wait () in
  Lwt_main.run forever

let _clean_tmp () =
  let _ =
    Lwt_process.exec ("rm", [| "rm"; "-rf"; tmp_path |]) |> Lwt_main.run
  in
  ()

let () =
  setup_log Info;
  Sys.(
    set_signal
      sigpipe
      (Signal_handle (fun _ -> Format.eprintf "handle sigpipe@.")));
  let port = ref 8080 in
  let cwd = ref tmp_path in

  Arg.parse
    [ "-p", Arg.Set_int port, " Listening port number (8080 by default)"
    ; ( "-c"
      , Arg.Set_string cwd
      , " Directory to clone data into (/tmp/ocaml-nix-updater by default)" )
    ]
    ignore
    "Creates a list of packages that needs to be updated.";

  let opam_repo_path = !cwd ^ "/opam" in
  let nixpkgs_repo_path = !cwd ^ "/nixpkgs" in

  let _ =
    [ Ocaml_nix_updater.Opam.prepare_repo opam_repo_path
    ; Ocaml_nix_updater.Nixpkgs.prepare_repo nixpkgs_repo_path
    ]
    |> Lwt.all
    |> Lwt_main.run
  in
  main !port ~opam_repo_path ~nixpkgs_repo_path
