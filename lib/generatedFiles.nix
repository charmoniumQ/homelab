{ lib, config, pkgs, ... }:
{
  config = {
    system = {
      activationScripts = {
        generateFiles = (builtins.concatStringsSep
          "\n"
          (builtins.map (elemConfig: ''
              mkdir -p $(dirname ${elemConfig.path})
              ${pkgs.bash}/bin/bash -c ${lib.strings.escapeShellArg elemConfig.script} > ${elemConfig.path}
              chmod ${elemConfig.mode} ${elemConfig.path}
              chown ${elemConfig.user}:${elemConfig.group} ${elemConfig.path}
            '')
            (builtins.attrValues config.generatedFiles)));
      };
    };
  };
  options = {
    generatedFiles = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule (attrs:
        let
          elemConfig = attrs.config;
        in {
          options = {
            script = lib.mkOption {
              type = lib.types.lines;
              description = ''
                Bash script which will generate the file.
              '';
            };
            name = lib.mkOption {
              type = lib.types.strMatching "[a-zA-Z0-9.-]+";
              description = ''
                Filename of the generated file
              '';
            };
            path = lib.mkOption {
              type = lib.types.path;
              default = "/run/secrets/${elemConfig.name}";
              description = ''
                Path on the resulting system where the generated file is stored.
              '';
            };
            mode = lib.mkOption {
              type = lib.types.strMatching "[0-9]{4}";
              default = "0400";
              description = ''
                Permissions mode of the generated file.
              '';
            };
            user = lib.mkOption {
              type = lib.types.strMatching "[a-z0-9]+";
              default = "root";
              description = ''
                User who will own the generated file.
              '';
            };
            group = lib.mkOption {
              type = lib.types.strMatching "[a-z0-9]+";
              default = config.users.${elemConfig.user}.group or "root";
              description = ''
                User who will own the generated file.
              '';
            };
          };
        }));
    };
  };
}
