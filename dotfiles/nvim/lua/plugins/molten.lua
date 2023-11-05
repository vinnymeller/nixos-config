vim.g.molten_image_provider = "image.nvim"

vim.keymap.set(
	"n",
	"<localleader>R",
	":MoltenEvaluateOperator<CR>",
	{ silent = true, noremap = true, desc = "run operator selection" }
)
vim.keymap.set(
	"n",
	"<localleader>rl",
	":MoltenEvaluateLine<CR>",
	{ silent = true, noremap = true, desc = "evaluate line" }
)
vim.keymap.set(
	"n",
	"<localleader>rc",
	":MoltenReevaluateCell<CR>",
	{ silent = true, noremap = true, desc = "re-evaluate cell" }
)
vim.keymap.set(
	"v",
	"<localleader>r",
	":<C-u>MoltenEvaluateVisual<CR>gv",
	{ silent = true, noremap = true, desc = "evaluate visual selection" }
)
