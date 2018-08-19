{ stdenv, jdk, unzip, zip }:

let
  javaScript = name: src: stdenv.mkDerivation {
    inherit name src;
    buildInputs = [ jdk unzip zip ];
    buildPhase = ''
      javac ${name}.java
    '';
    installPhase = ''
      jar cfm ${name}.jar manifest.txt ${name}.class
      . ${<nixpkgs/pkgs/build-support/release/functions.sh>}
      canonicalizeJar ${name}.jar

      mv ${name}.jar $out
    '';
  };
in
# Etlas will call out to a Coursier jar to figure out where jars are.
# We instead reference a jar which just dumps out an environment variable.
javaScript "FindMavenDepends" ./find-maven-depends
