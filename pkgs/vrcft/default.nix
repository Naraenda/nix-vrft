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
  vulkan-loader,
  wrapGAppsHook4,
  jq,
  moreutils,
  ...
}:
let
  dotnet = dotnetCorePackages.dotnet_10;

in
buildDotnetModule (finalAttrs: rec {

  src = fetchFromGitHub {
    owner = "benaclejames";
    repo = "VRCFaceTracking";
    rev = "07efd7dd3534092433df8c00cfe97e68477f560b"; # refactor/avalonia
    hash = "sha256-Ox2jyUyS0efkb291iu8NrqodeKtoL6MIQkFNzQAPL6A=";
    # hash = "sha256-Ox2jyUyS0efkb291iu8NrqodeKtoL6MIQkFNzQAPL6A=";
    fetchSubmodules = true;
  };

  version = "5.4.5.0";
  pname = "vrchatfacetracking";

  nugetDeps = ./deps.json;
  dotnet-sdk = dotnet.sdk;
  dotnet-runtime = dotnet.runtime;
  executables = [
    "VRCFaceTracking"
  ];
  projectFile = [
    "VRCFaceTracking/VRCFaceTracking.csproj"
  ];

  nativeBuildInputs = [
    autoPatchelfHook
    wrapGAppsHook4
    jq
    moreutils
  ];

  buildInputs = [
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
    vulkan-loader
    fontconfig
    icu
  ];

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
    install -m 444 -D $src/VRCFaceTracking/Assets/SmallTile.scale-400.png $out/share/icons/VRCFaceTracking.png
  ''; # postInstall

  postFixup = ''
    # Remove hard versioning requirement on icu.
    find $out -name '*.runtimeconfig.json' -exec sh -c '
      jq "del(.runtimeOptions.configProperties.\"System.Globalization.AppLocalIcu\")" "$1" | sponge "$1"
    ' sh {} \;

    # It's also important to CD to the library directory. It may try to do font discovery
    # through harfbuzz and fontconfig in the current working directory which may be
    # extremely slow when a networked drive is attached!
    mv $out/bin/VRCFaceTracking $out/bin/vrcft
    wrapProgram $out/bin/vrcft --run "cd $out/lib/vrchatfacetracking"
  '';

  meta = {
    platforms = lib.platforms.linux;
    homepage = "https://github.com/benaclejames/VRCFaceTracking";
    description = "OSC App to allow VRChat avatars to interact with eye and facial tracking hardware";
    mainProgram = "vrcft";
  };
}) # buildDotnetModule
