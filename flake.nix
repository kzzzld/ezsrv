{
  description = "ezsrv: easy way to create a server using nixos";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = {
    self,
    nixpkgs,
    ...
  }: {
    nixosModules = {
      xmpp = import ./modules/xmpp.nix;
    };
  };
}
