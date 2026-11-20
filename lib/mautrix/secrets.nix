{ config, lib, ... }:
let
  pickleBridges = [
    "signal"
    "slack"
    "whatsapp"
    "meta"
    "gmessages"
    "telegram"
    "discord"
  ];
  envVar = bridge: "MAUTRIX_${lib.toUpper bridge}_PICKLE_KEY";
in {
  sops = {
    secrets = builtins.listToAttrs (map (bridge: {
      name = "mautrix/${bridge}/pickle_key";
      value = { };
    }) pickleBridges);
    templates."mautrix-pickle-keys.env".content =
      lib.concatMapStringsSep "\n"
        (bridge: "${envVar bridge}=${config.sops.placeholder."mautrix/${bridge}/pickle_key"}")
        pickleBridges
      + "\n";
  };
}
