require("zk").setup({
	picker = "fzf_lua",
})

local opts = { noremap = true, silent = false }

-- Create a new note after asking for its title.
vim.api.nvim_set_keymap("n", "<leader>zn", "<Cmd>ZkNew { title = vim.fn.input('Title: ') }<CR>", opts)

-- Open notes.
vim.api.nvim_set_keymap("n", "<leader>zo", "<Cmd>ZkNotes { sort = { 'modified' } }<CR>", opts)
-- Open notes associated with the selected tags.
vim.api.nvim_set_keymap("n", "<leader>zt", "<Cmd>ZkTags<CR>", opts)

-- Search for the notes matching a given query.
vim.api.nvim_set_keymap(
	"n",
	"<leader>zf",
	"<Cmd>ZkNotes { sort = { 'modified' }, match = { vim.fn.input('Search: ') } }<CR>",
	opts
)
-- Search for the notes matching the current visual selection.
vim.api.nvim_set_keymap("v", "<leader>zf", ":'<,'>ZkMatch<CR>", opts)

-- open daily note
vim.api.nvim_set_keymap("n", "<leader>zd", "<Cmd>ZkNew { group = 'daily'}<CR>", opts)

-- create new bibliographic note
vim.api.nvim_set_keymap("n", "<leader>zb", "<Cmd>ZkNew { group = 'bib', title = vim.fn.input('Title: ') }<CR>", opts)
