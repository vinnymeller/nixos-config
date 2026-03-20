require("conform").setup({
	default_format_opts = {
		lsp_format = "fallback",
	},
	notify_on_error = true,
	notify_no_formatters = true,
	formatters_by_ft = {
		-- universal: always available via extraPackages
		lua = { "stylua" },
		nix = { "nixfmt" },
		sh = { "shfmt" },
		sql = { "sql_formatter" },

		-- environment-provided: come from devshells
		python = { "ruff_format", "isort", "black" },
		javascript = { "prettier" },
		typescript = { "prettier" },
		typescriptreact = { "prettier" },
		javascriptreact = { "prettier" },
		json = { "prettier" },
		yaml = { "prettier" },
		go = { "goimports", "gofmt" },
		rust = { "rustfmt", lsp_format = "fallback" },

		-- fallback
		["_"] = { "trim_whitespace" },
	},
})

vim.keymap.set("n", "<leader>fm", function()
	require("conform").format({ async = true, lsp_format = "fallback" })
end, { desc = "[F]ormat [M]anually" })
