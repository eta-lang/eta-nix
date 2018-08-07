#!/bin/sh

PATCHES="$1"

indent() {
  awk 'NR==1{print $0} NR>1{print "     " $0}'
}

packages() {
  ls $PATCHES/*.patch | sed -E 's|.*/(.*)-[^-]*|\1|g' | sort -u
}

latest() {
  NAME="$1"
  ls $PATCHES/$NAME-[0-9.]*.patch | sort -rV | head -n1
}

toNix() {
  NAME="$1"
  PACKAGE="$(basename "$2" .patch)"
  # FILE="$(echo "$2" | sed 's/\.patch$/.cabal/')"
  CABAL="$PATCHES/$PACKAGE.cabal"
  URL="$CABAL"
  if [ ! -e "$CABAL" ]; then
    URL="cabal://$PACKAGE"
  fi
  cat <<EOF
  "$NAME" = callPackage
    ($(cabal2nix --compiler ghc-7.10 "$URL" | indent)) {};

EOF
}

cat <<EOF
/* eta-hackage-packages.nix is an auto-generated file -- DO NOT EDIT! */
{ pkgs, stdenv, callPackage }:

self: {

$(for i in $(packages); do
  toNix "$i" "$(latest $i)"
done)

}
EOF
