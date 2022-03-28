(* Code in this file is borrowed from or heavily inspired by code provided in
   slack by https://github.com/dra27 *)

let src = Logs.Src.create "opam"

module Log = (val Logs.src_log src : Logs.LOG)

let latest_packages = ref OpamPackage.Name.Map.empty
let packages = ref OpamPackage.Set.empty

let clear_cache () =
  latest_packages := OpamPackage.Name.Map.empty;
  packages := OpamPackage.Set.empty

let get_packages_in repository_root =
  if OpamPackage.Set.is_empty !packages
  then (
    packages :=
      OpamRepository.packages (OpamFilename.Dir.of_string repository_root);
    !packages)
  else !packages

let filter_latest packages =
  if OpamPackage.Name.Map.is_empty !latest_packages
  then (
    let f package latest =
      let open OpamPackage in
      try
        if OpamPackage.Version.compare
             package.version
             (OpamPackage.Name.Map.find package.name latest).version
           > 0
        then OpamPackage.Name.Map.add package.name package latest
        else latest
      with
      | Not_found -> OpamPackage.Name.Map.add package.name package latest
    in
    latest_packages :=
      OpamPackage.Set.fold f packages OpamPackage.Name.Map.empty;
    !latest_packages)
  else !latest_packages

let get_version repo_root name =
  try
    Log.debug (fun m -> m "get_version: %s" name);
    let packages = get_packages_in repo_root in
    let latest_versions = filter_latest packages in
    let package =
      List.find
        (fun (pkg : OpamPackage.t) ->
          let opam_name = pkg.name |> OpamPackage.Name.to_string in
          opam_name = name)
        (OpamPackage.Name.Map.values latest_versions)
    in
    package.version |> OpamPackage.Version.to_string
  with
  | _ ->
    Log.err (fun m ->
        m "get_version for %s failed, returning 0.0.0 as version" name);
    "0.0.0"

let prepare_repo opam_repo_path =
  Git.clone_or_pull
    "https://github.com/ocaml/opam-repository.git"
    opam_repo_path
