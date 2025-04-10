-- require("copilot").setup({
--     panel = { enabled = false },
--     suggestion = {
--         enabled = true,
--         auto_trigger = true,
--         keymap = {
--             accept = "<C-c>",
--         },
--     },
--     -- enable all filetypes
--     filetypes = {
--         ["*"] = true,
--     },
-- })

vim.api.nvim_create_augroup("github_copilot", { clear = true })
vim.api.nvim_create_autocmd({ "FileType", "BufUnload" }, {
    group = "github_copilot",
    callback = function(args)
        vim.fn["copilot#On" .. args.event]()
    end,
})
vim.fn["copilot#OnFileType"]()
