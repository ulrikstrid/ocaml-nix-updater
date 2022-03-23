let src = Logs.Src.create "git"

module Log = (val Logs.src_log src : Logs.LOG)

let clone ?(depth = 3000) repo target =
  Log.info (fun m -> m "Cloning %s into %s" repo target);

  Lwt_process.pread_lines
    ~stderr:(`FD_copy Unix.stdout)
    ("git", [| "git"; "clone"; "--depth=" ^ string_of_int depth; repo; target |])
  |> Lwt_stream.iter (fun str -> Log.info (fun m -> m "%s" str))

let pull cwd =
  Lwt_process.pread_lines
    ~stderr:(`FD_copy Unix.stdout)
    ~cwd
    ("git", [| "git"; "pull" |])
  |> Lwt_stream.iter (fun str -> Log.info (fun m -> m "%s" str))

let clone_or_pull ?depth repo target =
  try
    if Sys.is_directory target then pull target else clone ?depth repo target
  with
  | _ -> clone ?depth repo target
