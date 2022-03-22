let read path =
  let channel = Lwt_io.open_file ~mode:Lwt_io.Input path in
  let stream =
    Lwt.map
      (fun c ->
        Lwt_io.read_lines c
        |> Lwt_stream.map (String.split_on_char ',')
        |> Lwt_stream.map (function
               | [ nixpkg; opam ] -> nixpkg, opam
               | _ -> assert false))
      channel
  in
  Lwt.bind stream Lwt_stream.to_list
