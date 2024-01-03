require("sg").setup()

local nmap = function(keys, func, desc)
	if desc then
		desc = "LSP: " .. desc
	end

	vim.keymap.set("n", keys, func, { desc = desc })
end

nmap("<leader>ss", "<cmd>lua require('sg.extensions.telescope').fuzzy_search_results()<CR>", "[S]ourcegraph [S]earch")
