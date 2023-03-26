return {
	{
        "TimUntersberger/neogit",
        dependencies = { "sindrets/diffview.nvim" },
        opts = {
            integrations = {
                diffview = true
            },
        },
        config = function(_, opts)
            require("neogit").setup(opts)
            vim.keymap.set("n", "<leader>ng", require("neogit").open, { desc = "[N]eo[G]it" })
        end,
    },
}
