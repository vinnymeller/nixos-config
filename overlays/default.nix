{ inputs, ... }:
{
  cust-pkgs = final: prev: import ../pkgs { pkgs = final; };

  master-pkgs-overlay = final: prev: {
    master-pkgs = import inputs.nixpkgs-master { system = final.system; };
  };

  stable-pkgs-overlay = final: prev: {
    stable-pkgs = import inputs.nixpkgs-stable { system = final.system; };
  };

  # cust-pkgs-overlay = final: prev: {
  #   cust-pkgs = import ../pkgs { pkgs = prev; };
  # };
}
