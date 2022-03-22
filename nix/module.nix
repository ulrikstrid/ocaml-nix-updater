{ config, lib, pkgs, ... }:

with lib;

let cfg = config.ocaml-nix-updater;

in {
  options = {
    ocaml-nix-updater = {
      enable = mkEnableOption "enable ocaml-nix-updater";

      port = mkOption {
        type = types.int;
        default = 8080;
        description = "Web server port";
      };

      package = mkOption {
        description = "ocaml-nix-updater package to use";
        default = pkgs.ocaml-nix-updater;
        defaultText = literalExpression ''
          pkgs.ocaml-nix-updater
        '';
        type = types.package;
      };
    };
  };

  config = mkIf (cfg.enable) {
    systemd.services.ocaml-nix-updater = {
      description = "OCaml nix updater web server";
      wantedBy = [ "multi-user.target " ];
      after = [ "network.target" ];
      serviceConfig = {
        ExecStart = "${cfg.package}/bin/ocaml-nix-updater";
        User = "ocaml_nix_updater";
        Group = "ocaml_nix_updater";
        Restart = "on-failure";

        # TODO: Hardening
      };
    };

    users = {
      users.ocaml_nix_updater = {
        group = "ocaml_nix_updater";
        isSystemUser = true;
      };
    };
  };
}
