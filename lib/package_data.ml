let src = Logs.Src.create "package_data"

module Log = (val Logs.src_log src : Logs.LOG)

type t =
  { nixpkg : string
  ; pname : string
  ; curr_version : string
  ; next_version : string
  ; update_page : string
  }

let pp ppf t =
  Format.fprintf
    ppf
    "ocamlPackages.%s %s %s %s"
    t.nixpkg
    t.curr_version
    t.next_version
    t.update_page

let get nixpkgs_path opam_path nixpkg opampkg =
  let open Lwt.Syntax in
  let+ curr_version = Nixpkgs.get_version nixpkgs_path nixpkg in
  let pname = opampkg in
  Log.debug (fun m -> m "get: %s - %s" nixpkg pname);
  let next_version = Opam.get_version opam_path pname in
  let update_page = Printf.sprintf "https://opam.ocaml.org/packages/%s/%s.%s" pname pname next_version in
  { nixpkg; pname; curr_version; next_version; update_page }

let filter ts =
  List.filter
    (fun t -> OpamVersionCompare.compare t.curr_version t.next_version <> 0)
    ts
