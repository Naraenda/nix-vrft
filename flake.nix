{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  };

  outputs =
    {
      nixpkgs,
      ...
    }:
    let
      forAllSystems = nixpkgs.lib.genAttrs [
        "x86_64-linux"
      ];

      mkPackages =
        pkgs:
        let
          mkPkg =
            module:
            {
              hasOptionalCudaSupport ? false,
              ...
            }@overrides:
            pkgs.callPackage module (
              {
                # We want to ensure these packages get built with the right support!
                enableCuda = pkgs.lib.warnIf (
                  hasOptionalCudaSupport && !pkgs.config.cudaSupport
                ) "${module}: This package works best with CUDA support enabled!" pkgs.config.cudaSupport;
              }
              // overrides
            ); # mkPkg
        in
        rec {
          vrcft-avalonia = mkPkg ./pkgs/vrcft-avalonia { };
          babble-trainer = mkPkg ./pkgs/babble-trainer {
            hasOptionalCudaSupport = true;
          };
          baballonia = mkPkg ./pkgs/baballonia {
            inherit babble-trainer;
            hasOptionalCudaSupport = true;
          }; # baballonia
        }; # mkPackages

      pinnedPkgs =
        system:
        import nixpkgs {
          inherit system;
          config = {
            allowUnfree = true;
            cudaSupport = true;
          }; # config
        }; # pkgs
    in
    {
      packages = forAllSystems (system: mkPackages (pinnedPkgs system));

      overlays = {
        # This does not work well with dotnet modules. Nix is
        # very picky about having the deps pinned.
        default = final: prev: mkPackages final;

        # This is the recommended overlay. All depedencies are
        # generated from this version.
        pinned = final: prev: mkPackages (pinnedPkgs final.system);
      }; # overlays
    }; # outputs
}
