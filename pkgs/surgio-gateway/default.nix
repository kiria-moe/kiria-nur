{
  lib,
  gnused,
  buildNpmPackage,
}:

buildNpmPackage {
  pname = "surgio-gateway";
  version = "0.1.0";

  src = lib.fileset.toSource {
    root = ./.;
    fileset = lib.fileset.unions [
      ./gateway.js
      ./package.json
      ./package-lock.json
    ];
  };

  postInstall = ''
    ${gnused}/bin/sed -i "2icd \$SURGIO_PROJECT_DIR" $out/bin/surgio-gateway
    ${gnused}/bin/sed -i "3s#^#NODE_PATH=$out/lib/node_modules/surgio-gateway/node_modules/ &#" $out/bin/surgio-gateway
  '';

  npmDepsHash = "sha256-vnX9+Td8g2IWnpqvxZA+uYA6T8QU3ExTU7eA9bm1GYo=";

  npmPackFlags = [ "--ignore-scripts" ];

  dontNpmBuild = true;
}
