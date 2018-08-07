{ lib
, runCommandNoCC
, symlinkJoin
, makeWrapper
, buildHaskellPackages
, packages
}:
let
  paths = lib.closePropagation packages;
in
runCommandNoCC "eta-with-packages" {
  nativeBuildInputs = [ makeWrapper ];
  inherit paths;
} ''
  local packageConfDir="$out/lib/${buildHaskellPackages.eta.name}/package.conf.d";
  mkdir -p "$packageConfDir"

  for p in $paths; do
    if [ -d "$p/lib/${buildHaskellPackages.eta.name}/package.conf.d" ]; then
      cp -f "$p/lib/${buildHaskellPackages.eta.name}/package.conf.d/"*.conf "$packageConfDir/"
    fi
  done

  makeWrapper ${buildHaskellPackages.eta-pkg}/bin/eta-pkg $out/bin/eta-pkg \
    --set ETA_PACKAGE_PATH "$packageConfDir" \
    --add-flags "--global-package-db=$packageConfDir"

  makeWrapper ${buildHaskellPackages.eta}/bin/eta $out/bin/eta \
    --set ETA_PACKAGE_PATH "$packageConfDir"

  $out/bin/eta-pkg recache
  $out/bin/eta-pkg check
''
