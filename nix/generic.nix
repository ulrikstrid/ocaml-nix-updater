{ pkgs, stdenv, lib, ocamlPackages, static ? false, doCheck }:

with ocamlPackages; rec {
  ocaml_nix_updater = buildDunePackage {
    pname = "ocaml_nix_updater";
    version = "0.1.0";

    src = lib.filterGitSource {
      src = ./..;
      dirs = [ "test" "bin" "lib" ];
      files = [ "dune-project" "ocaml_nix_updater.opam" ];
    };

    # Static builds support, note that you need a static profile in your dune file
    buildPhase = ''
      echo "running ${if static then "static" else "release"} build"
      dune build bin/main.exe --display=short --profile=${
        if static then "static" else "release"
      }
    '';
    installPhase = ''
      mkdir -p $out/bin
      mv _build/default/bin/main.exe $out/bin/ocaml_nix_updater
    '';

    checkInputs = [ alcotest ];

    propagatedBuildInputs = [
      piaf
      lwt
      yojson
      logs
      fmt
      opam-repository
      astring

      pkgs.git
    ];

    inherit doCheck;

    meta = { description = "Your ocaml_nix_updater"; };
  };
}
