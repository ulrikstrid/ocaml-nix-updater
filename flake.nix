{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";

    ocaml-overlay.url = "github:anmonteiro/nix-overlays/auto-update-sources-2140478561";
    ocaml-overlay.inputs.nixpkgs.follows = "nixpkgs";
    ocaml-overlay.inputs.flake-utils.follows = "flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils, ocaml-overlay }:
    let
      out = system:
        let
          pkgs = import nixpkgs {
            inherit system;
            overlays = [ ocaml-overlay.overlay ];
          };
          inherit (pkgs) lib;
          myPkgs = pkgs.recurseIntoAttrs (import ./nix {
            inherit pkgs;
            doCheck = true;
          }).native;
          myDrvs = lib.filterAttrs (_: value: lib.isDerivation value) myPkgs;
        in {
          devShell = (pkgs.mkShell {
            inputsFrom = lib.attrValues myDrvs;
            buildInputs = with pkgs;
              with ocamlPackages; [
                ocaml-lsp
                ocamlformat
                odoc
                ocaml
                dune_3
                nixfmt
              ];
          });

          defaultPackage = myPkgs.ocaml_nix_updater;

          defaultApp =
            flake-utils.lib.mkApp { drv = self.defaultPackage."${system}"; };

          nixosModule = (import ./nix/module.nix);
        };
    in with flake-utils.lib; eachSystem defaultSystems out;

}
