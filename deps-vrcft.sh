#! /usr/bin/env sh
set -euxo pipefail
nix build .#vrcft-cpu.fetch-deps
./result ./pkgs/vrcft/deps.json
rm ./result
