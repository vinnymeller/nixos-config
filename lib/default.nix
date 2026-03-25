{ lib, hmLib }:
let

  discoverFeatures =
    dir:
    let
      entries = builtins.readDir dir;
      featureEntries = lib.filterAttrs (
        name: type:
        (type == "regular" && lib.hasSuffix ".nix" name && name != "default.nix") || (type == "directory")
      ) entries;
    in
    lib.mapAttrsToList (name: type: {
      name = if type == "regular" then lib.removeSuffix ".nix" name else name;
      feature = import (dir + "/${name}");
    }) featureEntries;

  mkFeatureOptions =
    {
      name,
      feature,
      config,
      lib,
    }:
    {
      enable = lib.mkEnableOption "Enable the ${name} feature";
      users = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = config.features.defaults.users;
        description = "Users for this feature. Defaults to features.defaults.users.";
      };
    }
    // (
      if feature ? options then
        (feature.options {
          inherit lib config name;
          cfg = config.features.${name};
        })
      else
        { }
    );

  callFeatureHome =
    { feature, featureCfg }:
    {
      config,
      lib,
      pkgs,
      ...
    }:
    feature.home {
      cfg = featureCfg;
      hmConfig = config;
      inherit lib pkgs;
    };

  defaultsOptions =
    { lib, ... }:
    {
      options.features.defaults = {
        users = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
          description = "Default list of users for all features.";
        };
        colors = lib.mkOption {
          type = lib.types.attrsOf lib.types.str;
          default = {
            # Backgrounds (dark to light)
            bg = "#282828";
            bg-dark = "#000000";
            bg1 = "#3c3836";
            bg2 = "#504945";

            # Foregrounds (light to dark)
            fg = "#ebdbb2";
            fg0 = "#fbf1c7";
            fg2 = "#d5c4a1";

            # Neutral gray
            gray = "#928374";

            # ANSI colors (normal)
            black = "#665c54";
            red = "#cc241d";
            green = "#98971a";
            yellow = "#d79921";
            blue = "#458588";
            magenta = "#b16286";
            cyan = "#689d6a";
            white = "#a89984";

            # ANSI colors (bright)
            black-bright = "#7c6f64";
            red-bright = "#fb4934";
            green-bright = "#b8bb26";
            yellow-bright = "#fabd2f";
            blue-bright = "#83a598";
            magenta-bright = "#d3869b";
            cyan-bright = "#8ec07c";
            white-bright = "#bdae93";
          };
          description = "Color palette used by features (kitty, hyprland, etc).";
        };
      };
    };

  defaultsAssertions =
    { config, featureNames }:
    let
      anyFeatureEnabled = lib.any (name: config.features.${name}.enable or false) featureNames;
    in
    lib.optionals anyFeatureEnabled [
      {
        assertion = config.features.defaults.users != [ ];
        message = "features.defaults.users must be set when any feature is enabled.";
      }
    ];

  mkDefaultsModule =
    { extraAssertions }:
    { lib, config, ... }:
    let
      featureNames = lib.attrNames (lib.filterAttrs (n: _: n != "defaults") (config.features or { }));
    in
    {
      imports = [ defaultsOptions ];

      config.assertions =
        defaultsAssertions { inherit config featureNames; } ++ extraAssertions { inherit config lib; };
    };

  mkNixosFeature =
    { name, feature }:
    {
      config,
      lib,
      pkgs,
      inputs,
      ...
    }:
    let
      featureCfg = config.features.${name};
    in
    {
      options.features.${name} = mkFeatureOptions {
        inherit
          name
          feature
          config
          lib
          ;
      };

      config = lib.mkMerge [
        (lib.mkIf featureCfg.enable (
          lib.mkMerge [
            (lib.optionalAttrs (feature ? nixos) (
              feature.nixos {
                cfg = featureCfg;
                eachUser =
                  arg: lib.genAttrs featureCfg.users (user: if builtins.isFunction arg then arg user else arg);
                resolveUser =
                  username:
                  let
                    user =
                      config.users.users.${username}
                        or (throw "resolveUser: user '${username}' does not exist in users.users");
                    group =
                      config.users.groups.${user.group}
                        or (throw "resolveUser: group '${user.group}' for user '${username}' does not exist in users.groups");
                  in
                  {
                    uid =
                      if user.uid != null then
                        toString user.uid
                      else
                        throw "resolveUser: user '${username}' must have an explicit uid set";
                    gid =
                      if group.gid != null then
                        toString group.gid
                      else
                        throw "resolveUser: group '${user.group}' for user '${username}' must have an explicit gid set";
                    inherit user group;
                  };
                inherit
                  config
                  lib
                  pkgs
                  inputs
                  ;
              }
            ))
            (lib.optionalAttrs (feature ? home) {
              home-manager.users = lib.genAttrs featureCfg.users (
                _: callFeatureHome { inherit feature featureCfg; }
              );
            })
          ]
        ))
        (lib.optionalAttrs (feature ? assertions) {
          assertions = lib.optionals featureCfg.enable (
            feature.assertions {
              features = config.features;
              inherit lib;
            }
          );
        })
      ];
    };

  mkHmFeature =
    { name, feature }:
    {
      lib,
      config,
      pkgs,
      osConfig ? null,
      ...
    }:
    let
      featureCfg = config.features.${name};
    in
    {
      options.features.${name} = mkFeatureOptions {
        inherit
          name
          feature
          config
          lib
          ;
      };

      config = lib.mkMerge [
        # On standalone HM, apply home config. On NixOS, mkNixosFeature handles this.
        (lib.optionalAttrs (feature ? home && osConfig == null) (
          lib.mkIf featureCfg.enable (
            callFeatureHome { inherit feature featureCfg; } { inherit config lib pkgs; }
          )
        ))
        (lib.optionalAttrs (feature ? assertions) {
          assertions = lib.optionals featureCfg.enable (
            feature.assertions {
              features = config.features;
              inherit lib;
            }
          );
        })
        {
          assertions =
            # Warn if feature without home key enabled on standalone HM
            lib.optional (osConfig == null && featureCfg.enable && !(feature ? home)) {
              assertion = false;
              message = "features.${name} has no home-manager configuration and does nothing on a standalone home-manager system.";
            };
        }
      ];
    };
