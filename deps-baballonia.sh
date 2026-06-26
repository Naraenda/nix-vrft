#! /usr/bin/env sh
set -euxo pipefail
nix build .#baballonia-rocm.fetch-deps
./result ./pkgs/baballonia/deps.json
rm ./result
