source $stdenv/setup

export COURSIER_CACHE=$(pwd)

runHook preFetch

coursier \
  fetch \
  -A jar \
  --intransitive \
  $coursierFlags \
  > deps

DIR="$out/share/java"
mkdir -p "$DIR"
mv $(< deps) "$DIR/"

runHook postFetch
