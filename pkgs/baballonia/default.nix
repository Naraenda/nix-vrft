{
  babble-trainer,
  buildDotnetModule,
  callPackage,
  cmake,
  config,
  copyDesktopItems,
  dotnetCorePackages,
  enableCuda ? config.cudaSupport,
  fetchFromGitHub,
  fetchpatch,
  fetchurl,
  fontconfig,
  lib,
  libGL,
  libice,
  libjpeg,
  libsm,
  libusb1,
  libuvc,
  libv4l,
  libx11,
  libxcb,
  libxcursor,
  libxext,
  libxi,
  libxkbcommon,
  makeDesktopItem,
  onnxruntime,
  opencv,
  pkgsCuda, # Packages configured with 'config.cudaSupport = true'.
  steam-run,
  udev,
  unzip,
  ...
}:
let
  opencvsharp = callPackage ./opencvsharp { inherit enableCuda; };

  calibZip = fetchurl {
    url = "https://github.com/Project-Babble/BabbleCalibration/releases/download/1.0.8/Linux.zip";
    hash = "sha256-ytKGg+qVZwHtZUWfJwesvodjIjhffortX6zPs7nWBpU=";
    executable = true;
  };
  dotnet = dotnetCorePackages.dotnet_10;
in
buildDotnetModule (finalAttrs: rec {
  version = "1.1.1.0-rc6";
  pname = "baballonia";

  src = fetchFromGitHub {
    owner = "Project-Babble";
    repo = "Baballonia";
    rev = "v1.1.1.0rc6";
    hash = "sha256-3A2HjdMOHJvLDqAU43AUtwV5y/t6C4UyVtxoRPvFJPU=";
    fetchSubmodules = true;
  };

  projectFile = "src/Baballonia.Desktop/Baballonia.Desktop.csproj";
  nugetDeps = ./deps.json;
  dotnet-sdk = dotnet.sdk;
  dotnet-runtime = dotnet.runtime;

  patches = [
    # Remove VCPKG dependancy on "Microsoft.ML.OnnxRuntime" in favor of using the native onnx runtime provided locally
    (fetchpatch {
      url = "https://github.com/Project-Babble/Baballonia/commit/1c60dbffab7fa1689d8a441ff52bfd4b0cfecc0c.diff";
      hash = "sha256-k4vTgKgKJg595502TPujEDZIIv6UhZjt23AzPd2IW0s=";
    })
  ]; # patches

  nativeBuildInputs = [
    copyDesktopItems
    unzip
  ];

  buildInputs = [
    cmake
    fontconfig
    libGL
    libice
    libjpeg
    libsm
    libusb1
    libuvc
    libx11
    opencv
    opencvsharp
    udev
  ]; # buildInputs

  runtimeDependencies = [
    libGL
    libusb1
    libuvc
    libv4l
    libxcb
    libxcursor
    libxext
    libxi
    libxkbcommon
    opencvsharp
    udev
  ]
  ++ lib.optionals (!enableCuda) [
    onnxruntime
  ]
  ++ lib.optionals enableCuda [
    pkgsCuda.onnxruntime
  ]; # runtimeDependencies

  postUnpack = ''
    unzip ${calibZip} -d $sourceRoot/src/Baballonia.Desktop/Calibration/Linux/Overlay
    ln -s ${babble-trainer}/bin/babble-trainer $sourceRoot/src/Baballonia.Desktop/Calibration/Linux/Trainer/BabbleTrainer
  ''; # postUnpack

  postFixup =
    let
      # The internal calibration tool. We need to wrap this so it launches properly.
      calibTool = "$out/lib/baballonia/Calibration/Linux/Overlay/BabbleCalibration.x86_64";
      runtimeLibPath = lib.makeLibraryPath finalAttrs.runtimeDependencies;
    in
    ''
      # Clear out bin folder, we'll link since some of these may need
      # to be wrapped. We'll also want to rename them for consistency's
      # sake.
      rm $out/bin/*

      wrapDotnetProgram \
        $out/lib/baballonia/Baballonia.Desktop \
        $out/bin/baballonia

      # 'onnxruntime' does automatically load 'libnvrtc'this is fixed in version 1.27.0.
      wrapProgram $out/bin/baballonia \
        --prefix LD_LIBRARY_PATH : ${runtimeLibPath} \
        --prefix LD_PRELOAD : "${pkgsCuda.cudaPackages.cuda_nvrtc.lib}/lib/libnvrtc.so.12"

      # Godot applications requires steam-run for whatever reason.
      # I'm too lazy to figure out what part of the FSH it needs.
      # https://nixos.wiki/wiki/Godot
      #
      # Create a backup of the original.
      mv ${calibTool} ${calibTool}-original
      # And wrap it!
      makeWrapper ${steam-run}/bin/steam-run \
        ${calibTool} \
        --add-flags ${calibTool}-original \
        --add-flags --xr-mode \
        --add-flags on \
        --set XR_LOADER_DEBUG all

      # Actually export our binaries.
      ln -s ${calibTool} $out/bin/babble-calibration

      # Move dll files to Modules that it wants there instead
      mkdir -p $out/lib/baballonia/Modules
      mv $out/lib/baballonia/Baballonia.*Capture.dll $out/lib/baballonia/Modules/
    ''; # postFixup


  desktopEntry = makeDesktopItem {
    name = finalAttrs.pname;
    desktopName = "Baballonia";
    comment = finalAttrs.meta.description;
    exec = "${finalAttrs.meta.mainProgram} %u";
    terminal = false;
    type = "Application";
    icon = "baballonia";
    categories = [ "Game" ];
  }; # desktopEntry

  postInstall = ''
    mkdir -p $out/share/applications $out/share/icons
    install -m 444 -D ${desktopEntry}/share/applications/${finalAttrs.pname}.desktop $out/share/applications/${finalAttrs.pname}.desktop
    install -m 444 -D $src/src/Baballonia/Assets/Icon_512x512.png $out/share/icons/baballonia.png
  ''; # postInstall

  meta = {
    platforms = lib.platforms.linux;
    homepage = "https://github.com/Project-Babble/Baballonia";
    description = "Free and open source eye and face tracking for social VR";
    mainProgram = "baballonia";
  }; # meta
}) # buildDotnetModule
