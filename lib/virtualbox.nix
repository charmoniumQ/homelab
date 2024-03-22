{ config, ... }:
{
   virtualisation = {
     virtualbox = {
       host = {
         enable = true;
       };
     };
   };
   users = {
     extraGroups = {
       vboxusers = {
         members = [ config.sysadmin.username ];
       };
     };
   };
}
