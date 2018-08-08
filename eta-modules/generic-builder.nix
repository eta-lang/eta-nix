{ stdenv, buildPackages, buildHaskellPackages, eta-hackage }:

let
  inherit (buildPackages)
    fetchurl writeText runCommandNoCC makeWrapper jdk;

  etlasConfig = writeText "etlas-config" ''
    auto-update: False
    send-metrics: False
    remote-build-reporting: none
  '';

  etaPkgWrapper = runCommandNoCC "eta-pkg-wrapper" {
    nativeBuildInputs = [ makeWrapper ];
  } ''
    makeWrapper ${buildHaskellPackages.eta-pkg}/bin/eta-pkg $out/bin/eta-pkg \
      --run 'extraFlagsArray=("--global-package-db=$TMPDIR/package.conf.d")'
    '';

  etlasWrapper = runCommandNoCC "etlas-wrapper" {
    nativeBuildInputs = [ makeWrapper ];
  } ''
    makeWrapper ${buildHaskellPackages.etlas}/bin/etlas $out/bin/etlas \
      --run 'export HOME=$TMPDIR/home' \
      --run 'mkdir -p "$HOME/.etlas/binaries"' \
      --run 'echo "\$PATH\n\$PATH\n\$PATH" > "$HOME/.etlas/binaries/eta"' \
      --run 'cat "${etlasConfig}" > $HOME/.etlas/config' \
      --prefix PATH : "${stdenv.lib.makeBinPath [ buildHaskellPackages.eta etaPkgWrapper ]}"
    '';
in
{ pname
, version, revision ? null
, sha256 ? null
, src ? fetchurl { url = "mirror://hackage/${pname}-${version}.tar.gz"; inherit sha256; }
, buildDepends ? []
, editedCabalFile ? null
, setupHaskellDepends ? [], libraryHaskellDepends ? []
, description ? ""
, doCheck ? true
, testHaskellDepends ? []
, benchmarkHaskellDepends ? []
, testToolDepends ? []
, hydraPlatforms ? null
, isExecutable ? false, isLibrary ? !isExecutable
, license
, preConfigure ? ""
, preBuild ? ""
, postInstall ? ""
, homepage ? "https://hackage.haskell.org/package/${pname}"
}:
stdenv.mkDerivation ({
  name = "${pname}-${version}";
  inherit src;
  outputs = [ "out" "data" "doc" ];

  buildInputs = [ jdk etlasWrapper buildHaskellPackages.eta-pkg ];

  propagatedBuildInputs = buildDepends ++ libraryHaskellDepends;

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
  '';
  prePatch = ''
    ETA_PATCH="${eta-hackage}/patches/${pname}-${version}.patch"
    if [ -e "$ETA_PATCH" ]; then
      patches=("$ETA_PATCH")
    fi
  '';
  postPatch = ''
    ETA_CABAL="${eta-hackage}/patches/${pname}-${version}.cabal"
    if [ -e "$ETA_CABAL" ]; then
      cp "$ETA_CABAL" "${pname}.cabal"
    fi
  '';
  # Etlas doesn't persist most configure flags.
  # We supply the flags for each step as a workaround for now.
  # https://github.com/typelead/etlas/issues/62
  configurePhase = ''
    runHook preConfigure

    # https://github.com/typelead/etlas/issues/63
    echo 'packages: .' > cabal.project

    etlas configure \
      --disable-tests \
      --allow-boot-library-installs
  '';
  # Supplying the flags will reconfigure, so install will build again,
  # let's just skip build for now.
  buildPhase = ''
    runHook preBuild

    # etlas build \
    #    --allow-boot-library-installs \
    #    --package-db="$packageConfDir"
  '';
  installPhase = ''
    etlas install \
       --libdir="$out/lib" \
       --datadir="$data/share/${buildHaskellPackages.eta.name}" \
       --docdir="$doc/share/doc/${pname}-${version}" \
       --allow-boot-library-installs \
       --package-db="$packageConfDir"

    packageConfDir="$out/lib/${buildHaskellPackages.eta.name}/package.conf.d"
    packageConfFile="$packageConfDir/${pname}-${version}.conf"
    mkdir -p "$packageConfDir"
    etlas register --gen-pkg-config=$packageConfFile

    mkdir -p $doc $data

    runHook postInstall
  '';
}
// stdenv.lib.optionalAttrs (preConfigure != "")   { inherit preConfigure; }
// stdenv.lib.optionalAttrs (preBuild != "")       { inherit preBuild; }
// stdenv.lib.optionalAttrs (postInstall != "")    { inherit postInstall; }
)
