return {
    {
        "catppuccin/nvim",
        name = "catppuccin",
        init = function()
            vim.g.catppuccin_flavour = "macchiato"
            vim.cmd("colorscheme catppuccin")
        end,
    },
}
