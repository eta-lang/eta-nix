{ stdenv
, fetchFromGitHub
, fetchgit
, fetchurl
, writeText
, runCommandNoCC
, makeWrapper
, jdk
, haskell
, pkgs

, eta-hackage ? import ./eta-hackage.nix { inherit fetchFromGitHub; }
, hackage-packages ? import <nixpkgs/pkgs/development/haskell-modules/hackage-packages.nix>
}:

let
  haskellPackages = import ../. { inherit pkgs; };

  rtsjar = stdenv.mkDerivation {
    name = "rts.jar";
    buildInputs = [ haskellPackages.eta-build pkgs.jdk ];
    src = haskellPackages.eta.src;
    buildPhase = ''
      eta-build libraries/rts/build/rts.jar
    '';
    installPhase = ''
      mv libraries/rts/build/rts.jar $out
    '';
  };

  mkScope = scope: pkgs // scope;

  callPackageWithScope = scope: fn: manualArgs:
    let
      drv = if stdenv.lib.isFunction fn then fn else import fn;
      auto = builtins.intersectAttrs (stdenv.lib.functionArgs drv) scope;
      drvScope = allArgs: drv allArgs // {
        overrideScope = f:
          let newScope = mkScope (stdenv.lib.fix' (stdenv.lib.extends f scope.__unfix__));
          in callPackageWithScope newScope drv manualArgs;
      };
    in stdenv.lib.makeOverridable drvScope (auto // manualArgs);

  mkDerivation = stdenv.lib.makeOverridable (pkgs.callPackage ./generic-builder.nix {
    inherit eta-hackage find-maven-depends;
    buildHaskellPackages = haskellPackages;
  });

  find-maven-depends = pkgs.callPackage ./coursier/find-maven-depends.nix { };
  fetchCoursier = pkgs.callPackage ./coursier/fetch.nix { };
  mavenPackages = pkgs.callPackage ./maven-packages.nix { inherit fetchCoursier; };

  haskellLib = pkgs.haskell.lib;
  initialPackages = self:
    let
      defaultScope = mkScope self;
      callPackage = drv: args: callPackageWithScope defaultScope drv args;
    in
    hackage-packages {
      inherit pkgs stdenv callPackage;
    } self // {
      inherit mkDerivation callPackage;
      etaWithPackages = selectFrom:
        callPackage ./with-packages-wrapper.nix {
          buildHaskellPackages = haskellPackages;
          packages = selectFrom self;
        };
    };
  etaHackagePackages = self: _:
    builtins.removeAttrs
      (import ./eta-hackage-packages.nix {
        inherit pkgs stdenv;
        inherit (self) callPackage;
      } self)
      (import ./ignore-patch-list.nix);
  configurationEta = self: import ./configuration-eta.nix {
    inherit pkgs haskellLib rtsjar mavenPackages;
    inherit (self) callPackage;
    etaSrc = haskellPackages.eta.src;
  } self;
in
stdenv.lib.makeExtensible
  (stdenv.lib.extends configurationEta
    (stdenv.lib.extends etaHackagePackages
      initialPackages))
