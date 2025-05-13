{ config, lib, pkgs, ... }:

let

  cfg = config.services.trojan-go;
  configFile = pkgs.writeText "config.json" (builtins.toJSON {
    run_type = cfg.run_type;
    local_addr = cfg.local_addr;
    local_port = cfg.local_port;
    remote_addr = cfg.remote_addr;
    remote_port = cfg.remote_port;
    password = cfg.password;
    ssl = lib.optionalAttrs (cfg.ssl.cert != null) { cert = cfg.ssl.cert; }
      // lib.optionalAttrs (cfg.ssl.key != null) { key = cfg.ssl.key; }
      // lib.optionalAttrs (cfg.ssl.sni != null) { sni = cfg.ssl.sni; }
      // lib.optionalAttrs (cfg.ssl.fallback_addr != null) { fallback_addr = cfg.ssl.fallback_addr; }
      // lib.optionalAttrs (cfg.ssl.fallback_port != null) { fallback_port = cfg.ssl.fallback_port; };
  });

in

{
  options = {
    services.trojan-go = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Whether to enable the trojan-go daemon.";
      };
      run_type = lib.mkOption {
        type = lib.types.str;
      };
      local_addr = lib.mkOption {
        type = lib.types.str;
      };
      local_port = lib.mkOption {
        type = lib.types.port;
      };
      remote_addr = lib.mkOption {
        type = lib.types.str;
      };
      remote_port = lib.mkOption {
        type = lib.types.port;
      };
      password = lib.mkOption {
        type = lib.types.listOf lib.types.str;
      };
      ssl = lib.mkOption {
        type = lib.types.submodule {
          options = {
            cert = lib.mkOption {
              type = lib.types.nullOr lib.types.str;
              default = null;
            };
            key = lib.mkOption {
              type = lib.types.nullOr lib.types.str;
              default = null;
            };
            sni = lib.mkOption {
              type = lib.types.nullOr lib.types.str;
              default = null;
            };
            fallback_addr = lib.mkOption {
              type = lib.types.nullOr lib.types.str;
              default = null;
            };
            fallback_port = lib.mkOption {
              type = lib.types.nullOr lib.types.port;
              default = null;
            };
          };
        };
      };
      openFirewall = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Whether to open the specified ports in the firewall.";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services."trojan-go" = {
      enable = true;
      unitConfig = {
        Description = "Trojan-Go - An unidentifiable mechanism that helps you bypass GFW";
        Documentation = "https://p4gefau1t.github.io/trojan-go/";
        After = [ "network.target" "nss-lookup.target" ];
      };
      serviceConfig = {
        DynamicUser = "yes";
        CapabilityBoundingSet = [ "CAP_NET_ADMIN" "CAP_NET_BIND_SERVICE" ];
        AmbientCapabilities = [ "CAP_NET_ADMIN" "CAP_NET_BIND_SERVICE" ];
        NoNewPrivileges = true;
        ExecStart = "${pkgs.callPackage ../../pkgs/trojan-go/default.nix {}}/bin/trojan-go -config ${configFile}";
        Restart = "on-failure";
        RestartSec = "10s";
        LimitNOFILE = "infinity";
      };
      wantedBy = [ "multi-user.target" ];
    };

    networking.firewall.allowedTCPPorts = lib.optionals cfg.openFirewall [ cfg.local_port ];
    networking.firewall.allowedUDPPorts = lib.optionals cfg.openFirewall [ cfg.local_port ];
  };
}
