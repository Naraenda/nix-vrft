{
  config,
  lib,
  stdenv,
  cmake,
  fetchFromGitHub,
  opencv,
  cudaPackages,
  enableCuda ? config.cudaSupport,
  ...
}:
stdenv.mkDerivation rec {
  pname = "opencvsharp";
  version = "4.13.0.20260602";

  src = fetchFromGitHub {
    owner = "shimat";
    repo = "opencvsharp";
    tag = version;
    hash = "sha256-NeFfuSgNZjZnA23iVOvFJCWDoSzip8FtJVz22cBRvzg=";
  };
  sourceRoot = "${src.name}/src";

  patches = [
    # ./cvsharp-cv4-compat.patch
  ];

  buildInputs = [ opencv ] ++ lib.optionals enableCuda [ cudaPackages.cudatoolkit ];

  nativeBuildInputs = [ cmake ];

  cmakeFlags = [
    (lib.cmakeFeature "CMAKE_POLICY_VERSION_MINIMUM" "3.5")
    (lib.cmakeBool "NO_ML" true)
    (lib.cmakeBool "NO_DNN" true)
  ]
  ++ lib.optionals enableCuda [ "-DCUDAToolkit_ROOT=${cudaPackages.cudatoolkit}" ];
} # stdenv.mkDerivation
