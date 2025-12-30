{
  config,
  pkgs,
  lib,
  ...
}:
let
  inherit (lib)
    mkIf
    mkOption
    optional
    optionals
    optionalAttrs
    types
    ;

  cfg = config.services.kmscon-macslow;
in
{
  options = let
    vtOption = {
      options = {
        enable = mkOption {
          description = ''
            For services.kmscon-macslow.all, replace all gettys with kmscon-macslow.
            For services.kmscon-macslow.vts, whether use kmscon-macslow or not on a vt.
          '';
          type = types.bool;
          default = false;
        };

        hwRender = mkOption {
          description = "Whether to use 3D hardware acceleration to render the console.";
          type = types.bool;
          default = false;
        };

        fonts = mkOption {
          description = "Fonts used by kmscon, in order of priority.";
          default = null;
          example = lib.literalExpression ''[ { name = "Source Code Pro"; package = pkgs.source-code-pro; } ]'';
          type =
            with types;
            let
              fontType = submodule {
                options = {
                  name = mkOption {
                    type = str;
                    description = "Font name, as used by fontconfig.";
                  };
                  package = mkOption {
                    type = package;
                    description = "Package providing the font.";
                  };
                };
              };
            in
            nullOr (nonEmptyListOf fontType);
        };

        useXkbConfig = mkOption {
          description = "Configure keymap from xserver keyboard settings.";
          type = types.bool;
          default = false;
        };

       extraConfig = mkOption {
          description = "Extra contents of the kmscon.conf file.";
          type = types.lines;
          default = "";
          example = "font-size=14";
        };

        extraOptions = mkOption {
          description = "Extra flags to pass to kmscon.";
          type = types.separatedString " ";
          default = "";
          example = "--term xterm-256color";
        };

        autologinUser = mkOption {
          type = types.nullOr types.str;
          default = null;
          description = ''
            Username of the account that will be automatically logged in at the console.
            If unspecified, a login prompt is shown as usual.
          '';
        };

        executeCommand = mkOption {
          type = types.nullOr types.str;
          default = null;
          description = "Command that will be execeuted instead of login.";
        };
      };
    };
  in {
    services.kmscon-macslow = {
      all = mkOption {
        description = "Default config for each VT except for those which has config defined in services.kmscon-macslow.vts";
        type = types.submodule vtOption;
        default = { };
      };

      vts = mkOption {
        description = "Config for every single VT.";
        type = types.attrsOf (types.submodule vtOption);
        default = { };
      };
    };
  };

  config = mkIf (
        cfg.all.enable ||
        lib.pipe cfg.vts [
          lib.attrValues
          (lib.fold (a: b: a.enable || b.enable) false)
        ]
    ) {
      assertions = lib.singleton {
        assertion = !config.services.kmscon.enable;
        message = "services.kmscon enabled";
      };

      # Always-on
      systemd.packages = [ (pkgs.callPackage ../../pkgs/kmscon-macslow/default.nix { }) ];

      # On by checking all and every vts
      hardware.graphics.enable = cfg.all.hwRender ||
        lib.pipe cfg.vts [
          (lib.mapAttrsToList (_: x: x.hwRender))
          (lib.fold (a: b: a || b) false)
        ];

      fonts = if (
        cfg.all.fonts != null ||
        lib.pipe cfg.vts [
          (lib.mapAttrsToList (_: x: x.fonts != null))
          (lib.fold (a: b: a || b) false)
        ]
      ) then {
        fontconfig.enable = true;
        packages = map (f: f.package) (cfg.all.fonts ++ lib.flatten (lib.mapAttrsToList (_: x: x.fonts) cfg.vts));
      } else { };

      # On by checking all
      systemd.suppressedSystemUnits = optionals cfg.all.enable [ "autovt@.service" ];

      # Units
      systemd.services = let
        systemdUnit = {
          instance,
          vtOption,
          alias
        }: let
          configDir = pkgs.writeTextFile {
            name = "kmscon-${instance}-config";
            destination = "/kmscon.conf";
            text = lib.concatLines [ vtOption.extraConfig extraConfig ];
          };
          loginArg = if vtOption.executeCommand != null then 
              vtOption.executeCommand
            else "${pkgs.shadow}/bin/login -p" + (lib.optionalString (vtOption.autologinUser != null) " -f ${vtOption.autologinUser}");
          extraConfig = let
            xkb = optionals vtOption.useXkbConfig (
              lib.mapAttrsToList (n: v: "xkb-${n}=${v}") (
                lib.filterAttrs (
                  n: v:
                  builtins.elem n [
                    "layout"
                    "model"
                    "options"
                    "variant"
                  ]
                  && v != ""
                ) config.services.xserver.xkb
              )
            );
            render = optionals vtOption.hwRender [
              "drm"
              "hwaccel"
            ];
            fonts =
              optional (vtOption.fonts != null)
                "font-name=${lib.concatMapStringsSep ", " (f: f.name) vtOption.fonts}";
          in
            lib.concatLines (xkb ++ render ++ fonts);
        in {
          after = [
            "systemd-logind.service"
            "systemd-vconsole-setup.service"
          ];
          requires = [ "systemd-logind.service" ];

          serviceConfig.ExecStart = [
            ""
            ''
              ${pkgs.callPackage ../../pkgs/kmscon-macslow/default.nix { }}/bin/kmscon "--vt=${instance}" ${vtOption.extraOptions} --seats=seat0 --no-switchvt --configdir ${configDir} --login -- ${loginArg}
            ''
          ];

          restartIfChanged = false;
          aliases = alias;
        };
      in optionalAttrs cfg.all.enable {
        "kmsconvt@" = systemdUnit { instance = "%I"; vtOption = cfg.all; alias = [ "autovt@.service" ]; };
      } // lib.foldl lib.mergeAttrs {} (lib.attrValues (lib.mapAttrs (instance: vtOption: optionalAttrs cfg.vts.${instance}.enable { "kmsconvt@${instance}" = systemdUnit { inherit instance vtOption; alias = [ "autovt@${instance}.service" ]; }; }) cfg.vts));

      #systemd.services.systemd-vconsole-setup.enable = false;
      #systemd.services.reload-systemd-vconsole-setup.enable = false;
    };
}
