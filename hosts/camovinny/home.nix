{
  pkgs,
  outputs,
  ...
}:
{
  imports = [
    ../../hm
  ];

  profile.vinny.enable = true;
  # nvim nightly overlay doesn't seem to work on aarch64-darwin for now. TODO look into why
  # nixpkgs.overlays = builtins.attrValues (builtins.removeAttrs outputs.overlays [ "neovim-nightly" ]);
  nixpkgs.overlays = builtins.attrValues outputs.overlays;
  nixpkgs.config = {
    allowBroken = true;
    allowUnfree = true;
    allowUnsupportedSystem = true;
  };
  nix.package = pkgs.nixVersions.stable;
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];
  nix.settings.auto-optimise-store = true;
  nix.settings.require-sigs = false;
  nix.settings.trusted-users = [
    "vinny"
    "root"
  ];

  home.username = "vinny";
  home.homeDirectory = "/Users/vinny";
  home.stateVersion = "22.11";

}
