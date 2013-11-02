{ pkgs, config, nodes, resources, ... }:

with pkgs.lib;

let
  hydraRelease = import ./hydra/release.nix {};
  hydra = builtins.getAttr config.nixpkgs.system hydraRelease.build;

  buildUser = "hydrabuild";

  isBuildNode = name: node: hasAttr buildUser node.config.users.extraUsers;
  buildNodes = filterAttrs isBuildNode nodes;

  buildKey = resources.sshKeyPairs."hydra-build".privateKey;
in {
  imports = [ ./hydra/hydra-module.nix ];

  services.hydra = {
    inherit hydra;
    enable = true;
    hydraURL = "https://headcounter.org/hydra/";
    notificationSender = "hydra@headcounter.org";
    dbi = "dbi:Pg:dbname=hydra;";
    listenHost = "localhost";
  };

  nix.maxJobs = mkForce 0;
  nix.distributedBuilds = true;
  nix.buildMachines = flip mapAttrsToList buildNodes (hostName: node: {
    inherit hostName;
    inherit (node.config.nix) maxJobs;
    systems = if node.config.nixpkgs.system == "x86_64-linux"
              then [ "i686-linux" "x86_64-linux" ]
              else singleton node.config.nixpkgs.system;
    sshKey = "/run/keys/buildkey.priv";
    sshUser = buildUser;
  });

  deployment.keys."signkey.priv" = readFile ./ssl/signing-key.sec;
  deployment.keys."buildkey.priv" = buildKey;
  deployment.storeKeysOnMachine = false;

  environment.etc."nix/signing-key.sec".source = "/run/keys/signkey.priv";

  services.postgresql.enable = true;
  services.postgresql.package = pkgs.postgresql92;
  services.postgresql.authentication = ''
    local hydra hydra peer
  '';
}
