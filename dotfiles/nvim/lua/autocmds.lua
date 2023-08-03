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

-- stop fookin autocommenting when i go to a new line
vim.api.nvim_create_autocmd("BufEnter", {
	callback = function()
		vim.opt.formatoptions = vim.opt.formatoptions - { "c", "r", "o" }
	end,
})

-- automatically format on certain conditions that are unlikely to cause issues with cursor
--  commented this out because its annoying me  while i edit in nixpkgs, just fkin press <leader>fm if i need format so bad
-- vim.api.nvim_create_autocmd("WinLeave", {
-- 	callback = function()
-- 		-- silntry try calling a command
-- 		vim.cmd([[silent! FormatWrite]])
-- 	end,
-- })

-- copy last yank to system clipboard when nvim loses focus
vim.api.nvim_create_autocmd("FocusLost", {
	callback = function()
		vim.cmd([[call setreg("+", getreg("@"))]])
	end,
})

-- copy system clipboard to @ when nvim gains focus
vim.api.nvim_create_autocmd("FocusGained", {
	callback = function()
		vim.cmd([[call setreg("@", getreg("+"))]])
	end,
})
