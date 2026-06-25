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
  version = "4.11.0.20250507";

  src = fetchFromGitHub {
    owner = "shimat";
    repo = "opencvsharp";
    tag = version;
    hash = "sha256-CkG4Kx/AkZqyhtclMfS51a9a9R+hsqBRlM4fry32YJ0=";
  };
  sourceRoot = "${src.name}/src";

  patches = [
    ./cvsharp-cv4-compat.patch
  ];

  buildInputs = [ opencv ] ++ lib.optionals enableCuda [ cudaPackages.cudatoolkit ];

  nativeBuildInputs = [ cmake ];

  cmakeFlags = [
    (lib.cmakeFeature "CMAKE_POLICY_VERSION_MINIMUM" "3.5")
  ]
  ++ lib.optionals enableCuda [ "-DCUDAToolkit_ROOT=${cudaPackages.cudatoolkit}" ];
} # stdenv.mkDerivation
