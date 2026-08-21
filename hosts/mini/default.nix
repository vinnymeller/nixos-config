{
  inputs,
  outputs,
  vlib,
  pkgs,
  ...
}:
inputs.home-manager.lib.homeManagerConfiguration {
  inherit pkgs;
  extraSpecialArgs = {
    inherit inputs outputs vlib;
  };
  modules = [
    # Declares the `stylix` option tree. On vinnix this arrives automatically
    # via inputs.stylix.nixosModules.stylix (its home-manager integration pulls
    # in homeModules.stylix), but standalone home-manager has no NixOS parent to
    # do that -- so features/stylix.nix's `home` section would reference an
    # undeclared `stylix.targets` and fail. That happens even with the feature
    # disabled, because unknown-option detection walks the definition's
    # attribute path before evaluating its mkIf condition.
    inputs.stylix.homeModules.stylix
    ./home.nix
  ];
}
