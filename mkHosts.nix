/*
Turns a colmena deply object into QEMU VMs and nixosConfigurations.
*/
{ nixpkgs, flake-utils, ... }@inputs: { colmena }:
let
  hosts = nixpkgs.lib.lists.remove "meta" (builtins.attrNames colmena);
  importsForHost = host: [
    (./hosts + "/${host}")
    ./hosts/site.nix
  ];
  lib = nixpkgs.lib;
in (flake-utils.lib.eachDefaultSystem (system: {
  packages = builtins.listToAttrs ((lib.trivial.flip builtins.map) hosts (host: {
    name = "${host}-qemu";
    value = (nixpkgs.lib.nixosSystem {
      system = colmena.meta.nixpkgs.system;
      specialArgs = inputs;
      modules = importsForHost host;
    }).config.system.build.vm;
  }));
})) // {
  nixosConfigurations = builtins.listToAttrs ((lib.trivial.flip builtins.map) hosts (host: {
    name = "${host}";
    value = nixpkgs.lib.nixosSystem {
      system = colmena.meta.nixpkgs.system;
      specialArgs = inputs;
      modules = importsForHost host;
    };
  }));
  colmena = {
    meta = {
      nixpkgs = import nixpkgs {
        system = "x86_64-linux";
      };
      specialArgs = inputs;
    };
  } // builtins.listToAttrs ((lib.trivial.flip builtins.map) hosts (host: {
    name = host;
    value = colmena."${host}" // {
      imports = importsForHost host;
    };
  }));
}
