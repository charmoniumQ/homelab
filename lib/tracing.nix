{ ... }: {
  boot = {
    kernel = {
      sysctl = {
        "kernel.perf_event_paranoid" = -1;
      };
    };
  };
}
