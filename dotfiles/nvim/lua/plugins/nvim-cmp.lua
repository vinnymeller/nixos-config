local cmp = require("cmp")

local cmp_autopairs = require("nvim-autopairs.completion.cmp")
local luasnip = require("luasnip")
local lspkind = require("lspkind")
require("copilot_cmp").setup({})
require("cmp_git").setup({})

lspkind.init({
	symbol_map = {
		Copilot = "",
	},
})

vim.api.nvim_set_hl(0, "CmpItemKindCopilot", { fg = "#6CC644" })

local strict_source_name_preference = function(source_name)
	return function(entry1, entry2)
		if entry1.source.name == entry2.source.name then
			return nil
		end
		if entry1.source.name == source_name then
			return true
		end
		if entry2.source.name == source_name then
			return false
		end
	end
end

vim.o.pumheight = 20

cmp.setup({
	enabled = function()
		return true
	end,
	window = {
		completion = {
			winhighlight = "Normal:CmpPmenu,FloatBorder:CmpPmenuBorder,CursorLine:PmenuSel,Search:None,luaParenError:NormalFloat,luaError:NormalFloat",
		},
		documentation = {
			max_height = 50,
			winhighlight = "Normal:CmpPmenu,FloatBorder:CmpPmenuBorder,CursorLine:PmenuSel,Search:None,luaParenError:NormalFloat,luaError:NormalFloat",
		},
	},
	view = {
		entries = {
			name = "custom",
			selection_order = "near_cursor",
			follow_cursor = true,
		},
		docs = {
			auto_open = true,
		},
	},
	snippet = {
		expand = function(args)
			luasnip.lsp_expand(args.body)
		end,
	},
	mapping = cmp.mapping.preset.insert({
		["<C-d>"] = cmp.mapping.scroll_docs(-4),
		["<C-f>"] = cmp.mapping.scroll_docs(4),
		["<C-Space>"] = cmp.mapping.complete(),
		["<C-e>"] = cmp.mapping.close(),
		["<Tab>"] = cmp.mapping.confirm(),
		["<C-CR>"] = cmp.mapping.confirm(),
		["<C-n>"] = cmp.mapping.select_next_item({ behavior = cmp.SelectBehavior.Select }),
		["<C-p>"] = cmp.mapping.select_prev_item({ behavior = cmp.SelectBehavior.Select }),
	}),
	sources = {
		{ name = "nvim_lsp_signature_help" },
		{
			name = "nvim_lsp",
			entry_filter = function(entry)
				return entry:get_kind() ~= cmp.lsp.CompletionItemKind.Snippet
			end,
		},
		{ name = "copilot" },
		{ name = "vim-dadbod-completion" },
		{ name = "git" },
		{ name = "nvim_lua" },
		{ name = "buffer" },
		{ name = "path" },
	},
	formatting = {
		format = lspkind.cmp_format({
			max_width = 60,
			mode = "symbol_text",
			menu = {
				nvim_lsp_signature_help = "[SIG]",
				copilot = "[AI]",
				nvim_lsp = "[LSP]",
				git = "[GIT]",
				nvim_lua = "[LUA]",
				luasnip = "[SNIP]",
				buffer = "[BUF]",
				path = "[PATH]",
				["vim-dadbod-completion"] = "[DB]",
			},
		}),
	},
	sorting = {
		priority_weight = 2.0,
		comparators = {
			strict_source_name_preference("nvim_lsp_signature_help"),
			strict_source_name_preference("copilot"),
			cmp.config.compare.offset,
			cmp.config.compare.exact,
			cmp.config.compare.score,
			-- copied from cmp-under, but I don't think I need the plugin for this.
			-- I might add some more of my own.
			function(entry1, entry2)
				local _, entry1_under = entry1.completion_item.label:find("^_+")
				local _, entry2_under = entry2.completion_item.label:find("^_+")
				entry1_under = entry1_under or 0
				entry2_under = entry2_under or 0
				if entry1_under > entry2_under then
					return false
				elseif entry1_under < entry2_under then
					return true
				end
			end,

			cmp.config.compare.kind,
			cmp.config.compare.sort_text,
			cmp.config.compare.length,
			cmp.config.compare.order,
		},
	},
	nvim_lsp_signature_help = {
		max_height = 50
	},
	preselect = cmp.PreselectMode.None,
	completion = {
		autocomplete = {
			cmp.TriggerEvent.InsertEnter,
			cmp.TriggerEvent.TextChanged,
		},
		completeopt = "menu,menuone,noinsert",
	},
	experimental = {
		ghost_text = true,
	},
})

cmp.event:on("confirm_done", cmp_autopairs.on_confirm_done())

cmp.setup.cmdline({ "/", "?" }, {
	mapping = cmp.mapping.preset.cmdline(),
	view = {
		entries = { name = "wildmenu" },
	},
	sources = {
		{ name = "buffer" },
	},
})

cmp.setup.cmdline(":", {
	mapping = cmp.mapping.preset.cmdline(),
	view = {
		entries = { name = "wildmenu" },
	},
	sources = cmp.config.sources({
		{ name = "path" },
	}, {
		{
			name = "cmdline",
			option = {
				ignore_cmds = {}, -- this lets us get shell completion for ! commands, for some reason its ignored by default
			},
		},
	}),
})
