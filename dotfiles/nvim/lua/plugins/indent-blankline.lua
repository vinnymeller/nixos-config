-- vim.opt.list = true
local highlight = {
	"RainbowRed",
	"RainbowYellow",
	"RainbowGreen",
	"RainbowBlue",
	"RainbowPurple",
}

local hooks = require("ibl.hooks")

hooks.register(hooks.type.HIGHLIGHT_SETUP, function()
	vim.api.nvim_set_hl(0, "RainbowRed", { fg = "#FF4E4E", nocombine = true })
	vim.api.nvim_set_hl(0, "RainbowYellow", { fg = "#FEFF64", nocombine = true })
	vim.api.nvim_set_hl(0, "RainbowGreen", { fg = "#95FF6A", nocombine = true })
	vim.api.nvim_set_hl(0, "RainbowBlue", { fg = "#88EEFF", nocombine = true })
	vim.api.nvim_set_hl(0, "RainbowPurple", { fg = "#C678DD", nocombine = true })
	vim.api.nvim_set_hl(0, "IblScope", { fg = "#FFFFFF", nocombine = true })
end)

require("ibl").setup({
	indent = {
		highlight = highlight,
		char = "│",  -- the default doesn't work when im in tmux->ssh->tmux->nvim for whatever reason but this one does. only difference is this symbol is slightly thicker
	},
	scope = { enabled = true },
})
