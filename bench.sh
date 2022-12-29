#! /usr/bin/env bash
set -eu;
set -o pipefail

: "${NIX:=nix}";
: "${NIXPKGS_REF:=nixpkgs}";
: "${COUNT:=1000}";

# Ensure dependencies are built first.
$NIX build --no-link      \
  $NIXPKGS_REF#bash       \
  $NIXPKGS_REF#coreutils  \
  $NIXPKGS_REF#stdenv     \
;

echo "mkDerivation x $COUNT:" >&2;
time $NIX build --no-link --arg count "$COUNT" -f ./. mkDerivations;
echo '' >&2;

echo "derivation x $COUNT:" >&2;
time $NIX build --no-link --arg count "$COUNT" -f ./. derivations;
