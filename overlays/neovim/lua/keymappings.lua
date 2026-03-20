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
map("v", "J", ":m '>+1<CR>gv=gv", { desc = "Move selection down" })
map("v", "K", ":m '<-2<CR>gv=gv", { desc = "Move selection up" })

-- paste over selection without clobbering register (default behavior)
-- use <leader>p to paste and *replace* the register with what was selected
map("x", "p", '"_dP', { desc = "Paste without clobbering register" })
map("x", "<leader>p", "p", { desc = "Paste (clobber register with selection)" })

-- keep cursor centered when jumping
map("n", "<C-d>", "<C-d>zz")
map("n", "<C-u>", "<C-u>zz")
map("n", "n", "nzzzv")
map("n", "N", "Nzzzv")

-- backspace in normal mode to replace current word. can i upgrade this ? think about it
map("n", "<bs>", "ciw", { desc = "Change current word" })

-- open dadbod ui
map("n", "<leader>db", "<cmd>DBUIToggle<CR>", { desc = "[D]ad[B]od Toggle" })

map("n", "<leader>bd", "<cmd>bdelete<CR>", { desc = "[B]uffer [D]elete" })

-- <leader>fm is now handled by conform.lua
map("n", "<leader>;", ":<C-f>k", { desc = "Open command window" })
map("n", "<leader>.", "@:", { desc = "Repeat last command" })

-- tabs
map("n", "<leader>tn", "<cmd>tabnew<CR>", { desc = "[T]ab [N]ew" })
map("n", "<leader>tc", "<cmd>tabclose<CR>", { desc = "[T]ab [C]lose" })
map("n", "<leader>tl", "<cmd>tabnext<CR>", { desc = "[T]ab next (right)" })
map("n", "<leader>th", "<cmd>tabprevious<CR>", { desc = "[T]ab previous (left)" })
map("n", "<leader>to", "<cmd>tabonly<CR>", { desc = "[T]ab [O]nly (close all others)" })
map("n", "<leader>tmr", "<cmd>+tabmove<CR>", { desc = "[T]ab [M]ove [R]ight" })
map("n", "<leader>tml", "<cmd>-tabmove<CR>", { desc = "[T]ab [M]ove [L]eft" })

-----------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------

--- window resizing
local resize_amount = 5

local function is_at_edge(edge)
	local win_id = vim.api.nvim_get_current_win()
	-- Renamed to nvim_win_get_position in recent Neovim versions
	local win_pos = vim.api.nvim_win_get_position(win_id)
	local win_width = vim.api.nvim_win_get_width(win_id)
	local win_height = vim.api.nvim_win_get_height(win_id)

	local row = win_pos[1]
	local col = win_pos[2]
	if edge == "left" then
		return col == 0
	elseif edge == "right" then
		return (col + win_width) == vim.o.columns
	elseif edge == "top" then
		return row == 0
	elseif edge == "bottom" then
		-- the extra -1 is for lualine
		return (row + win_height) == vim.o.lines - vim.o.cmdheight - 1
	end
	return false
end

local function directional_push_left()
	if is_at_edge("left") then
		vim.cmd("vertical resize -" .. resize_amount)
	else
		local original_win = vim.api.nvim_get_current_win()
		vim.cmd.wincmd("h") -- Move to the left neighbor
		vim.cmd("vertical resize -" .. resize_amount) -- Shrink it
		vim.api.nvim_set_current_win(original_win) -- Go back
	end
end

local function directional_push_right()
	if is_at_edge("right") then
		local original_win = vim.api.nvim_get_current_win()
		vim.cmd.wincmd("h") -- Move to the left neighbor
		vim.cmd("vertical resize +" .. resize_amount) -- Expand it
		vim.api.nvim_set_current_win(original_win) -- Go back
	else
		vim.cmd("vertical resize +" .. resize_amount)
	end
end

