vim.opt.runtimepath:append("$HOME/.local/share/treesitter")

vim.api.nvim_create_augroup("_cmd_win", { clear = true })
vim.api.nvim_create_autocmd("CmdWinEnter", {
	callback = function()
		vim.keymap.del("n", "<CR>", { buffer = true })
	end,
	group = "_cmd_win",
})

require("nvim-treesitter.configs").setup({

	-- these only exist to make "required" args happy
	sync_install = false,
	modules = {},
	ensure_installed = {},
	ignore_install = {},
	--

	auto_install = true,
	parser_install_dir = "$HOME/.local/share/treesitter",
	matchup = {
		enable = true,
	},

	highlight = {
		enable = true,
	},
	indent = {
		enable = true,
		disable = { "python" },
	},
	incremental_selection = {
		enable = true,
		keymaps = {
			init_selection = "<enter>",
			node_incremental = "<enter>",
			node_decremental = "<bs>",
		},
	},
	textobjects = {
		select = {
			enable = true,
			lookahead = true, -- Automatically jump forward to textobj, similar to targets.vim
			keymaps = {
				-- You can use the capture groups defined in textobjects.scm
				["aa"] = "@parameter.outer",
				["ia"] = "@parameter.inner",
				["af"] = "@function.outer",
				["if"] = "@function.inner",
				["ac"] = "@class.outer",
				["ic"] = "@class.inner",
			},
		},
		move = {
			enable = true,
			set_jumps = true, -- whether to set jumps in the jumplist
			goto_next_start = {
				["]m"] = "@function.outer",
				["]]"] = "@class.outer",
			},
			goto_next_end = {
				["]M"] = "@function.outer",
				["]["] = "@class.outer",
			},
			goto_previous_start = {
				["[m"] = "@function.outer",
				["[["] = "@class.outer",
			},
			goto_previous_end = {
				["[M"] = "@function.outer",
				["[]"] = "@class.outer",
			},
		},
		swap = {
			enable = true,
			swap_next = {
				["<leader>a"] = "@parameter.inner",
			},
			swap_previous = {
				["<leader>A"] = "@parameter.inner",
			},
		},
	},
})
