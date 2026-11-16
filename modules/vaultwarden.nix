{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.services.ezsrv.vaultwarden;
in {
  # Let's define settings here
  options.services.ezsrv.vaultwarden = {
    enable = lib.mkEnableOption "Vaultwarden server";

    domain = lib.mkOption {
      type = lib.types.str;
      example = "example.com";
      description = "Domain name of Vaultwarden server";
    };

    enableRegistrations = lib.mkOption {
      type = lib.types.bool;
      example = true;
      default = false;
      description = "Enable registrations";
    };

    port = lib.mkOption {
      type = lib.types.port;
      example = 22;
      default = 8492;
      description = "Port";
    };

    enableSSL = lib.mkOption {
      type = lib.types.bool;
      example = true;
      default = false;
      description = "Enable SSL";
    };
  };

  # Vaultwarden configuration
  config = lib.mkIf cfg.enable (lib.mkMerge [
    {
      # allow port 80 for nginx
      networking.firewall.allowedTCPPorts = [80];

      services.vaultwarden = {
        enable = true;
        config = {
          DOMAIN = "${if cfg.enableSSL then "https" else "http"}://${cfg.domain}";
          SIGNUPS_ALLOWED = cfg.enableRegistrations;
          ROCKET_ADDRESS = lib.mkDefault "127.0.0.1";
          ROCKET_PORT = cfg.port;
        };
      };

      services.nginx = {
        enable = lib.mkDefault true;
        virtualHosts.${cfg.domain} = {
          locations."/".proxyPass = lib.mkDefault "http://127.0.0.1:${toString config.services.vaultwarden.config.ROCKET_PORT}";
        };
      };
    }

    (lib.mkIf cfg.enableSSL {
      networking.firewall.allowedTCPPorts = [443];
      security.acme.acceptTerms = lib.mkDefault true;
      services.nginx = {
        virtualHosts.${cfg.domain} = {
          forceSSL = true;
          enableACME = true;
        };
      };
    })
  ]);
}