local function directional_push_up()
	if is_at_edge("top") then
		local original_cmdheight = vim.o.cmdheight
		vim.cmd("resize -" .. resize_amount)
		vim.o.cmdheight = original_cmdheight -- Restore cmdheight
	else
		local original_win = vim.api.nvim_get_current_win()
		vim.cmd.wincmd("k") -- Move to the neighbor above
		vim.cmd("resize -" .. resize_amount) -- Shrink it
		vim.api.nvim_set_current_win(original_win) -- Go back
	end
end

local function directional_push_down()
	if is_at_edge("bottom") then
		local original_win = vim.api.nvim_get_current_win()
		vim.cmd.wincmd("k") -- Move to the neighbor above
		vim.cmd("resize +" .. resize_amount) -- Expand it
		vim.api.nvim_set_current_win(original_win) -- Go back
	else
		vim.cmd("resize +" .. resize_amount)
	end
end

map("n", "<M-h>", directional_push_left, { silent = true, desc = "Push window left" })
map("n", "<M-l>", directional_push_right, { silent = true, desc = "Push window right" })
map("n", "<M-j>", directional_push_down, { silent = true, desc = "Push window down" })
map("n", "<M-k>", directional_push_up, { silent = true, desc = "Push window up" })

map("n", "<leader>dst", function()
	vim.o.number = not vim.o.number
	vim.o.relativenumber = not vim.o.relativenumber
	require("gitsigns").toggle_signs()
	require("ibl").setup_buffer(0, {
		enabled = not require("ibl.config").get_config(0).enabled,
	})
end, { desc = "Toggle decorative stuff for copy/pasting" })

map("n", "<leader>df", "<cmd>DiffviewOpen<CR>", { desc = "[D]iffview current [File]" })
map("n", "<leader>dF", "<cmd>DiffviewFileHistory %<CR>", { desc = "[D]iffview current [File]" })

-- resurrected dadbod treesitter keybind
vim.api.nvim_create_autocmd("FileType", {
	pattern = "sql",
	callback = function(args)
		local function find_statement()
			local node = vim.treesitter.get_node()
			while node and node:type() ~= "statement" do
				node = node:parent()
			end
			if not node then
				local row = vim.api.nvim_win_get_cursor(0)[1] - 1
				while row >= 0 do
					node = vim.treesitter.get_node({ pos = { row, 0 } })
					while node and node:type() ~= "statement" do
						node = node:parent()
					end
					if node then
						break
					end
					row = row - 1
				end
			end
			return node
		end

		local execute_plug = vim.api.nvim_replace_termcodes("<Plug>(DBUI_ExecuteQuery)", true, true, true)

		vim.keymap.set("n", "<leader>e", function()
			local cursor = vim.api.nvim_win_get_cursor(0)
			local node = find_statement()
			if not node then
				vim.notify("No SQL statement found", vim.log.levels.WARN)
				return
			end
			local sr, sc, er, ec = node:range()
			vim.api.nvim_win_set_cursor(0, { sr + 1, sc })
			vim.cmd("normal! v")
			vim.api.nvim_win_set_cursor(0, { er + 1, ec - 1 })
			vim.fn.feedkeys(execute_plug, "x")
			vim.schedule(function()
				vim.api.nvim_win_set_cursor(0, cursor)
			end)
		end, { buffer = args.buf, desc = "Execute current SQL statement" })

		vim.keymap.set("v", "<leader>e", function()
			vim.fn.feedkeys(execute_plug, "x")
		end, { buffer = args.buf, desc = "Execute selected SQL" })

		vim.keymap.set("n", "<leader>j", function()
			local node = find_statement()
			if not node then
				return
			end
			local sibling = node:next_named_sibling()
			if sibling and sibling:type() == "statement" then
				local row, col = sibling:range()
				vim.api.nvim_win_set_cursor(0, { row + 1, col })
			end
		end, { buffer = args.buf, desc = "Jump to next SQL statement" })

		vim.keymap.set("n", "<leader>k", function()
			local node = find_statement()
			if not node then
				return
			end
			local sibling = node:prev_named_sibling()
			if sibling and sibling:type() == "statement" then
				local row, col = sibling:range()
				vim.api.nvim_win_set_cursor(0, { row + 1, col })
			end
		end, { buffer = args.buf, desc = "Jump to previous SQL statement" })
	end,
})
