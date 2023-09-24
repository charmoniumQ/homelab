/*
This is a set of configuration variables that will be applied to every host at my site.
*/
{ config, ... }:
{
  networking = {
    useDHCP = true;
    domain = "samgrayson.me";
  };
  time = {
    timeZone = "America/Chicago";
  };
  sysadmin = {
    email = "sam+acme@samgrayson.me";
    sshKeys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDWwABCkuyQy2cqP7wppkQbMgfZqCWmQ18FHrh9P18C8 sam@laptop"
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
}
