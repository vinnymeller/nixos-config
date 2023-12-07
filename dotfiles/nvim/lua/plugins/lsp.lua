vim.api.nvim_create_autocmd("LspAttach", {
	group = vim.api.nvim_create_augroup("UserLspConfig", {}),
	callback = function(args)
		-- NOTE: Remember that lua is a real programming language, and as such it is possible
		-- to define small helper and utility functions so you don't have to repeat yourself
		-- many times.
		--
		-- In this case, we create a function that lets us more easily define mappings specific
		-- for LSP related items. It sets the mode, buffer and description for us each time.
		local client = vim.lsp.get_client_by_id(args.data.client_id)
		local nmap = function(keys, func, desc)
			if desc then
				desc = "LSP: " .. desc
			end

			vim.keymap.set("n", keys, func, { buffer = args.buf, desc = desc })
		end

		nmap("<leader>rn", vim.lsp.buf.rename, "[R]e[n]ame")
		nmap("<leader>ca", vim.lsp.buf.code_action, "[C]ode [A]ction")

		nmap("gd", vim.lsp.buf.definition, "[G]oto [D]efinition")
		nmap("gr", require("telescope.builtin").lsp_references, "[G]oto [R]eferences")
		nmap("gI", vim.lsp.buf.implementation, "[G]oto [I]mplementation")
		nmap("<leader>D", vim.lsp.buf.type_definition, "Type [D]efinition")
		nmap("<leader>ds", require("telescope.builtin").lsp_document_symbols, "[D]ocument [S]ymbols")
		nmap("<leader>ws", require("telescope.builtin").lsp_dynamic_workspace_symbols, "[W]orkspace [S]ymbols")
		nmap("<leader>lr", "<cmd>LspRestart<CR>", "[L]sp [R]estart")

		-- See `:help K` for why this keymap
		nmap("K", vim.lsp.buf.hover, "Hover Documentation")
		-- nmap("<C-k>", vim.lsp.buf.signature_help, "Signature Documentation") -- dont think ive ever used this

		-- Lesser used LSP functionality
		nmap("gD", vim.lsp.buf.declaration, "[G]oto [D]eclaration")
		nmap("<leader>wa", vim.lsp.buf.add_workspace_folder, "[W]orkspace [A]dd Folder")
		nmap("<leader>wr", vim.lsp.buf.remove_workspace_folder, "[W]orkspace [R]emove Folder")
		nmap("<leader>wl", function()
			print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
		end, "[W]orkspace [L]ist Folders")

		-- Create a command `:Format` local to the LSP buffer
		vim.api.nvim_buf_create_user_command(args.buf, "Format", function(_)
			if vim.lsp.buf.format then
				vim.lsp.buf.format()
			elseif vim.lsp.buf.formatting then
				vim.lsp.buf.formatting()
			end
		end, { desc = "Format current buffer with LSP" })

		if client.server_capabilities.inlayHintProvider then
			vim.lsp.inlay_hint(args.buf, true)
		end
	end,
})

-- nvim-cmp supports additional completion capabilities
local capabilities = vim.lsp.protocol.make_client_capabilities()
capabilities = require("cmp_nvim_lsp").default_capabilities(capabilities)

require("lspconfig").lua_ls.setup({
	-- on_attach = on_attach,
	capabilities = capabilities,
	settings = {
		Lua = {
			hint = {
				enable = true,
			},
			runtime = {
				-- Tell the language server which version of Lua you're using (most likely LuaJIT)
				version = "LuaJIT",
			},
			diagnostics = {
				globals = { "vim" },
			},
			workspace = {
				library = vim.api.nvim_get_runtime_file("", true),
				checkThirdParty = false,
			},
			-- Do not send telemetry data containing a randomized but unique identifier
			telemetry = { enable = false },
		},
	},
})

require("lspconfig").ltex.setup({
	capabilities = capabilities,
	settings = {
		ltex = {
			language = "en-US",
			additionalRules = {
				languageModel = "~/.ngrams/",
			},
		},
	},
})

local basic_servers = {
	"clangd",
	"hls",
	"nil_ls",
	"ocamllsp",
	"pyright",
	"terraformls",
	"yamlls",
}

for _, lsp in ipairs(basic_servers) do
	require("lspconfig")[lsp].setup({
		capabilities = capabilities,
	})
end

-- Turn on lsp status information
require("fidget").setup()
