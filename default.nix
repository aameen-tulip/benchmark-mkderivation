# ============================================================================ #
#
# Benchmark performance of a trivial build using `stdenv.mkDerivation' vs. a
# plain `derivation'.
#
# This build simply calls `touch' on `$out'.
# Setting the argument `count' controls the number of builds to be tested.
#
# The outputs of this expression are two derivations which depend on `count'
# inputs using `stdenv.mkDerivation' and `derivation' respectively.
#
#
# ---------------------------------------------------------------------------- #

{ nixpkgs      ? builtins.getFlake "nixpkgs"
, system       ? builtins.currentSystem
, lib          ? nixpkgs.lib
, pkgsFor      ? nixpkgs.legacyPackages.${system}
, mkDerivation ? pkgsFor.stdenv.mkDerivation
, bash         ? pkgsFor.bash
, coreutils    ? pkgsFor.coreutils
, count        ? 1000
, timestamp    ? toString builtins.currentTime  # Used to invalidate past runs
}: let

# ---------------------------------------------------------------------------- #

  withMkDerivation = n: mkDerivation {
    name             = "mkDerivation-benchmark-${toString n}-${timestamp}";
    unpackPhase      = ":";
    installPhase     = "touch \"$out\";";
    dontPatch        = true;
    dontConfigure    = true;
    dontBuild        = true;
    dontFixup        = true;
    allowSubstitutes = ( builtins.currentSystem or "unknown" ) != system;
    preferLocalBuild = true;
  };


# ---------------------------------------------------------------------------- #

  withDerivation = n: derivation {
    name             = "derivation-benchmark-${toString n}-${timestamp}";
    builder          = "${coreutils}/bin/touch";
    args             = [( builtins.placeholder "out" )];
    allowSubstitutes = ( builtins.currentSystem or "unknown" ) != system;
    preferLocalBuild = true;
    inherit system;
  };


# ---------------------------------------------------------------------------- #

  joinDrvs = { name, drvs }: derivation {
    name       = name + "-${timestamp}";
    builder    = "${bash}/bin/bash";
    deps       = builtins.concatStringsSep "\n" drvs;
    passAsFile = ["deps"];
    args       = ["-euc" ''
      while read -r line; do
        echo "$line" >> "$out";
      done <"$depsPath";
    ''];
    allowSubstitutes = ( builtins.currentSystem or "unknown" ) != system;
    preferLocalBuild = true;
    inherit system;
  };


# ---------------------------------------------------------------------------- #

in {

  mkDerivations = joinDrvs {
    name = "all-mkDerivations-${toString count}";
    drvs = builtins.genList withMkDerivation count;
  };

  derivations = joinDrvs {
    name = "all-derivations-${toString count}";
    drvs = builtins.genList withDerivation count;
  };

}

# ---------------------------------------------------------------------------- #
#
#
#
# ============================================================================ #
