# splices-load-save.nix
Splices for Haskell, decoupled from reflex-platform, with helper functions in nix, along with patches available for easy patching of GHC

# Overview

## Who Should consider using this?
* Anyone that doesn't need all of the features of reflex-platform, and just needs a relatively easy way to pull up splices on a non-reflex project.
* Anyone that wants/needs splices for GHCJS

## How to use
### GHC & GHCJS:
```nix
(self: super: let
    foldExtensions = super.lib.foldr super.lib.composeExtensions (_: _: { });
    splices-load-save-nix = super.fetchFromGitHub {
        owner = "obsidiansystems";
        repo = "splices-load-save.nix";
        rev = "...(latest)";
        sha256 = "";
    };
  splices-func = import splices-load-save-nix {
    pkgs = super;
  };
in
rec {
    saves = splices-func.saveSplices super.haskell.packages.ghc8107.version;
    loads = splices-func.loadSplices8_10 self.haskell.packages.ghcSplices8_10;
    ghcSplices8_10 = (splices-func.makeRecursivelyOverridable super.haskell.packages.ghc8107).override rec {
        overrides = foldExtensions [
            saves
        ];
    };
    ghcjsSplices8_10 = (splices-func.makeRecursivelyOverridable super.haskell.packages.ghcjs810).override rec {
        overrides = foldExtensions [
            loads
        ];
    };
    haskell = super.haskell // {
        compiler = super.haskell.compiler // {
            ghcSplices8_10 = (splices-func.patchGHC (self.haskell.compiler.ghc8107) self.haskell.compiler.ghc8107.name);
            ghcSplices8_10 = (splices-func.patchGHC (self.haskell.compiler.ghc8107) self.haskell.compiler.ghc8107.name);
        };

        packages = super.haskell.packages // {
            ghcSplices8_10 = ghcSplices8_10.override {
                ghc = self.haskell.compiler.ghcSplices8_10;
                buildHaskellPackages = self.buildPackages.haskell.packages.ghcSplices8_10;
            };
            ghcjsSplices8_10 = ghcjsSplices8_10.override {
                ghc = self.haskell.compiler.ghcjsSplices8_10;
                buildHaskellPackages = self.buildPackages.haskell.packages.ghcjsSplices8_10;
            };
        };
    };
})
```     
