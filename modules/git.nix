
{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.services.ezsrv.git;

  domain = cfg.domain;
in {
  # Let's define settings here
  options.services.ezsrv.git = {
    enable = lib.mkEnableOption "Git server (Forgejo)";

    domain = lib.mkOption {
      type = lib.types.str;
      example = "example.com";
      description = "Domain name of Git server";
    };

    disableRegistration = lib.mkOption {
      type = lib.types.bool;
      example = true;
      default = true;
      description = "Disable registration";
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
      # allow port 80 and 443 for nginx
      networking.firewall.allowedTCPPorts = [ 80 443 ];

      services.forgejo = {
        enable = lib.mkDefault true;
        settings = {
          server = {
            SSH_PORT = lib.mkDefault cfg.sshPort;
            HTTP_PORT = lib.mkDefault cfg.httpPort;
            HTTP_ADDR = lib.mkDefault "127.0.0.1";
            ROOT_URL = lib.mkDefault "${if cfg.enableSSL then "https" else "http"}://${domain}/";
          };

          service.DISABLE_REGISTRATION = lib.mkDefault cfg.disableRegistration;
        };
      };

      services.nginx = {
        enable = lib.mkDefault true;
        virtualHosts.${domain} = {
          extraConfig = ''
            client_max_body_size 512M;
          '';
          locations."/".proxyPass = "http://127.0.0.1:${toString config.services.forgejo.settings.server.HTTP_PORT}";
        };
      };
    }

    (lib.mkIf cfg.enableSSL {
      security.acme.acceptTerms = true;
      services.nginx = {
        virtualHosts.${domain} = {
          forceSSL = true;
          enableACME = true;
        };
      };
    })
  ]);
}

