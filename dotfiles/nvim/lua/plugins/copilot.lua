require("copilot").setup({
	panel = { enabled = false },
	suggestion = { enabled = false },
	-- enable all filetypes
	filetypes = {
		markdown = true,
		yaml = true,
		gitcommit = true,
		gitrebase = true,
	},
})
