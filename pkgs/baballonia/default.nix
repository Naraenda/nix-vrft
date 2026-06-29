{
  babble-trainer,
  buildDotnetModule,
  cmake,
  config,
  copyDesktopItems,
  dotnetCorePackages,
  enableCuda ? config.cudaSupport,
  enableRocm ? config.rocmSupport,
  fetchFromGitHub,
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
  cudaPackages,
  steam-run,
  udev,
  unzip,
  gst_all_1,
  glib,
  openxr-loader,
  ...
}:
let
  calibZip = fetchurl {
    url = "https://github.com/Project-Babble/BabbleCalibration/releases/download/1.0.8/Linux.zip?dummy=1";
    hash = "sha256-chNGgZUbJdI85QDDBJi9rfc6JoZPHO/wYRCH+5MR+Y8=";
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
    rev = "fa739149a196dbfc23396a42a7430a806a5ba261"; # expr-opt
    hash = "sha256-lijsJnI49Y7JytF5xA/Sn1GJHHbEu1fXF4yYbJM+UPU=";
    fetchSubmodules = true;
  };

  projectFile = "src/Baballonia.Desktop/Baballonia.Desktop.csproj";
  nugetDeps = ./deps.json;
  dotnet-sdk = dotnet.sdk;
  dotnet-runtime = dotnet.runtime;

  # This patch changes the required onnxruntime to the exact
  # same version as the one provisioned by nixpkgs.
  patches = [
    ./onnxruntime-version.patch
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
    onnxruntime # Will be transitively be built with CUDA or ROCm support.
    udev
    fontconfig
    glib
    gst_all_1.gstreamer
    gst_all_1.gst-plugins-base
    gst_all_1.gst-plugins-good
    openxr-loader
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
      ${dotnet.sdk}/bin/dotnet nuget why Microsoft.ML.OnnxRuntime.Managed > $out/share/meow.txt

      # Clear out bin folder, we'll link since some of these may need
      # to be wrapped. We'll also want to rename them for consistency's
      # sake.
      rm $out/bin/*

      wrapDotnetProgram \
        $out/lib/baballonia/Baballonia.Desktop \
        $out/bin/baballonia

      # It's also important to CD to the library directory. It may try to do font discovery
      # through harfbuzz and fontconfig in the current working directory which may be
      # extremely slow when a networked drive is attached!
      #
      # 'onnxruntime' does not automatically load 'libnvrtc' this is fixed in version 1.27.0.
      wrapProgram $out/bin/baballonia \
        --run "cd $out/lib/baballonia" \
        --prefix LD_LIBRARY_PATH : ${runtimeLibPath} \
        ${lib.optionalString enableCuda ''
          --prefix LD_PRELOAD : "${cudaPackages.cuda_nvrtc.lib}/lib/libnvrtc.so.12" \
        ''}

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
