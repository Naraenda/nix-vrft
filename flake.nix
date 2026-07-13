{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  };

  outputs =
    {
      self,
      nixpkgs,
      ...
    }:
    let
      lib = nixpkgs.lib;
      forAllSystems = lib.genAttrs [
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
                  hasOptionalCudaSupport && !pkgs.config.cudaSupport && !pkgs.config.rocmSupport
                ) "${module}: This package works best with CUDA/ROCM support enabled!" pkgs.config.cudaSupport;
                enableRocm = pkgs.config.rocmSupport;
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
          vrcft = mkPkg ./pkgs/vrcft { };
          etvr = mkPkg ./pkgs/etvr { };
        }; # mkPackages

      pinnedPkgs =
        system: config:
        import nixpkgs {
          inherit system config;
        }; # pkgs
    in
    {
      overlays = {
        # This does not work well with dotnet modules. Nix is
        # very picky about having the deps pinned.
        default = final: prev: mkPackages final;

        # This is the recommended overlay. All depedencies are
        # generated from this version.
        pinned = final: prev: mkPackages (pinnedPkgs final.system final.config);
      };

      packages = forAllSystems (
        system:
        let
          mkPkgs =
            config:
            self.overlays.pinned {
              inherit system config;
            } { };
          pkgs = mkPkgs {
            allowUnfree = true;
          };
          pkgsCuda = mkPkgs {
            allowUnfree = true;
            cudaSupport = true;
          };
          pkgsRocm = mkPkgs {
            allowUnfree = true;
            rocmSupport = true;
          };
        in
        pkgs
        // {
          baballonia-cuda = pkgsCuda.baballonia;
          baballonia-rocm = pkgsRocm.baballonia;
          babble-trainer-cuda = pkgsCuda.babble-trainer;
          babble-trainer-rocm = pkgsRocm.babble-trainer;
        }
      );

      nixosModules = {
        default =
          { ... }:
          {
            nixpkgs.overlays = [ self.overlays.default ];
          };
        pinned =
          { ... }:
          {
            nixpkgs.overlays = [ self.overlays.pinned ];
          };
      };
    }; # outputs
}
