{
  fetchFromGitHub,
  fetchpatch2,
  fetchPypi,
  lib,
  makeWrapper,
  opencv4,
  pkg-config,
  python3,
  python3Packages,
  stdenv,
  ...
}:

let
  src = fetchFromGitHub {
    owner = "Project-Babble";
    repo = "BabbleTrainer";
    rev = "1.5.2";
    hash = "sha256-DBQ/Ez3W95QyyTjCtLBS924RJRuoXnu4vujQr9VQjlg=";
  };

  version = "1.3.8";

  pyPkgs = python3Packages;

  onnxscript = pyPkgs.buildPythonPackage rec {
    pname = "onnxscript";
    version = "0.6.2";
    format = "wheel";

    src = fetchPypi {
      inherit pname version format;
      python = "py3";
      dist = "py3";
      abi = "none";
      platform = "any";
      hash = "sha256-IOPD/R2hmzZVVJ1UVaLfcZ20c3T+Qw4B6GWuaRJ8N7k=";
    };

    dependencies = [
      onnx-ir
      pyPkgs.numpy
      pyPkgs.ml-dtypes
      pyPkgs.onnx
      pyPkgs.typing-extensions
    ];
  };

  onnx-ir = pyPkgs.buildPythonPackage rec {
    pname = "onnx-ir";
    version = "0.1.16";
    format = "wheel";

    src = fetchPypi {
      pname = "onnx_ir";
      inherit version format;

      python = "py3";
      dist = "py3";
      abi = "none";
      platform = "any";

      hash = "sha256-qBgvK6cWZAqv3RDFyXOgLipPfBDtV7awAKO+kOnqbTg=";
    };

    dependencies = [
      pyPkgs.numpy
      pyPkgs.ml-dtypes
      pyPkgs.onnx
      pyPkgs.typing-extensions
    ];
  };

  babble-data = pyPkgs.buildPythonPackage {
    pname = "babble_data";
    inherit version;

    src = "${src}/babble_data";

    pyproject = true;
    build-system = [
      pyPkgs.setuptools
    ];

    buildInputs = [
      pyPkgs.numpy
      (opencv4.override {
        enableGtk3 = true;
      })
    ];

    nativeBuildInputs = [
      pkg-config
    ];
  };

  pythonEnv = python3.withPackages (ps: [
    ps.torch
    ps.numpy
    ps.onnx
    ps.opencv-python
    ps.pillow
    ps.tqdm
    ps.torchvision

    # Missing nixpkgs deps
    onnxscript
    onnx-ir
    babble-data
  ]);

in
stdenv.mkDerivation {
  inherit version src;

  pname = "babble-trainer";

  nativeBuildInputs = [
    pythonEnv
    makeWrapper
  ];

  patches = [
    (fetchpatch2 {
      url = "https://github.com/Project-Babble/BabbleTrainer/commit/00b33f1f773c20340b03c006187172232261d3c2.diff?full_index=1";
      hash = "sha256-9C8UkUz3MlG67LCs8fTeetcHJ+qNhwBAtjKpoIendpE=";
    })
  ];

  buildPhase = ''
    mkdir -p $out/lib
    cp -r *.py $out/lib
  '';

  installPhase = ''
    mkdir -p $out/bin
    makeWrapper ${pythonEnv}/bin/python $out/bin/babble-trainer \
      --add-flags "$out/lib/main.py"
  '';

  meta = {
    platforms = lib.platforms.linux;
    description = "On-device B.A.B.A.L.L.S. trainer";
    homepage = "https://github.com/Project-Babble/BabbleTrainer";
    mainProgram = "babble-trainer";
  }; # meta
} # stdenv.mkDerivation
