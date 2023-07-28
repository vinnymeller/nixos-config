vim.opt.runtimepath:prepend("~/.nixdots/dotfiles/nvim") -- this is where my actual config lives, and i use nix as the plugin manager
require("opts")
require("autocmds")
require("keymappings")
require("plugins")
require("cmds")
