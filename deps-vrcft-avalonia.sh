#! /usr/bin/env sh
set -euxo pipefail
nix build .#vrcft-avalonia.fetch-deps
./result ./pkgs/vrcft-avalonia/deps.json
rm ./result
