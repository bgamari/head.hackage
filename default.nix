# Build head.hackage packages
#
# Usage:
#   Build using nixpkgs' ghcHEAD:
#       nix build -f ./.
#
#   Build using GHC built from source tree $GHC_TREE:
#       nix build -f --arg ghc "(import build.nix {ghc-path=$GHC_TREE;})"
#
let
  baseNixpkgs = (import <nixpkgs> {}).fetchFromGitHub {
    owner = "nixos";
    repo = "nixpkgs";
    rev = "140ad12d71c57716b3ee3b777d53c27b019360f0";
    sha256 = null;
  };
in

# ghc: path to a GHC source tree
{ ghc ? import ./ghc.nix }:

let
  jailbreakOverrides = self: super: {
    mkDerivation = drv: super.mkDerivation (drv // { jailbreak = true; doCheck = false; });
  };

  overrides = self: super: rec {
    all-cabal-hashes = self.fetchurl (import ./all-cabal-hashes.nix);

    # Should this be self?
    ghcHEAD = ghc super;

    haskellPackages =
      let patchesOverrides = self.callPackage patches {};
          patches = self.callPackage (import ./scripts/overrides.nix) { patches = ./patches; };
          overrides = self.lib.composeExtensions patchesOverrides jailbreakOverrides;

          baseHaskellPackages = self.callPackage "${baseNixpkgs}/pkgs/development/haskell-modules" {
            haskellLib = import "${baseNixpkgs}/pkgs/development/haskell-modules/lib.nix" {
              inherit (self) lib;
              pkgs = self;
            };
            buildHaskellPackages = haskellPackages; #self.buildPackages.haskell.packages.ghc843;
            ghc = ghcHEAD;
            compilerConfig = self1: super1: {
              # Packages included in GHC's global package database
              Cabal = null;
              array = null;
              base = null;
              binary = null;
              bytestring = null;
              containers = null;
              deepseq = null;
              directory = null;
              filepath = null;
              ghc-boot = null;
              ghc-boot-th = null;
              ghc-compact = null;
              ghc-prim = null;
              ghci = null;
              haskeline = null;
              hpc = null;
              integer-gmp = null;
              integer-simple = null;
              mtl = null;
              parsec = null;
              pretty = null;
              process = null;
              rts = null;
              stm = null;
              template-haskell = null;
              text = null;
              time = null;
              transformers = null;
              unix = null;

              doctest = haskellPackages.callPackage ./doctest.nix {};
              http-api-data = haskellPackages.callPackage ./http-api-data.nix {};

              jailbreak-cabal = self.haskell.packages.ghc802.jailbreak-cabal;
            };
          };
      in baseHaskellPackages.extend overrides;
  };
in import baseNixpkgs { overlays = [ overrides ]; }
