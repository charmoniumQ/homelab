{ config, lib, ... }: {
  config = {
    i18n = {
      defaultLocale = lib.mkDefault "${builtins.replaceStrings ["-"] ["_"] config.locale.lang}.UTF-8";
    };
  };
  options = {
    locale = {
      unit_system = lib.mkOption {
        type = lib.types.enum [ "metric" "us_customary" ];
        description = "Preferred units.";
      };
      country = lib.mkOption {
        type = lib.types.strMatching "[A-Z][A-Z]";
        description = "ISO 3166-1 alpha-2 country code";
      };
      lang = lib.mkOption {
        type = lib.types.strMatching "[a-zA-Z]{1,8}(-[a-zA-Z0-9]{1,8})*";
        description = "RFC 5646 language tag";
      };
      currency = lib.mkOption {
        type = lib.types.strMatching "[A-Z][A-Z][A-Z]";
        description = "ISO 4217 currency code";
        default =
          if config.locale.country == "US"
          then "USD"
          else lib.trivial.warn ("Unknown currency for country " ++ config.locale.country) null;
      };
    };
  };
}
