{
  lib, fetchFromGitHub, buildGoModule,
  api ? true,
  client ? true,
  server ? true,
  forward ? true,
  nat ? true,
  other ? true,
}:

buildGoModule rec {
  pname = "trojan-go";
  version = "0.10.6";

  src = fetchFromGitHub {
    owner = "p4gefau1t";
    repo = "trojan-go";
    rev = "v${version}";
    hash = "sha256-ZzIEKyLhHwYEWBfi6fHlCbkEImetEaRewbsHQEduB5Y=";
  };

  vendorHash = "sha256-c6H/8/dmCWasFKVR15U/kty4AzQAqmiL/VLKrPtH+s4=";

  ldflags = [ 
    "-s"
    "-w"
    "-X github.com/p4gefau1t/trojan-go/constant.Version=v${version}"
    "-X github.com/p4gefau1t/trojan-go/constant.Commit=fd344b2d01c91922d8e636d400ab17bafe078d85"
  ];

  tags = lib.optionals api [ "api" ]
    ++ lib.optionals client [ "client" ]
    ++ lib.optionals server [ "server" ]
    ++ lib.optionals forward [ "forward" ]
    ++ lib.optionals nat [ "nat" ]
    ++ lib.optionals other [ "other" ];

  CGO_ENABLED = 0;

  doCheck = false;

  meta = {
    description = "A Trojan proxy written in Go. An unidentifiable mechanism that helps you bypass GFW.";
    homepage = "https://github.com/p4gefau1t/trojan-go";
    license = lib.licenses.gpl3;
  };
}
