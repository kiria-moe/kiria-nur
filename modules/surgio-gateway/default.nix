{ config, pkgs, lib, ... }:

{
  options = {
    services.surgio-gateway = {
      enable = lib.mkEnableOption "surgio-gateway";
      src = lib.mkOption {
        type = lib.types.path;
        description = "Source used by surgio-gateway";
      };
      address = lib.mkOption {
        type = lib.types.str;
        default = "0.0.0.0";
        description = "Address to bind";
      };
      port = lib.mkOption {
        type = lib.types.port;
        default = 3000;
        description = "Port to listen on";
      };
      openFirewall = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Whether to open the specified ports in the firewall.";
      };
    };
  };

  config = let
    cfg = config.services.surgio-gateway;
  in lib.mkIf cfg.enable {
    systemd.services."surgio-gateway" = {
      enable = true;
      unitConfig = {
        Description = "Generating rules for Surge, Clash, Quantumult like a PRO";
        Documentation = "https://surgio.js.org/";
        After = [ "network.target" "nss-lookup.target" ];
      };
      serviceConfig = {
        DynamicUser = "yes";
        CapabilityBoundingSet = [ "CAP_NET_BIND_SERVICE" ];
        AmbientCapabilities = [ "CAP_NET_BIND_SERVICE" ];
        NoNewPrivileges = true;
        StateDirectory = "surgio-gateway";
        Environment = "SURGIO_PROJECT_DIR=/var/lib/private/surgio-gateway";
        ExecStartPre = "+${pkgs.bash}/bin/bash -c \"${pkgs.coreutils}/bin/cp -r ${cfg.src}/* /var/lib/private/surgio-gateway\"";
        ExecStart = "${pkgs.callPackage ../../pkgs/surgio-gateway { }}/bin/surgio-gateway ${cfg.address} ${builtins.toString cfg.port}";
        Restart = "on-failure";
        RestartSec = "10s";
        LimitNOFILE = "infinity";
      };
      wantedBy = [ "multi-user.target" ];
    };

    networking.firewall.allowedTCPPorts = lib.optionals cfg.openFirewall [ cfg.port ];
  };
}
