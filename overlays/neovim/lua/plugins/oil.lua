require("oil").setup({
	default_file_explorer = false,
	skip_confirm_for_simple_edits = true,
	view_options = {
		show_hidden = true,
	},
})
vim.keymap.set("n", "-", "<cmd>Oil<CR>", { desc = "Open parent directory" })
