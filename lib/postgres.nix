{ ... }: {
  services = {
    postgresql = {
      enable = true;
      settings = {
        port = 5432;
      };
      enableJIT = true;
    };
  };
}
