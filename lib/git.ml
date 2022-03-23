let clone ?(depth = 3000) repo target =
  Lwt_process.exec
    ("git", [| "git"; "clone"; "--depth=" ^ string_of_int depth; repo; target |])

let pull cwd = Lwt_process.exec ~cwd ("git", [| "git"; "pull" |])

let clone_or_pull ?depth repo target =
  try
    if Sys.is_directory target then pull target else clone ?depth repo target
  with
  | _ -> clone ?depth repo target
