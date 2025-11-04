require("neotest").setup({
    adapters = {
        require("rustaceanvim.neotest"),
    },
})

vim.keymap.set("n", "<leader>nt", function()
    require("neotest").run.run()
end, { desc = "Run [N]earest [t]est" })
vim.keymap.set("n", "<leader>nT", function()
    require("neotest").run.run(vim.fn.expand("%"))
end, { desc = "Run all tests in file" })
