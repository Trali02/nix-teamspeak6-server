{
  description = "TeamSpeak 6 Server flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
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
      cfg = config.services.teamspeak6-server;

      package = self.packages.${pkgs.system}.teamspeak6-server;
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

        ip = lib.mkOption {
          type = lib.types.str;
          default = "127.0.0.1";
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

        acceptLicense = lib.mkOption {
          type = lib.types.bool;
          default = false;
        };
      };

      config = lib.mkIf cfg.enable {

        ########################################
        # systemd Service
        ########################################
        systemd.services.teamspeak6-server = {
          description = "TeamSpeak 6 Server";
          wantedBy = [ "multi-user.target" ];
          after = [ "network.target" ];

          environment = {
            TSSERVER_LICENSE_ACCEPTED = builtins.toString cfg.acceptLicense;
            TSSERVER_DEFAULT_PORT = builtins.toString cfg.voicePort;
            TSSERVER_DATABASE_SQL_PATH = "${cfg.package}/share/teamspeak6-server/sql";
            TSSERVER_QUERY_HTTP_PORT = builtins.toString cfg.queryPort;
            TSSERVER_FILE_TRANSFER_PORT = builtins.toString cfg.fileTransferPort;
            TSSERVER_VOICE_IP = cfg.ip;
          };

          serviceConfig = {
            ExecStart =
              "${cfg.package}/bin/teamspeak6-server";

            WorkingDirectory = cfg.dataDir;

            StateDirectory = "teamspeak6-server";
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
