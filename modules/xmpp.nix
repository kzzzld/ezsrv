{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.services.ezsrv.xmpp;

  domain = cfg.domain;
  mucDomain = "conference.${domain}";
  uploadDomain = "upload.${domain}";
in {
  # Let's define settings here
  options.services.ezsrv.xmpp = {
    enable = lib.mkEnableOption "XMPP server (Prosody)";

    domain = lib.mkOption {
      type = lib.types.str;
      example = "example.com";
      description = "Domain name of XMPP server";
    };

    adminUser = lib.mkOption {
      type = lib.types.str;
      example = "admin@example.com";
      description = "Administrator XMPP address";
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

  # Prosody configuration
  config = lib.mkIf cfg.enable (lib.mkMerge [
    {
      services.prosody = {
        enable = true;
        admins = [cfg.adminUser];

        httpFileShare = {
          domain = uploadDomain;
          uploadFileSizeLimit = lib.mkDefault (100 * 1024 * 1024);
        };

        muc = [
          {
            domain = mucDomain;
            name = lib.mkDefault "Chat Rooms";
            restrictRoomCreation = lib.mkDefault false;
          }
        ];

        virtualHosts.${domain} = {
          enabled = lib.mkDefault true;
          domain = domain;
        };

        modules = lib.mapAttrs (_: lib.mkDefault) {
          roster = true;
          saslauth = true;
          tls = true;
          dialback = true;
          disco = true;
          carbons = true;
          pep = true;
          mam = true;
          ping = true;
          admin_adhoc = true;
          http_files = true;
        };

        allowRegistration = cfg.enableRegistrations;
      };

      networking.firewall.allowedTCPPorts = [80 443 5281 5222 5269];
    }

    # SSL configuration if needed
    (lib.mkIf cfg.enableSSL {
      services.nginx = {
        enable = lib.mkDefault true;

        virtualHosts.${domain} = {
          serverAliases = [mucDomain uploadDomain];

          locations."/.well-known/acme-challenge/" = {
            root = lib.mkDefault "/var/lib/acme/acme-challenge";
          };
        };
      };

      users.groups.certs.members = ["prosody" "nginx"];

      security.acme.certs.${domain} = {
        group = lib.mkDefault "certs";
        webroot = lib.mkDefault "/var/lib/acme/acme-challenge";
        postRun = lib.mkDefault "systemctl reload prosody.service";
        extraDomainNames = [mucDomain uploadDomain];
      };

      services.prosody = {
        ssl = {
          cert = lib.mkDefault "/var/lib/acme/${domain}/fullchain.pem";
          key = lib.mkDefault "/var/lib/acme/${domain}/key.pem";
        };

        virtualHosts.${domain}.ssl = {
          cert = lib.mkDefault "/var/lib/acme/${domain}/fullchain.pem";
          key = lib.mkDefault "/var/lib/acme/${domain}/key.pem";
        };
      };
    })
  ]);
}
