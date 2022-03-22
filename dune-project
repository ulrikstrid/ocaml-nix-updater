(lang dune 3.1)

(name ocaml_nix_updater)

(generate_opam_files true)

(source
 (github ulrikstrid/ocaml-nix-updater))

(authors "Ulrik Strid")

(maintainers "Ulrik Strid")

(license BSD3)

(documentation https://url/to/documentation)

(package
 (name ocaml_nix_updater)
 (synopsis "A short synopsis")
 (description "A longer description")
 (depends ocaml dune)
 (tags
  (topics "to describe" your project)))

; See the complete stanza docs at https://dune.readthedocs.io/en/stable/dune-files.html#dune-project
