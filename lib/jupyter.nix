{ config, lib, pkgs, ... }:
{
  config = {
    services = {
      jupyter = {
        package = pkgs.python311.withPackages (pypkgs: [pypkgs.jupyterlab pypkgs.jupyter-collaboration]);
        command = "jupyter-lab";
        password = "'argon2:$argon2id$v=19$m=10240,t=10,p=8$ky9rOLfxjV/m5szwNgW4gg$JrgwLG0uGVH9hIkyLhdmiVQIMoUjcyaM1N4F4f29pjE'";
        port = 38967;
        kernels = {
          python3 = let
            env = (pkgs.python311.withPackages (pythonPackages: with pythonPackages; [
              ipykernel
              numpy
              scipy
              pandas
              scikit-learn
              matplotlib
            ]));
          in {
            displayName = "Python 3 for machine learning";
            argv = [
              "${env.interpreter}"
              "-m"
              "ipykernel_launcher"
              "-f"
              "{connection_file}"
            ];
            language = "python";
            # logo32 = "${env.sitePackages}/ipykernel/resources/logo-32x32.png";
            # logo64 = "${env.sitePackages}/ipykernel/resources/logo-64x64.png";
          };
        };
      };
    };
    systemd = {
      services = {
        jupyter = {
          serviceConfig = {
            ExecStart = let
              cfg = config.services.jupyter;
              package = cfg.package;
              notebookConfig = pkgs.writeText "jupyter_config.py" ''
                ${cfg.notebookConfig}
                c.NotebookApp.password = ${cfg.password}
              '';
            in lib.mkForce ''${package}/bin/${cfg.command} \
              --no-browser \
              --ip=${cfg.ip} \
              --port=${toString cfg.port} --port-retries 0 \
              --notebook-dir=${cfg.notebookDir} \
              --NotebookApp.config_file=${notebookConfig} \
              --ServerApp.allow_remote_access=True
            '';
          };
        };
      };
    };
    users = {
      users = {
        jupyter = {
          group = "jupyter";
        };
      };
      groups = {
        jupyter = {};
      };
    };
    reverseProxy = {
      domains = {
        "jupyter.${config.networking.domain}" = {
          port = config.services.jupyter.port;
        };
      };
    };
  };
}
