{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.services.ezsrv.git;
in {
  # Let's define settings here
  options.services.ezsrv.git = {
    enable = lib.mkEnableOption "Git server (Forgejo)";

    domain = lib.mkOption {
      type = lib.types.str;
      example = "example.com";
      description = "Domain name of Git server";
    };

    enableRegistrations = lib.mkOption {
      type = lib.types.bool;
      example = true;
      default = false;
      description = "Enable registrations";
    };

    sshPort = lib.mkOption {
      type = lib.types.port;
      example = 22;
      default = 22;
      description = "SSH port";
    };

    httpPort = lib.mkOption {
      type = lib.types.port;
      example = 3000;
      default = 3000;
      description = "HTTP port";
    };

    enableSSL = lib.mkOption {
      type = lib.types.bool;
      example = true;
      default = false;
      description = "Enable SSL";
    };
  };

  # Forgejo configuration
  config = lib.mkIf cfg.enable (lib.mkMerge [
    {
      # allow port 80 for nginx
      networking.firewall.allowedTCPPorts = [80];

      services.forgejo = {
        enable = true;
        settings = {
          server = {
            SSH_PORT = cfg.sshPort;
            HTTP_PORT = cfg.httpPort;
            HTTP_ADDR = lib.mkDefault "127.0.0.1";
            ROOT_URL = "${
              if cfg.enableSSL
              then "https"
              else "http"
            }://${cfg.domain}/";
          };

          service.DISABLE_REGISTRATION = !cfg.enableRegistrations;
        };
      };

      services.nginx = {
        enable = lib.mkDefault true;
        virtualHosts.${cfg.domain} = {
          extraConfig = lib.mkDefault ''
            client_max_body_size 512M;
          '';
          locations."/".proxyPass = lib.mkDefault "http://127.0.0.1:${toString config.services.forgejo.settings.server.HTTP_PORT}";
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
