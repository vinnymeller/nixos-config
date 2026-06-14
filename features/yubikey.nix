{
  # Centralizes everything YubiKey: the smartcard/PIV/OTP device plumbing
  # (moved out of features/gpg.nix) and declarative pam_u2f touch-to-auth.
  #
  # GPG-on-YubiKey now needs BOTH features.gpg.enable AND features.yubikey.enable
  # (gpg provides the agent/pinentry; yubikey provides pcscd + the card glue).

  options =
    { lib, ... }:
    {
      # `enable` (turns on the device plumbing) and `users` come from the
      # feature framework.

      yubikeyAgent = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Run yubikey-agent (PIV-based SSH agent).";
      };

      u2f = {
        enable = lib.mkEnableOption "pam_u2f touch-to-authenticate (e.g. for sudo)";

        origin = lib.mkOption {
          type = lib.types.str;
          default = "pam://vinnix.net";
          description = ''
            Fixed FIDO origin used for BOTH registration and authentication.
            Using a stable string instead of the default `pam://$HOSTNAME` is
            what makes a single registration work on every machine — enroll a
            key once, use it on any host that shares this origin + mappings.
          '';
        };

        appId = lib.mkOption {
          type = lib.types.str;
          default = "pam://vinnix.net";
          description = "FIDO appId; keep equal to `origin`. Must match what the keys were registered with.";
        };

        mappings = lib.mkOption {
          type = lib.types.lines;
          default = "";
          description = ''
            pam_u2f authfile contents — the output of:

              pamu2fcfg -o <origin> -i <appId>        # first key (includes the username)
              pamu2fcfg -o <origin> -i <appId> -n     # each extra key (append to the SAME line)

            One line per user: `user:cred1:cred2:...`. These are PUBLIC key
            handles + public keys (the private key never leaves the YubiKey),
            so they are safe to commit — even to a public repo. Register every
            key you own plus a backup; paste them here and every host that
            enables `u2f` shares the same set.
          '';
        };

        pamServices = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ "sudo" ];
          description = ''
            PAM services that require a YubiKey touch. Start with just "sudo".
            Add "login" / "hyprlock" / "su" only once you've confirmed it works
            — a bad config on those locks you out of the machine, not just sudo
            (recoverable by booting a previous generation).
          '';
        };

        control = lib.mkOption {
          type = lib.types.enum [
            "required"
            "requisite"
            "sufficient"
            "optional"
          ];
          default = "required";
          description = ''
            "required"   = password AND touch (true 2FA; compensates for a weak password).
            "sufficient" = touch INSTEAD of password.
          '';
        };
      };
    };

  assertions =
    { features, lib, ... }:
    [
      {
        # Guard against bricking: pam_u2f with control=required and no
        # registered keys means the protected services can never authenticate.
        assertion =
          !(
            features.yubikey.u2f.enable && features.yubikey.u2f.control == "required"
          )
          || features.yubikey.u2f.mappings != "";
        message = ''
          features.yubikey.u2f: `mappings` is empty but control = "required" — enabling
          would lock you out of: ${lib.concatStringsSep ", " features.yubikey.u2f.pamServices}.
          Run `pamu2fcfg -o ${features.yubikey.u2f.origin} -i ${features.yubikey.u2f.appId}`
          for each key and paste the line(s) into features.yubikey.u2f.mappings first.
        '';
      }
    ];

  nixos =
    {
      cfg,
      lib,
      pkgs,
      ...
    }:
    lib.mkMerge [
      # ── Device plumbing: smartcard / PIV / OTP ──
      {
        programs.yubikey-touch-detector.enable = lib.mkDefault true;
        services.pcscd.enable = lib.mkDefault true;
        services.udev.packages = [ pkgs.yubikey-personalization ];
        hardware.gpgSmartcards.enable = lib.mkDefault true;
        services.yubikey-agent.enable = lib.mkDefault cfg.yubikeyAgent;
        # ykman for management; pam_u2f ships pamu2fcfg (needed to enroll keys,
        # available even before u2f is switched on).
        environment.systemPackages = [
          pkgs.yubikey-manager
          pkgs.pam_u2f
        ];
      }

      # ── pam_u2f: touch to authenticate ──
      (lib.mkIf cfg.u2f.enable {
        security.pam.u2f = {
          enable = true;
          control = cfg.u2f.control;
          settings = {
            cue = true; # print "Please touch the device"
            origin = cfg.u2f.origin;
            appid = cfg.u2f.appId;
            authfile = pkgs.writeText "u2f-mappings" cfg.u2f.mappings;
          };
        };
        security.pam.services = lib.genAttrs cfg.u2f.pamServices (_: { u2fAuth = true; });
      })
    ];

  home =
    { lib, pkgs, ... }:
    {
      home.packages = lib.optionals pkgs.stdenv.hostPlatform.isLinux [ pkgs.yubioath-flutter ];
    };
}
