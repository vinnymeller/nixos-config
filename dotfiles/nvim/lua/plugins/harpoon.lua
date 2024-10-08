local harpoon = require("harpoon")

harpoon:setup()

vim.keymap.set("n", "<leader>ha", function()
	harpoon:list():add()
end, { desc = "[H]arpoon [A]dd" })
vim.keymap.set("n", "<leader>hl", function()
	harpoon.ui:toggle_quick_menu(harpoon:list())
end, { desc = "[H]arpoon [L]ist" })
vim.keymap.set("n", "<leader>hn", function()
	harpoon:list():next()
end, { desc = "[H]arpoon [N]ext" })
vim.keymap.set("n", "<leader>hp", function()
	harpoon:list():prev()
end, { desc = "[H]arpoon [P]revious" })
vim.keymap.set("n", "<leader>h1", function()
	harpoon:list():select(1)
end, { desc = "[H]arpoon [1]st menu item" })
vim.keymap.set("n", "<leader>h2", function()
	harpoon:list():select(2)
end, { desc = "[H]arpoon [2]nd menu item" })
vim.keymap.set("n", "<leader>h3", function()
	harpoon:list():select(3)
end, { desc = "[H]arpoon [3]rd menu item" })
vim.keymap.set("n", "<leader>h4", function()
	harpoon:list():select(4)
end, { desc = "[H]arpoon [4]th menu item" })
