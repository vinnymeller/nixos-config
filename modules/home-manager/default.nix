{
  vlib,
  ...
}:
let
  modules = vlib.readModuleFiles ./.;
in
{
  imports = modules ++ vlib.mkHmFeatures ../../features;

  config = {
    programs.home-manager.enable = true;
  };
}
