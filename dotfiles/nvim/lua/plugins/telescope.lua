local telescope = require("telescope")
local telescope_builtin = require("telescope.builtin")
local lga_actions = require("telescope-live-grep-args.actions")
local trouble = require("trouble.providers.telescope")

telescope.setup({
	pickers = {
		find_files = {
			hidden = true,
		},
		live_grep = {
			hidden = true,
		},
	},
	defaults = {
		file_ignore_patterns = {
			"%.git/",
			"node_modules/",
			"target/",
			"dist/",
			"build/",
			"vendor/",
			"bin/",
			"__pycache__/",
			"venv/",
			"%.direnv/",
			"%.cargo/",
		},
		mappings = {
			i = {
				["<C-t>"] = trouble.open_with_trouble,
			},
			n = {
				["<C-t>"] = trouble.open_with_trouble,
			},
		},
	},
	extensions = {
		ast_grep = {
			command = {
				"ast-grep",
				"-p",
				"--json=stream",
			},
			grep_open_files = false,
			lang = nil,
		},
		live_grep_args = {
			auto_quoting = true,
			mappings = {
				i = {
					["<C-k>"] = lga_actions.quote_prompt(),
					["<C-i>"] = lga_actions.quote_prompt({ postfix = " --iglob " }),
				},
			},
		},
	},
})

require("telescope").load_extension("ast_grep")
require("telescope").load_extension("live_grep_args")
require("telescope").load_extension("jsonfly")

vim.keymap.set("n", "<leader>?", require("telescope.builtin").oldfiles, { desc = "[?] Find recently opened files" })
vim.keymap.set("n", "<leader><space>", require("telescope.builtin").buffers, { desc = "[ ] Find existing buffers" })
vim.keymap.set("n", "<leader>/", function()
	-- You can pass additional configuration to telescope to change theme, layout, etc.
	require("telescope.builtin").current_buffer_fuzzy_find(require("telescope.themes").get_dropdown({
		winblend = 20,
		previewer = false,
	}))
end, { desc = "[/] Fuzzily search in current buffer]" })

vim.keymap.set("n", "<leader>ff", require("telescope.builtin").find_files, { desc = "[F]ind [F]iles" })
vim.keymap.set("n", "<leader>fh", require("telescope.builtin").help_tags, { desc = "[F]ind [H]elp" })
vim.keymap.set("n", "<leader>fw", require("telescope.builtin").grep_string, { desc = "[F]ind current [W]ord" })
-- vim.keymap.set("n", "<leader>fg", require("telescope.builtin").live_grep, { desc = "[F]ind by [G]rep" })
vim.keymap.set(
	"n",
	"<leader>fg",
	"<cmd>lua require('telescope').extensions.live_grep_args.live_grep_args()<CR>",
	{ desc = "[F]ind by [G]rep" }
)
vim.keymap.set("n", "<leader>fd", require("telescope.builtin").diagnostics, { desc = "[F]ind [D]iagnostics" })
vim.keymap.set("n", "<leader>fc", require("telescope.builtin").git_commits, { desc = "[F]ind Git [C]ommits" })
vim.keymap.set("n", "<leader>fk", require("telescope.builtin").keymaps, { desc = "[F]ind [K]eymaps" })
vim.keymap.set("n", "<leader>fa", "<cmd>Telescope ast_grep<cr>", { desc = "[F]ind [A]ST" })
