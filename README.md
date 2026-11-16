# ezsrv

An easy way to start services in your NixOS server.

## Setup

First, you should add this repo as an input in your flake.

```nix
{
  inputs = {
    # your flakes ...

    # ezsrv flake
    ezsrv.url = "github:kzzzld/ezsrv";
  };

  outputs = { nixpkgs, ezsrv, ... }: {
    nixosConfigurations.server = nixpkgs.lib.nixosSystem {
      # your configuration ...

      modules = [
        # your config files ...

        # ezsrv nixos module
        ezsrv.nixosModules.default
      ];
    };
  };
}
```

Then, you can use ezsrv modules in your configuration file. See [Example Usage](#example-usage) for examples.

## Example Usage

```nix
{
  # Add ACME mail if you're going to use SSL
  security.acme.defaults.email = "kzzzl@kzzzl.xyz";
  services.ezsrv.git = {
    enable = true;
    domain = "git.kzzzl.xyz";
    enableSSL = true;
  };

  services.ezsrv.xmpp = {
    enable = true;
    domain = "xmpp.kzzzl.xyz";
    enableSSL = true;
  };
}
```

## Modules

- [XMPP (Prosody)](./modules/xmpp.nix)
- [Git (Forgejo)](./modules/git.nix)
- [Akkoma](./modules/akkoma.nix)
