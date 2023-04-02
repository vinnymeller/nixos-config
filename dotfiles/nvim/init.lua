local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim" -- :echo stdpath("data") will show the path on different OS
if not vim.loop.fs_stat(lazypath) then -- install lazy if it doesn't exist in the correct path
	vim.fn.system({
		"git",
		"clone",
		"--filter=blob:none",
		"--single-branch",
		"https://github.com/folke/lazy.nvim.git",
		lazypath,
	})
end
vim.opt.runtimepath:prepend(lazypath) --add lazy's path to runtimepath
vim.opt.runtimepath:prepend("~/.nixdots/dotfiles/nvim") -- add custom plugins to runtimepath

require("opts")
require("autocmds")
require("keymappings")

require("lazy").setup(
    "plugins",
    {
        lockfile = "~/.nixdots/dotfiles/nvim/lazy-lock.json",
    }
)

require("swagger-preview").setup({})
