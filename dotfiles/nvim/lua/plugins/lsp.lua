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
        nmap("<leader>lr", "<cmd>LspRestart | e!<CR>", "[L]sp [R]estart")

        -- See `:help K` for why this keymap
        nmap("K", vim.lsp.buf.hover, "Hover Documentation")
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

require("blink.compat").setup({})
require("blink.cmp").setup({
    fuzzy = {
        prebuilt_binaries = {
            download = false,
        },
    },
    keymap = {
        ["<C-space>"] = { "show", "show_documentation", "hide_documentation" },
        ["<C-e>"] = { "cancel", "fallback" },

        ["<Tab>"] = {
            function(cmp)
                if vim.snippet.active() then
                    return cmp.accept()
                else
                    return cmp.select_and_accept()
                end
            end,
            "snippet_forward",
            "fallback",
        },
        ["<S-Tab>"] = { "snippet_backward", "fallback" },

        ["<Up>"] = { "select_prev", "fallback" },
        ["<Down>"] = { "select_next", "fallback" },
        ["<C-p>"] = { "select_prev", "fallback" },
        ["<C-n>"] = { "select_next", "fallback" },
        ["<C-y>"] = { "select_and_accept" },

        ["<C-d>"] = { "scroll_documentation_up", "fallback" },
        ["<C-f>"] = { "scroll_documentation_down", "fallback" },
    },
    signature = {
        enabled = true,
    },
    completion = {
        accept = {
            auto_brackets = {
                enabled = true,
            },
        },
        documentation = {
            auto_show = true,
            auto_show_delay_ms = 50,
        },
        trigger = {
            show_in_snippet = true,
        },
        menu = {
            draw = {
                align_to = "label",
                padding = 1,
                gap = 1,
                columns = {
                    { "label", "label_description", gap = 1 },
                    { "kind_icon" },
                },
                components = {
                    kind_icon = {
                        ellipsis = false,
                        text = function(ctx)
                            return ctx.kind_icon .. " "
                        end,
                        highlight = function(ctx)
                            return "BlinkCmpKind" .. ctx.kind
                        end,
                    },

                    kind = {
                        ellipsis = false,
                        text = function(ctx)
                            return ctx.kind .. " "
                        end,
                        highlight = function(ctx)
                            return "BlinkCmpKind" .. ctx.kind
                        end,
                    },

                    label = {
                        width = { fill = true, max = 60 },
                        text = function(ctx)
                            return ctx.label .. (ctx.label_detail or "")
                        end,
                        highlight = function(ctx)
                            -- label and label details
                            local highlights = {
                                {
                                    0,
                                    #ctx.label,
                                    group = ctx.deprecated and "BlinkCmpLabelDeprecated" or "BlinkCmpLabel",
                                },
                            }
                            if ctx.label_detail then
                                table.insert(
                                    highlights,
                                    { #ctx.label, #ctx.label + #ctx.label_detail, group = "BlinkCmpLabelDetail" }
                                )
                            end

                            -- characters matched on the label by the fuzzy matcher
                            if ctx.label_matched_indices ~= nil then
                                for _, idx in ipairs(ctx.label_matched_indices) do
                                    table.insert(highlights, { idx, idx + 1, group = "BlinkCmpLabelMatch" })
                                end
                            end

                            return highlights
                        end,
                    },

                    label_description = {
                        width = { max = 30 },
                        text = function(ctx)
                            return ctx.label_description or ""
                        end,
                        highlight = "BlinkCmpLabelDescription",
                    },
                },
            },
        },
    },
    sources = {
        default = {
            "lsp",
            "path",
            "codecompanion",
            "snippets",
            "buffer",
            "dadbod",
        },
        providers = {
            dadbod = {
                name = "Dadbod",
                module = "vim_dadbod_completion.blink",
            },
        },
    },
})

-- nvim-cmp supports additional completion capabilities
-- local capabilities = vim.lsp.protocol.make_client_capabilities()
-- local capabilities = {}
-- local capabilities = require("blink.cmp").get_lsp_capabilities()
-- capabilities = require("cmp_nvim_lsp").default_capabilities(capabilities)
-- capabilities = require("blink.cmp").get_lsp_capabilities(capabilities)

require("lspconfig").lua_ls.setup({
    -- on_attach = on_attach,
    -- capabilities = capabilities,
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

require("lspconfig").ltex.setup({
    -- capabilities = capabilities,
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

vim.filetype.add({
    extension = {
        lock = "json",
    },
})
require("lspconfig").jsonls.setup({
    -- capabilities = capabilities,
    filetypes = { "json", "lock" },
    settings = {
        json = {
            schemas = require("schemastore").json.schemas(),
            validate = { enable = true },
        },
    },
})

require("lspconfig").yamlls.setup({
    -- capabilities = capabilities,
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

require("lspconfig").nixd.setup({
    -- capabilities = capabilities,
    cmd = { "nixd", "--semantic-tokens=false" },
    settings = {
        nixd = {
            formatting = {
                command = { "nixfmt" },
            },
        },
    },
})

-- htmx lsp is fucking up all the other ones and i dont get proper html and tailwind autocomplete for some reason
-- figure out later TODO
-- require("lspconfig").htmx.setup({
-- 	capabilities = capabilities,
-- 	filetypes = { "html", "htmldjango" },
-- })

require("lspconfig").html.setup({
    -- capabilities = capabilities,
    filetypes = { "html", "htmldjango" },
})

local basic_servers = {
    "ccls",
    "dockerls",
    "gopls",
    "hls",
    "ocamllsp",
    "pyright",
    "tailwindcss",
    "taplo",
    "terraformls",
}

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
        require("efmls-configs.formatters.black"),
        require("efmls-configs.formatters.isort"),
    },
    -- nix = {
    -- 	require("efmls-configs.formatters.nixfmt"),
    -- },
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

require("lspconfig").efm.setup(vim.tbl_extend("force", efmls_config, {
    -- capabilities = capabilities,
}))

for _, lsp in ipairs(basic_servers) do
    require("lspconfig")[lsp].setup({
        -- capabilities = capabilities,
    })
end

-- Turn on lsp status information
require("fidget").setup({})

require("typescript-tools").setup({})
