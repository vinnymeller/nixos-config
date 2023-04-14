require("copilot").setup({
    suggestion = {
        auto_trigger = true,
        keymap = {
            accept = false,
        },
    },
    filetypes = {
        ["*"] = true,
    },
})

local cosug = require("copilot.suggestion")
vim.keymap.set("i", "<Tab>", function()
    if cosug.is_visible() then
        cosug.accept()
    else
        vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Tab>", true, false, true), "n", false)
    end
end, {
    silent = true,
    }
)
