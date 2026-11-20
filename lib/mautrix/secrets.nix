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
  doublePuppetSecrets = [
    "double_puppetting_as_token"
    "double_puppetting_hs_token"
    "double_puppetting_sender_localpart"
  ];
in {
  sops = {
    secrets = builtins.listToAttrs (
      map (bridge: {
        name = "mautrix/${bridge}/pickle_key";
        value = { };
      }) pickleBridges
      ++ map (name: {
        name = "mautrix/${name}";
        value = { };
      }) doublePuppetSecrets
    );
    templates = {
      "mautrix-pickle-keys.env".content =
        lib.concatMapStringsSep "\n"
          (bridge: "${envVar bridge}=${config.sops.placeholder."mautrix/${bridge}/pickle_key"}")
          pickleBridges
        + "\n";
      "mautrix-double-puppet.env".content =
        lib.concatMapStringsSep "\n"
          (name: "MATRIX_${lib.toUpper name}=${config.sops.placeholder."mautrix/${name}"}")
          doublePuppetSecrets
        + "\n";
    };
  };
}
