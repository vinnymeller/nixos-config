{ inputs, ... }:
{
  cust-pkgs = final: prev: import ../pkgs { pkgs = final; };

  master-pkgs-overlay = final: prev: {
    master-pkgs = import inputs.nixpkgs-master {
      system = final.system;
      config.allowUnfree = true;
    };
  };

  stable-pkgs-overlay = final: prev: {
    stable-pkgs = import inputs.nixpkgs-stable { system = final.system; };
  };

  blink-cmp-overlay = final: prev: {
    blink-cmp-flake = inputs.blink-cmp.packages.${final.system}.default;
  };

  ragenix = final: prev: {
    ragenix = inputs.ragenix.packages.${final.system}.default;
  };

  nix-ai-tools = final: prev: {
    nix-ai-tools = inputs.nix-ai-tools.packages.${final.system};
  };

  remove-0xproto-italics = final: prev: {
    _0xproto-no-italics = prev._0xproto.overrideAttrs (
      finalAttrs: prevAttrs: {
        postInstall = ''
          rm $out/share/fonts/opentype/0xProto-Italic.otf
          rm $out/share/fonts/truetype/0xProto-Italic.ttf
        '';
      }
    );
  };

  twm-src = final: _prev: { twm = inputs.twm.packages.${final.system}.default; };

}
