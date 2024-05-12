{ inputs, ... }:
{
  cust-pkgs = final: prev: import ../pkgs { pkgs = final; };

  master-pkgs-overlay = final: prev: {
    master-pkgs = import inputs.nixpkgs-master { system = final.system; };
  };

  stable-pkgs-overlay = final: prev: {
    stable-pkgs = import inputs.nixpkgs-stable { system = final.system; };
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

  # cust-pkgs-overlay = final: prev: {
  #   cust-pkgs = import ../pkgs { pkgs = prev; };
  # };
}
