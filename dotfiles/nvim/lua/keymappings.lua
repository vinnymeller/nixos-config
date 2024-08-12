local map = vim.keymap.set

map({ "n", "v" }, "<Space>", "<Nop>", { silent = true })
-- handle wordwrap better
map("n", "k", "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true })
map("n", "j", "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true })
map("i", "jk", "<Esc>", { desc = "jk to escape" })

-- Diagnostic keymaps
map("n", "<leader>e", vim.diagnostic.open_float)
map("n", "<leader>q", vim.diagnostic.setloclist)
map("n", "<leader>Q", vim.diagnostic.setqflist)

map("n", "<leader>dj", function()
	vim.diagnostic.jump({ count = vim.v.count1 })
end, { desc = "Jump to the next diagnostic in the current buffer" })

map("n", "<leader>dk", function()
	vim.diagnostic.jump({ count = -vim.v.count1 })
end, { desc = "Jump to the previous diagnostic in the current buffer" })

-- helpful visual mode mappings
map("v", ">", ">gv", { noremap = true })
map("v", "<", "<gv", { noremap = true })

-- backspace in normal mode to replace current word. can i upgrade this ? think about it
map("n", "<bs>", "ciw", { desc = "Change current word" })

-- open dadbod ui
map("n", "<leader>db", "<cmd>DBUIToggle<CR>", { desc = "[D]ad[B]od Toggle" })

local lsp_format = function()
	local fmt_server_name = nil
	local clients = vim.lsp.get_clients({ bufnr = vim.api.nvim_get_current_buf() })

	-- if efm client is available and can format, use it
	local efm_client = vim.tbl_filter(function(client)
		return client.name == "efm"
	end, clients)

	if not vim.tbl_isempty(efm_client) then
		efm_client = efm_client[1]
		-- check if our efm client has documentFormattingProvider capability
		-- check if efm has a formatCommand configured for the current filetype
		local efm_lang = efm_client.config.settings.languages[vim.bo.filetype]
		-- search all the tables in the lang config for a formatCommand key
		for _, config in ipairs(efm_lang) do
			if config.formatCommand ~= nil then
				fmt_server_name = efm_client.name
				break
			end
		end
	end

	-- if efm client isn't available, check if any other client can format
	if fmt_server_name == nil then
		for _, client in ipairs(clients) do
			if client.server_capabilities.documentFormattingProvider then
				fmt_server_name = client.name
				break
			end
		end
	end

	if fmt_server_name ~= nil then
		vim.lsp.buf.format({ name = fmt_server_name })
		vim.print("Formatted with LSP server: " .. fmt_server_name)
	else
		vim.print("No formatters available!")
	end
end

vim.api.nvim_create_user_command("LspFormat", lsp_format, { desc = "Format current buffer with LSP" })
map("n", "<leader>fm", "<cmd>LspFormat<CR>", { desc = "[F]ormat [M]anually" })
map("n", "<leader>;", ":<C-f>k", { desc = "Open command window" })
map("n", "<leader>.", "@:", { desc = "Repeat last command" })
map("n", "<leader>pp", "<cmd>lua require('precognition').toggle()<CR>", { desc = "[P]recognition Toggle" })

-- window resizing
map("n", "<M-h>", "<C-w>5<", { desc = "Decrease window width 5" })
map("n", "<M-l>", "<C-w>5>", { desc = "Increase window width 5" })
map("n", "<M-j>", "<C-w>-", { desc = "Decrease window height" })
map("n", "<M-k>", "<C-w>+", { desc = "Increase window height" })
