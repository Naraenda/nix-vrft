#! /usr/bin/env sh
set -euxo pipefail
nix build .#baballonia-cpu.fetch-deps
./result ./pkgs/baballonia/deps.json
rm ./result
