local dap = require("dap")
require("dapui").setup()

require("dap-lldb").setup({
    codelldb_path = vim.env.CODELLDB_PATH,
})

require("dap-python").setup("python3")

vim.keymap.set("n", "<leader>du", "<cmd>lua require('dapui').toggle()<CR>", { desc = "DAP: Toggle UI" })
vim.keymap.set("n", "<leader>dc", "<cmd>lua require('dap').continue()<CR>", { desc = "DAP: Continue" })
vim.keymap.set(
    "n",
    "<leader>dt",
    "<cmd>lua require('dap').toggle_breakpoint()<CR>",
    { desc = "DAP: Toggle Breakpoint" }
)
vim.keymap.set("n", "<leader>dsi", "<cmd>lua require('dap').step_into()<CR>", { desc = "DAP: Step Into" })
vim.keymap.set("n", "<leader>dso", "<cmd>lua require('dap').step_over()<CR>", { desc = "DAP: Step Over" })

dap.adapters.lldb = {
    type = "executable",
    command = vim.env.CODELLDB_PATH,
    name = "lldb",
}

dap.configurations.rust = {
    {
        name = "Launch debug",
        type = "lldb",
        request = "launch",
        program = function()
            return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/target/debug/", "file")
        end,
        cwd = "${workspaceFolder}",
        stopOnEntry = false,
    },
}

dap.configurations.python = {
    {
        type = "python",
        request = "launch",
        name = "Launch file",
        program = "${file}",
        python = "python3",
        cwd = "${workspaceFolder}",
        console = "integratedTerminal",
    },
    {
        type = "python",
        request = "attach",
        name = "Attach to debugpy :5678",
        connect = {
            host = "127.0.0.1",
            -- port = 5678
            port = function()
                return tonumber(vim.fn.input("Port: ", "5678"))
            end,
        },
        justMyCode = false,
    },
}
