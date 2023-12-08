# https://github.com/NixOS/nixpkgs/blob/nixos-unstable/nixos/modules/services/networking/mosquitto.nix

/*
Warning: File /nix/store/avb8wd844fhsnw14bpkd5pcf0izmjm6q-mosquitto-acl-0.conf has world readable permissions. Future versions will refuse to load this file.
Warning: File /nix/store/avb8wd844fhsnw14bpkd5pcf0izmjm6q-mosquitto-acl-0.conf owner is not mosquitto. Futuree versions will refuse to load this file.
Warning: File /nix/store/avb8wd844fhsnw14bpkd5pcf0izmjm6q-mosquitto-acl-0.conf group is not mosquitto. Futuree versions will refuse to load this file.
*/
{ pkgs, config, lib, ... }:
with lib; let
  cfg = config.services.mosquitto;
  str = types.strMatching "[^\r\n]*" // {
    description = "single-line string";
  };
  formatBridge = name: bridge:
    [
      "connection ${name}"
      "addresses ${concatMapStringsSep " " (a: "${a.address}:${toString a.port}") bridge.addresses}"
    ]
    ++ map (t: "topic ${t}") bridge.topics
    ++ formatFreeform {} bridge.settings;
  path = types.addCheck types.path (p: str.check "${p}");
  optionToString = v:
    if isBool v then trivial.boolToString v
    else if path.check v then "${v}"
    else toString v;
  formatFreeform = { prefix ? "" }: attrsets.mapAttrsToList (n: v: "${prefix}${n} ${optionToString v}");
  formatListener = idx: listener:
    [
      "listener ${toString listener.port} ${toString listener.address}"
      "acl_file /etc/mosquitto/mosquitto-acl-${toString idx}.conf"
    ]
    ++ lists.optional (! listener.omitPasswordAuth) "password_file ${cfg.dataDir}/passwd-${toString idx}"
    ++ formatFreeform {} listener.settings
    ++ concatMap formatAuthPlugin listener.authPlugins;
  formatAuthPlugin = plugin:
    [
      "auth_plugin ${plugin.plugin}"
      "auth_plugin_deny_special_chars ${optionToString plugin.denySpecialChars}"
    ]
    ++ formatFreeform { prefix = "auth_opt_"; } plugin.options;
  formatGlobal = cfg:
    [
      "per_listener_settings true"
      "persistence ${optionToString cfg.persistence}"
    ]
    ++ map
      (d: if path.check d then "log_dest file ${d}" else "log_dest ${d}")
      cfg.logDest
    ++ map (t: "log_type ${t}") cfg.logType
    ++ formatFreeform {} cfg.settings
    ++ concatLists (lists.imap0 formatListener cfg.listeners)
    ++ concatLists (mapAttrsToList formatBridge cfg.bridges)
    ++ map (d: "include_dir ${d}") cfg.includeDirs;

  configFile = pkgs.writeText "mosquitto.conf"
    (concatStringsSep "\n" (formatGlobal cfg));
in {
  systemd = lib.attrsets.optionalAttrs cfg.enable {
    services = {
      mosquitto = {
        serviceConfig = {
          ExecStart = lib.mkForce "${cfg.package}/bin/mosquitto -c ${configFile}";
        };
      };
    };
  };
  environment = lib.attrsets.optionalAttrs cfg.enable {
    etc = listToAttrs (
      lists.imap0
        (idx: listener: {
          name = "mosquitto/mosquitto-acl-${toString idx}.conf";
          value = {
            user = config.users.users.mosquitto.name;
            group = config.users.users.mosquitto.group;
            mode = "0400";
            text = (concatStringsSep
              "\n"
              (flatten [
                listener.acl
                (attrsets.mapAttrsToList
                  (n: u: [ "user ${n}" ] ++ map (t: "topic ${t}") u.acl)
                  listener.users)
              ]));
          };
        })
        cfg.listeners
    );
  };
}
