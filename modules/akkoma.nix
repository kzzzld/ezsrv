{
  config,
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
      networking.firewall.allowedTCPPorts = [ 80 ];

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
            background = "/images/back.png";
          };
        };

        "Pleroma.Web.Endpoint" = {
          url.host = cfg.domain;
        };
      };
    };

  };

  services.nginx = {
    clientMaxBodySize = "16m";
    recommendedOptimisation = true;
    recommendedGzipSettings = true;
  };

    }

    (lib.mkIf cfg.enableSSL {
      networking.firewall.allowedTCPPorts = [ 443 ];
      services.akkoma.nginx = {
        enableACME = true;
        forceSSL = true;
      };
      security.acme.acceptTerms = true;
      services.nginx = {
      recommendedTlsSettings = true;
        virtualHosts.${cfg.domain} = {
          forceSSL = true;
          enableACME = true;
        };
      };
    })
  ]);
}

