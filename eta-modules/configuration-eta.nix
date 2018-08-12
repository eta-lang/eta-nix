{ pkgs, haskellLib, callPackage, rtsjar, etaSrc }:

with haskellLib;

self: super: {

  Cabal = null;
  ghc-boot-th = null;
  unix = null;

  mtl = self.mtl_2_2_2 or super.mtl;
  stm = self.stm_2_4_5_0 or super.stm;

  ansi-wl-pprint = addBuildDepend super.ansi-wl-pprint self.semigroups;
  cereal = addBuildDepend super.cereal self.fail;
  free = addBuildDepend super.free self.fail;
  parser-combinators = addBuildDepend super.parser-combinators self.semigroups;
  transformers-compat = addBuildDepend super.transformers-compat self.generic-deriving;

  eta-serv = callPackage
    ({ mkDerivation, stdenv }:
    mkDerivation {
      pname = "eta-serv";
      version = "0.8.4.1";
      src = etaSrc + "/eta-serv";
      configureFlags = [ "--enable-uberjar-mode" ];
      libraryHaskellDepends = [
        self.base self.eta-repl self.eta-meta self.bytestring self.deepseq
        self.directory self.filepath
      ];
      license = stdenv.lib.licenses.bsd3;
    }) {};

  rts = callPackage
    ({ mkDerivation, stdenv }:
    mkDerivation {
      pname = "rts";
      version = "0.1.0.0";
      src = etaSrc + "/libraries/rts";
      preBuild = ''
        mkdir build
        ln -s "${rtsjar}" build/rts.jar
      '';
      license = stdenv.lib.licenses.bsd3;
    }) {};
  ghc-prim = callPackage
    ({ mkDerivation, rts, stdenv }:
    mkDerivation {
      pname = "ghc-prim";
      version = "0.4.0.0";
      src = etaSrc + "/libraries/ghc-prim";
      libraryHaskellDepends = [ rts ];
      postInstall = ''
        awk -i inplace \
          '{ if ( $1 !~ /GHC\./ ) { print $0 } else { gsub(/^ */, "", $0); print "    GHC.Prim " $0 } }' \
          $packageConfDir/*
      '';
      license = stdenv.lib.licenses.bsd3;
    }) {};
  integer = callPackage
    ({ mkDerivation, ghc-prim, stdenv }:
    mkDerivation {
      pname = "integer";
      version = "0.5.1.0";
      src = etaSrc + "/libraries/integer";
      libraryHaskellDepends = [ ghc-prim ];
      license = stdenv.lib.licenses.bsd3;
    }) {};
  base = callPackage
    ({ mkDerivation, rts, ghc-prim, integer, stdenv }:
    mkDerivation {
      pname = "base";
      version = "4.11.1.0";
      src = etaSrc + "/libraries/base";
      libraryHaskellDepends = [ rts ghc-prim integer ];
      license = stdenv.lib.licenses.bsd3;
    }) {};

  eta-boot-meta = callPackage
    ({ mkDerivation, base, stdenv }:
    mkDerivation {
      pname = "eta-boot-meta";
      version = "0.8.4";
      src = etaSrc + "/libraries/eta-boot-meta";
      libraryHaskellDepends = [ base ];
      license = stdenv.lib.licenses.bsd3;
    }) {};
  eta-boot = callPackage
    ({ mkDerivation, base, binary, bytestring, directory, filepath, eta-boot-meta, stdenv }:
    mkDerivation {
      pname = "eta-boot";
      version = "0.8.4";
      src = etaSrc + "/libraries/eta-boot";
      libraryHaskellDepends = [ base binary bytestring directory filepath eta-boot-meta ];
      license = stdenv.lib.licenses.bsd3;
    }) {};
  eta-meta = callPackage
    ({ mkDerivation, base, pretty, eta-repl, eta-boot, stdenv }:
    mkDerivation {
      pname = "eta-meta";
      version = "0.8.4.1";
      src = etaSrc + "/libraries/eta-meta";
      libraryHaskellDepends = [ base pretty eta-repl eta-boot ];
      license = stdenv.lib.licenses.bsd3;
    }) {};
  eta-repl = callPackage
    ({ mkDerivation, base, eta-boot-meta, deepseq, bytestring, binary, stdenv }:
    mkDerivation {
      pname = "eta-repl";
      version = "0.8.4.1";
      src = etaSrc + "/libraries/eta-repl";
      libraryHaskellDepends = [ base eta-boot-meta deepseq bytestring binary ];
      license = stdenv.lib.licenses.bsd3;
    }) {};

  eta-java-interop = callPackage
   ({ mkDerivation, base, fetchgit, stdenv }:
   mkDerivation {
     pname = "eta-java-interop";
     version = "0.1.5.0";
     src = fetchgit {
       url = "https://github.com/typelead/eta-java-interop";
       sha256 = "141mvi54svia3wqkvzcvik7v5wsa8rl814ys6wznc69n4i2b1crs";
       rev = "a9a8d857e6cec9094439da38b143832848fd431b";
     };
     libraryHaskellDepends = [ base ];
     description = "Utilities for interoperating with Java";
     license = stdenv.lib.licenses.bsd3;
   }) {};

  # nixpkgs 18.03 has some old versions which don't work under Eta
  tagged = callPackage
    ({ mkDerivation, base, deepseq, stdenv, template-haskell
     , transformers
     }:
     mkDerivation {
       pname = "tagged";
       version = "0.8.6";
       sha256 = "ad16def0884cf6f05ae1ae8e90192cf9d8d9673fa264b249499bd9e4fac791dd";
       libraryHaskellDepends = [
         base deepseq template-haskell transformers
       ];
       homepage = "http://github.com/ekmett/tagged";
       description = "Haskell 98 phantom types to avoid unsafely passing dummy arguments";
       license = stdenv.lib.licenses.bsd3;
     }) {};
  profunctors = callPackage
    ({ mkDerivation, base, base-orphans, bifunctors, comonad
    , contravariant, distributive, semigroups, stdenv, tagged
    , transformers
    }:
    mkDerivation {
      pname = "profunctors";
      version = "5.3";
      sha256 = "74632acc5bb76e04ade95e187be432b607da0e863c0e08f3cabafb23d8b4a3b7";
      libraryHaskellDepends = [
        base base-orphans bifunctors comonad contravariant distributive
        semigroups tagged transformers
      ];
      homepage = "http://github.com/ekmett/profunctors/";
      description = "Profunctors";
      license = stdenv.lib.licenses.bsd3;
    }) {};

  # https://github.com/typelead/eta-hackage/issues/76
  template-haskell = haskellLib.addBuildDepend super.template-haskell self.eta-meta;
  text = haskellLib.addBuildDepend super.text self.eta-java-interop;

}
