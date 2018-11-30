{ pkgs ? import <nixpkgs> {}
, overrides ? self: super: { }
}:

(import ./eta.nix { inherit pkgs; }).override {
  overrides = self: super: {
    Cabal = null;
    semigroupoids = pkgs.haskell.lib.overrideCabal super.semigroupoids (drv: {
      postPatch = ''
        sed -iE 's/tagged >=.*/tagged/g' semigroupoids.cabal
      '';
    });
    tasty = pkgs.haskell.lib.doJailbreak super.tasty;
  } // overrides self super;
}
