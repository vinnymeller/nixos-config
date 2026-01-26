require("copilot").setup({
	panel = { enabled = false },
	suggestion = {
		enabled = true,
		auto_trigger = true,
		keymap = {
			-- accept = "<C-y>",
		},
	},
	-- enable all filetypes
	filetypes = {
		["*"] = true,
	},
})
