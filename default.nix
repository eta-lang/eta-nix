{ pkgs ? import <nixpkgs> {} }:

(import ./eta.nix { inherit pkgs; }).override {
  overrides = self: super: {
    Cabal = null;
    binary = pkgs.haskell.lib.dontCheck (self.callPackage ./eta-modules/binary-0.8.5.1.nix { });
  };
}
