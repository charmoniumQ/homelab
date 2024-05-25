{ config, ... }: {
  virtualisation = {
    docker = {
      enable = true;
      storageDriver = "btrfs";
    };
  };
  users = {
    users = {
      "${config.sysadmin.username}" = {
        extraGroups = [ "docker" ];
      };
    };
  };
}
