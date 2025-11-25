{ config, pkgs, ... }:
{
   virtualisation = {
     # virtualbox = {
     #   host = {
     #     enable = true;
     #     enableKvm = true;
     #     # VirtualBox KVM only supports standard NAT networking for VMs. Please turn off virtualisation.virtualbox.host.addNetworkInterface.
     #     addNetworkInterface = false;
     #   };
     # };

     libvirtd = {
       enable = true;
     };

     spiceUSBRedirection = {
       enable = true;
     };
   };

   programs = {
     virt-manager = {
       enable = true;
     };
     # network block device
     # Enables mounting qcow2 images with qemu-nbd
     nbd = {
       enable = true;
     };
   };

   users = {
     extraGroups = {
       libvirtd = {
         members = [ config.sysadmin.username ];
       };
       vboxusers = {
         members = [ config.sysadmin.username ];
       };
     };
   };
}
