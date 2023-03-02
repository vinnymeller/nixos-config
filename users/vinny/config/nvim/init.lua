local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim" -- :echo stdpath("data") will show the path on different OS
if not vim.loop.fs_stat(lazypath) then -- install lazy if it doesn't exist in the correct path
	vim.fn.system({
		"git",
		"clone",
		"--filter=blob:none",
		"--single-branch",
		"https://github.com/folke/lazy.nvim.git",
		lazypath,
	})
end
vim.opt.runtimepath:prepend(lazypath) --add lazy's path to runtimepath

local lazylock = "~/.nixdots/users/vinny/config/nvim/lazy-lock.json"
require("lazy").setup({
	-- theme stuff
	{ "catppuccin/nvim", name = "catppuccin" },
	"levouh/tint.nvim",
	"lukas-reineke/indent-blankline.nvim",
	"tamton-aquib/duck.nvim",
	{ "kyazdani42/nvim-tree.lua", dependencies = { "kyazdani42/nvim-web-devicons" }, tag = "nightly" },
	"nvim-lualine/lualine.nvim",

	-- lsp stuff
	{
		"neovim/nvim-lspconfig",
		dependencies = {
			"j-hui/fidget.nvim", -- LSP status updates
			"williamboman/mason.nvim",
			"williamboman/mason-lspconfig.nvim",
		},
	},
	"simrat39/rust-tools.nvim",

	-- autocompletion
	{
		"hrsh7th/nvim-cmp",
		dependencies = {
			"hrsh7th/cmp-nvim-lsp",
			"L3MON4D3/LuaSnip",
			"saadparwaiz1/cmp_luasnip",
			"hrsh7th/cmp-path",
			"hrsh7th/cmp-buffer",
		},
	},

	-- treesitter
	{
		"nvim-treesitter/nvim-treesitter",
		build = function()
			pcall(require("nvim-treesitter.install").update({ with_sync = true }))
		end,
		dependencies = {
			"nvim-treesitter/nvim-treesitter-textobjects",
			"nvim-treesitter/nvim-treesitter-context",
		},
	},

	-- git related
	{ "TimUntersberger/neogit", dependencies = { "sindrets/diffview.nvim" } },
	"APZelos/blamer.nvim",

	-- folke!
	"folke/which-key.nvim",

	-- tpope!
	"tpope/vim-fugitive",
	"tpope/vim-rhubarb",
	"tpope/vim-surround",

	"lewis6991/gitsigns.nvim",

	-- fun stuff
	"numToStr/Comment.nvim",
	"github/copilot.vim",

	-- telescope
	{ "nvim-telescope/telescope.nvim", branch = "0.1.x", dependencies = { "nvim-lua/plenary.nvim" } },

	-- formatting
	"mhartington/formatter.nvim",
	"gpanders/editorconfig.nvim",

    -- folding
    { "kevinhwang91/nvim-ufo", dependencies = { "kevinhwang91/promise-async"} },

	-- file previews
	{
		"iamcco/markdown-preview.nvim",
		build = function()
			vim.fn["mkdp#util#install"]()
		end,
	},

	{ "vinnymeller/swagger-preview.nvim", build = "npm install -g swagger-ui-watcher" },

	"nullishamy/autosave.nvim",
	"ggandor/leap.nvim",
	"windwp/nvim-autopairs",
	"mfussenegger/nvim-dap",
	"rcarriga/nvim-dap-ui",
	"michaeljsmith/vim-indent-object",
}, {
        lockfile = "~/.nixdots/users/vinny/config/nvim/lazy-lock.json"
    })

-- [[ Setting options ]]
-- See `:help vim.o`

vim.o.hlsearch = false

-- Make line numbers default
vim.o.number = true
vim.o.relativenumber = true
vim.o.hidden = true

vim.o.tabstop = 4
vim.o.softtabstop = 4
vim.o.shiftwidth = 4
vim.o.expandtab = true
vim.o.smartindent = true

vim.o.scrolloff = 12
vim.o.updatetime = 100

vim.o.colorcolumn = "120"
vim.o.breakindent = true

-- Save undo history
vim.o.undofile = true
vim.o.swapfile = false
vim.o.splitbelow = true
vim.o.splitright = true

-- Case insensitive searching UNLESS /C or capital in search
vim.o.ignorecase = true
vim.o.smartcase = true

vim.wo.signcolumn = "yes"

-- Set colorscheme
vim.o.termguicolors = true
-- vim.cmd([[colorscheme onedark]])
vim.g.catppuccin_flavour = "macchiato"
require("catppuccin").setup()
vim.cmd([[colorscheme catppuccin]])

