{ inputs, ... }:
{
  cust-pkgs = final: prev: import ../pkgs { pkgs = final; };

  master-pkgs-overlay = final: prev: {
    master-pkgs = import inputs.nixpkgs-master { system = final.system; };
  };

  stable-pkgs-overlay = final: prev: {
    stable-pkgs = import inputs.nixpkgs-stable { system = final.system; };
  };

  blink-cmp-overlay = final: prev: {
    blink-cmp = inputs.blink-cmp.packages.${final.system}.default;
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

  # cust-pkgs-overlay = final: prev: {
  #   cust-pkgs = import ../pkgs { pkgs = prev; };
  # };
}
