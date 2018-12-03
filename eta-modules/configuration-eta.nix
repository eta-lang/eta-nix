{ pkgs, haskellLib, callPackage, rtsjar, etaSrc, mavenPackages }:

with haskellLib;

let
  addMavenDepend = drv: x:
    haskellLib.overrideCabal drv (drv': {
      mavenDepends = (drv'.mavenDepends or []) ++ [ x ];
    });
in
self: super:
let
  addEtaServ = drv:
    haskellLib.overrideCabal drv (drv': {
      configureFlags = (drv'.configureFlags or []) ++
        [
          "--eta-option=-pgmi"
          "--eta-option=${self.eta-serv}/bin/eta-serv.jar"
        ];
      buildDepends = (drv'.buildDepends or []) ++ [ self.eta-meta ];
    });
  addHappyAlex = drv:
    haskellLib.overrideCabal drv (drv': {
      preConfigure = ''
        export PATH="${pkgs.haskellPackages.happy}/bin:${pkgs.haskellPackages.alex}/bin:$PATH"
      '';
    });
in
{

  Cabal = null;
  ghc-boot-th = null;
  integer-gmp = null;
  unix = null;

  constraints = self.constraints_0_10 or super.constraints;
  mtl = self.mtl_2_2_2 or super.mtl;
  stm = self.stm_2_4_5_1 or self.stm_2_4_5_0 or super.stm;

  cryptonite = addMavenDepend super.cryptonite mavenPackages.bouncycastle;

  aeson = addEtaServ super.aeson;
  ansi-wl-pprint = addBuildDepend super.ansi-wl-pprint self.semigroups;
  case-insensitive = addBuildDepend super.case-insensitive self.semigroups;
  cereal = addBuildDepend super.cereal self.fail;
  dhall = doJailbreak super.dhall;
  free = addBuildDepend super.free self.fail;
  hedgehog = addEtaServ super.hedgehog;
  insert-ordered-containers = doJailbreak super.insert-ordered-containers;
  language-javascript = addHappyAlex super.language-javascript;
  optparse-applicative = addEtaServ super.optparse-applicative;
  parser-combinators = addBuildDepend super.parser-combinators self.semigroups;
  parsers = addEtaServ super.parsers;
  pretty-show = addHappyAlex super.pretty-show_1_7;
  natural-transformation = addBuildDepend super.natural-transformation self.semigroups;
  prettyprinter = addBuildDepend super.prettyprinter self.semigroups;
  purescript = addEtaServ (doJailbreak super.purescript);
  transformers-compat = addBuildDepend super.transformers-compat self.generic-deriving;
  uniplate = addEtaServ super.uniplate;
  wai-app-static = addEtaServ super.wai-app-static;
  wai-websockets = addEtaServ super.wai-websockets;
  wl-pprint-annotated = addBuildDepend super.wl-pprint-annotated self.semigroups;

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
  blaze-builder = callPackage
    ({ mkDerivation, base, bytestring, deepseq, HUnit, QuickCheck
    , semigroups, stdenv, test-framework, test-framework-hunit
    , test-framework-quickcheck2, text, utf8-string
    }:
    mkDerivation {
      pname = "blaze-builder";
      version = "0.4.1.0";
      sha256 = "91fc8b966f3e9dc9461e1675c7566b881740f99abc906495491a3501630bc814";
      libraryHaskellDepends = [
        base bytestring deepseq semigroups text
      ];
      testHaskellDepends = [
        base bytestring HUnit QuickCheck test-framework
        test-framework-hunit test-framework-quickcheck2 text utf8-string
      ];
      homepage = "http://github.com/lpsmith/blaze-builder";
      description = "Efficient buffered output";
      license = stdenv.lib.licenses.bsd3;
    }) {};
  # http-types = callPackage
  #   ({ mkDerivation, array, base, bytestring, case-insensitive, doctest
  #   , hspec, QuickCheck, quickcheck-instances, stdenv, text
  #   }:
  #   mkDerivation {
  #     pname = "http-types";
  #     version = "0.12.1";
  #     sha256 = "3fa7715428f375b6aa4998ef17822871d7bfe1b55ebd9329efbacd4dad9969f3";
  #     libraryHaskellDepends = [
  #       array base bytestring case-insensitive text
  #     ];
  #     testHaskellDepends = [
  #       base bytestring doctest hspec QuickCheck quickcheck-instances text
  #     ];
  #     homepage = "https://github.com/aristidb/http-types";
  #     description = "Generic HTTP types for Haskell (for both client and server code)";
  #     license = stdenv.lib.licenses.bsd3;
  #   }) {};
  http-date = callPackage
    ({ mkDerivation, array, attoparsec, base, bytestring, doctest, hspec
    , old-locale, stdenv, time
    }:
    mkDerivation {
      pname = "http-date";
      version = "0.0.8";
      sha256 = "0f4c6348487abe4f9d58e43d3c23bdefc7fd1fd5672effd3c7d84aaff05f5427";
      libraryHaskellDepends = [ array attoparsec base bytestring time ];
      testHaskellDepends = [
        base bytestring doctest hspec old-locale time
      ];
      description = "HTTP Date parser/formatter";
      license = stdenv.lib.licenses.bsd3;
    }) {};
  conduit-extra = callPackage
    ({ mkDerivation, async, attoparsec, base, bytestring
    , bytestring-builder, conduit, directory, exceptions, filepath
    , gauge, hspec, network, primitive, process, QuickCheck, resourcet
    , stdenv, stm, streaming-commons, text, transformers
    , transformers-base, typed-process, unliftio-core
    }:
    mkDerivation {
      pname = "conduit-extra";
      version = "1.3.0";
      sha256 = "2c41c925fc53d9ba2e640c7cdca72c492b28c0d45f1a82e94baef8dfa65922ae";
      libraryHaskellDepends = [
        async attoparsec base bytestring conduit directory filepath network
        primitive process resourcet stm streaming-commons text transformers
        typed-process unliftio-core
      ];
      testHaskellDepends = [
        async attoparsec base bytestring bytestring-builder conduit
        directory exceptions hspec process QuickCheck resourcet stm
        streaming-commons text transformers transformers-base
      ];
      benchmarkHaskellDepends = [
        base bytestring bytestring-builder conduit gauge transformers
      ];
      homepage = "http://github.com/snoyberg/conduit";
      description = "Batteries included conduit: adapters for common libraries";
      license = stdenv.lib.licenses.mit;
    }) {};
  resourcet = callPackage
    ({ mkDerivation, base, containers, exceptions, hspec, mtl, primitive
    , stdenv, transformers, unliftio-core
    }:
    mkDerivation {
      pname = "resourcet";
      version = "1.2.1";
      sha256 = "e765c12a6ec0f70efc3c938750060bc17569b99578aa635fd4da0c4d06fcf267";
      libraryHaskellDepends = [
        base containers exceptions mtl primitive transformers unliftio-core
      ];
      testHaskellDepends = [ base exceptions hspec transformers ];
      homepage = "http://github.com/snoyberg/conduit";
      description = "Deterministic allocation and freeing of scarce resources";
      license = stdenv.lib.licenses.bsd3;
    }) {};
  boxes = callPackage
    ({ mkDerivation, base, QuickCheck, split, stdenv }:
    mkDerivation {
      pname = "boxes";
      version = "0.1.5";
      sha256 = "38e1782e8a458f342a0acbb74af8f55cb120756bc3af7ee7220d955812af56c3";
      libraryHaskellDepends = [ base split ];
      testHaskellDepends = [ base QuickCheck split ];
      description = "2D text pretty-printing library";
      license = stdenv.lib.licenses.bsd3;
    }) {};
  bsb-http-chunked = callPackage
    ({ mkDerivation, base, bytestring, bytestring-builder, stdenv }:
    mkDerivation {
      pname = "bsb-http-chunked";
      version = "0.0.0.2";
      sha256 = "28cb750979763c815fbf69a6dc510f837b7ccbe262adf0a28ad270966737d5f4";
      libraryHaskellDepends = [ base bytestring bytestring-builder ];
      homepage = "http://github.com/sjakobi/bsb-http-chunked";
      description = "Chunked HTTP transfer encoding for bytestring builders";
      license = stdenv.lib.licenses.bsd3;
    }) {};
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
