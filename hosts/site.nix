/*
This is a set of configuration variables that will be applied to every host at my site.
*/
{ config, ... }:
{
  imports = [
    ../lib
  ];
  networking = {
    useDHCP = true;
    domain = "samgrayson.me";
    enableIPv6 = false;
  };
  time = {
    timeZone = "America/Chicago";
  };
  sysadmin = {
    email = "sam+acme@samgrayson.me";
    sshKeys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDWwABCkuyQy2cqP7wppkQbMgfZqCWmQ18FHrh9P18C8 sam@laptop"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIP5wkgmvprQC0v8p4UfmRDosFwqA8Sq4suRhLa/bC5YO JuiceSSH"
    ];
    hashedPassword = "$y$j9T$QfgpfZwUTsKsyhHUh71aD1$o9OuIHMYXkbUGOFbDaUOouJpnim9aRrX2YmQPYo.N67";
  };
  externalSmtp = {
    enable = true;
    security = "ssl";
    authentication = true;
    passwordFile = config.age.secrets.smtpPass.path;
    host = "mail.runbox.com";
    port = 465;
    fromUser = "sam";
    fromDomain = "samgrayson.me";
  };
  locale = {
    unit_system = "us_customary";
    country = "US";
    lang = "en-US";
  };
  automaticMaintenance = {
    enable = true;
    weeklyTime = "Sat 03:00:00";
    dailyTime = "02:30:00";
    randomizedDelay = "4h";
  };
}
