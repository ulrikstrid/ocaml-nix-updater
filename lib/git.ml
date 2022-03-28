let src = Logs.Src.create "git"

module Log = (val Logs.src_log src : Logs.LOG)

let clone ?(depth = 3000) repo target =
  Log.info (fun m -> m "Cloning %s into %s" repo target);

  Lwt_process.pread_lines
    ("git", [| "git"; "clone"; "--depth=" ^ string_of_int depth; repo; target |])
  |> Lwt_stream.iter (fun str -> Log.info (fun m -> m "%s" str))

let pull cwd =
  Lwt_process.pread_lines ~cwd ("git", [| "git"; "pull" |])
  |> Lwt_stream.iter (fun str -> Log.info (fun m -> m "%s" str))

let clean cwd =
  Lwt_process.pread_lines ~cwd ("git", [| "git"; "clean"; "-f"; "-d" |])
  |> Lwt_stream.iter (fun str -> Log.info (fun m -> m "%s" str))

let restore cwd =
  Lwt_process.pread_lines ~cwd ("git", [| "git"; "restore"; "*" |])
  |> Lwt_stream.iter (fun str -> Log.info (fun m -> m "%s" str))

let clone_or_pull ?depth repo target =
  let open Lwt.Syntax in
  try
    if Sys.is_directory target
    then
      let* () = clean target in
      let* () = restore target in
      pull target
    else clone ?depth repo target
  with
  | _ -> clone ?depth repo target
