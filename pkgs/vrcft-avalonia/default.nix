{
  autoPatchelfHook,
  buildDotnetModule,
  dotnetCorePackages,
  fetchFromGitHub,
  fontconfig,
  icu,
  krb5,
  lib,
  libice,
  libsm,
  libx11,
  makeDesktopItem,
  openssl,
  pkg-config,
  rustPlatform,
  vulkan-loader,
  wrapGAppsHook4,
  ...
}:
let
  dotnet = dotnetCorePackages.dotnet_8;

  src = fetchFromGitHub {
    owner = "dfgHiatus";
    repo = "VRCFaceTracking.Avalonia";
    rev = "v1.1.1.0";
    hash = "sha256-Fx4+SL5E0CX5Qr1R1aq/CrpD0/+FIFKU+CHVRsLI09k=";
    fetchSubmodules = true;
  };

  simple-rust-osc = rustPlatform.buildRustPackage {
    name = "SimpleRustOSC";

    src = "${src}/src/SimpleRustOSC";

    cargoLock.lockFile = ./Cargo.lock;
    postPatch = ''
      ln -s ${./Cargo.lock} Cargo.lock
    '';

    meta = {
      platforms = lib.platforms.unix;
      license = lib.licenses.unlicense;
      homepage = "https://github.com/benaclejames/SimpleRustOSC";
      description = "A simple one-file OSC library with C exports made in Rust.";
    }; # meta
  }; # simple-rust-osc
in
buildDotnetModule (finalAttrs: rec {
  inherit src;

  version = "1.1.1.0";
  pname = "vrchatfacetracking";

  nugetDeps = ./deps.json;
  dotnet-sdk = dotnet.sdk;
  dotnet-runtime = dotnet.runtime;
  executables = [ "VRCFaceTracking.Avalonia.Desktop" ];
  projectFile = [
    "src/VRCFaceTracking.Avalonia.Desktop/VRCFaceTracking.Avalonia.Desktop.csproj"
  ];

  nativeBuildInputs = [
    autoPatchelfHook
    wrapGAppsHook4
  ];

  buildInputs = [
    simple-rust-osc
    pkg-config
    fontconfig
    openssl
    icu
    krb5
    libx11
    libsm
    libice
  ];

  runtimeDependencies = [
    simple-rust-osc
    vulkan-loader
  ];

  postUnpack = ''
    # I don't know why but it but it really doesn't like this nuget.config file
    rm $sourceRoot/Nuget.Config
  '';

  postFixup = ''
    mv $out/bin/VRCFaceTracking.Avalonia.Desktop $out/bin/vrcft-avalonia
    wrapProgram $out/bin/vrcft-avalonia --set LD_LIBRARY_PATH ${lib.makeLibraryPath runtimeDependencies}
  '';

  dotnetInstallFlags = ["--framework net8.0"];

  desktopEntry = makeDesktopItem {
    name = finalAttrs.pname;
    desktopName = "VRCFaceTracking";
    comment = finalAttrs.meta.description;
    exec = "${finalAttrs.meta.mainProgram} %u";
    terminal = false;
    type = "Application";
    icon = "VRCFaceTracking";
    categories = [ "Game" ];
  }; # desktopEntry

  postInstall = ''
    mkdir -p $out/share/applications $out/share/icons
    install -m 444 -D ${desktopEntry}/share/applications/${finalAttrs.pname}.desktop $out/share/applications/${finalAttrs.pname}.desktop
    install -m 444 -D $src/src/VRCFaceTracking.Avalonia/Assets/VRCFT-logo-150.png $out/share/icons/VRCFaceTracking.png
  ''; # postInstall

  meta = {
    platforms = lib.platforms.linux;
    homepage = "https://github.com/dfgHiatus/VRCFaceTracking.Avalonia";
    description = "Cross-platform VRCFaceTracking made with Avalonia";
    mainProgram = "vrcft-avalonia";
  };
}) # buildDotnetModule
