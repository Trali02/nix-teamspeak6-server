{
  description = "TeamSpeak 6 Server flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }:
  let
    systems = [ "x86_64-linux" "aarch64-linux" ];

    forAllSystems = f:
      nixpkgs.lib.genAttrs systems (system:
        f (import nixpkgs { 
          inherit system;  
          config = {
            allowUnfree = true;
            allowUnfreePredicate = _: true;
          };}));
  in
  {
    ########################################
    # Packages
    ########################################
    packages = forAllSystems (pkgs: {
      teamspeak6-server =
        pkgs.callPackage ./teamspeak6-server.nix { };
      default = self.packages.${pkgs.system}.teamspeak6-server;
    });

    ########################################
    # Apps (for nix run)
    ########################################
    apps = forAllSystems (pkgs: {
      default = {
        type = "app";
        program =
          "${self.packages.${pkgs.system}.teamspeak6-server}/bin/teamspeak6-server";
      };
    });

    ########################################
    # NixOS Module
    ########################################
    nixosModules.default = { config, lib, pkgs, ... }:

    let
      cfg = config.services.teamspeak6;

      package = self.packages.${pkgs.system}.teamspeak6-server;

      configFile = pkgs.writeText "tsserver.ini" ''
        default_voice_port=${toString cfg.voicePort}
        filetransfer_port=${toString cfg.fileTransferPort}
        query_port=${toString cfg.queryPort}
        license_accepted=1
      '';
    in
    {
      options.services.teamspeak6-server = {
        enable = lib.mkEnableOption "TeamSpeak 6 Server";

        package = lib.mkOption {
          type = lib.types.package;
          default = package;
          description = "The TeamSpeak 6 server package.";
        };

        dataDir = lib.mkOption {
          type = lib.types.str;
          default = "/var/lib/teamspeak6-server";
          description = "Persistent data directory.";
        };

        voicePort = lib.mkOption {
          type = lib.types.port;
          default = 9987;
        };

        fileTransferPort = lib.mkOption {
          type = lib.types.port;
          default = 30033;
        };

        queryPort = lib.mkOption {
          type = lib.types.port;
          default = 10011;
        };

        openFirewall = lib.mkOption {
          type = lib.types.bool;
          default = true;
        };
      };

      config = lib.mkIf cfg.enable {

        ########################################
        # systemd Service
        ########################################
        systemd.services.teamspeak6 = {
          description = "TeamSpeak 6 Server";
          wantedBy = [ "multi-user.target" ];
          after = [ "network.target" ];

          serviceConfig = {
            ExecStart =
              "${cfg.package}/bin/tsserver ini=${configFile}";

            WorkingDirectory = cfg.dataDir;

            StateDirectory = "teamspeak6";
            DynamicUser = true;

            Restart = "always";
            RestartSec = 5;

            # Hardening
            ProtectSystem = "strict";
            ProtectHome = true;
            PrivateTmp = true;
            NoNewPrivileges = true;
          };
        };

        ########################################
        # Firewall
        ########################################
        networking.firewall = lib.mkIf cfg.openFirewall {
          allowedUDPPorts = [ cfg.voicePort ];
          allowedTCPPorts = [
            cfg.fileTransferPort
            cfg.queryPort
          ];
        };
      };
    };
  };
}
