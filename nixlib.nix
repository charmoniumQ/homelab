{ lib, ... }:
{
  types = {
    # https://stackoverflow.com/a/7109208
    absolute-url-path = lib.types.strMatching
      "^[A-Za-z0-9-._~:/\[\]@!$&'()*+,;%=]+$";

    # https://stackoverflow.com/questions/106179/regular-expression-to-match-dns-hostname-or-ip-address
    domain-name = lib.types.strMatching
      "^(([a-zA-Z0-9]|[a-zA-Z0-9][a-zA-Z0-9\-]*[a-zA-Z0-9])\.)*([A-Za-z0-9]|[A-Za-z0-9][A-Za-z0-9\-]*[A-Za-z0-9])$";

    # https://stackoverflow.com/a/8829363
    email = lib.strMatching
      "^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$";

    # https://superuser.com/a/1516549/110096
    unix-username = lib.types.strMatching "^[a-z][-a-z0-9_]+$";

    unpriv-port = lib.types.numbers.between 1000 65535;
  };
  checked-python-script = {
    pname,
      script,
      pypkgs-fn,
      system,
      nixpkgs,
      python ? nixpkgs.${system}.python313,
      other-pkgs ? [],
  }: (nixpkgs.${system}.stdenv.mkDerivation {
    pname = "${pname}";
    version = "only";
    src = script;
    checkInputs = [
      (python.withPackages (pypkgs: (pypkgs-fn pypkgs) ++ pypkgs.mypy))
      nixpkgs.${system}.ruff
    ] ++ other-pkgs;
    checkPhase = ''
      ruff format --check ${script}
      ruff check ${script}
      mypy --strict ${script}
    '';
    buildInputs = [
      (python.withPackages pypkgs-fn)
    ];
    buildPhase = "";
    installPhase = ''
      mkdir --parents $out/bin
      echo "#! ${(python.withPackages pypkgs-fn)}" > $out/bin/${pname}
      cat ${script} >> $out/bin/${pname}
      chmod +x $out/bin/${pname}
    '';
  }) + "/bin/${pname}";
}
