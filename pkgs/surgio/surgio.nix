{
  lib,
  stdenv,
  fetchFromGitHub,
  nodejs,
  pnpm_9
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "surgio";
  version = "3.10.6";

  src = fetchFromGitHub {
    owner = "surgioproject";
    repo = finalAttrs.pname;
    rev = "v${finalAttrs.version}";
    hash = "sha256-F8Ng6qdGDdNLD1t5mzovCqSgzohM0PtAzPh2n6TNk/w=";
  };

  nativeBuildInputs = [
    nodejs
    pnpm_9.configHook
  ];

  pnpmDeps = pnpm_9.fetchDeps {
    inherit (finalAttrs) pname version src;
    pnpmInstallFlags = [ "--prod" ];
    hash = "sha256-+oeLP7OQdqNKKVdrvmjkZl6PttbSnjbyZf7Kwry87M0=";
  };

  buildPhase = ''
    ${pnpm_9}/bin/pnpm run build
  '';

  installPhase = ''
    cp -r . $out/
    mv $out/bin/run $out/bin/surgio
    rm $out/bin/run.cmd $out/bin/dev $out/bin/dev.cmd
    chmod +x $out/bin/surgio
    patchShebangs --build $out/bin/surgio
  '';

  meta = {
    description = "Generating rules for Surge, Clash, Quantumult like a PRO";
    homepage = "https://surgio.js.org/";
    license = lib.licenses.mit;
  };
})
