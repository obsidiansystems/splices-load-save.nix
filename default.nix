#{ haskellLib, fetchFromGitHub, lib, splicedHaskellPackages, isExternalPlugin }: {
{ ghc }: {
  #loadSplices8_6 = import ./load-splices.nix { inherit haskellLib fetchFromGitHub lib splicedHaskellPackages isExternalPlugin; };
  loadSplices8_10 = null;
  saveSplices = null;

  ghc810patched = ghc.overrideAttrs (old: {
    patches = (old.patches or [ ]) ++ [
      ./blank.patch
    ];
  });

}
