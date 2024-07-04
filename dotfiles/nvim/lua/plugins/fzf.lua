local actions = require("fzf-lua").actions

-- TODO: some of this stuff just doesn't do anything / is broken
require("fzf-lua").setup({
	fzf_opts = { ["--layout"] = "default", ["--marker"] = "+" },
	winopts = {
		width = 0.8,
		height = 0.9,
		preview = {
			hidden = "nohidden",
			vertical = "up:45%",
			horizontal = "right:50%",
			layout = "flex",
			flip_columns = 120,
			delay = 10,
			winopts = { number = false },
		},
	},
	keymap = {
		builtin = {
			["<F1>"] = "toggle-help",
			["<F2>"] = "toggle-fullscreen",
			-- Only valid with the 'builtin' previewer
			["<F3>"] = "toggle-preview-wrap",
			["<F4>"] = "toggle-preview",
			["<F5>"] = "toggle-preview-ccw",
			["<F6>"] = "toggle-preview-cw",
			["<C-f>"] = "preview-page-down",
			["<C-d>"] = "preview-page-up",
		},
		fzf = {
			["alt-a"] = "toggle-all",
			-- Only valid with fzf previewers (bat/cat/git/etc)
			["f3"] = "toggle-preview-wrap",
			["f4"] = "toggle-preview",
		},
	},
	actions = {
		files = {
			["default"] = actions.file_edit_or_qf,
			["ctrl-s"] = actions.file_split,
			["ctrl-v"] = actions.file_vsplit,
			["ctrl-t"] = actions.file_tabedit,
			["alt-q"] = actions.file_sel_to_qf,
			["alt-l"] = actions.file_sel_to_ll,
			["ctrl-q"] = { fn = actions.file_sel_to_qf, prefix = "select-all+" },
		},
		buffers = {
			["default"] = actions.buf_edit,
			["ctrl-s"] = actions.buf_split,
			["ctrl-v"] = actions.buf_vsplit,
			["ctrl-t"] = actions.buf_tabedit,
		},
	},
	buffers = {
		keymap = { builtin = { ["<C-d>"] = false } },
		actions = { ["ctrl-x"] = false, ["ctrl-d"] = { actions.buf_del, actions.resume } },
	},
})

vim.keymap.set("n", "sb", "<cmd>lua require('fzf-lua').buffers()<CR>", { desc = "[S]earch [B]uffers" })
vim.keymap.set("n", "sc", "<cmd>lua require('fzf-lua').changes()<CR>", { desc = "[S]earch [C]hanges" })
vim.keymap.set("n", "sc", "<cmd>lua require('fzf-lua').commands()<CR>", { desc = "[S]earch [C]ommands" })
vim.keymap.set(
	"n",
	"s<C-c>",
	"<cmd>lua require('fzf-lua').command_history()<CR>",
	{ desc = "[S]earch [C]ommand History" }
)
vim.keymap.set(
	"n",
	"sd",
	"<cmd>lua require('fzf-lua').diagnostics_document()<CR>",
	{ desc = "[S]earch Document [D]iagnostics" }
)
vim.keymap.set(
	"n",
	"sD",
	"<cmd>lua require('fzf-lua').diagnostics_workspace()<CR>",
	{ desc = "[S]earch Workspace [D]iagnostics" }
)
vim.keymap.set("n", "sf", "<cmd>lua require('fzf-lua').files()<CR>", { desc = "[S]earch [F]iles" })
vim.keymap.set("n", "sg", "<cmd>lua require('fzf-lua').live_grep_native()<CR>", { desc = "[S]earch [G]rep" })
vim.keymap.set("n", "sG", "<cmd>lua require('fzf-lua').live_grep_glob()<CR>", { desc = "[S]earch [G]lob" })
vim.keymap.set("n", "s<C-g>", "<cmd>lua require('fzf-lua').git_status()<CR>", { desc = "[S]earch [G]it Status" })
vim.keymap.set("n", "sh", "<cmd>lua require('fzf-lua').help_tags()<CR>", { desc = "[S]earch [H]elp" })
vim.keymap.set("n", "sj", "<cmd>lua require('fzf-lua').jumps()<CR>", { desc = "[S]earch [J]umps" })
vim.keymap.set("n", "sk", "<cmd>lua require('fzf-lua').keymaps()<CR>", { desc = "[S]earch [K]eymaps" })
vim.keymap.set("n", "sr", "<cmd>lua require('fzf-lua').resume()<CR>", { desc = "[S]earch [R]esume" })
vim.keymap.set("n", "sw", "<cmd>lua require('fzf-lua').grep_cword()<CR>", { desc = "[S]earch [W]ord" })
vim.keymap.set("n", "sW", "<cmd>lua require('fzf-lua').grep_cWORD()<CR>", { desc = "[S]earch [W]ORD" })
vim.keymap.set("n", "s/", "<cmd>lua require('fzf-lua').lgrep_curbuf()<CR>", { desc = "[S]earch [/]" })
