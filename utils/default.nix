{ lib, hmLib }:
{
  readModuleFiles =
    dir:
    lib.pipe (builtins.readDir dir) [
      (lib.filterAttrs (_: type: type == "regular"))
      builtins.attrNames
      (builtins.filter (filename: filename != "default.nix" && lib.hasSuffix ".nix" filename))
      (builtins.map (filename: dir + "/${filename}"))
    ];

  mergeJsonTopLevel =
    mergeInto: mergeFrom:
    hmLib.hm.dag.entryAfter [ "writeBoundary" ] ''
      if [ ! -f ${mergeInto} ]; then
        echo "{}" > ${mergeInto}
      fi
      cp ${mergeInto} ${mergeInto}.bak
      jq -s '
        .[0] as $f1 |
        .[1] as $f2 |
        ($f1 | with_entries(select(.key as $k | $f2 | has($k) | not))) * $f2
      ' ${mergeInto} ${mergeFrom} > ${mergeInto}.tmp
      mv ${mergeInto}.tmp ${mergeInto}
    '';
  mergeJsonDeep =
    mergeInto: mergeFrom:
    hmLib.hm.dag.entryAfter [ "writeBoundary" ] ''
      if [ ! -f ${mergeInto} ]; then
        echo "{}" > ${mergeInto}
      fi
      cp ${mergeInto} ${mergeInto}.bak
      jq -s '.[0] * .[1]' ${mergeInto} ${mergeFrom} > ${mergeInto}.tmp
      mv ${mergeInto}.tmp ${mergeInto}
    '';
}
