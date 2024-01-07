local map = vim.keymap.set

map({ "n", "v" }, "<Space>", "<Nop>", { silent = true })

-- handle wordwrap better
map("n", "k", "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true })
map("n", "j", "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true })

map("n", "<Leader>fm", "<cmd>FormatWrite<CR>", {})
map("i", "jk", "<Esc>", { desc = "jk to escape" })

-- move to the split above/below/left/right
map("n", "<M-h>", "<C-w>h", { desc = "Move left" })
map("n", "<M-j>", "<C-w>j", { desc = "Move down" })
map("n", "<M-k>", "<C-w>k", { desc = "Move up" })
map("n", "<M-l>", "<C-w>l", { desc = "Move right" })


-- Diagnostic keymaps
map("n", "[d", vim.diagnostic.goto_prev)
map("n", "]d", vim.diagnostic.goto_next)
map("n", "<leader>e", vim.diagnostic.open_float)
map("n", "<leader>q", vim.diagnostic.setloclist)
map("n", "<leader>dj", vim.diagnostic.goto_next, { desc = "[D]iagnostic [J]ump" })
map("n", "<leader>dk", vim.diagnostic.goto_prev, { desc = "[D]iagnostic Jump[k]" })

-- helpful visual mode mappings
map("v", ">", ">gv", { noremap = true })
map("v", "<", "<gv", { noremap = true })

-- backspace in normal mode to replace current word. can i upgrade this ? think about it
map("n", "<bs>", "ciw", { desc = "Replace current word" })

map("n", "<leader>sv", "<cmd>vs<CR>", { desc = "[S]plit [V]ertical" })
map("n", "<leader>sh", "<cmd>sp<CR>", { desc = "[S]plit [H]orizontal" })

-- exit window & close buffer
map("n", "<leader>q", "<cmd>q<CR>", { desc = "[Q]uit" })
map("n", "<leader>k", "<cmd>bd<CR>", { desc = "[K]ill" })

map("n", "<C-j>", ":bprev<CR>", { desc = "Previous buffer" })
map("n", "<C-k>", ":bnext<CR>", { desc = "Next buffer" })

-- stage current file in git
map("n", "<leader>gs", "<cmd>Git add %<CR>", { desc = "[G]it [S]tage current file" })
map("n", "<leader>gS", "<cmd>Git add -A<CR>", { desc = "[G]it [S]tage all files" })
map("n", "<leader>gc", "<cmd>Git commit<CR>", { desc = "[G]it [C]ommit" })
map("n", "<leader>gp", "<cmd>Git push<CR>", { desc = "[G]it [P]ush" })
map("n", "<leader>gd", "<cmd>Git diff %<CR>", { desc = "[G]it [D]iff current file" })
map("n", "<leader>gD", "<cmd>Git diff<CR>", { desc = "[G]it [D]iff" })
map("n", "<leader>gb", "<cmd>Git blame<CR>", { desc = "[G]it [B]lame" })
map("n", "<leader>gl", "<cmd>Git log<CR>", { desc = "[G]it [L]og" })
map("n", "<leader>g<C-s>", "<cmd>Git status<CR>", { desc = "[G]it [S]tatus" })
map("n", "<leader>gr", "<cmd>Git restore %<CR>", { desc = "[G]it [R]estore current file" })
map("n", "<leader>gR", "<cmd>Git restore .<CR>", { desc = "[G]it [R]estore all files" })
map("n", "<leader>gP", "<cmd>Git pull<CR>", { desc = "[G]it [P]ull" })

-- open dadbod ui
map("n", "<leader>db", "<cmd>DBUIToggle<CR>", { desc = "[D]ad[B]od Toggle" })
