{ stdenv, buildPackages, buildHaskellPackages, jailbreak-cabal, eta-hackage, find-maven-depends }:

let
  inherit (buildPackages)
    fetchurl writeText writeScript runCommandNoCC makeWrapper jdk;

  etlasConfig = writeText "etlas-config" ''
    auto-update: False
    send-metrics: False
    remote-build-reporting: none
  '';
in
{ pname
, version, revision ? null
, sha256 ? null
, src ? fetchurl { url = "mirror://hackage/${pname}-${version}.tar.gz"; inherit sha256; }
, buildDepends ? [], setupHaskellDepends ? [], libraryHaskellDepends ? [], executableHaskellDepends ? []
, buildTools ? [], libraryToolDepends ? [], executableToolDepends ? [], testToolDepends ? [], benchmarkToolDepends ? []
, configureFlags ? []
, description ? ""
, doCheck ? true
, editedCabalFile ? null
, extraLibraries ? [], librarySystemDepends ? [], executableSystemDepends ? []
, testHaskellDepends ? []
, benchmarkHaskellDepends ? []
, hydraPlatforms ? null
, isExecutable ? false, isLibrary ? !isExecutable
, jailbreak ? false
, license
, doHaddock ? false
, pkgconfigDepends ? [], libraryPkgconfigDepends ? [], executablePkgconfigDepends ? [], testPkgconfigDepends ? [], benchmarkPkgconfigDepends ? []
, prePatch ? "", postPatch ? ""
, preConfigure ? "", postConfigure ? ""
, preBuild ? "", postBuild ? ""
, installPhase ? "", preInstall ? "", postInstall ? ""
, homepage ? "https://hackage.haskell.org/package/${pname}"
, enableSeparateDataOutput ? false

, mavenDepends ? []
}:

assert editedCabalFile != null -> revision != null;

let
  newCabalFileUrl = "http://hackage.haskell.org/package/${pname}-${version}/revision/${revision}.cabal";
  newCabalFile = fetchurl {
    url = newCabalFileUrl;
    sha256 = editedCabalFile;
    name = "${pname}-${version}-r${revision}.cabal";
  };

  defaultConfigureFlags = [
    "--verbose" "--prefix=$out" "--libdir=\\$prefix/lib/\\$compiler" "--libsubdir=\\$pkgid"
    "--datadir=$data/share/${buildHaskellPackages.eta.name}"
    "--docdir=$doc/share/doc/${pname}-${version}"
    "--package-db=$packageConfDir"
    "--allow-newer=base"
  ];
in
stdenv.mkDerivation ({
  name = "${pname}-${version}";
  inherit src;
  outputs = [ "out" "data" "doc" ];
  setOutputFlags = false;

  buildInputs = [
    buildHaskellPackages.etlas buildHaskellPackages.eta buildHaskellPackages.eta-pkg
    jdk
  ];

  propagatedBuildInputs = buildDepends ++ libraryHaskellDepends ++ executableHaskellDepends;

  inherit mavenDepends;

  prePhases = [ "setupCompilerEnvironmentPhase" ];
  setupCompilerEnvironmentPhase = ''
    packageConfDir="$TMPDIR/package.conf.d"
    mkdir -p $packageConfDir

    for p in "''${pkgsHostHost[@]}" "''${pkgsHostTarget[@]}"; do
      if [ -d "$p/lib/${buildHaskellPackages.eta.name}/package.conf.d" ]; then
        cp -f "$p/lib/${buildHaskellPackages.eta.name}/package.conf.d/"*.conf "$packageConfDir/"
        continue
      fi
    done

    HOME="$TMPDIR/home" eta-pkg --package-db="$packageConfDir" recache

    configureFlags="${stdenv.lib.concatStringsSep " " defaultConfigureFlags} $configureFlags"

    # Make Etlas work
    export HOME="$TMPDIR/home"
    mkdir -p "$HOME/.etlas/binaries" "$HOME/.etlas/tools"
    echo "\$PATH\n\$PATH\n\$PATH" > "$HOME/.etlas/binaries/eta"
    ln -s "${find-maven-depends}" "$HOME/.etlas/tools/coursier"
    cat "${etlasConfig}" > "$HOME/.etlas/config"
  '';
  prePatch = stdenv.lib.optionalString (editedCabalFile != null) ''
    echo "Replace Cabal file with edited version from ${newCabalFileUrl}."
    cp ${newCabalFile} ${pname}.cabal
  '' + ''
    ETA_PATCH="${eta-hackage}/patches/${pname}-${version}.patch"
    if [ -e "$ETA_PATCH" ]; then
      patches=("$ETA_PATCH")
    fi
  '' + prePatch;
  postPatch = stdenv.lib.optionalString jailbreak ''
    echo "Run jailbreak-cabal to lift version restrictions on build inputs."
    ${jailbreak-cabal}/bin/jailbreak-cabal ${pname}.cabal
  '' + postPatch;

  inherit configureFlags;
  configurePhase = ''
    runHook preConfigure

    etlas \
      old-configure \
      $configureFlags

    runHook postConfigure
  '';

  buildPhase = ''
    runHook preBuild

    etlas \
      old-build

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    etlas \
      copy

    packageConfDir="$out/lib/${buildHaskellPackages.eta.name}/package.conf.d"
    packageConfFile="$packageConfDir/${pname}-${version}.conf"
    mkdir -p "$packageConfDir"
    etlas register --gen-pkg-config=$packageConfFile

    mkdir -p $doc $data

    runHook postInstall
  '';
}
// stdenv.lib.optionalAttrs (preConfigure != "")   { inherit preConfigure; }
// stdenv.lib.optionalAttrs (postConfigure != "")  { inherit postConfigure; }
// stdenv.lib.optionalAttrs (preBuild != "")       { inherit preBuild; }
// stdenv.lib.optionalAttrs (postBuild != "")      { inherit postBuild; }
// stdenv.lib.optionalAttrs (preInstall != "")     { inherit preInstall; }
// stdenv.lib.optionalAttrs (installPhase != "")   { inherit installPhase; }
// stdenv.lib.optionalAttrs (postInstall != "")    { inherit postInstall; }
)
