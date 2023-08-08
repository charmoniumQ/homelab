/*
This is a set of configuration variables that will be applied to every host at my site.
*/
{ ... }:
{
  networking = {
    useDHCP = /* TODO */ true;
    domain = /* TODO */ "example.com";
  };
  time = {
    timeZone = /* TODO */ "America/Chicago";
  };
  sysadmin = {
    email = /* TODO */ "admin@example.com";
    sshKeys = [
	  /* TODO */
      "ssh-ed25519 AAAA.... admin@laptop"
    ];
  };
}