-- Set completeopt to have a better completion experience
vim.o.completeopt = "menuone,noselect"

-- [[ Basic Keymaps ]]
-- Set <space> as the leader key
-- See `:help mapleader`
--  NOTE: Must happen before plugins are required (otherwise wrong leader will be used)
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Keymaps for better default experience
-- See `:help vim.keymap.set()`
vim.keymap.set({ "n", "v" }, "<Space>", "<Nop>", { silent = true })

vim.keymap.set("n", "<leader>ntt", require("nvim-tree").toggle, {})

-- Remap for dealing with word wrap
vim.keymap.set("n", "k", "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true })
vim.keymap.set("n", "j", "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true })
vim.keymap.set("n", "<Leader>fm", "<cmd>FormatWrite<CR>", {})

-- [[ Highlight on yank ]]
-- See `:help vim.highlight.on_yank()`
local highlight_group = vim.api.nvim_create_augroup("YankHighlight", { clear = true })
vim.api.nvim_create_autocmd("TextYankPost", {
	callback = function()
		vim.highlight.on_yank()
	end,
	group = highlight_group,
	pattern = "*",
})

-- Set lualine as statusline
-- See `:help lualine.txt`
require("lualine").setup({
	options = {
		icons_enabled = false,
		theme = "catppuccin",
		component_separators = "|",
		section_separators = "",
	},
})

-- Enable Comment.nvim
require("Comment").setup()

-- Gitsigns
-- See `:help gitsigns.txt`
require("gitsigns").setup({
	signs = {
		add = { text = "+" },
		change = { text = "~" },
		delete = { text = "_" },
		topdelete = { text = "‾" },
		changedelete = { text = "~" },
	},
})

-- [[ Configure Telescope ]]
-- See `:help telescope` and `:help telescope.setup()`
require("telescope").setup({
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
			".git/",
		},
	},
})

vim.keymap.set("i", "jk", "<Esc>", { desc = "jk to escape" })
-- See `:help telescope.builtin`
vim.keymap.set("n", "<leader>?", require("telescope.builtin").oldfiles, { desc = "[?] Find recently opened files" })
vim.keymap.set("n", "<leader><space>", require("telescope.builtin").buffers, { desc = "[ ] Find existing buffers" })
vim.keymap.set("n", "<leader>/", function()
	-- You can pass additional configuration to telescope to change theme, layout, etc.
	require("telescope.builtin").current_buffer_fuzzy_find(require("telescope.themes").get_dropdown({
		winblend = 20,
		previewer = false,
	}))
end, { desc = "[/] Fuzzily search in current buffer]" })
-- vim.keymap.set(
-- 	"n",
-- 	"<leader>/",
-- 	require("telescope.builtin").current_buffer_fuzzy_find,
-- 	{ desc = "[/] Fuzzily search in current buffer]" }
-- )

vim.keymap.set("n", "<leader>ff", require("telescope.builtin").find_files, { desc = "[F]ind [F]iles" })
vim.keymap.set("n", "<leader>fh", require("telescope.builtin").help_tags, { desc = "[F]ind [H]elp" })
vim.keymap.set("n", "<leader>fw", require("telescope.builtin").grep_string, { desc = "[F]ind current [W]ord" })
vim.keymap.set("n", "<leader>fg", require("telescope.builtin").live_grep, { desc = "[F]ind by [G]rep" })
vim.keymap.set("n", "<leader>fd", require("telescope.builtin").diagnostics, { desc = "[F]ind [D]iagnostics" })
vim.keymap.set("n", "<leader>fc", require("telescope.builtin").git_commits, { desc = "[F]ind Git [C]ommits" })
vim.keymap.set("n", "<leader>fk", require("telescope.builtin").keymaps, { desc = "[F]ind [K]eymaps" })

vim.keymap.set("n", "<leader>ng", require("neogit").open, { desc = "[N]eo[G]it" })

