let src = Logs.Src.create "nixpkgs"

module Log = (val Logs.src_log src : Logs.LOG)

let get_version nixpkgs_path name =
  Log.debug (fun m -> m "get_version: %s" name);
  let open Lwt.Infix in
  Lwt_process.pread_line
    ~cwd:nixpkgs_path
    ( "nix"
    , [| "nix"; "eval"; "-f"; "./"; "ocamlPackages." ^ name ^ ".version" |] )
  >|= Astring.String.trim ~drop:(fun c -> c = '"')

let get_name nixpkgs_path name =
  Log.debug (fun m -> m "get_name: %s" name);
  let open Lwt.Syntax in
  let+ raw_pname =
    Lwt_process.pread_line
      ~cwd:nixpkgs_path
      ( "nix"
      , [| "nix"; "eval"; "-f"; "./"; "ocamlPackages." ^ name ^ ".pname" |] )
  in
  let pname = Astring.String.trim ~drop:(fun c -> c = '"') raw_pname in
  match Astring.String.cut ~sep:"-" ~rev:true pname with
  | Some (_, pname) -> pname
  | None -> pname

let prepare_repo nixpkgs_repo_path =
  Git.clone_or_pull "https://github.com/NixOS/nixpkgs.git" nixpkgs_repo_path
