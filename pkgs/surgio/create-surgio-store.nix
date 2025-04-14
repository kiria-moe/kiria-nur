{
  lib,
  stdenv,
  fetchFromGitHub,
  fetchYarnDeps,
  yarnConfigHook,
  yarnInstallHook,
  nodejs,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "create-surgio-store";
  version = "3.1.0";

  src = fetchFromGitHub {
    owner = "surgioproject";
    repo = finalAttrs.pname;
    rev = "v${finalAttrs.version}";
    hash = "sha256-iBWilZR47SRGUBgoLlnPv1NCbv8YSpHAs3wDLFrEuKk=";
  };

  patches = [ ./npm.patch ];

  postPatch = ''
    substituteInPlace createSurgioStore.js --replace /bin/npm ${nodejs}/bin/npm
  '';

  yarnOfflineCache = fetchYarnDeps {
    yarnLock = finalAttrs.src + "/yarn.lock";
    hash = "sha256-msd7VQ5zcvJui/svb4frA5ux4KmX13zU/LCzTv6k/Ps=";
  };

  nativeBuildInputs = [
    yarnConfigHook
    yarnInstallHook
    nodejs
  ];

  postFixup = ''
    mkdir -p $out/nix-support
    echo "${nodejs}" >> $out/nix-support/depends
  '';

  meta = {
    description = "A Surgio starter kit.";
    homepage = "https://surgio.js.org/";
    license = lib.licenses.mit;
  };
})
