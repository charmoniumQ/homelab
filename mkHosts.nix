/*
Turns a simple object into QEMU VMs and nixosConfigurations.
*/
{ nixpkgs, flake-utils, ... }@flake-inputs: hosts:
let
  lib = nixpkgs.lib;
  importsForHost = host: [
    ./hosts/site.nix
    (./hosts + "/${host}")
  ];
in (flake-utils.lib.eachDefaultSystem (system: {
  packages = builtins.listToAttrs ((lib.trivial.flip builtins.map) hosts (host: {
    name = "${host}-qemu";
    value = (nixpkgs.lib.nixosSystem {
      specialArgs = flake-inputs;
      modules = importsForHost host;
    }).config.system.build.vm;
  }));
})) // {
  nixosConfigurations = builtins.listToAttrs ((lib.trivial.flip builtins.map) hosts (host: {
    name = "${host}";
    value = nixpkgs.lib.nixosSystem {
      specialArgs = flake-inputs;
      modules = importsForHost host;
    };
  }));
}
