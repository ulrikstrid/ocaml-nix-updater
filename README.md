# OCaml nix-updater list

Generates a list for [nixpkgs-update](https://github.com/ryantm/nixpkgs-update) to do batch update of ocaml packages that are in the [OPAM repository](https://opam.ocaml.org).

## How it works

We're reading the [packages_to_update.txt](./packages_to_update.txt) file as a list of packages, where the first string is the name in [nixpkgs](https://github.com/nixos/nixpkgs) after `ocamlPackages` (example: `ocamlPackages.ansiterminal`) and the second is the name in the opam repository (example: `ANSITerminal`).

We then query a local clone of the nixpkgs repo for the current version (note that this only works on packages that has the version as a attribute). We then query a local clone of the [opam-repository](https://github.com/ocaml/opam-repository) for the latest version of the same package. If these versions differ we add it to the list.

## Goals

Have @r-ryantm query the service and create the PRs to update packages.

Currently there is only a web service but a CLI might be coming soon so that you can generate this list and run the the batch update locally.
