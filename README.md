# splices-load-save.nix
Splices for Haskell, decoupled from reflex-platform, with helper functions in nix, along with patches available for easy patching of GHC

# Overview

## Who Should consider using this?
* Anyone that wants to build code that uses template haskell for platforms where template haskell isn't supported (e.g., mobile)
* Anyone that wants/needs splices for GHCJS (if, e.g., you're encountering slow GHCJS template haskell compilation times)

## Caveats
* Most libraries must be built twice, once for the platform dumping the splices and once for the platform that will load the splices
  * This is mitigated by having a nix cache setup that already has these spliced libraries built
* More than likely you will have to build the patched GHC 

# How to use
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
            ghcjsSplices8_10 = (splices-func.patchGHCJS self.haskell.compiler.ghcjs810);
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
