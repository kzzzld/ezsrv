{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.services.ezsrv.akkoma;
in {
  # Let's define settings here
  options.services.ezsrv.akkoma = {
    enable = lib.mkEnableOption "Akkoma server";

    domain = lib.mkOption {
      type = lib.types.str;
      example = "example.com";
      description = "Domain name of Akkoma server";
    };

    name = lib.mkOption {
      type = lib.types.str;
      example = "my akkoma server";
      default = "my akkoma server";
      description = "Name for Akkoma";
    };

    description = lib.mkOption {
      type = lib.types.str;
      example = "my akkoma server";
      default = "my akkoma server";
      description = "Description for Akkoma";
    };

    email = lib.mkOption {
      type = lib.types.str;
      example = "example@example.com";
      description = "Mail address";
    };

    enableRegistrations = lib.mkOption {
      type = lib.types.bool;
      example = true;
      default = false;
      description = "Enable registrations";
    };

    enableSSL = lib.mkOption {
      type = lib.types.bool;
      example = true;
      default = false;
      description = "Enable SSL";
    };
  };

  # Akkoma configuration
  config = lib.mkIf cfg.enable (lib.mkMerge [
    {
      # allow port 80
      networking.firewall.allowedTCPPorts = [80];

      services.akkoma = {
        enable = true;

        config = {
          ":pleroma" = {
            ":instance" = {
              name = cfg.name;
              description = cfg.description;
              email = cfg.email;
              registrations_open = cfg.enableRegistrations;
            };

            ":frontend_configurations" = {
              pleroma_fe = {
                background = lib.mkDefault "/images/back.png";
              };
            };

            ":http_security" = {
              enabled = cfg.enableSSL;
            };

            "Pleroma.Upload" = {
              base_url = "${if cfg.enableSSL then "https" else "http"}://${cfg.domain}/media";
            };

            "Pleroma.Web.Endpoint" = {
              url.host = cfg.domain;
            };
          };
        };
      };

      services.postgresql = {
        enable = lib.mkDefault true;
      };

      services.nginx = {
        clientMaxBodySize = lib.mkDefault "16m";
        recommendedOptimisation = lib.mkDefault true;
        recommendedGzipSettings = lib.mkDefault true;
        virtualHosts.${cfg.domain} = {
          forceSSL = cfg.enableSSL;
          enableACME = cfg.enableSSL;

          locations."/" = {
            proxyPass = lib.mkDefault "http://unix:/run/akkoma/socket:";
            proxyWebsockets = lib.mkDefault true;
            recommendedProxySettings = lib.mkDefault true;
          };
        };
      };
    }

    (lib.mkIf cfg.enableSSL {
      networking.firewall.allowedTCPPorts = [443];
      security.acme.acceptTerms = lib.mkDefault true;
      services.nginx = {
        recommendedTlsSettings = lib.mkDefault true;
        virtualHosts.${cfg.domain} = {
          forceSSL = true;
          enableACME = true;
        };
      };
    })
  ]);
}
