{ stdenv, coursier }:

{ organisation
, module
, revision
, sha256
, repositories ? []
, preFetch ? null
, postFetch ? null
}:

# TODO: Coursier in nixpkgs is just a light wrapper which fetches Coursier
# Create a complete wrapper which includes the Coursier jar.
# Supposedly supported by Couriser:
# bash scripts/generate-launcher.sh -s
stdenv.mkDerivation {
  name = "${organisation}-${module}-${revision}";
  version = revision;

  nativeBuildInputs = [ coursier ];
  coursierFlags =
    map (s: "-r ${s}") repositories
    ++ ["${organisation}:${module}:${revision}"];
  inherit preFetch postFetch;
  builder = ./builder.sh;

  outputHashMode = "recursive";
  outputHashAlgo = "sha256";
  outputHash = sha256;

  preferLocalBuild = true;
}
