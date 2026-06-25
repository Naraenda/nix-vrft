# Flake for VR facial tracking.

The packages in `packages` and the `pinned` overlay are built with CUDA support enabled ([`cudaSupport = true`](https://wiki.nixos.org/wiki/CUDA#Enabling_CUDA_In_Packages)).

AMD/ROCm support is untested. Baballonia needs to be fed the right flavor of the onnxruntime and I don't have a machine to test this on right now.

Provides the following packages:

- [`baballonia`](https://github.com/Project-Babble/Baballonia)
- [`vrcft-avalonia`](https://github.com/dfgHiatus/VRCFaceTracking.Avalonia)
- [`babble-trainer`](https://github.com/Project-Babble/BabbleTrainer) (untested)

Run it directly:

```sh
nix run github:naraenda/nix-vrft#baballonia
```

Installing this flake:

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
