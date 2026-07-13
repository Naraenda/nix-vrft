# Flake for VR facial tracking.

Provides the following packages:

- [`baballonia`](https://github.com/Project-Babble/Baballonia)
- [`vrcft`](https://github.com/benaclejames/VRCFaceTracking)
- [`vrcft-avalonia`](https://github.com/dfgHiatus/VRCFaceTracking.Avalonia)
- [`babble-trainer`](https://github.com/Project-Babble/BabbleTrainer)
- [`etvr`](https://github.com/EyeTrackVR/EyeTrackVR)

Packages are provided in CPU, CUDA, and ROCm variants:

```sh
nix run github:naraenda/nix-vrft#baballonia-cuda # Pinned to pkgsCuda.
nix run github:naraenda/nix-vrft#baballonia-rocm # Pinned to pkgsRocm.
nix run github:naraenda/nix-vrft#baballonia # No GPU support!
```

CUDA tested on a dedicated GPU (4090).
ROCm tested on an integrated GPU (9800x3D).

Overlays do not provide multiple variants, e.g. only `baballonia` is provided.
The `pinned` overlay is recommended when using these packages as it builds them against this flake's pinned nixpkgs revision.
This avoids dependency mismatches, which are especially problematic for dotnet-based packages.

## Installing this flake

The avalonia based apps want the Noto Sans font.
Ensure it's available:

```sh
fc-match "Noto Sans"
```

The flake can be installed as an overlay.

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
        # Important!
        allowUnfree = true;
      };
      
      overlays = [
        # Include this flake as an overlay.
        nix-vrft.overlays.pinned
      ];
    };
  in {
    # Use any of the exposed packages.
    # E.g. exporting it out of the flake again.
    packages.${system}.baballonia-cpu  = pkgs.baballonia;
    packages.${system}.baballonia-cuda = pkgs.pkgsCuda.baballonia;
    packages.${system}.baballonia-rocm = pkgs.pkgsRocm.baballonia;

    # EyeTrackVR:
    packages.${system}.etvr            = pkgs.etvr;

    # Recommended VRCFT:
    packages.${system}.vrcft           = pkgs.vrcft;

    # Legacy VRCFT:
    packages.${system}.vrcft-avalonia  = pkgs.vrcft-avalonia;
  };
}
```

---

## Development

When updating any dotnet-based package, you can run the `deps-*.sh` script to update the locks on the NuGet packages.
