{ lib }:
{
  readModuleFiles =
    dir:
    lib.pipe (builtins.readDir dir) [
      (lib.filterAttrs (_: type: type == "regular"))
      builtins.attrNames
      (builtins.filter (filename: filename != "default.nix" && lib.hasSuffix ".nix" filename))
      (builtins.map (filename: dir + "/${filename}"))
    ];
}
