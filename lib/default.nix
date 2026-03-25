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
    // (if feature ? options then (feature.options { inherit lib config; }) else { });

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

  defaultsModule =
    { lib, config, ... }:
    let
      featureNames = lib.attrNames (lib.filterAttrs (n: _: n != "defaults") (config.features or { }));
      anyFeatureEnabled = lib.any (name: config.features.${name}.enable or false) featureNames;
    in
    {
      options.features.defaults.users = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = "Default list of users for all features.";
      };

      config.assertions = lib.optional anyFeatureEnabled {
        assertion = config.features.defaults.users != [ ];
        message = "features.defaults.users must be set when any feature is enabled.";
      };
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
        (lib.optionalAttrs (feature ? home) (
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
            # Warn if NixOS-only feature enabled in HM on a NixOS system
            lib.optional (osConfig != null && featureCfg.enable) {
              assertion = false;
              message = "features.${name} is enabled in a home-manager configuration, but this is a NixOS system. Enable features in the NixOS configuration instead.";
            }
            # Warn if feature without home key enabled on standalone HM
            ++ lib.optional (osConfig == null && featureCfg.enable && !(feature ? home)) {
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

  mkFeatures = dir: [ defaultsModule ] ++ map mkNixosFeature (discoverFeatures dir);

  mkHmFeatures = dir: [ defaultsModule ] ++ map mkHmFeature (discoverFeatures dir);
}
