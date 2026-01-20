{ inputs, ... }:
let
  nvimmod = inputs.nixpkgs.lib.modules.importApply ./neovim inputs;
  nvimWrapper = inputs.wrappers.lib.evalModule nvimmod;
in
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

  ragenix = final: prev: {
    ragenix = inputs.ragenix.packages.${final.system}.default;
  };

  llm-agents = final: prev: {
    llm-agents = inputs.llm-agents.packages.${final.system};
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

  claude-code = import ./agents { inherit inputs; };

  neovim = final: prev: { neovim = nvimWrapper.config.wrap { pkgs = final; }; };

}
