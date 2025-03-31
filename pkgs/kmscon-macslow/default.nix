{
  lib,
  callPackage,
  stdenv,
  fetchFromGitHub,
  meson,
  systemdLibs,
  libxkbcommon,
  libdrm,
  libGLU,
  libGL,
  pango,
  pixman,
  pkg-config,
  docbook_xsl,
  libxslt,
  mesa,
  ninja,
  check,
  buildPackages,
}:

stdenv.mkDerivation {
  pname = "kmscon";
  version = "978c416";

  src = fetchFromGitHub {
    owner = "MacSlow";
    repo = "kmscon";
    rev = "978c416a01e80effe64b9a5d31233ade4de2d11b";
    sha256 = "sha256-+M1hfhhnwGi4hkO7hug5Gi1xQqMFM8DuNCMYu8EcWew=";
  };

  strictDeps = true;

  depsBuildBuild = [
    buildPackages.stdenv.cc
  ];

  buildInputs = [
    libGLU
    libGL
    libdrm
    (callPackage ../libtsm { })
    libxkbcommon
    pango
    pixman
    systemdLibs
    mesa
    check
  ];

  nativeBuildInputs = [
    meson
    ninja
    docbook_xsl
    pkg-config
    libxslt # xsltproc
  ];

  # _FORTIFY_SOURCE requires compiling with optimization (-O)
  env.NIX_CFLAGS_COMPILE =
    lib.optionalString stdenv.cc.isGNU "-O" + " -Wno-error=maybe-uninitialized"; # https://github.com/Aetf/kmscon/issues/49

  configureFlags = [
    "--enable-multi-seat"
    "--disable-debug"
    "--enable-optimizations"
    "--with-renderers=bbulk,gltex,pixman"
  ];

  enableParallelBuilding = true;

  patches = [
    ./sandbox.patch # Generate system units where they should be (nix store) instead of /etc/systemd/system
  ];

  meta = with lib; {
    description = "KMS/DRM based System Console";
    mainProgram = "kmscon";
    homepage = "https://www.freedesktop.org/wiki/Software/kmscon/";
    license = licenses.mit;
    maintainers = with maintainers; [ omasanori ];
    platforms = platforms.linux;
  };
}