in
{
  readModuleFiles =
    dir:
    lib.pipe (builtins.readDir dir) [
      (lib.filterAttrs (name: type: type == "directory" || lib.hasSuffix ".nix" name))
      builtins.attrNames
      (builtins.filter (name: name != "default.nix"))
      (map (name: dir + "/${name}"))
    ];

  mergeJsonTopLevel =
    {
      pkgs,
      mergeInto,
      mergeFrom,
    }:
    hmLib.hm.dag.entryAfter [ "writeBoundary" ] ''
      if [ ! -f ${mergeInto} ]; then
        echo "{}" > ${mergeInto}
      fi
      cp ${mergeInto} ${mergeInto}.bak
      ${pkgs.jq}/bin/jq -s '
        .[0] as $f1 |
        .[1] as $f2 |
        ($f1 | with_entries(select(.key as $k | $f2 | has($k) | not))) * $f2
      ' ${mergeInto} ${mergeFrom} > ${mergeInto}.tmp
      mv ${mergeInto}.tmp ${mergeInto}
    '';

  mergeJsonDeep =
    {
      pkgs,
      mergeInto,
      mergeFrom,
    }:
    hmLib.hm.dag.entryAfter [ "writeBoundary" ] ''
      if [ ! -f ${mergeInto} ]; then
        echo "{}" > ${mergeInto}
      fi
      cp ${mergeInto} ${mergeInto}.bak
      ${pkgs.jq}/bin/jq -s '.[0] * .[1]' ${mergeInto} ${mergeFrom} > ${mergeInto}.tmp
      mv ${mergeInto}.tmp ${mergeInto}
    '';

  mergeIntoTomlFromJsonTopLevel =
    {
      pkgs,
      mergeInto,
      mergeFrom,
    }:
    hmLib.hm.dag.entryAfter [ "writeBoundary" ] ''
      if [ ! -f ${mergeInto} ]; then
        echo "" > ${mergeInto}
      fi
      # convert to json, merge, convert back to toml
      cp ${mergeInto} ${mergeInto}.bak
      cat ${mergeInto} | ${pkgs.yj}/bin/yj -tj > ${mergeInto}.tmp.json
      ${pkgs.jq}/bin/jq -s '
        .[0] as $f1 |
        .[1] as $f2 |
        ($f1 | with_entries(select(.key as $k | $f2 | has($k) | not))) * $f2
      ' ${mergeInto}.tmp.json ${mergeFrom} > ${mergeInto}.tmp
      cat ${mergeInto}.tmp | ${pkgs.yj}/bin/yj -jt > ${mergeInto}
      rm ${mergeInto}.tmp ${mergeInto}.tmp.json
    '';

  sharedDeps = pkgs: {
    lsps = with pkgs; [
      ccls
      dockerfile-language-server
      gopls
      ltex-ls-plus
      lua-language-server
      nixd
      nodePackages.typescript-language-server
      tailwindcss-language-server
      taplo
      terraform-ls
      tinymist
      ty
      vscode-langservers-extracted
      yaml-language-server
    ];
  };

  mkFeatures =
    dir:
    let
      features = discoverFeatures dir;
    in
    [
      (mkDefaultsModule {
        extraAssertions =
          { config, ... }:
          map (user: {
            assertion = config.users.users ? ${user};
            message = "features.defaults.users contains '${user}' but users.users.${user} is not defined.";
          }) config.features.defaults.users;
      })
      # Propagate all feature enable states + defaults from NixOS into HM
      (
        { config, ... }:
        let
          allFeatureNames = map (f: f.name) features;
        in
        {
          home-manager.sharedModules = [
            {
              features =
                lib.genAttrs allFeatureNames (name: {
                  enable = lib.mkDefault config.features.${name}.enable;
                })
                // {
                  defaults = {
                    users = lib.mkDefault config.features.defaults.users;
                    colors = lib.mkDefault config.features.defaults.colors;
                  };
                };
            }
          ];
        }
      )
    ]
    ++ map mkNixosFeature features;

  mkHmFeatures =
    dir:
    [
      (mkDefaultsModule {
        extraAssertions =
          { config, lib, ... }:
          lib.optional (config.features.defaults.users != [ ]) {
            assertion = lib.length config.features.defaults.users == 1;
            message = "features.defaults.users must have exactly one user on standalone home-manager systems.";
          };
      })
      (
        {
          config,
          lib,
          pkgs,
          osConfig ? null,
          ...
        }:
        lib.mkIf (osConfig == null && config.features.defaults.users != [ ]) (
          let
            user = builtins.head config.features.defaults.users;
          in
          {
            home.username = lib.mkDefault user;
            home.homeDirectory = lib.mkDefault (
              if pkgs.stdenv.isDarwin then "/Users/${user}" else "/home/${user}"
            );
          }
        )
      )
    ]
    ++ map mkHmFeature (discoverFeatures dir);
}
