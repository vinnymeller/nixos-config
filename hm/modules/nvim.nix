{
  config,
  lib,
  outputs,
  ...
}:
let
  cfg = config.mine.nvim;
in
{
  imports = [
    outputs.myNixCats.homeModule
  ];

  options.mine.nvim = {
    enable = lib.mkEnableOption "Enable nvim with nixCats";
  };

  config = lib.mkIf cfg.enable {
    nixCats = {
      enable = true;
      packageNames = [ "nixCats" ];
    };

  };

}
