# Flake for VR facial tracking.

Provides the following packages:

- [`baballonia`](https://github.com/Project-Babble/Baballonia)
- [`vrcft-avalonia`](https://github.com/dfgHiatus/VRCFaceTracking.Avalonia)
- [`babble-trainer`](https://github.com/Project-Babble/BabbleTrainer) (untested)

Packages are provided in CPU, CUDA, and ROCm variants:

```sh
nix run github:naraenda/nix-vrft#baballonia-cuda
nix run github:naraenda/nix-vrft#baballonia-rocm
nix run github:naraenda/nix-vrft#baballonia-cpu # No GPU support!
```

CUDA packages are built with [`cudaSupport = true`](https://wiki.nixos.org/wiki/CUDA#Enabling_CUDA_In_Packages).
ROCm support is experimental and currently untested.

Overlays do not provide multiple variants, e.g. only `baballonia` is provided.
The `pinned` overlay is recommended when using these packages as it builds them against this flake's pinned nixpkgs revision.
This avoids dependency mismatches, which are especially problematic for dotnet-based packages.

## Installing this flake

```nix
# flake.nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    # Include this repository as a flake.
    nix-vrft.url = "github:naraenda/nix-vrft";
  };

  outputs = { self, nixpkgs, nix-vrft }:
  let
    system = "x86_64-linux";

    pkgs = import nixpkgs {
      inherit system;

      config = {
        allowUnfree = true;
        cudaSupport = true;
        # Or for AMD:
        # rocmSupport = true;
      };
      
      overlays = [
        # Include this flake as an overlay.
        nix-vrft.overlays.pinned
      ];
    };
  in {
    # Use any of the exposed packages.
    # E.g. exporting it out of the flake again.
    packages.${system}.default = pkgs.baballonia;
  };
}
```

---

## Development

When updating any dotnet-based package, you can run the `deps-*.sh` script to update the locks on the NuGet packages.
