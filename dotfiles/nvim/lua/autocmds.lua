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
-- vim.api.nvim_create_autocmd({ "WinLeave", "FocusLost" }, {
-- 	callback = function()
-- 		-- silntry try calling a command
-- 		vim.cmd([[silent! LspFormat]])
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

-- make any file that starts with "Dockerfile" be recognized as a dockerfile, not just strictly ^Dockerfile$
vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
    pattern = "*Dockerfile*",
    callback = function()
        vim.bo.filetype = "dockerfile"
    end,
})

vim.api.nvim_create_autocmd("FileType", {
    pattern = "xml",
    callback = function()
        vim.api.nvim_buf_create_user_command(0, "FormatXML", function(_)
            vim.cmd(
                string.format(
                    [[%%!%s -c "import xml.dom.minidom, sys; print(xml.dom.minidom.parse(sys.stdin).toprettyxml())"]],
                    vim.g.python3_host_prog
                )
            )
        end, { desc = "Format XML file" })
        vim.keymap.set("n", "<leader>xml", "<cmd>FormatXML<CR>", { buffer = 0, desc = "Format XML file" })
    end,
})
