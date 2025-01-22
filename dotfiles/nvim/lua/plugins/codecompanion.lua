require("codecompanion").setup({})
vim.api.nvim_set_keymap("n", "<leader>cc", "<cmd>CodeCompanionChat<CR>", { noremap = true, silent = true })