-- [[ Configure Treesitter ]]
-- See `:help nvim-treesitter`
require("nvim-treesitter.configs").setup({
	auto_install = true,
	-- Add languages to be installed here that you want installed for treesitter
	ensure_installed = { "c", "cpp", "go", "lua", "python", "rust", "typescript", "help" },

	highlight = { enable = true },
	indent = {
		enable = true,
		disable = { "python" },
	},
	incremental_selection = {
		enable = true,
		keymaps = {
			init_selection = "<c-space>",
			node_incremental = "<c-space>",
			scope_incremental = "<c-s>",
			node_decremental = "<c-backspace>",
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

-- Diagnostic keymaps
vim.keymap.set("n", "[d", vim.diagnostic.goto_prev)
vim.keymap.set("n", "]d", vim.diagnostic.goto_next)
vim.keymap.set("n", "<leader>e", vim.diagnostic.open_float)
vim.keymap.set("n", "<leader>q", vim.diagnostic.setloclist)
vim.keymap.set("n", "<leader>dj", vim.diagnostic.goto_next, { desc = "[D]iagnostic [J]ump" })
vim.keymap.set("n", "<leader>dk", vim.diagnostic.goto_prev, { desc = "[D]iagnostic Previous [O]k" })

-- LSP settings.
--  This function gets run when an LSP connects to a particular buffer.
local on_attach = function(_, bufnr)
	-- NOTE: Remember that lua is a real programming language, and as such it is possible
	-- to define small helper and utility functions so you don't have to repeat yourself
	-- many times.
	--
	-- In this case, we create a function that lets us more easily define mappings specific
	-- for LSP related items. It sets the mode, buffer and description for us each time.
	local nmap = function(keys, func, desc)
		if desc then
			desc = "LSP: " .. desc
		end

		vim.keymap.set("n", keys, func, { buffer = bufnr, desc = desc })
	end

	nmap("<leader>rn", vim.lsp.buf.rename, "[R]e[n]ame")
	nmap("<leader>ca", vim.lsp.buf.code_action, "[C]ode [A]ction")

	nmap("gd", vim.lsp.buf.definition, "[G]oto [D]efinition")
	nmap("gr", require("telescope.builtin").lsp_references, "[G]oto [R]eferences")
	nmap("gI", vim.lsp.buf.implementation, "[G]oto [I]mplementation")
	nmap("<leader>D", vim.lsp.buf.type_definition, "Type [D]efinition")
	nmap("<leader>ds", require("telescope.builtin").lsp_document_symbols, "[D]ocument [S]ymbols")
	nmap("<leader>ws", require("telescope.builtin").lsp_dynamic_workspace_symbols, "[W]orkspace [S]ymbols")

	-- See `:help K` for why this keymap
	nmap("K", vim.lsp.buf.hover, "Hover Documentation")
	nmap("<C-k>", vim.lsp.buf.signature_help, "Signature Documentation")

	-- Lesser used LSP functionality
	nmap("gD", vim.lsp.buf.declaration, "[G]oto [D]eclaration")
	nmap("<leader>wa", vim.lsp.buf.add_workspace_folder, "[W]orkspace [A]dd Folder")
	nmap("<leader>wr", vim.lsp.buf.remove_workspace_folder, "[W]orkspace [R]emove Folder")
	nmap("<leader>wl", function()
		print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
	end, "[W]orkspace [L]ist Folders")

	-- Create a command `:Format` local to the LSP buffer
	vim.api.nvim_buf_create_user_command(bufnr, "Format", function(_)
		if vim.lsp.buf.format then
			vim.lsp.buf.format()
		elseif vim.lsp.buf.formatting then
			vim.lsp.buf.formatting()
		end
	end, { desc = "Format current buffer with LSP" })
end

-- nvim-cmp supports additional completion capabilities
local capabilities = vim.lsp.protocol.make_client_capabilities()
capabilities = require("cmp_nvim_lsp").default_capabilities(capabilities)

require("mason").setup()

require("mason-lspconfig").setup({
	ensure_installed = { "rust_analyzer", "pylsp", "yamlls", "lua_ls", "rnix" },
})

require("mason-lspconfig").setup_handlers({
	function(server_name)
		require("lspconfig")[server_name].setup({
			on_attach = on_attach,
			capabilities = capabilities,
		})
	end,
	["rust_analyzer"] = function()
		local rt = require("rust-tools")
		rt.setup({
			server = {
				-- setup rust specific lsp keymaps
				on_attach = function(_, bufnr)
					on_attach(_, bufnr)
					vim.keymap.set("n", "<leader>ha", rt.hover_actions.hover_actions, { buffer = bufnr })
					vim.keymap.set("n", "<leader>cg", rt.code_action_group.code_action_group, { buffer = bufnr })
					vim.keymap.set("n", "<leader>me", rt.expand_macro.expand_macro, { buffer = bufnr })
					vim.keymap.set("n", "<leader>oc", rt.open_cargo_toml.open_cargo_toml, { buffer = bufnr })
				end,
				capabilities = capabilities,
			},
		})
	end,
	["yamlls"] = function()
		require("lspconfig").yamlls.setup({
			capabilities = capabilities,
			on_attach = on_attach,
			settings = {
				yaml = {
					schemas = {
						["https://json.schemastore.org/github-workflow.json"] = ".github/workflows/*",
						["https://json.schemastore.org/swagger-2.0.json"] = "swagger*.yaml",
					},
				},
			},
		})
	end,
	["lua_ls"] = function()
		-- Make runtime files discoverable to the server
		local runtime_path = vim.split(package.path, ";")
		table.insert(runtime_path, "lua/?.lua")
		table.insert(runtime_path, "lua/?/init.lua")

		require("lspconfig").lua_ls.setup({
			on_attach = on_attach,
			capabilities = capabilities,
			settings = {
				Lua = {
					runtime = {
						-- Tell the language server which version of Lua you're using (most likely LuaJIT)
						version = "LuaJIT",
						-- Setup your lua path
						path = runtime_path,
					},
					diagnostics = {
						globals = { "vim" },
					},
					workspace = { library = vim.api.nvim_get_runtime_file("", true) },
					-- Do not send telemetry data containing a randomized but unique identifier
					telemetry = { enable = false },
				},
			},
		})
	end,
	["pylsp"] = function()
		require("lspconfig").pylsp.setup({
			on_attach = on_attach,
			capabilities = capabilities,
			settings = {
				pylsp = {
					plugins = {
						pycodestyle = {
							ignore = { "W391", "E501" },
						},
					},
				},
			},
		})
	end,
})

-- Turn on lsp status information
require("fidget").setup()

-- Example custom configuration for lua
--

-- nvim-cmp setup
local cmp = require("cmp")
local luasnip = require("luasnip")

cmp.setup({
	snippet = {
		expand = function(args)
			luasnip.lsp_expand(args.body)
		end,
	},
	mapping = cmp.mapping.preset.insert({
		["<C-Space>"] = cmp.mapping.complete(),
		["<C-e>"] = cmp.mapping.abort(),
		["<CR>"] = cmp.mapping.confirm({
			behavior = cmp.ConfirmBehavior.Replace,
			select = false,
		}),
		["<C-CR>"] = cmp.mapping.confirm({
			behavior = cmp.ConfirmBehavior.Replace,
			select = true,
		}),
	}),
	sources = {
		{ name = "nvim_lsp" },
		{ name = "luasnip" },
		{ name = "buffer" },
		{ name = "path" },
	},
})

require("nvim-autopairs").setup({})
require("which-key").setup({})

vim.g.copilot_filetypes = {
	["*"] = true,
}

require("swagger-preview").setup({})

require("tint").setup({
	tint = -20,
	saturation = 0.75,
})

require("leap").set_default_keymaps()

require("neogit").setup({
	integrations = {
		diffview = true,
	},
})

require("diffview").setup({})

vim.g.blamer_enabled = 1
vim.g.blamer_delay = 200

-- indent-blankline config for rainbow indents
vim.opt.termguicolors = true
vim.cmd([[highlight IndentBlanklineIndent1 guifg=#E06C75 gui=nocombine]])
vim.cmd([[highlight IndentBlanklineIndent2 guifg=#E5C07B gui=nocombine]])
vim.cmd([[highlight IndentBlanklineIndent3 guifg=#98C379 gui=nocombine]])
vim.cmd([[highlight IndentBlanklineIndent4 guifg=#56B6C2 gui=nocombine]])
vim.cmd([[highlight IndentBlanklineIndent5 guifg=#61AFEF gui=nocombine]])
vim.cmd([[highlight IndentBlanklineIndent6 guifg=#C678DD gui=nocombine]])

vim.opt.list = true
-- vim.opt.listchars:append "space:\u22c5"
-- vim.opt.listchars:append "eol:\u21b4"

require("indent_blankline").setup({
	space_char_blankline = " ",
	char_highlight_list = {
		"IndentBlanklineIndent1",
		"IndentBlanklineIndent2",
		"IndentBlanklineIndent3",
		"IndentBlanklineIndent4",
		"IndentBlanklineIndent5",
		"IndentBlanklineIndent6",
	},
})

-- use mason to install formatters. not sure how to automate this part yet
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
			require("formatter.filetypes.sql").sqlformat,
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

-- stop fookin autocommenting when i go to a new line
vim.api.nvim_create_autocmd("BufEnter", {
	callback = function()
		vim.opt.formatoptions = vim.opt.formatoptions - { "c", "r", "o" }
	end,
})

-- automatically format on certain conditions that are unlikely to cause issues with cursor
vim.api.nvim_create_autocmd("WinLeave", {
	callback = function()
		-- silntry try calling a command
        vim.cmd([[silent! FormatWrite]])
	end,
})

require("nvim-tree").setup({
	sort_by = "case_sensitive",
	view = {
		adaptive_size = true,
	},
	filters = {
		dotfiles = false,
	},
})

require("autosave").setup({})
