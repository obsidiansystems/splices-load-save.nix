{ pkgs }: rec {
  # NOTE: Set pkgs to what is relevant in what you're working with, either set it to your local nixpkgs or 
  #set it to "self" or "super" from global overlays

  # NOTE: Pull in needed lib functions for the nix-files
  haskellLib = pkgs.haskell.lib;
  lib = pkgs.lib;
  fetchFromGitHub = pkgs.fetchFromGitHub;

  # NOTE: provider some nice helper functions
  makeRecursivelyOverridable = x: x // {
    override = new: makeRecursivelyOverridable (x.override (old: (combineOverrides old new)));
  };

  combineOverrides = old: new: old // new // lib.optionalAttrs (old ? overrides && new ? overrides) {
    overrides = lib.composeExtensions old.overrides new.overrides;
  };

  makeRecursivelyOverridableBHPToo = x: x // {
    override = new: makeRecursivelyOverridableBHPToo (x.override
      (combineOverrides
        {
          overrides = self: super: {
            buildHaskellPackages = super.buildHaskellPackages.override new;
          };
        }
        new));
  };

  # NOTE: GHC 8.6.* doesn't support "external" plugins the way we want, so we disable the flag
  loadSplices8_6 = splicedpkgs: import ./load-splices.nix {
    inherit haskellLib lib fetchFromGitHub;
    isExternalPlugin = false;
    splicedHaskellPackages = splicedpkgs;
  };

  # NOTE: GHC 8.10.*+ supports "external" plugins, enable the flag
  # NOTE: Use this for GHCJS
  loadSplices8_10 = splicedpkgs: import ./load-splices.nix {
    inherit haskellLib lib fetchFromGitHub;
    isExternalPlugin = true;
    splicedHaskellPackages = splicedpkgs;
  };

  # NOTE: Same for any version of GHC with the splices plugin
  # NOTE: Pass a version string or "pkgs.haskell.compiler.ghc*.version"
  saveSplices = ghc: import ./save-splices.nix {
    inherit haskellLib lib fetchFromGitHub;
    ghcVersion = ghc;
  };


  # Generating patches with git diff for ghc
  # Make sure to fetch submodules first!
  # 8.10.7: git diff <commit> <commit> ':!.gitmodules' --submodule=diff
  # 8.6.5: git diff <commit> <commit> ':!.gitmodules' ':!compiler/parser/Parser.y' --submodule=diff
  # TODO: possibly add a way for user to provide own patches?
  # NOTE: patchGHC usage:
  # patchGhc (ghc.package);
  patchGHC = ghc: ver:
    ghc.overrideAttrs (old: {
      patches = (old.patches or [ ]) ++ [
        (./. + "/patches/${ver}/splices.patch")
      ];
    });

  patchGHCJS = ghcjs: ghcjs.override {
    ghcjsSrcJson = ./patches/ghcjs/git.json;
  };
}
