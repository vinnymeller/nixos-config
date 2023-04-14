-- vim.g.catppuccin_flavour = "macchiato"
-- vim.cmd("colorscheme catppuccin")
-- require("catppuccin").setup({
--     transparent_background = true,
-- })

vim.o.background = "dark"
require("gruvbox").setup({
    transparent_mode = true,
})
vim.cmd([[colorscheme gruvbox]])
