vim.api.nvim_create_autocmd("LspAttach", {
    group = vim.api.nvim_create_augroup("UserLspConfig", { clear = true }),
    callback = function(event)
        -- NOTE: Remember that lua is a real programming language, and as such it is possible
        -- to define small helper and utility functions so you don't have to repeat yourself
        -- many times.
        --
        -- In this case, we create a function that lets us more easily define mappings specific
        -- for LSP related items. It sets the mode, buffer and description for us each time.
        local client = vim.lsp.get_client_by_id(event.data.client_id)
        local map = function(mode, keys, func, desc)
            if desc then
                desc = "LSP: " .. desc
            end
            vim.keymap.set(mode, keys, func, { buffer = event.buf, desc = desc })
        end
        local nmap = function(keys, func, desc)
            map("n", keys, func, desc)
        end
        local imap = function(keys, func, desc)
            map("i", keys, func, desc)
        end

        nmap("<leader>rn", vim.lsp.buf.rename, "[R]e[n]ame")
        nmap("<leader>ca", vim.lsp.buf.code_action, "[C]ode [A]ction")

        nmap("gd", vim.lsp.buf.definition, "[G]oto [D]efinition")
        nmap("gr", "<cmd>lua require('fzf-lua').lsp_references()<CR>", "[G]oto [R]eferences")
        nmap("gI", vim.lsp.buf.implementation, "[G]oto [I]mplementation")
        nmap("<leader>D", vim.lsp.buf.type_definition, "Type [D]efinition")
        nmap("<leader>lr", "<cmd>lsp restart<CR>", "[L]sp [R]estart")

        -- See `:help K` for why this keymap
        nmap("K", "<cmd>lua vim.lsp.buf.hover({border='rounded'})<CR>", "Hover Documentation")
        imap("<C-k>", vim.lsp.buf.signature_help, "Signature Documentation") -- this gets rid of digraphs but i didnt even know it existed until i set this

        -- Lesser used LSP functionality
        nmap("gD", vim.lsp.buf.declaration, "[G]oto [D]eclaration")
        nmap("<leader>wa", vim.lsp.buf.add_workspace_folder, "[W]orkspace [A]dd Folder")
        nmap("<leader>wr", vim.lsp.buf.remove_workspace_folder, "[W]orkspace [R]emove Folder")
        nmap("<leader>wl", function()
            print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
        end, "[W]orkspace [L]ist Folders")

        -- Create a command `:Format` local to the LSP buffer
        vim.api.nvim_buf_create_user_command(event.buf, "Format", function(_)
            if vim.lsp.buf.format then
                vim.lsp.buf.format()
            elseif vim.lsp.buf.formatting then
                vim.lsp.buf.formatting()
            end
        end, { desc = "Format current buffer with LSP" })


        if client ~= nil and client.server_capabilities.inlayHintProvider then
            vim.lsp.inlay_hint.enable(true)
        end
    end,
})

-- turn off lsp semantic string highlights to not override treesitter injection
vim.api.nvim_set_hl(0, "@lsp.type.string.rust", {})

vim.lsp.config("lua_ls", {
    settings = {
        Lua = {
            hint = {
                enable = true,
            },
            runtime = {
                -- Tell the language server which version of Lua you're using (most likely LuaJIT)
                version = "LuaJIT",
            },
            diagnostics = {
                globals = { "vim" },
            },
            workspace = {
                library = vim.api.nvim_get_runtime_file("", true),
                checkThirdParty = false,
            },
            -- Do not send telemetry data containing a randomized but unique identifier
            telemetry = { enable = false },
        },
    },
})
vim.lsp.enable("lua_ls")

vim.lsp.config("ltex_plus", {
    on_attach = function(client, bufnr)
        require("ltex_extra").setup({})
    end,
    settings = {
        ltex = {
            language = "en-US",
            additionalRules = {
                languageModel = "~/.ngrams/",
            },
        },
    },
})
vim.lsp.enable("ltex_plus")

vim.filetype.add({
    extension = {
        lock = "json",
    },
})
vim.lsp.config("jsonls", {
    filetypes = { "json", "lock" },
    settings = {
        json = {
            schemas = require("schemastore").json.schemas(),
            validate = { enable = true },
        },
    },
})
vim.lsp.enable("jsonls")

vim.lsp.config("yamlls", {
    settings = {
        yaml = {
            schemaStore = {
                enable = false,
                url = "",
            },
            schemas = require("schemastore").yaml.schemas(),
        },
    },
})
vim.lsp.enable("yamlls")

vim.lsp.config("nixd", {
    cmd = { "nixd", "--semantic-tokens=false" },
    settings = {
        nixd = {
            nixpkgs = {
                expr = "import <nixpkgs> { }",
            },
            formatting = {
                command = { "nixfmt" },
            },
        },
    },
})
vim.lsp.enable("nixd")

vim.lsp.config("html", {
    filetypes = { "html", "htmldjango" },
})
vim.lsp.enable("html")

local basic_servers = {
    "ccls",
    "docker_language_server",
    "gopls",
    "taplo",
    "terraformls",
}

-- TODO: check upstream for when they fix the annoying issue with nvim 0.11
-- require("tailwind-tools").setup({})

-- try ty for a bit
vim.lsp.config("basedpyright", {
    settings = {
        basedpyright = {
            analysis = {
                autoImportCompletions = true,
                autoSearchPaths = true,
                diagnosticMode = "openFilesOnly",
                useLibraryCodeForype = true,
            },
        },
    },
})
vim.lsp.enable("basedpyright")

-- vim.lsp.config("ty", {
--     settings = {
--         ty = {},
--     },
-- })
-- vim.lsp.enable("ty")

local prettier = require("efmls-configs.formatters.prettier")
local eslint = require("efmls-configs.linters.eslint")
local languages = {
    -- html = {
    -- 	prettier_d,
    -- },
    -- htmldjango = {
    -- 	prettier_d,
    -- },
    -- css = {
    -- 	prettier_d,
    -- },
    typescript = {
        -- prettier_d,
        eslint,
        prettier,
    },
    typescriptreact = {
        eslint,
        prettier,
    },
    javascript = {
        eslint,
        prettier,
    },
    javascriptreact = {
        eslint,
        prettier,
    },
    go = {
        require("efmls-configs.formatters.gofmt"),
        require("efmls-configs.formatters.goimports"),
    },
    lua = {
        require("efmls-configs.formatters.stylua"),
    },
    python = {
        require("efmls-configs.formatters.ruff"),
    },
    nix = {
    	require("efmls-configs.formatters.nixfmt"),
    },
    sh = {
        require("efmls-configs.formatters.shfmt"),
        require("efmls-configs.linters.shellcheck"),
    },
    sql = {
        require("efmls-configs.formatters.sql-formatter"),
    },
    plsql = {
        require("efmls-configs.formatters.sql-formatter"),
    },
    json = {
        require("efmls-configs.formatters.prettier_d"),
    },
    yaml = {
        require("efmls-configs.formatters.prettier_d"),
    },
}

local efmls_config = {
    filetypes = vim.tbl_keys(languages),
    settings = {
        rootMarkers = { ".git/" },
        languages = languages,
    },
    init_options = {
        documentFormatting = true,
        documentRangeFormatting = true,
    },
}

vim.lsp.config("efm", vim.tbl_extend("force", efmls_config, {}))
vim.lsp.enable("efm")

for _, lsp in ipairs(basic_servers) do
    vim.lsp.enable(lsp)
end

-- Turn on lsp status information
require("fidget").setup({})

require("typescript-tools").setup({})
