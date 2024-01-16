local cmp = require("cmp")
local compare = require("cmp.config.compare")
local cmp_autopairs = require("nvim-autopairs.completion.cmp")
local luasnip = require("luasnip")
local lspkind = require("lspkind")

cmp.setup({
	snippet = {
		expand = function(args)
			luasnip.lsp_expand(args.body)
		end,
	},
	mapping = cmp.mapping.preset.insert({
		["<C-Space>"] = cmp.mapping.complete(),
		["<C-e>"] = cmp.mapping.close(),
		["<CR>"] = cmp.mapping.confirm({
			behavior = cmp.ConfirmBehavior.Replace,
			select = false,
		}),
		["<C-CR>"] = cmp.mapping.confirm({
			behavior = cmp.ConfirmBehavior.Replace,
			select = true,
		}),
	}),
	sources = cmp.config.sources({
		{
			name = "nvim_lsp",
			priority = 8,
			entry_filter = function(entry)
				return cmp.lsp.CompletionItemKind.Snippet ~= entry:get_kind()
			end,
		},
		{ name = "nvim_lsp_signature_help", priority = 7 },
		{ name = "vim-dadbod-completion", priority = 6 },
		{ name = "cmp_git", priority = 5 },
		{ name = "nvim_lua", priority = 4 },
		{ name = "buffer", priority = 3 },
		{ name = "path", priority = 2 },
		{ name = "luasnip", priority = 1 },
	}),
	formatting = {
		format = lspkind.cmp_format({
			mode = "symbol_text",
			menu = {
				nvim_lsp = "[LSP]",
				nvim_lsp_signature_help = "[LSP SIG]",
				cmp_git = "[GIT]",
				nvim_lua = "[LUA]",
				luasnip = "[LuaSnip]",
				buffer = "[BUF]",
				path = "[PATH]",
				["vim-dadbod-completion"] = "[DB]",
			},
		}),
	},
	sorting = {
		priority_weight = 1.0,
		comparators = {
			compare.recently_used,
			compare.score,
			compare.locality,
			compare.offset,
			compare.order,
		},
	},
	preselect = cmp.PreselectMode.None,
	completion = {
		completeopt = "menu,menuone,noinsert,noselect",
	},
})

cmp.event:on("confirm_done", cmp_autopairs.on_confirm_done)
