require("formatter").setup({
	-- Enable or disable logging
	logging = true,
	-- Set the log level
	log_level = vim.log.levels.WARN,
	-- All formatter configurations are opt-in
	filetype = {
		-- Formatter configurations are executed in order where there are multiple
		rust = {
			-- custom rustfmt commands
			function()
				return {
					exe = "rustfmt",
					args = { "--edition=2021" },
					stdin = true,
				}
			end,
		},
		python = {
			require("formatter.filetypes.python").black,
			require("formatter.filetypes.python").isort,
		},
		sql = {
			require("formatter.filetypes.sql").pgformat,
		},
		lua = {
			require("formatter.filetypes.lua").stylua,
		},
		sh = {
			require("formatter.filetypes.sh").shfmt,
		},
		-- Use the special "*" filetype for defining formatter configurations on
		-- any filetype
		["*"] = {
			require("formatter.filetypes.any").remove_trailing_whitespace,
		},
	},
})
