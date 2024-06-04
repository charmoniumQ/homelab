{ config, lib, ... }: {
  sysadmin = {
    email = "sam+acme@samgrayson.me";
    sshKeys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIP5wkgmvprQC0v8p4UfmRDosFwqA8Sq4suRhLa/bC5YO JuiceSSH"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGlV+zu9Fgj2Hsg7CIpoQxbPJTWxrasJ/Cy25Wg5pyxX sam@katherine-XPS-13-9350"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIH/7TzK2DDclyCe01RptAXD/p5aForn9V84iCzVeFmMw sam@laptop"
    ];
  };
  time = {
    timeZone = lib.mkDefault "America/Chicago";
  };
  locale = {
    unit_system = lib.mkDefault "us_customary";
    country = lib.mkDefault "US";
    lang = lib.mkDefault "en-US";
  };
} // lib.mkIf config.wifi {
  networking = {
    networkmanager = {
      ensureProfiles = {
        environmentFiles = [ config.age.secrets.wifi-env-file.path ];
        profiles = {
          home-wifi = {
            id = "$home_wifi_ssid";
            type = "wifi";
            mode = "infrastructure";
            ssid = "$home_wifi_ssid";
            auth-alg = "open";
            key-mgmt = "wpa-psk";
            psk = "$home_wifi_password";
          };
        };
      };
    };
  };
  age = {
    secrets = {
      wifi-env-file = {
        file = ../secrets/wifi-env-file.age;
      };
    };
  };
}
