{ ... }: {
  networking = {
    firewall = {
      allowedTCPPorts = [ 3389 ];
    };
  };
}
