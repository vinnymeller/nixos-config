vim.opt.runtimepath:prepend("~/.nixdots/overlays/neovim") -- this is where my actual config lives, and i use nix as the plugin manager
require("opts")
require("autocmds")
require("keymappings")
require("plugins")
require("cmds")
