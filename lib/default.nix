{ lib, hmLib }:
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
      nodePackages_latest.typescript-language-server
      pyrefly
      tailwindcss-language-server
      taplo
      terraform-ls
      tinymist
      vscode-langservers-extracted
      yaml-language-server
    ];
  };
}
