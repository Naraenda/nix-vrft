{
  fetchFromGitHub,
  fetchPypi,
  lib,
  makeWrapper,
  python3,
  python3Packages,
  stdenv,
  eigen,
  openxr-loader,
  vulkan-headers,
  vulkan-loader,
  stb,
  cmake,
  gcc,
  ...
}:

let
  src = fetchFromGitHub {
    owner = "EyeTrackVR";
    repo = "EyeTrackVR";
    rev = "EyeTrackApp-0.3.0-BETA-9";
    hash = "sha256-wA8jP+19bBuY0afa4AeY7K/DqeGSaTHN1yL4nBnBWGU=";
  };

  version = "0.3.0";

  pyPkgs = python3Packages;

  pye3d = pyPkgs.buildPythonPackage rec {
    pname = "pye3d";
    version = "0.3.2";
    format = "setuptools";
    doCheck = false;

    src = fetchPypi {
      inherit pname version format;
      hash = "sha256-Enk90LKSZTklLWsrqd9rDBd0lHoAdmGywWcO9zyQUzk=";
    };

    nativeBuildInputs = with pyPkgs; [
      setuptools
      wheel
      scikit-build
      cmake
      ninja
      numpy
      cython
      setuptools-scm
    ];

    buildInputs = [
      eigen
    ];

    configurePhase = "
      # Skipped!
    ";

    dependencies = with pyPkgs; [
      msgpack
      numpy
      sortedcontainers
    ];
  };

  pythonEnv = python3.withPackages (ps: with ps; [
    python-osc
    requests
    opencv-python
    numpy
    pye3d
    sv-ttk
    pydantic
    scikit-image
    scikit-learn
    pyserial
    colorama
    # taskipy
    pytest
    pytest-cov
    matplotlib
    numba
    onnxruntime
  ]);

  calibration-overlay = stdenv.mkDerivation {
    name = "EyeTrackVR-OpenVR-Calibration-Overlay";
    src = fetchFromGitHub {
      owner = "RedHawk989";
      repo = "EyeTrackVR-OpenVR-Calibration-Overlay";
      rev = "cb1b2e5932b76291561c31c1025c1b89e9c4f08c"; # main
      fetchSubmodules = true;
      hash = "sha256-eRku0/rTAJNSxToY8lR3e+2VbuPn1KAUlDxWW23Vfr0=";
    };

    nativeBuildInputs = [
      cmake
    ];

    buildInputs = [
      openxr-loader
      vulkan-headers
      vulkan-loader
      stb
    ];
    
    cmakeFlags = [
      "-DCMAKE_BUILD_TYPE=Release"
      "-DSTB_INCLUDE_DIR=${stb}/include/stb"
    ];

    installPhase =''
      runHook preInstall
      mkdir -p $out/lib
      cp EyeTrackVR-Overlay $out/lib/EyeTrackVR-Overlay
      cp -r assets $out/lib/assets
      runHook postInstall
    '';

    meta = {
      platforms = lib.platforms.linux;
    };
  };
in
stdenv.mkDerivation {
  inherit version src;

  pname = "etvr";

  nativeBuildInputs = [
    pythonEnv
    makeWrapper
  ];

  buildInputs = [
    calibration-overlay
  ];

  buildPhase = ''
    ls -la
    mkdir -p $out/lib
    cp -r EyeTrackApp $out/lib
    cp -r ${calibration-overlay}/lib/* $out/lib/EyeTrackApp/Tools/
  '';

  installPhase = ''
    mkdir -p $out/bin
    makeWrapper ${pythonEnv}/bin/python $out/bin/etvr \
      --add-flags "$out/lib/EyeTrackApp/eyetrackapp.py"
  '';

  meta = {
    platforms = lib.platforms.linux;
    description = "Free and Affordable, Virtual Reality Eye Tracking Platform. ";
    homepage = "https://github.com/Project-Babble/BabbleTrainer";
    mainProgram = "etvr";
  }; # meta
} # stdenv.mkDerivation
