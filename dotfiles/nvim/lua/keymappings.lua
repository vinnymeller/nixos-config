vim.keymap.set({ "n", "v" }, "<Space>", "<Nop>", { silent = true })

-- handle wordwrap better
vim.keymap.set("n", "k", "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true })
vim.keymap.set("n", "j", "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true })


vim.keymap.set("n", "<Leader>fm", "<cmd>FormatWrite<CR>", {})
vim.keymap.set("i", "jk", "<Esc>", { desc = "jk to escape" })


-- Diagnostic keymaps
vim.keymap.set("n", "[d", vim.diagnostic.goto_prev)
vim.keymap.set("n", "]d", vim.diagnostic.goto_next)
vim.keymap.set("n", "<leader>e", vim.diagnostic.open_float)
vim.keymap.set("n", "<leader>q", vim.diagnostic.setloclist)
vim.keymap.set("n", "<leader>dj", vim.diagnostic.goto_next, { desc = "[D]iagnostic [J]ump" })
vim.keymap.set("n", "<leader>dk", vim.diagnostic.goto_prev, { desc = "[D]iagnostic Previous [O]k" })
