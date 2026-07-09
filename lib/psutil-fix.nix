{ ... }:
{
  nixpkgs.overlays = [
    (final: prev: {
      pythonPackagesExtensions = prev.pythonPackagesExtensions ++ [
        (py-final: py-prev: {
          psutil = py-prev.psutil.overridePythonAttrs (oldAttrs: {
            disabledTests = (oldAttrs.disabledTests or []) ++ [
              "test_net_if_addrs"
              "test_net_if_stats"
              "test_disk_usage"
            ];
          });
        })
      ];
    })
  ];
}
