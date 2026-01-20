vim.g.fugitive_summary_format = "%cs || %<(20,trunc)%an || %s"

local map = vim.keymap.set
map("n", "<leader>gs", "<cmd>Git add %<CR>", { desc = "[G]it [S]tage current file" })
map("n", "<leader>gS", "<cmd>Git add -A<CR>", { desc = "[G]it [S]tage all files" })
map("n", "<leader>gc", "<cmd>Git commit<CR>", { desc = "[G]it [C]ommit" })
map("n", "<leader>gp", "<cmd>Git push<CR>", { desc = "[G]it [P]ush" })
map("n", "<leader>gd", "<cmd>Git diff %<CR>", { desc = "[G]it [D]iff current file" })
map("n", "<leader>gD", "<cmd>Git diff<CR>", { desc = "[G]it [D]iff" })
map("n", "<leader>gb", "<cmd>Git blame<CR>", { desc = "[G]it [B]lame" })
map("n", "<leader>gl", "<cmd>0GcLog!<CR>", { desc = "[G]it [L]og (Current file)" })
map("n", "<leader>gL", "<cmd>GcLog!<CR>", { desc = "[G]it [L]og (Repo)" })
map("n", "<leader>g<C-s>", "<cmd>Git status<CR>", { desc = "[G]it [S]tatus" })
map("n", "<leader>gr", "<cmd>Git restore %<CR>", { desc = "[G]it [R]estore current file" })
map("n", "<leader>gR", "<cmd>Git restore .<CR>", { desc = "[G]it [R]estore all files" })
map("n", "<leader>gP", "<cmd>Git pull<CR>", { desc = "[G]it [P]ull" })
map("n", "<leader>go", "<cmd>GBrowse!<CR>:GBrowse<CR>", { desc = "[G]it [O]pen in browser" })
map("v", "<leader>go", "<cmd>GBrowse!<CR>gv:GBrowse<CR>", { desc = "[G]it [O]pen in browser" })
