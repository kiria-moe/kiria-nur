{
  src, # The directory that contains a surgio.conf.js
  gnused,
  buildNpmPackage,
}:

buildNpmPackage {
  pname = "surgio-gateway";
  version = "0.1.0";

  inherit src;

  postPatch = ''
    cp ${./gateway.js} ./gateway.js
    cp ${./package.json} ./package.json
    cp ${./package-lock.json} ./package-lock.json
  '';

  # Surgio-gateway will read $cwd/surgio.conf.js
  # Cd to the location before running
  postInstall = ''
    ${gnused}/bin/sed -i "2icd $out/lib/node_modules/surgio-gateway" $out/bin/surgio-gateway
  '';

  npmDepsHash = "sha256-vnX9+Td8g2IWnpqvxZA+uYA6T8QU3ExTU7eA9bm1GYo=";

  npmPackFlags = [ "--ignore-scripts" ];

  dontNpmBuild = true;
}
