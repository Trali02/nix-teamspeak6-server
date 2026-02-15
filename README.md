# teamspeak6-server
This is a barebones flake with very limited options to host a  teamspeak6-server.

## currently available options

| option name     | type    | default                      |
|-----------------|---------|------------------------------|
| enable          | bool    | false                        |
| package         | package | package                      |
| dataDir         | str     | "/var/lib/teamspeak6-server" |
| ip              | str     | "127.0.0.1"                  |
| voicePort       | port    | 9987                         |
| fileTrasferPort | port    | 30033                        |
| queryPort       | port    | 10011                        |
| openFirewall    | bool    | true                         |
| acceptLicense   | bool    | false                        |

## usage

To use the teamspeak6-server service add this flake to your flake input:

```nix
# flake.nix
{
  description = "Teamspeak6 Server config";

  inputs = {
    # Nixpkgs
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.05";
    # Teamspeak6 Server flake
    nix-teamspeak6-server.url = "github:Trali02/nix-teamspeak6-server";
  };

  outputs = { self, nixpkgs, nix-teamspeak6-server, ... }@inputs:
    let inherit (self) outputs;
    in {
      # NixOS configuration entrypoint
      # Available through 'nixos-rebuild --flake .#Worlds'
      nixosConfigurations = {
        Worlds = nixpkgs.lib.nixosSystem {
          specialArgs = { inherit inputs outputs; };
          # > Our main nixos configuration file <
          modules = [ 
            ./configuration.nix
            nix-teamspeak6-server.nixosModules.default
          ];
        };
      };
    };
}
```
Now you can configure the service in your `./configuration.nix`
```nix
# configuration.nix
{ inputs, config, pkgs, lib, ... }: 
{
  ...
  services.teamspeak6-server = {
    enable = true;
    ip = "127.0.0.1"; # put the ip of your server/computer here
    openFirewall = true;
    acceptLicense = true;
  };
  ...
}
```

> [!IMPORTANT]
> The derivation is unfree, make sure that your configuration allows for that!